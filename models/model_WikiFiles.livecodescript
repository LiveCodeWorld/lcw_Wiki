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


--> Working on
-
function wikiFolder_ConstructStatus wikiDomain, pWikiFolder
   if pWikiFolder is empty then
      put wikiFolder_FromRouter (wikiDomain) into pWikiFolder
      put pWikiFolder & "status/" into statusFolder
   else
      text_AddTrailing pWikiFolder, slash
      text_AddTrailing wikiDomain, slash
      put pWikiFolder & wikiDomain & "status/" into statusFolder
   end if
   return statusFolder
end wikiFolder_ConstructStatus

function wikiFolder_ConstructRecycled wikiDomain, pWikiFolder
   if pWikiFolder is empty then
      put wikiFolder_FromRouter (wikiDomain) into pWikiFolder
   end if
   put pWikiFolder & "recycle/" into recycleFolder
   return recycleFolder
end wikiFolder_ConstructRecycled


--> WikiFile | Assets
-
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

function wikiFile_ConstructImageAsset shortFile, wikiDomain
   put wikiFolder_ConstructImageAssets (wikiDomain) into imageAssetsFolder
   put imageAssetsFolder & shortFile into imageFile
   return imageFile
end wikiFile_ConstructImageAsset


--> WikiUrl
-
function wikiUrl_Asset relAssetPath, wikiDomain
   -- http://podcast.anarchive.earth/assets/audio/Astral%20Cinema.m4a
   put "http://" & wikiDomain & "/assets/" into assetsURL
   put urlEncode (relAssetPath) after assetsURL
   return assetsURL
end wikiUrl_Asset

command wikiUrl_Deconstruct wikiURL, @wikiDomain, @slugDomain, @pageSlug, pLineUpNum
   -- http://snack.myth.garden/view/welcome-visitors
   if pLineUpNum is not a number then put 1 into pLineUpNum
   --
   set the itemdelimiter to slash
   put item 3 of wikiURL into wikiDomain
   
   -- 1 => 1, 2 => 3, -1 => -1, -2 => -3
   --
   delete item 1 to 3 of wikiURL
   if pLineUpNum > 0 then
      put 2 * (pLineUpNum - 1) + 1 into slugDomainItemNum
      put slugDomainItemNum + 1 into slugItemNum 
   else
      put 2 * pLineUpNum into slugDomainItemNum 
      put slugDomainItemNum + 1 into slugItemNum 
   end if
   
   put item slugDomainItemNum  of wikiURL into slugDomain
   put item slugItemNum of wikiURL into pageSlug
   if slugDomain = "view" then put wikiDomain into slugDomain
end wikiUrl_Deconstruct

function wikiFile_ConstructLocalHost pSlug
   put wikiFolder_ConstructLocalPages() into localPagesFolder
   if there is not a folder localPagesFolder then return empty
   
   put localPagesFolder & pSlug into pageJsonFile
   return pageJsonFile
end wikiFile_ConstructLocalHost


--> Wikifile | Owner
-
function wikiFile_ConstructOwner wikiDomain, pWikiFolder
   put wikiFolder_ConstructStatus (wikiDomain, pWikiFolder) into statusFolder
   put statusFolder & "owner.json" into faviconFile
   return faviconFile
end wikiFile_ConstructOwner

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


--> WikiFile | List
-
function wikiFile_ListRecycled wikiDomain
   put wikiFolder_ConstructRecycled (wikiDomain) into recycleFolder
   put file_ListShort (recycleFolder) into shortFiles
   return shortFiles
end wikiFile_ListRecycled


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

function wikiFile_Recycled wikiDomain, pSlug
   put wikiFile_ConstructRecycled (wikiDomain, pSlug) into recycledFile
   if there is a file recycledFile then
      return recycledFile
   else
      return empty
   end if
end wikiFile_Recycled


--> WikiFile | Construct
-
function wikiFile_ConstructClient clientRelativePath
   if char 1 of clientRelativePath = slash then delete char 1 of clientRelativePath
   --
   put wikiFolder_Client ("client/") into clientFolder
   put clientFolder & clientRelativePath into sFile
   return sFile
end wikiFile_ConstructClient

end wikiFile_ConstructOwner

function wikiFile_ConstructConfig pWikiDomain
   put wikiFolder_ConstructFromFarm (pWikiDomain) into farmFolder
   put farmFolder & "config.json" into wikiConfigFile
   return wikiConfigFile
end wikiFile_ConstructConfig

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
