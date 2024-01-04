script "model_WikiFiles"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_WikiFiles
type: model
version: 0.2


--> Variables
-
local Node_ModulesFolder
local Wiki_ModulesFolder
local Wiki_RootFolder


--> Working on
-
function wiki_ListRecyclePageSlugs wikiDomain
   put wiki_ConstructRecycleFolder (wikiDomain) into recycleFolder
   put file_ListShort (recycleFolder) into shortFiles
   return shortFiles
end wiki_ListRecyclePageSlugs

function wiki_ConstructRecycleFolder wikiDomain
   put wiki_ConstructFolder (wikiDomain) into wikiFolder
   put wikiFolder & "recycle/" into recycleFolder
   return recycleFolder
end wiki_ConstructRecycleFolder



--> Wiki | Files
-
function wikiJson_ConstructSiteIndexFile pWikiDomain
   put wiki_ConstructStatusFolder (pWikiDomain) into statusFolder
   put statusFolder & "site-index.json" into siteIndexFile
   return siteIndexFile
end wikiJson_ConstructSiteIndexFile

function wikiJson_ConstructSiteMapFile pWikiDomain
   -- .wiki/audio.commons.academy/status/sitemap.json
   put wiki_ConstructStatusFolder (pWikiDomain) into statusFolder
   put statusFolder & "sitemap.json" into siteMapFile
   return siteMapFile
end wikiJson_ConstructSiteMapFile

function pageJson_ConstructRecycledFile wikiDomain, pSlug
   if pSlug is empty then put "welcome-visitors" into pSlug
   --
   put wiki_RecycleFolder (wikiDomain) into wikiRecycleFolder
   if wikiRecycleFolder is empty then return empty
   put wikiRecycleFolder & pSlug into recycledFile
   return recycledFile
end pageJson_ConstructRecycledFile

function pageJson_ConstructFile wikiDomain, pSlug
   if pSlug is empty then put "welcome-visitors" into pSlug
   --
   put wiki_PagesFolder (wikiDomain) into pagesFolder
   if pagesFolder is empty then return empty
   put pagesFolder & pSlug into pageJsonFile
   return pageJsonFile
end pageJson_ConstructFile


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


--> Wiki | Favicon
-
function wiki_GetFavicon wikiDomain
   put wiki_FaviconFile (wikiDomain) into faviconFile
   if there is a file faviconFile then
      put url ("binfile:" & faviconFile) into pngData
      return pngData
   else
      return empty
   end if
end wiki_GetFavicon

command wiki_SetFavicon wikiDomain, pngData
   put wiki_FaviconFile (wikiDomain) into faviconFile
   put pngData into url ("binfile:" & faviconFile)
   return faviconFile
end wiki_SetFavicon

function wiki_FaviconFile wikiDomain
   put wiki_ConstructStatusFolder (wikiDomain) into statusFolder
   put statusFolder & "favicon.png" into faviconFile
   if there is a file faviconFile then
      return faviconFile
   else
      return empty
   end if
end wiki_FaviconFile

function wiki_GetDefaultFavicon
   put wikiServer_DefaultStatusFolder() into defaultStatusFolder
   put defaultStatusFolder & "favicon.png" into faviconFile
   if there is a file faviconFile then
      put url ("binfile:" & faviconFile) into pngData
      return pngData
   else
      return empty
   end if
end wiki_GetDefaultFavicon


--> Wiki | Folders
-
function wiki_GetFolder sDomain
   put wiki_ConstructFolder (sDomain) into folderPath 
   if there is a folder folderPath then
      return folderPath
   else
      return empty
   end if
end wiki_GetFolder

function wiki_ConstructFolder sDomain
   put wiki_RootFolder() into wikiRoot
   put wikiRoot & sDomain & slash into folderPath 
   return folderPath
end wiki_ConstructFolder


--> Wiki | Folders | Base
-
function wiki_RootFolder
   if Wiki_RootFolder is empty then _InitWikiRootFolder
   return Wiki_RootFolder
end wiki_RootFolder

function wiki_DefaultRootFolder
   put $HOME & "/.wiki/" into wikiRootFolder
   return wikiRootFolder
end wiki_DefaultRootFolder

function wiki_ModulesFolder
   if Wiki_ModulesFolder is empty then _InitWikiModulesFolder
   return Wiki_ModulesFolder
end wiki_ModulesFolder


--> Wiki | Status | Files
-
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


--> Wiki | Folder
-
function wiki_CommonsFolder
   put wiki_RootFolder() into wikiRoot
   put wikiRoot & "commons/" into wikiCommonsFolder
   return wikiCommonsFolder
end wiki_CommonsFolder

function wiki_RecycleFolder wikiDomain
   put wiki_GetFolder (wikiDomain) into wikiFolder
   if wikiFolder is empty then return empty
   put wikiFolder& "recycle/" into wikiRecycleFolder
   return wikiRecycleFolder
end wiki_RecycleFolder
   
function wiki_PagesFolder wikiDomain
   -- fedwiki_LocalPagesFolder
   put wiki_GetFolder (wikiDomain) into wikiFolder
   if wikiFolder is empty then return empty
   put wikiFolder& "pages/" into wikiPagesFolder
   return wikiPagesFolder
end wiki_PagesFolder


--> Nvm & Node | Paths
-
function node_GetModulesFolder pUseNpm
   if Node_ModulesFolder is empty then _InitNodeModulesFolder
   return Node_ModulesFolder
end node_GetModulesFolder

function node_WikiModulesFolder
   put node_GetModulesFolder() & "wiki/node_modules/" into wikiModulesFolder
   return wikiModulesFolder
end node_WikiModulesFolder

function node_GetNodeBinaryPath
   return line 1 of shell ("npm bin -g") & "/npm"
end node_GetNodeBinaryPath

function nvm_Directory
   return shell ("source ~/.zshrc; echo $NVM_DIR")
end nvm_Directory

function nvm_GetBin
   -- put "/Users/david/.nvm/versions/node/v21.0.0/bin/" before wikiBinFile
   get shell ("source ~/.zshrc; echo $NVM_BIN")
   return word 1 to -1 of line 1 of it
end nvm_GetBin


--> Private | Cache
-
private command _InitNodeModulesFolder pUseNpm
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
   if there is a folder nodeModulesFolder then
      return empty
   else
      return "Error, folder" && nodeModulesFolder && "does not exist"
   end if
end _InitNodeModulesFolder

private command _InitWikiModulesFolder
   -- it's inside the node modules /wiki/node-modules" folder
   put node_GetModulesFolder() into nodeModulesFolder   
   put nodeModulesFolder & "wiki/node_modules/" into wikiModulesFolder
   --
   put wikiModulesFolder into Wiki_ModulesFolder
   --
   if there is a folder wikiModulesFolder then
      return empty
   else
      return "Error, folder" && wikiModulesFolder && "does not exist"
   end if
end _InitWikiModulesFolder

private command _InitWikiRootFolder
   set the itemdelimiter to slash
   put env_GetRepoFolder() into sFolder
   put "Earth" into item -1 of sFolder
   --
   put sFolder into Wiki_RootFolder
   
   if there is a folder sFolder then
      return empty
   else
      return "Error, folder" && Wiki_RootFolder && "does not exist"
   end if
end _InitWikiRootFolder
