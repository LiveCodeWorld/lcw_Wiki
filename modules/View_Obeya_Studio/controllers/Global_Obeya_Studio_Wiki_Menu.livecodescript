script "Global | Obeya | Studio | Wiki | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Obeya | Studio | Wiki | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray


--> Menu | Props
-
getprop menu_Target [tObject]
   -- return _BrowserView(tObject)
   put the browser_View of tObject into browserView
   if exists (browserView) is false then
      put line 1 of display_List ("View|Obeya|Studio") into browserView
      if exists (browserView) is false then
         return empty
      end if
   end if
   
   # Lineup URLs are faster than LineUp Data
   put the lineup_Urls of browserView into lineUpURLs
   put lineUpURLs into LocalArray ["lineUpURLs"]
   
   # PageTitles
   put _SlugsFromLineUpURLs (lineUpURLs) into LocalArray ["pageTitles"]
   
   return browserView
end menu_Target

private function _SlugsFromLineUpURLs lineUpURLs
   -- put the page_Titles of browserView into LocalArray ["pageTitles"]
   put 1 into indexNum
   repeat for each line sURL in lineUpURLs
      set the itemdelimiter to slash
      put item -1 of sURL into pageSlug
      set the itemdelimiter to "."
      delete item -1 of pageSlug
      
      if pageSlug is among the lines of pageSlugs then
         /*
         set the itemdelimiter to slash
         get item 1 of sURL 
         set the itemdelimiter to ":"
         put item -1 of it into wikiDomain
         put wikiDomain && pageSlug & CR after pageSlugs
         */
         put indexNum  & CR after pageSlugs 
      else
         put pageSlug & CR after pageSlugs
      end if
      add 1 to indexNum
   end repeat
   delete char -1 of pageSlugs
   return pageSlugs
end _SlugsFromLineUpURLs

private function _TranslatePageJson browserView, pageTitle, sLang, pModel, pIncludeOriginal
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put the wiki_Domain of browserView into wikiDomain
   --
   put _GetPageText (browserView, pageSlug) into pageText
   
   # Fetch ChatGPT translation
   set the cursor to watch
   put pageTitle & CR before pageText
   put wikiPage_FetchTranslation (pageText, sLang, pModel) into sTranslation
   put line 1 of sTranslation into utf8Title
   put textDecode (utf8Title, "UTF-8") into translatedTitle
   delete line 1 of pageText
   delete line 1 of sTranslation
   
   # Construct PageArray
   put _ConstructPageJson (sLang, sTranslation, wikiDomain, pageSlug, pageTitle, pageText, translatedTitle, pIncludeOriginal) into pageJSON
   return pageJSON
end _TranslatePageJson

function _ConstructPageJson sLang, sTranslation, wikiDomain, pageSlug, pageTitle, pageText, translatedTitle, pIncludeOriginal
   -- we use replaceText on JSON to avoid utf8 chat issues with json_FromArray
   put urlEncode (sTranslation) into encodedTranslation
   put "{{sTranslation}}" into curlyStub
   
   # Construct pageArray
   -- put sLang && "Translation" into translatedTitle
   
   put "The following is a first draft [[ChatGPT]] mediated translation of the [[{{pageTitle}}]] wiki-page into [[{{sLang}}]]:" into someMD
   curly_ReplaceText someMD, "pageTitle", pageTitle
   curly_ReplaceText someMD, "sLang", sLang
   put pageArray_Construct ("{{pageTitle}}", someMD, "markdown") into pageArray
   
   # Add Translation
   put "# Translation" into sTitle
   -- put "#" && translatedTitle into sTitle
   pageArray_AddMarkdown pageArray, sTitle
   pageArray_AddMarkdown pageArray, curlyStub
   
   # Add Text-to-Speech button
   put transport_ConstructHiddenArray (wikiDomain, pageSlug, pageTitle) into hiddenArray
   put sLang into hiddenArray ["sLang"]
   put encodedTranslation into hiddenArray ["eTranslation"]
   
   put "{{translatedTitle}}" into hiddenArray ["translatedTitle"]
   put "http://rest.livecode.world/augmented/add_Audio" into hiddenArray ["postURL"]
   
   pageArray_AddMarkdown pageArray, "# Speak"
   put wikiSnippet_CurlyGet ("text-to-speech-form", hiddenArray) into formHTML
   pageArray_AddHTML pageArray, formHTML
   
   pageArray_AddMarkdown pageArray, "To record audio for an edited version of this text, first save this page, then edit the translation and use the button below:"
   
   put empty into hiddenArray ["eTranslation"]
   put "http://rest.livecode.world/augmented/add_PageAudio" into hiddenArray ["postURL"]
   put wikiSnippet_CurlyGet ("text-to-speech-form", hiddenArray) into formHTML
   pageArray_AddHTML pageArray, formHTML
   
   if pIncludeOriginal is true then
      # Add pageText
      pageArray_AddMarkdown pageArray, "# Original"
      pageArray_AddMarkdown pageArray, pageText
   end if
   
   # Strip and Return
   pageArray_StripJournal pageArray
   pageArray_AddChatGptCred pageArray
   
   # Replace translated PageTitle and sTranslation
   put json_FromArray (pageArray) into pageJSON
   
   curly_ReplaceText pageJSON, "PageTitle", translatedTitle
   
   put textDecode (translatedTitle, "UTF-8") into utf8TranslatedTitle
   curly_ReplaceText pageJSON, "translatedTitle", utf8TranslatedTitle
   
   put textDecode (sTranslation, "UTF-8") into sTranslation
   replace CR with "\n" in sTranslation
   put replaceText (pageJSON, curlyStub, sTranslation) into pageJSON
   
   return pageJSON
end _ConstructPageJson

private function _GetPageText browserView, pageSlug
   -- put the lineUp_Data [pageSlug] of browserView into pageArray
   put the lineUp_PageArray [pageSlug] of browserView into pageArray
   put pageArray_Text (pageArray) into pageText
   return pageText
end _GetPageText

private function _BrowserView tObject
   if exists (tObject) then
      put the browser_View of testView into browserView
      return browserView
   else
      return empty
   end if
end _BrowserView

getprop disabled_DisplayWiki [browserView]
   return exists (browserView) is false
end disabled_DisplayWiki

getprop displayDomain_Param [browserView]
   put the browser_Domain of browserView into wikiDomain
   return wikiDomain
end displayDomain_Param

getprop displayDomain_Params
   put wikiFolder_ListTopLevel() into wikiDomains
   --
   if wikiDomains is empty then
      return "ChatGPT,Localhost"
   else
      return wikiDomains & ",-,ChatGPT,Localhost"
   end if
end displayDomain_Params

getprop speak_Params [browserView]
   return LocalArray ["pageTitles"]
end speak_Params

getprop translateToGerman_Params [browserView]
   return LocalArray ["pageTitles"]
end translateToGerman_Params

getprop translateToIcelandic_Params [browserView]
   return LocalArray ["pageTitles"]
end translateToIcelandic_Params

getprop translateToWelsh_Params [browserView]
   return LocalArray ["pageTitles"]
end translateToWelsh_Params

getprop checked_MoveDomains [wikiView]
   return false
end checked_MoveDomains

getprop checked_LiveServer [wikiView]
   return true
end checked_LiveServer

getprop moveDomains_Params [wikiView]
   return wikiGarden_ListUniqueNames()
end moveDomains_Params

getprop createGardenPage_Params
   return wikiGarden_ListUniqueNames()
end createGardenPage_Params


--> Global | Obeya | Studio | Wiki | Menu
-
on menu_DisplayDomain browserView, wikiDomain   
   if the shiftKey is "down" then put empty into browserView
   switch wikiDomain
      case "ChatGPT"
         display_WikiBrowser "https://chat.openai.com/", browserView
         break
      default
         display_Wiki wikiDomain, browserView
   end switch
end menu_DisplayDomain

on menu_NodeServer wikiView
   if _DaemonIsRunning (wsView) is true then
      set the daemon_IsRunning of wsView to false
      wikiServer_StartNode
   else
      wikiServer_StopNode
      set the daemon_IsRunning of wsView to true
   end if
end menu_NodeServer

on menu_CloseOpenSockets
   socket_CloseOpen
end menu_CloseOpenSockets

on menu_Port wsView, sPort
   set the listen_Port of wsView to sPort
end menu_Port

private on _
end _

on insert_Create
   return "Global | Wiki | Browser | Create | Menu"
end insert_Create

private on __
end __

on menu_Speak browserView, pageSlug
   put fedwiki_ConstructTitle (pageSlug) into pageTitle
   --
   put _GetPageText (browserView, pageSlug) into pageText
   --
   -- put the wiki_Domain of browserView into wikiDomain
   put the lineUP_Domain [pageSlug] of browserView into wikiDomain
   --
   put pageSlug & ".mp3" into shortFile
   put wiki_ConstructAssetFile (shortFile, wikiDomain) into audioFile
   --
   openAI_TextToSpeech pageText, audioFile
   --
   finder_Reveal audioFile
end menu_Speak

on menu_TranslateToGerman browserView, pageSlug
   put fedwiki_ConstructTitle (pageSlug) into pageTitle
   --
   put _TranslatePageJson (browserView, pageTitle, "German") into pageJSON
   set the ghost_JSON of browserView to pageJSON
end menu_TranslateToGerman

on menu_TranslateToIcelandic browserView, pageSlug
   put fedwiki_ConstructTitle (pageSlug) into pageTitle
   --
   put _TranslatePageJson (browserView, pageTitle, "Icelandic") into pageJSON
   set the ghost_JSON of browserView to pageJSON
end menu_TranslateToIcelandic

on menu_TranslateToWelsh browserView, pageSlug
   put fedwiki_ConstructTitle (pageSlug) into pageTitle
   --
   put _TranslatePageJson (browserView, pageTitle, "Welsh") into pageJSON
   set the ghost_JSON of browserView to pageJSON
end menu_TranslateToWelsh

private on ___
end ___

on menu_SaveBrowser browserView
   put the stack_Name of browserView into stackName
   save stack stackName
   --
   put "Saved stack" && kwote (stackName) into sComment
   lcw_Notify sComment
end menu_SaveBrowser

on menu_SetGardenEcoFolder
   put wikiFarm_EarthFolder() into rootFolder
   answer folder "Choose a Garden eco-folder for wiki..." with rootFolder as sheet
   if it is empty then exit to top
   put it into ecoFolder
   
   wikiGarden_SetEcoFolder ecoFolder
   wikiGarden_Init true
   --
   finder_Reveal ecoFolder
end menu_SetGardenEcoFolder

on menu_StoreWikiFarmFolder
   put wikiFarm_EarthFolder() into rootFolder
   answer folder "Choose a default folder for wiki..." with rootFolder as sheet
   if it is empty then exit to top
   put it into newFarmFolder
   
   wikiFarm_SetFolder newFarmFolder
   wikiFarm_StoreFolder newFarmFolder
   --
   finder_Reveal newRootFolder
end menu_StoreWikiFarmFolder

private on ____
end ____

on menu_MoveWiki browserView
   put the wiki_Domain of browserView into wikiDomain
   put wikiFolder_FromRouter (wikiDomain) into oldWikiFolder
   
   put wikiGarden_GetEcoFolder() into oldEcoFolder
   put oldWikiFolder into oldEcoFolder
   set the itemdelimiter to slash
   delete item -1 of oldEcoFolder
   
   answer folder "Select a garden folder for the new farm..." with oldEcoFolder as sheet
   if it is empty then exit to top
   put it into newGardenFolder
   put slash after newGardenFolder
   --
   put newGardenFolder into newEcoFolder
   delete item -1 of newEcoFolder
   
   # Old Wiki Folder
   put newGardenFolder & wikiDomain & slash into newWikiFolder
   
   # Move
   revMoveFolder oldWikiFolder, newWikiFolder
   
   # ReIndex
   if folder_Within (ecoFolder, ecoFolders) is true then
      wikiGarden_Init true
   else
      wikiGarden_AddEcoFolder newEcoFolder
   end if
end menu_MoveWiki

on menu_MoveDomains wikiView, gardenName
   # Domains to Move
   put the wiki_Domain of wikiView into wikiDomain
   put url_GetTLD (wikiDomain) into tldDomain
   --
   put wikiGarden_ListAllDomains (tldDomain) into domainsToMove
   
   put wikiGarden_FindGardenFolder (gardenName) into toGarden
   repeat for each line wikiDomain in domainsToMove
      put toGarden & wikiDomain & slash into toFolder
      put wikiFolder_FromRouter (wikiDomain) into fromFolder
      --
      if there is not a folder fromFolder then next repeat
      if fromFolder = toFolder then next repeat
      if there is a folder toFolder then next repeat
      
      revMoveFolder fromFolder, toFolder
   end repeat
   
   wikiGarden_Init true
end menu_MoveDomains

on menu_UpdateEcoData
   wikiGarden_Init true
end menu_UpdateEcoData

private on _____
end _____

on menu_DisplayWikiServer
   display_ViewTemplate "View|Wiki|Server"
end menu_DisplayWikiServer

on menu_DisplayWikiGardenModel
   display_WikiEcoData
end menu_DisplayWikiGardenModel

on submenu_Dev
   return menu_DevTitle("Global | Obeya | Studio | Wiki | Menu")
end submenu_Dev
