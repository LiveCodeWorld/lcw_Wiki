script "model_WikiFiles"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_WikiFiles
type: model
version: 0.2


--> Working on
-
function wiki_FaviconFile wikiDomain
   put wiki_ConstructStatusFolder (wikiDomain) into statusFolder
   put statusFolder & "favicon.png" into faviconFile
   if there is a file faviconFile then
      return faviconFile
   else
      return empty
   end if
end wiki_FaviconFile

function wiki_GetStatusFolder wikiDomain
   put wiki_ConstructStatusFolder (wikiDomain) into statusFolder
   if there is a folder statusFolder then
      return statusFolder
   else
      return empty
   end if
end wiki_GetStatusFolder

function wiki_ConstructStatusFolder wikiDomain
   put wiki_ConstructFolder (wikiDomain) into wikiFolder
   put wikiFolder & "status/" into statusFolder
   return statusFolder
end wiki_ConstructStatusFolder

command wiki_CreateHardLink fromDomain, fromSlug, toDomain, toSlug
   put wiki_PageJsonFile (fromDomain, fromSlug) into fromFile
   if there is not a file fromFile then return "Error, file" && fromFile && "does not exist."
   put wiki_ConstructPageJsonFile (toDomain, toSlug) into toFile
   if there is not a file toFile then return "Error, domain" && toDomain && "does not exist."
   --
   hardlink_Create fromFile, toFile
   --
   return the result
end wiki_CreateHardLink

command hardlink_Create fromFile, toFile
   if there is not a file fromFile then return "Error," && fromFile && "does not exist."
   --
   if there is a file toFile then
      breakpoint
      return "Error, not overwriting existing file" & toFile
   end if
   
   put merge ("ln '[[fromFile]]' '[[toFile]]'") into someShell
   replace "'" with quote in someShell
   put shell (someShell) into shellResult
   return shellResult
end hardlink_Create

function wiki_PageJsonFile wikiDomain, pSlug
   if pSlug is empty then put "welcome-visitors" into pSlug
   --
   put wiki_PagesFolder (wikiDomain) into pagesFolder
   if pagesFolder is empty then return empty
   put pagesFolder & pSlug into pageJsonFile
   return pageJsonFile
end wiki_PageJsonFile

function wiki_ListMediaPhotos pListShort
   put wiki_MediaAssetFolder() into rootFolder
   if pListShort is true then
      return file_ListShort (rootFolder)
   else
      return file_ListLong (rootFolder)
   end if
end wiki_ListMediaPhotos

function wiki_ListPages sDomain
   put wiki_PagesFolder (sDomain) into wikiPagesFolder
   if there is a folder wikiPagesFolder then
      put folder_ShortFiles (wikiPagesFolder) into pageSlugs
      return pageSlugs
   else
      return empty
   end if
end wiki_ListPages


--> Gitwiki | Folders
-
function gitwiki_ConstructFolder sDomain
   put gitwiki_RootFolder() into gitWikiFolder
   put gitWikiFolder & sDomain into folderPath 
   return folderPath
end gitwiki_ConstructFolder

function gitwiki_GetFolder sDomain
   put gitwiki_ConstructFolder(sDomain) into folderPath
   if there is a folder folderPath then
      return folderPath
   else
      return empty
   end if
end gitwiki_GetFolder

function gitwiki_ListAllLocalFolders pFilter
   put gitwiki_RootFolder() into rootFolder
   --
   put folder_ListShortAll (rootFolder) into shortWikiFolders
   put _NotTheseWikiFolders() into notThese
   put wiki_StripNotThese (shortWikiFolders, notThese) into goodShortFolders
   --
   if pFilter is not empty then filter wikiFolders with pFilter
   url_SortDomainIndex goodShortFolders
   --
   return goodShortFolders
end gitwiki_ListAllLocalFolders

private function _NotTheseWikiFolders
   put ".git,fedwiki_owners,dead.anarchive.earth" into notThese
   return notThese
end _NotTheseWikiFolders

function gitwiki_ListFolders pListshort
   put gitwiki_RootFolder() into rootFolder
   put _NotTheseWikiFolders() into notThese
   --
   if pListshort is true then
      put wiki_ListShortFolders (rootFolder, notThese) into gitWikiFolders
   else
      put wiki_ListFolders (rootFolder, notThese) into gitWikiFolders
   end if
   return gitWikiFolders
end gitwiki_ListFolders

function gitwiki_ListEmptyFolders pListShort
   put gitwiki_RootFolder() into rootFolder
   put wiki_ListEmptyFolders (rootFolder, pListShort, ".git,fedwiki_owners,dead.anarchive.earth") into emptyFolders
   return emptyFolders
end gitwiki_ListEmptyFolders

function gitwiki_RootFolder
   put env_GetRepoFolder() into repoFolder
   put repoFolder & "wiki/" into gitWikiFolder
   return gitWikiFolder
end gitwiki_RootFolder

command gitwiki_CreateSymLink gitWikiDomain, pSymLinkDomain
   if pSymLinkDomain is empty then
      put gitWikiDomain into pSymLinkDomain
   end if
   --
   put gitwiki_GetFolder (gitWikiDomain) into gitWikiFolder
   put wiki_ConstructFolder (pSymLinkDomain) into symWikiFolder
   --
   symlink_CreateFolder gitWikiFolder, symWikiFolder
   --
   if the result is empty then
      return pSymLinkDomain
   else
      breakpoint
      return "Error," && the result
   end if
end gitwiki_CreateSymLink


--> Wiki
-
function wiki_SearchExport exportData, sKey, sValue, pSearchHow, pFirst
   local rData
   repeat for each key pageSlug in exportData
      put exportData [pageSlug]["story"] into storyArray
      --
      switch pSearchHow
         case "ends"
            put indexArray_FindEndsWith (storyArray, sKey, sValue) into itemNum
            break
         case "contains"
            put indexArray_FindContains (storyArray, sKey, sValue) into itemNum
            break
         default
            put indexArray_Find (storyArray, sKey, sValue) into itemNum
      end switch 
      --
      if itemNum > 0 then
         put itemNum into rArray ["itemNum"]
         put storyArray [itemNum] into rArray ["itemArray"]
         if pFirst is true then
            put pageSlug into rArray ["slug"]
            return rArray
         else
            put rArray into rData [pageSlug]
         end if
      end if
   end repeat
   return rData
end wiki_SearchExport

function wiki_FindImageListData wikiDomain, imageHash, pFirst
   put wiki_FetchExportData (wikiDomain) into exportData
   put wiki_SearchExport (exportData, "url", imageHash, "ends", pFirst) into rData
   return rData
end wiki_FindImageListData

function wiki_MediaAssetFolder
   put wiki_GetFolder ("media.localhost") into mediaWikiFolder
   put mediaWikiFolder & "assets/plugins/image/" into mediaAssetFolder
   if there is a folder mediaAssetFolder then
      return mediaAssetFolder
   else
      return empty
   end if
end wiki_MediaAssetFolder

function wiki_RootFolder pUseDefault
   if pUseDefault is true then
      put $HOME & "/.wiki/" into wikiRootFolder
      return wikiRootFolder
   else
      set the itemdelimiter to slash
      put env_GetRepoFolder() into wikiRootFolder
      put "Earth" into item -1 of wikiRootFolder
      --
      if there is a folder wikiRootFolder then
         return wikiRootFolder
      else
         return empty
      end if
   end if
end wiki_RootFolder

command wiki_CreateSymLink wikiDomain, pSymLinkDomain
   if pSymLinkDomain is empty then put wikiDomain into pSymLinkDomain
   --
   put wiki_GetFolder (wikiDomain) into wikiFolder
   put wiki_ConstructFolder (pSymLinkDomain) into symWikiFolder
   --
   symlink_CreateFolder wikiFolder, symWikiFolder
   return the result
end wiki_CreateSymLink


--> Wiki | config
-
function wiki_GetConfigFile
   -- see "lib_AtopiaDomainOwnership"
   put wiki_ConstructConfigFile() into wikiConfigFile
   if there is a file wikiConfigFile then
      return wikiConfigFile
   else
      return empty
   end if
end wiki_GetConfigFile

function wiki_ConstructConfigFile
   put wiki_RootFolder() into wikiRootFolder
   put wikiRootFolder & "config.json" into wikiConfigFile
   return wikiConfigFile
end wiki_ConstructConfigFile


--> Wiki | Folder
-
function wiki_ConstructFolder sDomain
   put wiki_RootFolder() into wikiRoot
   put wikiRoot & sDomain & slash into folderPath 
   return folderPath
end wiki_ConstructFolder

function wiki_CommonsFolder
   put wiki_RootFolder() into wikiRoot
   put wikiRoot & "commons/" into wikiCommonsFolder
   return wikiCommonsFolder
end wiki_CommonsFolder

function wiki_PagesFolder sDomain
   -- fedwiki_LocalPagesFolder
   put wiki_GetFolder (sDomain) into wikiFolder
   if wikiFolder is empty then return empty
   put wikiFolder& "pages/" into wikiPagesFolder
   return wikiPagesFolder
end wiki_PagesFolder

function wiki_GetWikiClientFolder
   put wiki_ModulesFolder() & "wiki-client/" into wikiClientFolder
   return wikiClientFolder
end wiki_GetWikiClientFolder

function wiki_GetFolder sDomain
   -- was "fedwiki_GetLocalWikiFolder"
   put wiki_ConstructFolder (sDomain) into folderPath 
   if there is a folder folderPath then
      return folderPath
   else
      return empty
   end if
end wiki_GetFolder


--> Fedwiki | Local | Paths
-
function wiki_DefaultPagePath pageSlug
   put wiki_DefaultPagesFolder() & pageSlug into wikiPagePath
   return wikiPagePath
end wiki_DefaultPagePath

function wiki_DefaultStatusFolder
   put wiki_DefaultDataFolder() & "status/" into defaultStatusFolder
   if there is a folder defaultStatusFolder then
      return defaultStatusFolder
   else
      return empty
   end if
end wiki_DefaultStatusFolder

function wiki_DefaultPagesFolder
   put wiki_DefaultDataFolder() & "pages/" into defaultPagesFolder
   if there is a folder defaultPagesFolder then
      return defaultPagesFolder
   else
      return empty
   end if
end wiki_DefaultPagesFolder

function wiki_DefaultDataFolder
   put node_WikiModulesFolder() & "wiki-server/default-data/" into defaultDataFolder
   if there is a folder defaultDataFolder then
      return defaultDataFolder
   else
      return empty
   end if
end wiki_DefaultDataFolder


--> Paths
-
function node_WikiModulesFolder
   put node_GetModulesFolder() & "wiki/node_modules/" into wikiModulesFolder
   return wikiModulesFolder
end node_WikiModulesFolder

function node_GetModulesFolder pUseNpm
   # Node version
   if pUseNpm is true then
      put line 1 of shell ("npm root -g") & "/" into nodeModulesFolder
      return nodeModulesFolder
   end if
   
   # NVM version
   set the itemdelimiter to slash
   put nvm_GetBin() into nodeModulesFolder
   put "lib/node_modules/" into item -1 of nodeModulesFolder
   
   if there is not a folder nodeModulesFolder then return empty
   return nodeModulesFolder
end node_GetModulesFolder

function node_GetNodeBinaryPath
   return line 1 of shell ("npm bin -g") & "/npm"
end node_GetNodeBinaryPath


--> Wiki | ModulesFolder
-
function wiki_ModulesFolder
   -- it's inside the node modules /wiki/node-modules" folder
   put node_GetModulesFolder() into nodeModulesFolder
   if there is not a folder nodeModulesFolder then  return empty
   
   put nodeModulesFolder & "wiki/node_modules/" into fedwikiModulesFolder
   if there is not a folder fedwikiModulesFolder then  return empty
   
   return fedwikiModulesFolder
end wiki_ModulesFolder


--> Nvm
-
function nvm_Directory
   return shell ("source ~/.zshrc; echo $NVM_DIR")
end nvm_Directory

function nvm_GetBin
   -- put "/Users/david/.nvm/versions/node/v21.0.0/bin/" before wikiBinFile
   get shell ("source ~/.zshrc; echo $NVM_BIN")
   return word 1 to -1 of line 1 of it
end nvm_GetBin
