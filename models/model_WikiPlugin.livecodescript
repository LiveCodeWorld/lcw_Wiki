script "model_WikiPlugin"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_WikiPlugin
type: model
version: 0.1


--> WikiPlugin
-
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

function wikiPlugin_List
   put node_WikiModulesFolder() into wikiModulesFolder
   put folder_ListShort (wikiModulesFolder) into shortPluginFolders
   filter shortPluginFolders with "wiki-plugin-*"
   --
   set the itemdelimiter to "-"
   sort shortPluginFolders by item 3 of each
   return shortPluginFolders
end wikiPlugin_List


--> WikiPlugin | Model
-
function wikiPlugin_GetJsMap pluginName, shortMapFile
   put "client/" & shortMapFile into relPath
   put wikiPlugin_GetData (pluginName, relPath) into jsMapJSON
   return jsMapJSON
end wikiPlugin_GetJsMap

function wikiPlugin_GetJavascript pluginName
   put "client/" & pluginName & ".js" into relPath
   put wikiPlugin_GetData (pluginName, relPath) into sJavascript
   return sJavascript
end wikiPlugin_GetJavascript

function wikiPlugin_GetData pluginName, shortFile
   put wikiPlugin_ConstructFile (pluginName, shortFile) into pluginFile
   if there is a file pluginFile then
      put url ("binfile:" & pluginFile) into sData
      return sData
   else
      return empty
   end if
end wikiPlugin_GetData

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

function wikiPlugin_ConstructPagesFile pluginName, pShortFile
   if pShortFile is empty then
      put merge ("about-[[pluginName]]-plugin") into pShortFile
   end if
   put wikiPlugin_ConstructPagesFolder (pluginName) into pluginPagesFolder
   put pluginPagesFolder & pShortFile into pluginPageFile
   return pluginPageFile
end wikiPlugin_ConstructPagesFile

function wikiPlugin_ConstructClientFolder pluginName
   put wikiPlugin_ConstructFolder (pluginName) into pluginFolder
   put pluginFolder & "client/" into pluginClientFolder
   return pluginClientFolder
end wikiPlugin_ConstructClientFolder

function wikiPlugin_ConstructPagesFolder pluginName
   put wikiPlugin_ConstructFolder (pluginName) into pluginFolder
   put pluginFolder & "pages/" into pluginPagesFolder
   return pluginPagesFolder
end wikiPlugin_ConstructPagesFolder

function wikiPlugin_ConstructFile pluginName, shortFile
   put wikiPlugin_ConstructFolder (pluginName) into pluginFolder
   put pluginFolder & shortFile into pluginFile
   return pluginFile
end wikiPlugin_ConstructFile

function wikiPlugin_Folder pluginName
   put wikiPlugin_ConstructFolder (pluginName) into pluginFolder
   if there is a folder pluginFolder then
      return pluginFolder
   else
      return empty
   end if
end wikiPlugin_Folder

function wikiPlugin_ConstructFolder pluginName
   put node_WikiModulesFolder() & "wiki-plugin-" & pluginName & slash into pluginFolder
   return pluginFolder
end wikiPlugin_ConstructFolder


--> Private
-
private function _CleanBinaryJson binaryJSON
   put json_ToArray (binaryJSON) into pageArray
   put pluginName into pageArray ["plugin"]
   put json_FromArray (pageArray) into binaryJSON
   return binaryJSON
end _CleanBinaryJson


--> Deps
-
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
