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


--> Wiki | Favicon
-
function wiki_GetFavicon wikiDomain
   put wikiFile_Favicon (wikiDomain) into faviconFile
   if there is a file faviconFile then
      put url ("binfile:" & faviconFile) into pngData
      return pngData
   else
      return empty
   end if
end wiki_GetFavicon

command wiki_SetFavicon wikiDomain, pngData
   put wikiFile_Favicon (wikiDomain) into faviconFile
   put pngData into url ("binfile:" & faviconFile)
   return faviconFile
end wiki_SetFavicon


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


--> WikiUrl
-
function wikiUrl_Asset relAssetPath, wikiDomain
   -- http://podcast.anarchive.earth/assets/audio/Astral%20Cinema.m4a
   put "http://" & wikiDomain & "/assets/" into assetsURL
   put urlEncode (relAssetPath) after assetsURL
   return assetsURL
end wikiUrl_Asset


--> WikiFile | List
-
function wikiFile_ListRecycled wikiDomain
   put wikiFolder_ConstructRecycled (wikiDomain) into recycleFolder
   put file_ListShort (recycleFolder) into shortFiles
   return shortFiles
end wikiFile_ListRecycled

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


--> WikiFile | Pages
-
function wikiFile_FoundPageMarkDown pageSlug, wikiDomain, pTrimFirstNumber
   put wikiFile_FoundAndMissingArray (pageSlug, wikiDomain, pTrimFirstNumber) into sArray
   return sArray ["found"]
end wikiFile_FoundPageMarkDown

function wikiFile_MissingPageMarkDown pageSlug, wikiDomain, pTrimFirstNumber
   put wikiFile_FoundAndMissingArray (pageSlug, wikiDomain, pTrimFirstNumber) into sArray
   return sArray ["missing"]
end wikiFile_MissingPageMarkDown

function wikiFile_FoundAndMissingArray pageSlug, wikiDomain, pTrimFirstNumber
   put wikiFile_ListPageSlugs (wikiDomain) into pageSlugs
   put wikiFile_ListShort (pageSlug, wikiDomain) into shortFiles
   --
   set the itemdelimiter to "."
   repeat for each line shortAudioFile in shortFiles
      put item 1 of shortAudioFile into testTitle
      /*
      get char 1 to 2 of testTitle
      if it is a number then
         delete word 1 of testTitle
      end if
      */
      put transcribe_TitleFromShortFile (shortAudioFile) into testTitle
      put fedwiki_ConstructSlug (testTitle) into testSlug
      
      put pTrimFirstNumber is not false into pTrimFirstNumber
      put testSlug is not among the lines of pageSlugs into slugExists
      if pTrimFirstNumber AND slugExists then
         put "- [[" & testTitle & "]]" & CR after foundTitleMarkdown
      else
         put "- [[" & testTitle & "]]" & CR after missingTitleMarkdown
      end if
   end repeat
   delete char -1 of missingTitleMarkdown
   delete char -1 of foundTitleMarkdown
   
   put missingTitleMarkdown into sArray ["missing"]
   put foundTitleMarkdown into sArray ["found"]
   return sArray
end wikiFile_FoundAndMissingArray

function wikiFile_ListShort pageSlug, wikiDomain
   put wikiFolder_ConstructPageAssets (pageSlug, wikiDomain) into pageFolder
   put file_ListShort (pageFolder) into shortFiles
   return shortFiles
end wikiFile_ListShort

function wikiFile_ListPageSlugs sDomain
   put wikiFolder_Pages (sDomain) into wikiPagesFolder
   if there is a folder wikiPagesFolder then
      put file_ListShort (wikiPagesFolder) into pageSlugs
      return pageSlugs
   else
      return empty
   end if
end wikiFile_ListPageSlugs


--> WikiFile
-
function wikiFile_Config
   -- see "lib_AtopiaDomainOwnership"
   put wikiFile_ConstructConfig() into wikiConfigFile
   if there is a file wikiConfigFile then
      return wikiConfigFile
   else
      return empty
   end if
end wikiFile_Config

function wikiFile_Favicon wikiDomain
   put wikiFile_ConstructFavicon (wikiDomain) into faviconFile
   if there is a file faviconFile then
      return faviconFile
   else
      return empty
   end if
end wikiFile_Favicon


--> WikiFile | Construct
-
function wikiFile_ConstructAsset relAssetPath, wikiDomain
   put wikiFolder_ConstructAssets (wikiDomain) into assetsFolder
   put assetsFolder & relAssetPath into sFile
   return sFile
end wikiFile_ConstructAsset

function wikiFile_ConstructRecycled wikiDomain, pSlug
   if pSlug is empty then put "welcome-visitors" into pSlug
   --
   put wikiFolder_Recycled (wikiDomain) into wikiRecycleFolder
   if wikiRecycleFolder is empty then return empty
   put wikiRecycleFolder & pSlug into recycledFile
   return recycledFile
end wikiFile_ConstructRecycled

function wikiFile_ConstructImageAsset shortFile, wikiDomain
   put wikiFolder_ConstructImageAssets (wikiDomain) into imageAssetsFolder
   put imageAssetsFolder & shortFile into imageFile
   return imageFile
end wikiFile_ConstructImageAsset

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

function wikiFile_ConstructConfig
   put wiki_RootFolder() into wikiRootFolder
   put wikiRootFolder & "config.json" into wikiConfigFile
   return wikiConfigFile
end wikiFile_ConstructConfig

function wikiFile_ConstructFavicon wikiDomain
   put wikiFolder_ConstructStatus (wikiDomain) into statusFolder
   put statusFolder & "favicon.png" into faviconFile
   return faviconFile
end wikiFile_ConstructFavicon

function wikiFile_Construct wikiDomain, pSlug
   if pSlug is empty then put "welcome-visitors" into pSlug
   --
   put wikiFolder_Pages (wikiDomain) into pagesFolder
   if pagesFolder is empty then return empty
   put pagesFolder & pSlug into pageJsonFile
   return pageJsonFile
end wikiFile_Construct


--> WikiFolder
-
function wikiFolder_Recycled wikiDomain
   put wikiFolder_ConstructRecycled (wikiDomain) into wikiRecycleFolder
   if there is a folder wikiRecycleFolder then
      return wikiRecycleFolder
   else
      return empty
   end if
end wikiFolder_Recycled

function wikiFolder_Pages wikiDomain
   put wikiFolder_Construct (wikiDomain) into wikiFolder 
   put wikiFolder & "pages/" into wikiPagesFolder
   if there is a folder wikiPagesFolder then
      return wikiPagesFolder
   else
      return empty
   end if
end wikiFolder_Pages

function wikiFolder_Get sDomain
   put wikiFolder_Construct (sDomain) into folderPath 
   if there is a folder folderPath then
      return folderPath
   else
      return empty
   end if
end wikiFolder_Get


--> WikiFolder | Construct
-
function wikiFolder_ConstructPageAssets pageSlug, wikiDomain
   put wikiFolder_ConstructAssets (wikiDomain) into assetsFolder
   put assetFolder & pageSlug & slash into oggFolder
   return oggFolder
end wikiFolder_ConstructPageAssets

function wikiFolder_ConstructImageAssets wikiDomain
   put wikiFolder_Construct (wikiDomain) into wikiFolder
   put wikiFolder & "assets/plugins/image/" into imageAssetsFolder
   return imageAssetsFolder
end wikiFolder_ConstructImageAssets

function wikiFolder_ConstructAssets wikiDomain
   put wikiFolder_Construct (wikiDomain) into wikiFolder
   put wikiFolder & "assets/" into assetsFolder
   return assetsFolder
end wikiFolder_ConstructAssets

function wikiFolder_ConstructStatus wikiDomain
   put wikiFolder_Construct (wikiDomain) into wikiFolder
   put wikiFolder & "status/" into statusFolder
   return statusFolder
end wikiFolder_ConstructStatus

function wikiFolder_ConstructCommons
   put wiki_RootFolder() into wikiRoot
   put wikiRoot & "commons/" into wikiCommonsFolder
   return wikiCommonsFolder
end wikiFolder_ConstructCommons

function wikiFolder_ConstructRecycled wikiDomain
   put wikiFolder_Construct (wikiDomain) into wikiFolder
   put wikiFolder & "recycle/" into recycleFolder
   return recycleFolder
end wikiFolder_ConstructRecycled

function wikiFolder_Construct sDomain
   put wiki_RootFolder() into wikiRoot
   put wikiRoot & sDomain & slash into folderPath 
   return folderPath
end wikiFolder_Construct


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
