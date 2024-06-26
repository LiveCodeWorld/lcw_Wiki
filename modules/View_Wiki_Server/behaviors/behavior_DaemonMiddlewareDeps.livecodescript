REVO7000    � behavior_DaemonMiddlewareDeps1 P�  --> Second
-
command curly_MergePageArray @pageArray, curlyData
   # Merge specific item ids
   put curlyData ["id"] into curlyIdArray
   curly_SetPageItems pageArray, curlyIdArray
   
   # Replace any sections such as ref-item arrays
   curly_ReplacePageItems pageArray, curlyData
   
   # Merge everything looping through every story item
   curly_MergeAll pageArray, curlyData
end curly_MergePageArray

command curly_ReplacePageArray @pageArray, curlyKey, curlyReplacement
   put pageArray ["story"] into storyArray
   repeat with itemNum = 1 to item 2 of the extents of storyArray
      get storyArray [itemNum]["text"]
      put it into itemText
      curly_ReplaceText itemText, curlyKey, curlyReplacement
      if itemText is not it then
         put itemText into pageArray ["story"][itemNum]["text"]
         put itemNum & comma after updateditemNums
      end if
   end repeat
   delete char -1 of updateditemNums
   return updateditemNums
end curly_ReplacePageArray

command fedwiki_PostJSON someJSON, restURL
   set the httpheaders to "Content-Type: application/json" -- required for revIgnitor
   post someJSON to url restURL
   put it into jsonResult
   return jsonResult
end fedwiki_PostJSON

command ffmpeg_ExportAudioAsWav audioFile, pWavFile
   if pWavFile is empty then
      put audioFile into pWavFile
      set the itemdelimiter to "."
      put "wav" into item -1 of pWavFile
   end if
   
   put merge ("ffmpeg -i" && kwote (audioFile) && "-ar 16000 -ac 1 -c:a pcm_s16le") && kwote (pWavFile) into someShell
   --
   put _ShellResult (someShell, audioFolder) into shellResult
   return shellResult
end ffmpeg_ExportAudioAsWav

command html_TopAndTailParagraphTags @someHTML
   get token 1 to 3 of someHTML
   replace space with empty in it
   if it is not "<p>" then return false
   
   delete token 1 to 3 of someHTML
   get token -3 to -1 of someHTML
   replace space with empty in it
   if it is "</p>" then
      delete token -3 to -1 of someHTML
   end if
   return true
end html_TopAndTailParagraphTags

command itemArray_Add itemArray, @pageArray
   if itemArray is not an array then return 0
   
   put pageArray ["story"] into storyArray
   put pageArray ["journal"] into journalArray
   put itemArray ["id"] into itemID
   
   # Add the item to the end of the story
   itemArray_AddToEnd itemArray, storyArray
   put the result into afterID -- this can be empty if it is the first entry
   put storyArray into pageArray ["story"]
   
   # Now let's add the edit or add to the journal
   put itemArray_ConstructFactory (itemID) into factoryArray
   journalArray_Add journalArray, factoryArray, "add", afterID -- after the id of the end paragraph
   
   # Finally add the journal entry for editing the factory
   journalArray_Add journalArray, itemArray, "edit"
   put journalArray into pageArray ["journal"]
   
   put pageArray ["story"] into storyArray
   put item 2 of the extents of storyArray into lastItemNum
   return lastItemNum
end itemArray_Add

function itemArray_Construct itemType, pID, pText
   itemArray_NormalizeID pID
   put pID into itemArray ["id"]
   --
   put itemType into itemArray ["type"]
   --
   if pText is not empty then  
      put pText into itemArray ["text"]
   end if
   return itemArray
end itemArray_Construct

function itemArray_ConstructActivity rosterTitle, pSinceWhen, pConversationItem, pID
   -- put "CONVERSATION" into pConversationItem
   -- put "1 week" into pSinceWhen
   
   put "ROSTER" && rosterTitle & CR into activityText
   if pConversationItems is not empty then
      put CR & pConversationItem after activityText
   end if
   if pSinceWhen is not empty then
      put CR & "SINCE" && pSinceWhen after activityText
   end if
   put itemArray_Construct ("activity", pID, activityText) into itemArray
   return itemArray
end itemArray_ConstructActivity

command itemArray_NormalizeID @pID
   if pID is empty then 
      put uuid () into pID
   end if
end itemArray_NormalizeID

command line_DeleteTail @someIndex
   repeat the number of lines of someIndex
      get word 1 to -1 of line -1 of someIndex
      if it is empty then
         delete line -1 of someIndex
      end if
   end repeat
end line_DeleteTail

command mediawiki_NormaliseTitle searchTitleString, @pageTitle, @pageID, pLang
   -- searches everything, not just title and finds best match
   put mediawiki_FindPageID (searchTitleString, true, pLang) into pageID
   
   -- /w/api.php?action=query&format=json&pageids=51071416&redirects=1&converttitles=1
   put wikipedia_GetApiRoot (pLang) & "/w/api.php" into apiRoot
   --
   put "?action=query&format=json" into apiPath
   put "&pageids=" & pageID after apiPath
   put "&redirects=1&converttitles=1" after apiPath
   put apiRoot & apiPath into restURL
   --
   put mediawiki_FetchJSON (restURL) into someJSON
   put json_ToArray (someJSON) into batchResultArray
   --
   put batchResultArray ["query"] into queryArray
   put queryArray ["pages"] into pagesArray
   put keys(pagesArray) into newPageIDs -- should only be one
   put line 1 of newPageIDs into newPageID
   put pagesArray [newPageID]["title"] into pageTitle
   --
   put textDecode (pageTitle, "utf-8") into pageTitle
   
   put queryArray ["redirects"][1]["to"] into rTitle -- = pageTitle
   put queryArray ["redirects"][1]["from"] into oTitle
   put queryArray ["redirects"][1]["tofragment"] into toFragment
   --   
   return batchResultArray
end mediawiki_NormaliseTitle

command pageArray_AddButton @pageArray, buttonName, postURL, pHiddenKeyValueArray, pLabel, pAlign, pBgColor, pID
   put fedwiki_ConstructButtonForm (buttonName, postURL, pHiddenKeyValueArray, pLabel, pAlign, pBgColor) into formHTML
   pageArray_AddHTML pageArray, formHTML, pID
   return formHTML
end pageArray_AddButton

command pageArray_AddChatGptCred @pageArray
   put accreditation_ChatGpt() into mdCred
   put mdCred into pageArray ["journal"][1]["provenance"]
   delete variable pageArray ["plugin"]
end pageArray_AddChatGptCred

command pageArray_AddHtml @pageArray, someHtml, pID
   if someCode is  empty then return 0
   put itemArray_Construct ("html", pID, someHtml) into itemArray
   itemArray_Add itemArray, pageArray
   return the result
end pageArray_AddHtml

command pageArray_AddReferenceIndex @pageArray, wikiDomains, pCaps
   put -3 into pItemNum
   set the itemDelimiter to "."
   repeat for each line wikiDomain in wikiDomains
      put item 1 to pItemNum of wikiDomain into someText
      if someText is empty then put wikiDomain into someText
      --
      if pCaps is true then
         replace "." with space in someText
         put text_InitialCaps (someText) into someText
      end if
      pageArray_AddReference pageArray, "Welcome Visitors", wikiDomain, someText, "welcome-visitors"
   end repeat
   delete char -1 of sMarkdown
   return sMarkdown
end pageArray_AddReferenceIndex

command pageArray_AddStory @pageArray, moreStoryItemArray
   if moreStoryItemArray is not an array then return false
   -- add multiple new storyItemArrays from moreStoryItemArray to end of pageArray story
   put pageArray ["story"] into storyItemArray
   storyArray_AddToEnd storyItemArray, moreStoryItemArray
   put storyItemArray into pageArray ["story"]
   --
   pageArray_StripJournal pageArray
   return true
end pageArray_AddStory

command pageArray_AddThumbnail @pageArray, imageURL, pImageCaption, pLinkURL
   if pageArray is not an array then return false
   if imageURL is empty then return false
   _SetImageDescription pImageCaption, pLinkURL, imageURL
   --
   put fedwiki_ConstructThumbHtml (imageURL, pImageCaption, pLinkURL) into imageHTML
   pageArray_AddHtml pageArray, imageHTML
   return true
end pageArray_AddThumbnail

command pageArray_AddTransport @pageArray, pTransportLine, pID
   if pTransportLine is  empty then return 0
   if pTransportLine is empty then
      put "POST https://rest.livecode.world/imagine" into pTransportLine
   end if
   put itemArray_ConstructTransport (pTransportLine, pID) into itemArray
   itemArray_Add itemArray, pageArray
   return the result
end pageArray_AddTransport

command pageArray_CleanFork @pageArray, pForkDomains
   pageArray_StripJournal pageArray
   pageArray_AddFork pageArray, pForkDomains
end pageArray_CleanFork

command pageArray_CleanJournal @pageArray, pPreserveActions
   -- ie pPreserveActions = "fork"
   switch pPreserveActions
      case empty
         pageArray_StripJournal pageArray
         break
      default
         put pageArray ["journal"] into journalArray
         put item 2 of the extents of journalArray into lastJournalNum
         put 1 into newItemNum
         repeat with jNum = 1 to lastJournalNum
            put journalArray [jNum] into itemArray
            if itemArray ["type"] is among the items of pPreserveActions then
               put itemArray into newJournalArray [newItemNum]
               add 1 to newItemNum
            end if
         end repeat
         put newJournalArray into pageArray ["journal"]
   end switch
end pageArray_CleanJournal

command pageArray_Rename @pageArray, newPageTitle, pForkDomains
   if newPageTitle is empty then return false
   put newPageTitle into pageArray ["title"]
   put newPageTitle into pageArray ["journal"][1]["item"]["title"]
   --
   if pForkDomains is not empty then
      pageArray_StripJournal pageArray
      pageArray_AddFork pageArray, pForkDomains
   end if
   return true
end pageArray_Rename

command pageArray_ReplaceSection @pArray, sTitle, storyArray
   pageArray_DeleteSection pArray, sTitle
   if the result = 0 then return 0
   put item 1 of the result - 1 into beforeTitleNum
   --
   pageArray_InsertStoryAfter pArray, storyArray, beforeTitleNum
   return beforeTitleNum
end pageArray_ReplaceSection

command pageArray_SetFirstItem @pageArray, itemType, itemText
   put pageArray_FindItemType (itemType, pageArray) into itemNum
   if itemNum = 0 then return 0
   put itemText into pageArray ["story"][itemNum]["text"]
   return itemNum
end pageArray_SetFirstItem

command storyArray_AddGraphviz @storyArray, graphText, pDot, pSVG, pItemID
   put itemArray_ConstructGraphviz (graphText, pDot, pSVG, pItemID) into itemArray
   itemArray_AddToEnd itemArray, storyArray
end storyArray_AddGraphviz

command storyArray_AddItemArray @storyArray, itemType, itemText, pID
   put itemArray_Construct (itemType, pID, itemText) into itemArray
   itemArray_AddToEnd itemArray, storyArray
end storyArray_AddItemArray

command url_FilterDomains @shortWikiFolders, pFilterDomain, pSimple
   if pFilterDomain is not empty then
      put pFilterDomain is among the lines of shortWikiFolders into addTLD
      
      if pSimple is true then
         filter shortWikiFolders with pFilterDomain
      else
         put "*." & pFilterDomain into sFilter
         filter shortWikiFolders with sFilter
      end if
      
      # Add Root
      set the wholeMatches to true
      if addTLD then
         put pFilterDomain & CR before shortWikiFolders
      end if
   end if
end url_FilterDomains

command wikiServer_Restart pNotify, pNotifyText
   if pNotify is not false then
      if pNotifyText is empty then put "Restarted wiki server!" into pNotifyText
      lcw_Notify pNotifyText
   end if
   
   put wikiServer_View() into serverObject
   set the daemon_IsRunning of serverObject to false
   resetAll
   set the daemon_IsRunning of serverObject to true
   return serverObject
end wikiServer_Restart


--> Deps
-
private function _ConstructModelDataFile modelDataFolder, pShortFile
   -- rename / replace
   if pShortFile is empty then
      set the itemdelimiter to slash
      put item -1 of modelDataFolder into modelName
      put modelName & ".array" into pShortFile
   end if
   put modelDataFolder & pShortFile into modelDataFile
   return modelDataFile
end _ConstructModelDataFile

private function _GetJson sFile
   if there is not a file sFile then return empty
   put url ("binfile:" & sFile) into binaryJSON
   put textDecode (binaryJSON, "UTF-8") into sJSON
   return sJSON
end _GetJson

private function _GetJsonArray sFile
   -- put _GetMergJsonArray (sFile) into jsonArray
   put _GetJson (sFile) into sJSON
   try
      # More tolerant and uses textDecode with _GetJson
      -- but numbers indexed arrays differently to mergeJSON
      put jsonImport (sJSON) into jsonArray
      if jsonArray is an array then
         return jsonArray
      else
         return "Error, json file cannot be turned into an array." && sFile
      end if
   catch e
      breakpoint
      return "Error, json file cannot be turned into an array." && sFile
   end try
end _GetJsonArray

private function _GetMergJsonArray sFile
   put url ("binfile:" & sFile) into binaryJSON
   if binaryJSON is empty then return empty
   -- put textDecode (binaryJSON, "UTF-8") into binaryJSON
   
   try
      # Use binary and not textDecode with JSONToArray
      -- put JSONToArray (binaryJSON) into jsonArray
      put json_ToArray (binaryJSON) into jsonArray
      if jsonArray is an array then
         return jsonArray
      else
         return "Error, json file cannot be turned into an array." && sFile
      end if
   catch e
      return "Error, json file cannot be turned into an array." && sFile
   end try
end _GetMergJsonArray

command curly_Merge @someText, curlyArray
   repeat for each key curlyKey in curlyArray
      put curlyArray [curlyKey] into curlyReplacement
      curly_ReplaceText someText, curlyKey, curlyReplacement
   end repeat
end curly_Merge

command curly_ReplaceText @someText, curlyKey, curlyReplacement
   put "(?Uim)\{\{\s*" & curlyKey & "\s*\}\}" into someReg
   put replacetext (someText, someReg, curlyReplacement) into someText
end curly_ReplaceText

function ecoData_Get
   return Garden_EcoData
end ecoData_Get

function ecoData_GetFarmFolder
   -- see "wikiFarm_GetDefaultFolder"
   put ecoData_Get() into ecoData
   put ecoData ["Farm"]["folder"] into farmFolder
   file_AddHome farmFolder
   return farmFolder
end ecoData_GetFarmFolder

function fedwiki_ConstructSlug pageTitle
   -- it is very annoying that "_" is not an allowed character
   replace space with "-" in pageTitle
   repeat for each char someChar in  "()_|.,:;'"
      replace someChar with empty in pageTitle
   end repeat
   put tolower (pageTitle) into pageSlug
   return pageSlug
end fedwiki_ConstructSlug

function fedwiki_ConstructTitle pageSlug
   replace "-" with space in pageSlug
   repeat for each word someWord in pageSlug
      put toupper (char 1 of someWord) into char 1 of someWord
      put someWord & space after pageTitle
   end repeat
   delete char -1 of pageTitle
   return pageTitle
end fedwiki_ConstructTitle

function fedwiki_FetchSitemap wikiDomain
   put fedwiki_JsonSiteMapUrl (wikiDomain) into sitemapURL
   put url sitemapURL into sitemapJSON
   return sitemapJSON
end fedwiki_FetchSitemap

function fedwiki_FetchSitemapArray wikiDomain
   put fedwiki_FetchSitemap (wikiDomain) into someJson
   if someJson is empty then return empty
   put json_ToArray (someJson) into sitemapArray
   if sitemapArray is false then return empty
   return sitemapArray
end fedwiki_FetchSitemapArray

function fedwiki_JsonSiteMapUrl wikiDomain   
   put "http://" & wikiDomain into sitemapURL
   put "/system/sitemap.json" after sitemapURL
   return sitemapURL
end fedwiki_JsonSiteMapUrl

function fedwiki_WikiExists someDomain
   put fedwiki_FetchSitemapArray (someDomain) into sitemapArray
   put sitemapArray is an array into someBoolean
   return someBoolean
end fedwiki_WikiExists

command file_AddHome @fileOrFolder, pDontStrip
   if pDontStrip is false then
      file_StripHome fileOrFolder
   else if char 1 of fileOrFolder = "~" then
      put $HOME into char 1 of fileOrFolder
   end if
end file_AddHome

command folder_CreateNested someFolder
   if there is a folder someFolder then return empty   
   set the itemdelimiter to "/"
   repeat with itemNum = 2 to the number of items of someFolder
      put item 1 to itemNum of someFolder & "/" into testFolder
      if there is a folder testFolder then next repeat
      create folder testFolder
   end repeat
   text_AddTrailing someFolder, slash
   return someFolder
end folder_CreateNested

function itemArray_Construct itemType, pID, pText
   itemArray_NormalizeID pID
   put pID into itemArray ["id"]
   --
   put itemType into itemArray ["type"]
   --
   if pText is not empty then  
      put pText into itemArray ["text"]
   end if
   return itemArray
end itemArray_Construct

function itemArray_ConstructFork wikiDomain, pForkDate, pItemID
   if pForkDate is empty then put the milliseconds into pForkDate
   --
   put itemArray_Construct ("fork", pItemID) into itemArray
   put pForkDate into itemArray ["date"]
   if wikiDomain is not empty then
      put wikiDomain into itemArray ["site"]
   end if
   return itemArray
end itemArray_ConstructFork

function itemArray_ConstructReference pageSlug, wikiDomain, refText, pageTitle, pID
   itemArray_NormalizeID pID   
   put pID into itemArray ["id"]
   put "reference" into itemArray ["type"]
   --
   put wikiDomain into itemArray ["site"]
   put pageTitle into itemArray ["title"]
   put pageSlug into itemArray ["slug"]
   put refText into itemArray ["text"]
   --
   return itemArray
end itemArray_ConstructReference

command itemArray_NormalizeID @pID
   if pID is empty then 
      put uuid () into pID
   end if
end itemArray_NormalizeID

command journalArray_Add @journalArray, itemArray, journalType, pAfterID, pMilliseconds
   if pMilliseconds is empty then put the milliseconds into pMilliseconds
   if pAfterID is not empty then
      put pAfterID into journalEntryArray ["after"]
   end if
   put pMilliseconds into journalEntryArray ["date"]
   put itemArray ["id"] into journalEntryArray ["id"]
   put itemArray into journalEntryArray ["item"]
   put journalType into journalEntryArray ["type"]
   
   itemArray_AddToEnd journalEntryArray, journalArray
end journalArray_Add

function jsonArray_FromFile sFile, pUseMerge
   if there is not a file sFile then return "Error, json file does not exist." && sFile
   
   if pUseMerge is not false then
      return _GetMergJsonArray (sFile)
   else
      return _GetJsonArray (sFile) -- uses "textDecode"
   end if
end jsonArray_FromFile

command lcw_Notify someMessage, pTitle, pMergeValue
   -- needs to work cross platform
   replace quote with empty in someMessage
   replace "'" with empty in someMessage
   text_ReQuote someMessage, pMergeValue
   --
   try
      if pTitle is empty then put "LiveCode World Notification" into pTitle
      put "osascript -e" && "'" & "display notification" && quote & someMessage & quote into someShell
      put "with title" && quote & pTitle & quote after someShell
      put "'" after someShell
      put shell (someShell) into shellResult
   catch e
      put someMessage
   end try
end lcw_Notify

command line_DeleteIndex @someIndex, pStripIndex
   /*
   split someIndex by CR as set
   split pStripIndex by CR as set
   difference someIndex with pStripIndex
   put keys (someIndex) into uniqueIndex
   return uniqueIndex
   */
   
   repeat for each line someLine in pStripIndex
      line_Delete someLine, someIndex
      if lineNum = 0 then
         put lineNum & comma after deletedLines
      end if
   end repeat
   delete char -1 of deletedLines
   return deletedLines
end line_DeleteIndex

getprop model_Array [pShortFile]
   -- assumes the target is a model stack
   put the model_DataFile [pShortFile] of the target into modelDataFile
   put array_FromFile (modelDataFile) into modelArray
   return modelArray
end model_Array

getprop model_DataFile [pShortFile]
   -- assumes the target is a model stack
   put the short name of the defaultstack into modelStackName
   put the stack_Folder of the target into projectFolder
   put model_GetDataFile (modelStackName, projectFolder, pShortFile) into modelDataFile
   return modelDataFile
end model_DataFile

function model_GetDataFile modelStackName, projectFolder, pShortFile
   put model_GetDataFolder (modelStackName, projectFolder) into modelDataFolder
   put _ConstructModelDataFile (modelDataFolder, pShortFile) into modelDataFile
   return modelDataFile
end model_GetDataFile

function model_GetDataFolder modelStackName, projectFolder
   put folder_AddShort (projectFolder, "models") into rootModelsFolder
   put rootModelsFolder & modelStackName & slash into modelDataFolder
   return modelDataFolder
end model_GetDataFolder

command pageArray_AddAddAction @pageArray, itemArray, afterID, pMilliseconds
   if pMilliseconds is empty then put the milliseconds into pMilliseconds
   put pageArray ["journal"] into journalArray
   --
   put "add" into actionArray ["type"]
   put afterID into actionArray ["after"]
   put itemArray into actionArray ["item"]
   put itemArray ["id"] into actionArray ["id"]
   put pMilliseconds into actionArray ["date"]
   --
   itemArray_AddToEnd actionArray, journalArray
   put journalArray into pageArray ["journal"]
   return actionArray
end pageArray_AddAddAction

command pageArray_DeleteItem @pageArray, itemNumsToDelete
   if itemNumsToDelete = 0 then return false
   replace CR with comma in itemNumsToDelete
   put pageArray ["story"] into storyArray
   sort numeric items of itemNumsToDelete
   repeat with itemNum = the number of items of itemNumsToDelete down to 1
      put item itemNum of itemNumsToDelete into itemNumToDelete
      storyArray_DeleteItem storyArray, itemNumToDelete
      put the result into deletedItemArray
      put deletedItemArray ["id"] into deletedItemID
      pageArray_AddDeleteAction pageArray, deletedItemID
   end repeat
   put storyArray into pageArray ["story"]
   return true
end pageArray_DeleteItem

function pageArray_ExtractForkDomains pageArray
   -- extract unique sorted index of fork domains regardless of data
   put pageArray ["journal"] into journalArray
   repeat for each key jNum in journalArray
      put journalArray [jNum] into itemArray
      if itemArray ["type"] = "fork" then
         put itemArray ["site"] into forkSite
         put itemArray ["date"] into forkDate
         if forkSite is empty then next repeat -- self-fork
         --
         put itemArray into forkArray [forkSite]
      end if
   end repeat
   put keys (forkArray) into forkDomains
   url_SortDomainIndex forkDomains
   return forkDomains
end pageArray_ExtractForkDomains

function pageArray_Get wikiDomain, pageSlug
   put wikiFile_Construct (wikiDomain, pageSlug) into wikiFile
   if there is a file wikiFile then
      put jsonArray_FromFile (wikiFile) into pageArray
      return pageArray
   else
      return empty
   end if
end pageArray_Get

command pageArray_SetItemArray @pageArray, itemID, itemArray
   -- was "pageArray_SetItemArray"
   put pageArray_FindItemID (itemID, pageArray) into itemNum
   if itemNum > 0 then
      put itemArray into pageArray ["story"][itemNum]
   end if
end pageArray_SetItemArray

command pageArray_SetItemText @pageArray, itemID, itemText
   put pageArray_FindItemID (itemID, pageArray) into itemNum
   if itemNum = 0 then return 0
   put itemText into pageArray ["story"][itemNum]["text"]
   return itemNum
end pageArray_SetItemText

function secret_Get secretName
   -- for server use only
   if the environment is not "server" then pass "secret_Get"
   --
   put rigFetchConfigItem (secretName) into someSecret
   return someSecret
end secret_Get

getprop stack_Folder
   put the effective filename of the defaultstack into stackFolder
   set the itemdelimiter to slash
   put empty into item -1 of stackFolder
   return stackFolder
end stack_Folder

command view_NormalizePiped @viewPath, pMakePretty
   if viewPath is empty then return false
   put word 1 to -1 of viewPath into viewPath
   
   set the itemdelimiter to "|"
   repeat with itemNum = 1 to the number of items of viewPath
      put word 1 to -1 of item itemNum of viewPath into someItem
      if pMakePretty is true then
         repeat for each word someWord in someItem
            put toUpper (char 1 of someWord) into char 1 of someWord
            put someWord & space after prettyItem
         end repeat
         put char 1 to -2 of prettyItem into someItem
      end if
      put someItem into item itemNum of viewPath
   end repeat
   return true
end view_NormalizePiped

function wikiFarm_GetDefaultFolder
   -- wee "ecoData_GetFarmFolder"
   put wikiGarden_GetModel() into ecoData
   put ecoData ["Farm"]["folder"] into farmFolder
   --
   file_AddHome farmFolder
   return farmFolder
end wikiFarm_GetDefaultFolder

function wikiFile_Construct wikiDomain, pSlug
   if pSlug is empty then put "welcome-visitors" into pSlug
   --
   put wikiFolder_Pages (wikiDomain) into pagesFolder
   if pagesFolder is empty then return empty
   put pagesFolder & pSlug into pageJsonFile
   return pageJsonFile
end wikiFile_Construct

function wikiFile_ConstructAsset relAssetPath, wikiDomain
   put wikiFolder_ConstructAssets (wikiDomain) into assetsFolder
   put assetsFolder & relAssetPath into sFile
   return sFile
end wikiFile_ConstructAsset

function wikiFolder_ConstructAssets wikiDomain
   put wikiFolder_FromRouter (wikiDomain) into wikiFolder
   put wikiFolder & "assets/" into assetsFolder
   return assetsFolder
end wikiFolder_ConstructAssets

function wikiFolder_ConstructFromFarm wikiDomain
   put ecoData_GetFarmFolder() into wikiFarm
   if there is not a folder wikiFarm then
      -- this check slows things (consider removing)
      -- breakpoint
      put wikiFarm_GetDefaultFolder() into wikiFarm
   end if
   
   put wikiFarm & wikiDomain & slash into wikiFolder
   return wikiFolder
end wikiFolder_ConstructFromFarm

function wikiFolder_FromRouter wikiDomain
   put wikiGarden_GetDomainData() into gardenDomainData
   put gardenDomainData [wikiDomain]["folder"] into gardenWikiFolder
     
   if gardenWikiFolder is empty then -- defaults to farm
      put wikiFolder_ConstructFromFarm (wikiDomain) into wikiFolder
      return wikiFolder
   else
      return gardenWikiFolder
   end if
end wikiFolder_FromRouter

function wikiFolder_Pages wikiDomain
   put wikiFolder_FromRouter (wikiDomain) into wikiFolder 
   put wikiFolder & "pages/" into wikiPagesFolder
   if there is a folder wikiPagesFolder then
      return wikiPagesFolder
   else
      return empty
   end if
end wikiFolder_Pages

function wikiGarden_GetDomainData
   return Garden_DomainData
end wikiGarden_GetDomainData

function wikiGarden_GetModel
   put the model_Array [GardenModelName] of stack "lcw_Wiki" into ecoData
   return ecoData
end wikiGarden_GetModel
    � 8.         ;            ����       cREVGeneral    breakpointstates breakpoints breakpointconditions scripteditorselection 13 scripteditorvscroll     scalefactor      �?  �    	@            : 