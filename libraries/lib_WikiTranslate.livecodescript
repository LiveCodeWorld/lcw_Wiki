script "lib_WikiTranslate"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_WikiTranslate
type: library
version: 0.2

/*Some help*/


--> Working on
-
function transcribe_TitleFromShortFile shortAudioFile
   set the itemdelimiter to "."
   put item 1 of shortAudioFile into testTitle
   --
   switch
      case char 1 to 2 of testTitle is a number
         delete word 1 of testTitle
         return testTitle
      case word -1 of testTitle is a number
         put word 1 to -2 of testTitle into stemTitle         
         return stemTitle
      case testTitle contains "-"
         set the itemdelimiter to "-"
         put item 2 to -1 of testTitle into stemTitle         
         return word 1 to -1 of stemTitle
      default
         return testTitle
   end switch
end transcribe_TitleFromShortFile

private function _CreateSeriesArray foundTitles
   local seriesArray
   repeat for each line foundTitle in foundTitles
      if word -1 of foundTitle is a number then
         put word 1 to -2 of foundTitle into stemTitle         
         put empty into seriesArray [stemTitle][foundTitle]
      end if
   end repeat  
   return seriesArray
end _CreateSeriesArray


--> WikiPage | Transcript | Add
-
function wikiPage_AddTidiedTranscript pageSlug, wikiDomain, pTidySlug
   put pageArray_Get (wikiDomain, pageSlug) into pageArray
   put transcribe_GetWavText (pageSlug, wikiDomain) into sTranscript
   transcribe_AddTidied pageArray, sTranscript, pTidySlug
   return pageArray
end wikiPage_AddTidiedTranscript


--> WikiPage | Graph and Summary
-
function wikiPage_GetGraphAndSummary pageSlug, wikiDomain, pGraphAndSummaryText, pFolderPageTitle
   if pGraphAndSummaryText is empty then
      put transcribe_GetGraphAndSummaryText (pageSlug, wikiDomain) into pGraphAndSummaryText
   end if
   
   put wikiPage_ConstructTranscriptPageArray (pageSlug, wikiDomain, pFolderPageTitle) into pageArray
   wikiPage_ReplaceTranscriptSummary pageArray, pGraphAndSummaryText
   return pageArray
end wikiPage_GetGraphAndSummary

function wikiPage_MissingPages folderPageSlug, wikiDomain, pFolderPageTitle
   if pFolderPageTitle is empty then
      put fedwiki_ConstructTitle (folderPageSlug) into pFolderPageTitle
   end if
   
   # Create ghost pageArray
   put "Missing" && pFolderPageTitle into missingTitle
   put pageArray_Construct (missingTitle, "Here are some missing pages. Use the buttons to create ghost pages from the audio files provided.", "markdown") into pageArray
   
   # Missing Button Section
   _AddMissingButtonSection pageArray, folderPageSlug, wikiDomain, pFolderPageTitle
   put the result into foundTitleMarkdown
   
   # Found Titles section
   if foundTitleMarkdown is not empty then
      put "# Transcribed Audio" & CR before foundTitleMarkdown
      pageArray_AddMarkdown pageArray, foundTitleMarkdown
   end if
   
   # Stem section
   _AddStemSection pageArray, seriesArray
   
   return pageArray
end wikiPage_MissingPages

function wikiPage_AudioFolder folderPageTitle, wikiDomain
   # Get Dialogue and merge
   put pageArray_GetDialogue ("Recording Folder Dialogue", folderPageTitle) into pageArray
   delete variable pageArray ["plugin"]
   --
   put fedwiki_ConstructSlug (folderPageTitle) into folderPageSlug
   
   # Replace Bullets
   put wikiFile_MissingPageMarkDown (folderPageSlug, wikiDomain) into missingMD
   curly_ReplacePageArray pageArray, "audioPageBullets", missingMD
   
   # Replace Curly
   curly_ReplacePageArray pageArray, "wikiDomain", wikiDomain
   curly_ReplacePageArray pageArray, "pageSlug", folderPageSlug
   curly_ReplacePageArray pageArray, "pageTitle", folderPageTitle
   --
   return pageArray
end wikiPage_AudioFolder

function wikiPage_ConstructTranscriptPageArray pageSlugToCreate, pTranscriptDomain, pFolderPageTitle
   put "- [[Test Audio Link]]" into audioPageBullets
   
   if pFolderPageTitle is empty then put "Transcript Template" into pFolderPageTitle
   put fedwiki_ConstructTitle (pageSlugToCreate) into pageTitle
   
   # Construct
   put pageArray_Get (pTranscriptDomain, "transcript-template") into pageArray
   if pageArray is not an array then
      return "Error, cannot locate template 'transcript-template"
   end if
   
   # Construct
   put pageTitle into pageArray ["title"]
   curly_ReplacePageArray pageArray, "pageSlug", pageSlugToCreate
   curly_ReplacePageArray pageArray, "audioPageBullets", audioPageBullets
   
   # Set Audio Text   
   put transcribe_WavURL (pageSlugToCreate, pTranscriptDomain) into wavURL
   put "[[" & pageTitle & "]]" into sText
   put wavURL &CR& sText into audioText
   pageArray_SetFirstItem pageArray, "audio", audioText
   
   return pageArray
end wikiPage_ConstructTranscriptPageArray

command wikiPage_ReplaceTranscriptSummary @pageArray, mdText
   put transcribe_ConstructSummaryStoryArray (mdText) into storyArray
   pageArray_ReplaceSection pageArray, "Summary", storyArray
end wikiPage_ReplaceTranscriptSummary


--> WikiPage | Transcript | Stub (old)
-
function wikiPage_Transcript wikiDomain, pageSlug, pFromOggSlug, pTranscriptDomain, pFolderPageTitle
   -- "wikiPage_CombinedTranscript" is a scripted version of this?
   put wikiPage_TranscriptStub (wikiDomain, pageSlug, pFromOggSlug, pTranscriptDomain, pFolderPageTitle) into pageArray
   
   # Fetch ChapGPT Summary
   put transcribe_GetWavText (pageSlug, wikiDomain) into sTranscript
   put openAI_GetText (sTranscript, "graph-and-summary", "gpt-4") into mdText
   
   # Replace Summary
   wikiPage_ReplaceTranscriptSummary pageArray, mdText
   
   # Strip and Return
   pageArray_StripJournal pageArray
   pageArray_AddChatGptCred pageArray
   return pageArray
end wikiPage_Transcript

function wikiPage_CombinedTranscript sTranscript, pageTitle, pageSlug, wikiDomian, tShortTitles, pNotify
   # Fetch Whisper graph-and-summary sections
   if pNotify is not false then
      get "Summarizing transcript for" && pageTitle && "using the 'Graph and Summary' prompt. This may take quite a bit of time..."
      lcw_Notify it
   end if
   put openAI_GetText (sTranscript, "graph-and-summary", "gpt-4") into mdText
   
   # Extract sections 
   put markdown_GetSection (mdText) into summaryText
   put markdown_GetSection (mdText, "Keywords") into keyWordSection
   put markdown_GetSection (mdText, "Graph", mdText) into graphSection
   
   put "On this page we transcribe and summarise the audio below." into sText
   put pageArray_Construct (pageTitle, sText, "markdown") into pageArray
   
   # Add Audios
   repeat for each item tShortTitle in tShortTitles
      put fedwiki_ConstructSlug (tShortTitle) into tShortFolder
      put transcribe_WavURL (tShortFolder, wikiDomian) into audioUrl
      --
      put "[[" & tShortTitle & "]]" into someText
      pageArray_AddAudio pageArray, audioUrl, someText
   end repeat
   
   # Add Summary
   pageArray_AddMarkdown pageArray, "# Summary"
   pageArray_AddMarkdown pageArray, summaryText
   
   # Add Tidied Transcript
   transcribe_AddTidied pageArray, sTranscript
   
   # Add Keywords
   -- pageArray_AddMarkdown pageArray, "# Keywords"
   pageArray_AddMarkdown pageArray, keyWordSection
   
   # Add Graph
   pageArray_AddMarkdown pageArray, "# Graph"
   put line 2 to -1 of graphSection into pDot
   if char 1 to 3 of pDot = "```" then delete char 1 to 3 of pDot
   storyArray_AddGraphviz storyArray, pDot, pDot
   if char -3 to -1 of pDot = "```" then delete char -3 to -1 of pDot
   pageArray_AddGraphviz pageArray, pDot, pDot
   
   # Add Assets
   pageArray_AddMarkdown pageArray, "# Assets"
   -- pageArray_AddAssets pageArray, pageSlug
   repeat for each item tShortTitle in tShortTitles
      put fedwiki_ConstructSlug (tShortTitle) into tShortFolder
      pageArray_AddAssets pageArray, tShortFolder
   end repeat
   
   # Add See also
   pageArray_AddMarkdown pageArray, "# See also"
   pageArray_AddMarkdown pageArray, "- [[Astral Thoughts]]"
   
   pageArray_StripJournal pageArray
   pageArray_AddChatGptCred pageArray
   --
   return pageArray
end wikiPage_CombinedTranscript

function wikiPage_TranscriptStub wikiDomain, pageSlugToCreate, pFromOggSlug, pTranscriptDomain, pFolderPageTitle
   if pTranscriptDomain is empty then put "transcript.thought.garden" into pTranscriptDomain
   
   if pFromOggSlug is not empty then
      #  Find oggFile
      put transcribe_FindOggFile (pageSlugToCreate) into oggFile
      if there is not a file oggFile then
         return pageArray_Construct ("Error", "Cannot fine ogg file", "markdown")
      end if
      
      # Transcode audio
      put transcribe_ConstructWavFile (pageSlugToCreate, pTranscriptDomain) into wavFile
      if there is not a file wavFile then
         set the cursor to watch
         ffmpeg_ExportAudioAsWav oggFile, wavFile
      end if
   else
      # Transcode audio
      put transcribe_ConstructWavFile (pageSlugToCreate, pTranscriptDomain) into wavFile
      if there is not a file wavFile then
         return "Error, wav file does not exist:" && wavFile
      end if
   end if
   
   # Transcribe Audio (export files)
   set the cursor to watch
   get whisper_GetTranscript (wavFile)   
   
   # Construct PageArray
   put wikiPage_ConstructTranscriptPageArray (pageSlugToCreate, pTranscriptDomain, pFolderPageTitle) into pageArray
   
   return pageArray
end wikiPage_TranscriptStub


--> Wiki | Translate
-
function wikiPage_Translation wikiDomain, pageSlug, sLang, pModel
   # Get userText
   put wikiPage_Get (wikiDomain, pageSlug) into pageArray
   put pageArray_Text (pageArray) into userText
   
   put wikiPage_FetchTranslation (userText, sLang, pModel) into sTranslation
   if sTranslation is empty then
      put pageArray_Construct ("Timeout", "Translation timed out. Try again?", "markdown") into pageArray
      send "wikiServer_Reset" to me in 30 ticks
      return pageArray
   else   
      put pageArray ["title"] into pageTitle
      put wikiPage_ConstructTranslation (sLang, sTranslation, wikiDomain, pageSlug, pageTitle, userText) into tPageArray
      return tPageArray
   end if
end wikiPage_Translation

function wikiPage_FetchTranslation userText, sLang, pModel
   if sLang is empty then put "Welsh" into sLang
   put platform_GetPrompt ("translate") into sPrompt
   
   # Set language
   put text_InitialCaps (sLang) into sLang
   curly_ReplaceText sPrompt, "language", sLang
   
   # Translate using ChatGPT
   put openAI_FetchChatData (userText, sPrompt, pModel) into rData
   if rData is not an array then
      return empty
   else
      put rData ["choices"][1]["message"]["content"] into binaryData
      put textDecode (binaryData, "UTF-8") into sTranslation
      return sTranslation
   end if
end wikiPage_FetchTranslation

function wikiPage_ConstructTranslation sLang, sTranslation, wikiDomain, pageSlug, pageTitle, userText
   # Construct pageArray
   put sLang && "Translation" into tranTitle
   put "[[ChatGPT]]" into sLink
   put merge ("The following is a first draft [[sLink]] mediated translation of the '[[pageTitle]]' wiki-page into [[sLang]]:") into someMD
   put pageArray_Construct (tranTitle, someMD, "markdown") into pageArray
   
   # Add Translation
   -- put "# Translation" into sTitle
   put "#" && tranTitle into sTitle
   pageArray_AddMarkdown pageArray, sTitle
   pageArray_AddMarkdown pageArray, sTranslation
   
   # Add Text-to-Speech button
   put transport_ConstructHiddenArray (wikiDomain, pageSlug, pageTitle) into hiddenArray
   put sLang into hiddenArray ["sLang"]
   put urlEncode (sTranslation) into hiddenArray ["eTranslation"]
   put "http://rest.livecode.world/augmented/add_Audio" into postURL
   put postURL into hiddenArray ["postURL"]
   --
   put wikiSnippet_CurlyGet ("text-to-speech-form", hiddenArray) into formHTML
   pageArray_AddHTML pageArray, formHTML
   -- pageArray_AddButton pageArray, "Add Audio", postURL, hiddenArray, "", "right", "lightgreen"
   
   # Add userText
   pageArray_AddMarkdown pageArray, "# Original"
   pageArray_AddMarkdown pageArray, userText
   
   return pageArray
end wikiPage_ConstructTranslation


--> Private
-
private command _AddMissingButtonSection @pageArray, folderPageSlug, wikiDomain, folderPageTitle
   put wikiFile_ListPageSlugs (wikiDomain) into pageSlugs
   put wikiFile_ListShort (folderPageSlug, wikiDomain) into shortAudioFiles
   --
   put wikiFolder_ConstructPageAssets (folderPageSlug, wikiDomain) into rawAudioFolder
   
   # Curly Merge
   -- curly_ReplacePageArray pageArray, "folderPageTitle", folderPageTitle
   put folderPageTitle into valueArray ["folderPageTitle"]
   
   put "http://rest.livecode.world/transcribe/create_Missing" into postURL
   put empty into sLabel
   put wikiDomain into valueArray ["wikiDomain"]
   --
   repeat for each line shortAudioFile in shortAudioFiles
      put rawAudioFolder & shortAudioFile into audioFile
      put transcribe_TitleFromShortFile (shortAudioFile) into testTitle
      --
      put fedwiki_ConstructSlug (testTitle) into testSlug
      if testSlug is among the lines of pageSlugs then
         put testTitle &CR after foundTitles
         put "- [[" & testTitle & "]]" & CR after foundTitleMarkdown
         next repeat
      end if
      
      put testSlug & CR after missingSlugs
      put "[[" & testTitle & "]]" & CR after missingTitles
      --
      put testSlug into valueArray ["pageSlug"]
      put testTitle into valueArray ["pageTitle"]
      put rawAudioFolder into valueArray ["rawAudioFolder"]
      put audioFile into valueArray ["rawAudioFile"]
      --
      pageArray_AddButton pageArray, testTitle, postURL, valueArray, sLabel, "right"
   end repeat
   delete char -1 of missingSlugs
   delete char -1 of foundTitles
   delete char -1 of foundTitleMarkdown
   
   return foundTitleMarkdown
end _AddMissingButtonSection

private command _AddStemSection @pageArray, foundTitles, folderPageSlug, wikiDomain
   put wikiFolder_ConstructPageAssets (folderPageSlug, wikiDomain) into rawAudioFolder
   put rawAudioFolder into valueArray ["rawAudioFolder"]
   put folderPageSlug into valueArray ["folderPageSlug"]
   put wikiDomain into valueArray ["wikiDomain"]
   
   put _CreateSeriesArray (foundTitles) into seriesArray
   put keys (seriesArray) into stemKeys
   if stemKeys is empty then return empty
   
   pageArray_AddMarkdown pageArray, "# Stem Titles"
   put "http://rest.livecode.world/transcribe/join_Missing" into postURL
   put empty into sLabel
   repeat for each key stemTitle in seriesArray 
      put fedwiki_ConstructSlug (stemTitle) into stemSlug
      put stemSlug into valueArray ["pageSlug"]
      put stemTitle into valueArray ["pageTitle"]
      --
      get seriesArray [stemTitle]
      put keys (it) into valueItems
      replace CR with comma in valueItems
      put valueItems into valueArray ["tShortFolders"]
      --
      pageArray_AddButton pageArray, stemTitle, postURL, valueArray, sLabel, "right"
   end repeat
   return stemKeys
end _AddStemSection
