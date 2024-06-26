REVO7000    � behavior_WikiServerDeps1 P�� --> Deps
-
private command _SetMergJsonArray sFile, jsonArray, pCreateFolder
   /* Use of ArrayToJSON and mergJsonEncode creates correct json.
   But accepts binary json and not result of textencode/decode.*/
   
   try
      # Use binary and not textEncode with JSONToArray
      -- put ArrayToJSON (jsonArray) into binaryJSON
      put json_FromArray (jsonArray) into binaryJSON
      --
      put binaryJSON into url ("binfile:" & sFile)
      put the result into writeResult
      return writeResult
   catch e
      return "Error, encoding jsonArray with _SetMergJsonArray."
   end try
end _SetMergJsonArray

private command _SetJsonArray sFile, jsonArray, pCreateFolder
   /* Use of jsonExport does not create correct json.
   Temporarily using ArrayToJSON and mergJson.*/
   
   try
      # More tolerant and uses textEncode with _SetJson
      put jsonExport (jsonArray) into sJSON
      _SetJson sFile, sJSON, pCreateFolder
      put the result into writeResult
      return writeResult
   catch e
      return "Error, problem decoding array to json for:" && sFile & CR & e
   end try
end _SetJsonArray

private command _SetJson sFile, sJSON, pCreateFolder
   if pCreateFolder is true then
      put sFile into sFolder
      set the itemdelimiter to slash
      put empty into item -1 of sFolder
      folder_CreateNested sFolder
   end if
   --
   put word 1 to -1 of sJSON into sJSON
   put textEncode (sJSON, "UTF-8") into binaryJSON
   put binaryJSON into url ("binfile:" & sFile)
   put the result into writeResult
   return writeResult
end _SetJson

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

private command _WalkAndList @NestedPaths, someFolder, pBaseFolderNum
   -- recursive
   put files (someFolder) into shortFiles
   put someFolder into pathFolder
   if pBaseFolderNum is a number then
      set the itemdelimiter to slash
      delete item 1 to pBaseFolderNum of pathFolder
   end if
   
   # Add files (not folders) to NestedPaths
   filter shortFiles without ".*"
   repeat for each line shortFile in shortFiles
      if char 1 of shortFile = "." then next repeat
      put pathFolder & shortFile into foundPath
      put foundPath & CR after NestedPaths
   end repeat
   
   # Recurse
   put folders (someFolder) into shortChildFolders
   repeat for each line shortChildFolder in shortChildFolders
      if char 1 of shortChildFolder = "." then next repeat
      put someFolder & shortChildFolder & slash into childFolder
      _WalkAndList NestedPaths, childFolder, pBaseFolderNum
   end repeat
end _WalkAndList

function array_FromFile someFile, pUseMerge
   put url ("binfile:" & someFile) into someData
   if someData is empty then return empty
   
   # Switch depending on file type
   set the itemdelimiter to "."
   switch item -1 of someFile
      case "json"
         -- put jsonImport (someData) into modelArray
         put json_ToArray (someData, pUseMerge) into modelArray
         return modelArray
      case "array"
         put arraydecode (someData) into modelArray
         return modelArray
      default
         return someData
   end switch
end array_FromFile

command curly_ReplaceText @someText, curlyKey, curlyReplacement
   put "(?Uim)\{\{\s*" & curlyKey & "\s*\}\}" into someReg
   put replacetext (someText, someReg, curlyReplacement) into someText
end curly_ReplaceText

function directory_ListNestedPaths someFolder, pSetRelative
   local NestedPaths
   if there is not a folder someFolder then return empty
   
   # Walk
   set the itemdelimiter to slash
   text_AddTrailing someFolder, slash
   if pSetRelative is true then
      put the number of items of someFolder into baseFolderNum
      _WalkAndList NestedPaths, someFolder, baseFolderNum
   else
      _WalkAndList NestedPaths, someFolder, baseFolderNum
   end if
   delete char -1 of NestedPaths
   return NestedPaths
end directory_ListNestedPaths

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

function fedwiki_GetLinks wikiText
   local sNum, eNum
   
   put "[^\]]+" into notBracket
   put "\[\[(" & notBracket & ")\]\]" into someReg
   repeat
      get matchchunk (wikiText, someReg, sNum, eNum) 
      if it is true then
         put char sNum to eNum of wikiText into pageTitle
         put pageTitle & CR after pageTitles
         --
         delete char 1 to eNum of wikiText
      else 
         exit repeat
      end if
   end repeat
   delete char -1 of pageTitles
   return pageTitles
end fedwiki_GetLinks

function file_AddFolderToPaths shortFiles, someFolder, pShowInvisible
   if pShowInvisible is not true then filter shortFiles without ".*"
   text_AddTrailing someFolder, slash
   repeat for each line shortFile in shortFiles
      put someFolder & shortFile & CR after filePaths
   end repeat
   delete last char of filePaths
   return filePaths
end file_AddFolderToPaths

command file_AddHome @fileOrFolder, pDontStrip
   if pDontStrip is false then
      file_StripHome fileOrFolder
   else if char 1 of fileOrFolder = "~" then
      put $HOME into char 1 of fileOrFolder
   end if
end file_AddHome

function file_ListLong someFolder, pShowInvisible, pSomeFilter
   if there is not a folder someFolder then return empty
   put files (someFolder) into shortFiles
   put file_AddFolderToPaths (shortFiles, someFolder, pShowInvisible, pSomeFilter) into filePaths
   return filePaths
end file_ListLong

function file_ListShort someFolder, pShowInvisible
   if there is not a folder someFolder then return empty
   put files (someFolder) into shortFiles
   if pShowInvisible is not true then filter shortFiles without ".*"
   return shortFiles
end file_ListShort

command file_StripHome @fileOrFolder
   put $HOME into myHome
   put the number of chars of myHome into maxNum
   if char 1 to maxNum of fileOrFolder is myHome then
      put "~" into char 1 to maxNum of fileOrFolder
   end if
end file_StripHome

function folder_AddShort projectFolder, shortFolder
   text_AddTrailing projectFolder, slash
   if shortFolder is not empty then put shortFolder & slash after projectFolder
   return projectFolder
end folder_AddShort

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

function folder_ListShort rootFolder
   if there is not a folder rootFolder then return empty
   
   put the defaultfolder into oDefault
   set the defaultfolder to rootFolder
   put the folders into shortFolders
   set the defaultfolder to oDefault
   
   filter shortFolders without ".*"
   return shortFolders
end folder_ListShort

function indexArray_Find sArray, sKey, sValue
   repeat with itemNum = 1 to item 2 of the extents of sArray
      put sArray [itemNum][sKey] into foundKey
      if foundKey = sValue then
         return itemNum
      end if
   end repeat
   return 0
end indexArray_Find

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

function json_ToArray pJSON, pUseMerge
   local tArray,tKeys
   if pJSON is empty then
      return false
   else if pUseMerge is false then -- not the same
      put jsonImport (pJSON) into tArray
      return tArray
   end if
   
   try -- as otherwise an error with non-json causes script to exit
      if pJSON is empty then return empty
      repeat for each line tKey in mergJSONDecode(pJSON,"tArray")
         put json_ToArray(tArray[tKey]) into tArray[tKey]
      end repeat
      return tArray
   catch e
      return empty
   end try
end json_ToArray

function jsonArray_FromFile sFile, pUseMerge
   if there is not a file sFile then return "Error, json file does not exist." && sFile
   
   if pUseMerge is not false then
      return _GetMergJsonArray (sFile)
   else
      return _GetJsonArray (sFile) -- uses "textDecode"
   end if
end jsonArray_FromFile

command jsonArray_ToFile sFile, jsonArray, pCreateFolder, pUseMerge
   if pUseMerge is not false then
      _SetMergJsonArray sFile, jsonArray, pCreateFolder
   else
      _SetJsonArray sFile, jsonArray, pCreateFolder -- uses "textEncode"
   end if
   return the result
end jsonArray_ToFile

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

function node_GetModulesFolder pUseNpm
   if Node_ModulesFolder is empty then
      # Node version
      if pUseNpm is true then
         put line 1 of shell ("npm root -g") & "/" into nodeModulesFolder
      else
         # NVM version
         set the itemdelimiter to slash
         put nvm_GetBin() into nodeModulesFolder
         put "lib/node_modules/" into item -1 of nodeModulesFolder
      end if
      --
      put nodeModulesFolder into Node_ModulesFolder
      --
      if there is not a folder nodeModulesFolder then
         return "Error, folder" && nodeModulesFolder && "does not exist"
      end if
   end if
   
   return Node_ModulesFolder
end node_GetModulesFolder

function node_WikiModulesFolder
   put node_GetModulesFolder() & "wiki/node_modules/" into wikiModulesFolder
   return wikiModulesFolder
end node_WikiModulesFolder

function nvm_GetBin
   -- put "/Users/david/.nvm/versions/node/v21.0.0/bin/" before wikiBinFile
   get shell ("source ~/.zshrc; echo $NVM_BIN")
   return word 1 to -1 of line 1 of it
end nvm_GetBin

function pageArray_FindItemID itemID, pageArray
   put pageArray ["story"] into storyArray
   put item 2 of the extents of storyArray into maxItem
   repeat with itemNum = 1 to maxItem
      put storyArray [itemNum]["id"] into testID
      if testID = itemID then
         return itemNum
      end if
   end repeat
   return 0
end pageArray_FindItemID

function pageArray_Get wikiDomain, pageSlug
   put wikiFile_Construct (wikiDomain, pageSlug) into wikiFile
   if there is a file wikiFile then
      put jsonArray_FromFile (wikiFile) into pageArray
      return pageArray
   else
      return empty
   end if
end pageArray_Get

function pageArray_GetLastModified pageArray
   put pageArray ["journal"] into journalArray
   put item 2 of the extents of journalArray into lastItemNum
   put journalArray [lastItemNum]["date"] into lastModifiedDate
   return lastModifiedDate
end pageArray_GetLastModified

command pageArray_Set wikiDomain, pageSlug, pageArray, pDeleteSiteMap
   put wikiFile_Construct (wikiDomain, pageSlug) into wikiFile
   jsonArray_ToFile wikiFile, pageArray
   --
   if pDeleteSiteMap is not false then
      wikiSiteMap_DeleteFile wikiDomain
   end if
   return wikiFile
end pageArray_Set

command pageArray_SetFork @pageArray, wikiDomain, pForkDate
   put pageArray ["journal"] into journalArray
   put item 2 of the extents of journalArray into indexNum
   add 1 to indexNum
   put itemArray_ConstructFork (wikiDomain, pForkDate) into itemArray
   put itemArray into journalArray [indexNum]
   put journalArray into pageArray ["journal"]
end pageArray_SetFork

function pageJson_Get wikiDomain, pageSlug
   put wikiFile_Construct (wikiDomain, pageSlug) into wikiPagePath
   put _GetJson (wikiPagePath) into pageJSON
   return pageJSON
end pageJson_Get

function pageJson_GetRecycled wikiDomain, pageSlug
   put wikiFile_ConstructRecycled (wikiDomain, pageSlug) into recycledPagePath
   put _GetJson (recycledPagePath) into pageJSON
   return pageJSON
end pageJson_GetRecycled

command pageJson_Trash wikiDomain, pageSlug
   put wikiFile_Construct (wikiDomain, pageSlug) into wikiPagePath
   if there is not a file wikiPagePath then
      return "Error, no such file to trash:" && wikiPagePath
   end if
   
   # Create Recycled folder
   put wikiFolder_ConstructRecycled (wikiDomain) into wikiRecycleFolder
   folder_CreateNested wikiRecycleFolder -- if necessary
   
   -- put wikiFile_ConstructRecycled (wikiDomain, pageSlug) into recycledPagePath
   put wikiRecycleFolder & pageSlug into recycledPagePath
   
   # Move
   rename wikiPagePath to recycledPagePath
   return the result
end pageJson_Trash

function secret_Get secretName, pArrayKey
   if pArrayKey is empty then put "secret" into pArrayKey
   put tolower(pArrayKey) & "_Authentication.array" into shortFile
   put user_GetValue (secretName, shortFile) into someSecret
   return someSecret
end secret_Get

getprop stack_Folder
   put the effective filename of the defaultstack into stackFolder
   set the itemdelimiter to slash
   put empty into item -1 of stackFolder
   return stackFolder
end stack_Folder

command storyArray_InsertAfter @storyArray, afterNum, itemArray
   put afterNum + 1 into intoNum
   storyArray_InsertInto storyArray, intoNum, itemArray
end storyArray_InsertAfter

command text_AddTrailing @someText, someChar
   if char -1 of someText is not someChar then
      put someChar after someText
   end if
end text_AddTrailing

function text_Get someFile
   put url ("binfile:" & someFile) into binaryData
   put textDecode (binaryData, "UTF-8") into sText
   -- put url ("file:" & someFile) into sText
   return sText
end text_Get

command wiki_SetTagOffsets sHTML, tagName, @startCharNum, @endCharNum
   put merge ("{{#[[tagName]]}}") into startTag
   put merge ("{{/[[tagName]]}}") into endTag
   --
   put offset (startTag, sHTML) into startCharNum
   if startCharNum = 0 then
      put 0 into endCharNum
      return empty
   else
      get offset (endTag, sHTML, startCharNum)
      if it = 0 then
         put 0 into endCharNum
         return empty
      end if
      put it + startCharNum - 1 into endInnerCharNum
      put endInnerCharNum + the number of chars of endTag into endCharNum
      --
      put startCharNum + the number of chars of startTag into startInnerCharNum
      put char startInnerCharNum to endInnerCharNum of sHTML into innerHtml
      return innerHtml
   end if
end wiki_SetTagOffsets

function wikiClient_ConstructFactoriesJson
   /*
   put url "http://livecode.world/system/factories.json" into factoriesJSON
   put json_ToArray (factoriesJSON) into fArray
   display_Data fArray, "factoriesJSON", "factories.json"
   */
   
   put wikiPlugin_List() into shortPluginFolders
   put node_WikiModulesFolder() into wikiModulesFolder
   put 1 into indexNum
   repeat for each line shortPluginFolder in shortPluginFolders
      put wikiModulesFolder & shortPluginFolder & "/factory.json" into factoryFile
      if there is a file factoryFile then
         put text_Get (factoryFile) into sJSON
         put json_ToArray (sJSON) into sArray
         put sArray into factoryData [indexNum]
         add 1 to indexNum
      end if
   end repeat
   put json_FromArray (factoryData) into factoriesJSON
   return factoriesJSON
end wikiClient_ConstructFactoriesJson

function wikiClient_GetFactoriesJson pForceUpdate
   if Wiki_FactoriesJson is empty or pForceUpdate is true then
      put wikiClient_ConstructFactoriesJson() into Wiki_FactoriesJson
   end if
   return Wiki_FactoriesJson
end wikiClient_GetFactoriesJson

function wikiClient_GetStaticHtml
   put wikiFolder_Client ("views/") into clientViewFolder
   put clientViewFolder & "static.html" into clientViewPath
   put text_Get (clientViewPath) into someHTML
   return someHTML
end wikiClient_GetStaticHtml

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

function wikiFile_ConstructClient clientRelativePath
   if char 1 of clientRelativePath = slash then delete char 1 of clientRelativePath
   --
   put wikiFolder_Client ("client/") into clientFolder
   put clientFolder & clientRelativePath into sFile
   return sFile
end wikiFile_ConstructClient

function wikiFile_ConstructFavicon wikiDomain
   put wikiFolder_ConstructStatus (wikiDomain) into statusFolder
   put statusFolder & "favicon.png" into faviconFile
   return faviconFile
end wikiFile_ConstructFavicon

function wikiFile_ConstructImageAsset shortFile, wikiDomain
   put wikiFolder_ConstructImageAssets (wikiDomain) into imageAssetsFolder
   put imageAssetsFolder & shortFile into imageFile
   return imageFile
end wikiFile_ConstructImageAsset

function wikiFile_ConstructRecycled wikiDomain, pSlug
   if pSlug is empty then put "welcome-visitors" into pSlug
   --
   put wikiFolder_ConstructRecycled (wikiDomain) into wikiRecycleFolder
   put wikiRecycleFolder & pSlug into recycledFile
   return recycledFile
end wikiFile_ConstructRecycled

function wikiFile_ConstructSiteIndex pWikiDomain
   put wikiFolder_ConstructStatus (pWikiDomain) into statusFolder
   put statusFolder & "site-index.json" into siteIndexFile
   return siteIndexFile
end wikiFile_ConstructSiteIndex

function wikiFile_ConstructSiteMap pWikiDomain
   -- .wiki/audio.commons.academy/status/sitemap.json
   put wikiFolder_ConstructStatus (pWikiDomain) into statusFolder
   put statusFolder & "sitemap.json" into siteMapFile
   return siteMapFile
end wikiFile_ConstructSiteMap

function wikiFile_Favicon wikiDomain
   put wikiFile_ConstructFavicon (wikiDomain) into faviconFile
   if there is a file faviconFile then
      return faviconFile
   else
      return empty
   end if
end wikiFile_Favicon

function wikiFile_ListAssets wikiDomain, pRelPath, pListShort
   put wikiFolder_ConstructAssets (wikiDomain) into assetsFolder
   if pRelPath is not empty then
      text_AddTrailing pRelPath, slash
      put pRelPath after assetsFolder
   end if
   if pListShort is true then
      return file_ListShort (assetsFolder)
   else
      return file_ListLong (assetsFolder)
   end if
end wikiFile_ListAssets

function wikiFile_ListPageSlugs sDomain
   put wikiFolder_Pages (sDomain) into wikiPagesFolder
   if there is a folder wikiPagesFolder then
      put file_ListShort (wikiPagesFolder) into pageSlugs
      return pageSlugs
   else
      return empty
   end if
end wikiFile_ListPageSlugs

function wikiFile_ListRecycled wikiDomain
   put wikiFolder_ConstructRecycled (wikiDomain) into recycleFolder
   put file_ListShort (recycleFolder) into shortFiles
   return shortFiles
end wikiFile_ListRecycled

function wikiFolder_Client pRelFolderPath
   put wikiFolder_ConstructClient() into wikiClientFolder
   put pRelFolderPath after wikiClientFolder
   text_AddTrailing wikiClientFolder, slash
   
   if there is a folder wikiClientFolder then
      return wikiClientFolder
   else
      return empty
   end if
end wikiFolder_Client

function wikiFolder_ConstructAssets wikiDomain
   put wikiFolder_FromRouter (wikiDomain) into wikiFolder
   put wikiFolder & "assets/" into assetsFolder
   return assetsFolder
end wikiFolder_ConstructAssets

function wikiFolder_ConstructClient
   put wikiFolder_Modules() & "wiki-client/" into wikiClientFolder
   return wikiClientFolder
end wikiFolder_ConstructClient

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

function wikiFolder_ConstructImageAssets wikiDomain
   put wikiFolder_FromRouter (wikiDomain) into wikiFolder
   put wikiFolder & "assets/plugins/image/" into imageAssetsFolder
   return imageAssetsFolder
end wikiFolder_ConstructImageAssets

function wikiFolder_ConstructRecycled wikiDomain
   put wikiFolder_FromRouter (wikiDomain) into wikiFolder
   put wikiFolder & "recycle/" into recycleFolder
   return recycleFolder
end wikiFolder_ConstructRecycled

function wikiFolder_ConstructStatus wikiDomain
   put wikiFolder_FromRouter (wikiDomain) into wikiFolder
   put wikiFolder & "status/" into statusFolder
   return statusFolder
end wikiFolder_ConstructStatus

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

function wikiFolder_Modules
   if Wiki_ModulesFolder is empty then
      -- it's inside the node modules /wiki/node-modules" folder
      put node_GetModulesFolder() into nodeModulesFolder   
      put nodeModulesFolder & "wiki/node_modules/" into wikiModulesFolder
      --
      put wikiModulesFolder into Wiki_ModulesFolder
      --
      if there is not a folder wikiModulesFolder then
         return "Error, folder" && wikiModulesFolder && "does not exist"
      end if
   end if
   
   return Wiki_ModulesFolder
end wikiFolder_Modules

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

function wikiPlugin_ConstructClientFolder pluginName
   put wikiPlugin_ConstructFolder (pluginName) into pluginFolder
   put pluginFolder & "client/" into pluginClientFolder
   return pluginClientFolder
end wikiPlugin_ConstructClientFolder

function wikiPlugin_ConstructFile pluginName, shortFile
   put wikiPlugin_ConstructFolder (pluginName) into pluginFolder
   put pluginFolder & shortFile into pluginFile
   return pluginFile
end wikiPlugin_ConstructFile

function wikiPlugin_ConstructFolder pluginName
   put node_WikiModulesFolder() & "wiki-plugin-" & pluginName & slash into pluginFolder
   return pluginFolder
end wikiPlugin_ConstructFolder

function wikiPlugin_ConstructPagesFile pluginName, pShortFile
   if pShortFile is empty then
      put merge ("about-[[pluginName]]-plugin") into pShortFile
   end if
   put wikiPlugin_ConstructPagesFolder (pluginName) into pluginPagesFolder
   put pluginPagesFolder & pShortFile into pluginPageFile
   return pluginPageFile
end wikiPlugin_ConstructPagesFile

function wikiPlugin_ConstructPagesFolder pluginName
   put wikiPlugin_ConstructFolder (pluginName) into pluginFolder
   put pluginFolder & "pages/" into pluginPagesFolder
   return pluginPagesFolder
end wikiPlugin_ConstructPagesFolder

function wikiPlugin_GetData pluginName, shortFile
   put wikiPlugin_ConstructFile (pluginName, shortFile) into pluginFile
   if there is a file pluginFile then
      put url ("binfile:" & pluginFile) into sData
      return sData
   else
      return empty
   end if
end wikiPlugin_GetData

function wikiPlugin_GetJavascript pluginName
   put "client/" & pluginName & ".js" into relPath
   put wikiPlugin_GetData (pluginName, relPath) into sJavascript
   return sJavascript
end wikiPlugin_GetJavascript

function wikiPlugin_GetJsMap pluginName, shortMapFile
   put "client/" & shortMapFile into relPath
   put wikiPlugin_GetData (pluginName, relPath) into jsMapJSON
   return jsMapJSON
end wikiPlugin_GetJsMap

function wikiPlugin_GetPageJson pluginName, pShortFile
   put wikiPlugin_ConstructPagesFile (pluginName, pShortFile) into pluginPageFile
   if there is a file pluginPageFile then
      put url ("binfile:" & pluginPageFile) into binaryJSON
      -- put _CleanBinaryJson (binaryJSON) into binaryJSON
      return binaryJSON
   else
      return empty
   end if
end wikiPlugin_GetPageJson

function wikiPlugin_List
   put node_WikiModulesFolder() into wikiModulesFolder
   put folder_ListShort (wikiModulesFolder) into shortPluginFolders
   filter shortPluginFolders with "wiki-plugin-*"
   --
   set the itemdelimiter to "-"
   sort shortPluginFolders by item 3 of each
   return shortPluginFolders
end wikiPlugin_List

function wikiPlugin_ListClientRelativePaths pluginName
   -- recursive directory walk
   put wikiPlugin_ConstructClientFolder (pluginName) into pluginClientFolder
   put directory_ListNestedPaths (pluginClientFolder, true) into relPaths
   return relPaths
end wikiPlugin_ListClientRelativePaths

function wikiPlugin_ListClientShortFiles pluginName
   put wikiPlugin_ConstructClientFolder (pluginName) into pluginClientFolder
   put file_ListShort (pluginClientFolder) into shortFiles
   return shortFiles
end wikiPlugin_ListClientShortFiles

function wikiPlugin_ListPageSlugs pluginName
   put wikiPlugin_ConstructPagesFolder (pluginName) into pluginPagesFolder
   put file_ListShort (pluginPagesFolder) into pageSlugs -- = shortFiles
   return pageSlugs
end wikiPlugin_ListPageSlugs

function wikiServer_ConstructDefaultPagePath pageSlug
   put wikiServer_DefaultPagesFolder() & pageSlug into wikiPagePath
   return wikiPagePath
end wikiServer_ConstructDefaultPagePath

function wikiServer_DefaultDataFolder
   put node_WikiModulesFolder() & "wiki-server/default-data/" into defaultDataFolder
   if there is a folder defaultDataFolder then
      return defaultDataFolder
   else
      return empty
   end if
end wikiServer_DefaultDataFolder

function wikiServer_DefaultPagesFolder
   put wikiServer_DefaultDataFolder() & "pages/" into defaultPagesFolder
   if there is a folder defaultPagesFolder then
      return defaultPagesFolder
   else
      return empty
   end if
end wikiServer_DefaultPagesFolder

function wikiServer_GetFavicon wikiDomain
   put wikiFile_Favicon (wikiDomain) into faviconFile
   if there is a file faviconFile then
      put url ("binfile:" & faviconFile) into pngData
      return pngData
   else
      return empty
   end if
end wikiServer_GetFavicon

function wikiServer_GetPageArray pageSlug
   put wikiServer_GetPageJson (pageSlug) into pageJSON
   put json_ToArray (pageJSON) into pageArray
   return pageArray
end wikiServer_GetPageArray

function wikiServer_GetPageJson pageSlug
   put wikiServer_ConstructDefaultPagePath (pageSlug) into defaultPath
   put text_Get (defaultPath) into pageJSON
   return pageJSON
end wikiServer_GetPageJson

function wikiSiteIndex_GetJson pWikiDomain
   put wikiFile_ConstructSiteIndex (pWikiDomain) into siteIndexFile
   if there is a file siteIndexFile then
      put url ("binfile:" & siteIndexFile) into binaryJSON
      return binaryJSON
   else
      return empty
   end if
end wikiSiteIndex_GetJson

function wikiSiteMap_Construct wikiDomain
   put wikiFile_ListPageSlugs (wikiDomain) into pageSlugs
   put 1 into indexNum
   repeat for each line pageSlug in pageSlugs
      put pageArray_Get (wikiDomain, pageSlug) into pageArray
      put pageArray_GetLastModified (pageArray) into dateInMilliseconds
      --
      wikiSiteMap_SetIndexItemArray siteMapArray, indexNum, pageSlug, pageArray, dateInMilliseconds
      add 1 to indexNum
   end repeat
   return siteMapArray
end wikiSiteMap_Construct

command wikiSiteMap_Create wikiDomain
   put wikiSiteMap_Construct (wikiDomain) into newSitemapArray
   wikiSiteMap_SetArray newSitemapArray, wikiDomain
   put the result into writeResult
   if writeResult is empty then
      return newSitemapArray
   else
      return writeResult
   end if
end wikiSiteMap_Create

function wikiSiteMap_GetArray wikiDomain
   put wikiFile_ConstructSiteMap (wikiDomain) into siteMapFile
   put jsonArray_FromFile (siteMapFile) into sitemapArray
   --
   switch
      case sitemapArray is an array
         return sitemapArray
         break
      case sitemapArray is empty
      case item 1 of sitemapArray is "Error"
         if there is a file siteMapFile then
            revDeleteFile siteMapFile
         end if
         wikiSiteMap_Create wikiDomain
         put the result into newSitemapArray
         return newSitemapArray
   end switch
end wikiSiteMap_GetArray

function wikiSiteMap_GetJson pWikiDomain
   put wikiFile_ConstructSiteMap (pWikiDomain) into siteMapFile
   if there is a file siteMapFile then
      -- put url ("file:" & siteMapFile) into binaryJSON
      put url ("binfile:" & siteMapFile) into binaryJSON
      -- put textDecode (binaryJSON, "UTF-8") into binaryJSON
      return binaryJSON
   else
      return empty
   end if
end wikiSiteMap_GetJson

command wikiSiteMap_SetArray siteMapArray, wikiDomain
   put wikiFile_ConstructSiteMap (wikiDomain) into siteMapFile
   jsonArray_ToFile siteMapFile, siteMapArray
   return the result 
end wikiSiteMap_SetArray

command wikiSiteMap_SetIndexItemArray @siteMapArray, indexNum, pageSlug, pageArray, dateInMilliseconds
   put pageArray ["title"] into siteMapArray [indexNum]["title"]
   put pageArray ["story"][1]["text"] into siteMapArray [indexNum]["synopsis"]
   put pageSlug into siteMapArray [indexNum]["slug"]
   put dateInMilliseconds into siteMapArray [indexNum]["date"]
   
   put pageArray ["story"] into storyArray
   put item 2 of the extents of storyArray into lastItemNum
   repeat with itemNum = lastItemNum down to 1
      put storyArray [itemNum]["id"] into itemID
      put storyArray [itemNum]["type"] into itemType
      -- if itemType is among the items of "text,html,markdown" then
      put storyArray [itemNum]["text"] into itemText
      put fedwiki_GetLinks (itemText) into linkIndex
      repeat for each line linkedText in linkIndex
         put itemID into siteMapArray [indexNum]["links"][linkedText]
      end repeat
      -- end if
   end repeat
end wikiSiteMap_SetIndexItemArray
    � '�         ;            ����       cREVGeneral    breakpointstates breakpoints breakpointconditions scripteditorselection 16532 scripteditorvscroll  � scalefactor      �?  �    	@            : 