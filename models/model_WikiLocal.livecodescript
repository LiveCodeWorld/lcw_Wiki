script "model_WikiLocal"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_WikiLocal
type: model
version: 0.2


--> Working on
-
function wiki_ListAllLocalFolders pFilter
   put wiki_RootFolder() into wikiFolder
   put folder_ListShortAll (wikiFolder) into shortWikiFolders
   put _NotTheseWikiFolders() into notThese
   put _StripNotThese (shortWikiFolders, notThese) into goodShortFolders
   _FilterAndSort goodShortFolders, pFilter
   return goodShortFolders
end wiki_ListAllLocalFolders

private function _NotTheseWikiFolders
   return "commons,assets"
end _NotTheseWikiFolders


--> Wiki | Pages
-
function wiki_FolderHasNoPages wikiFolder, pNum
   if pNum is not a number then put 1 into pNum
   put wiki_NumberOfpages (wikiFolder) into numOfPages
   if numOfPages is empty then return empty -- not a wiki
   return numOfPages < pNum
end wiki_FolderHasNoPages

function wiki_NumberOfpages wikiFolder
   put symlink_Destination (wikiFolder) into destFolder
   if destFolder is empty then
      put _NumberOfpages (wikiFolder) into numOfPages
   else
      put _NumberOfpages (destFolder) into numOfPages
   end if
   return numOfPages
end wiki_NumberOfpages

private function _NumberOfpages wikiFolder
   if there is not a folder wikiFolder then return empty
   
   # Check pages
   text_AddTrailing wikiFolder, slash
   put wikiFolder & "pages/" into pageFolder
   if there is not a folder pageFolder then
      return empty -- not a wiki
   end if
   
   # List wiki-pages and count
   put files (pageFolder) into pageFiles
   if pageFiles is empty then return 0
   put the number of lines of pageFiles - 1 into numOfPages
   return numOfPages
end _NumberOfpages

function wiki_LocalHostDomain localhostDomain
   set the itemdelimiter to "."
   if item -2 to -1 of localhostDomain = "localhost" then
      put "localhost" into item -2 to -1 of localhostDomain
   end if
   return localhostDomain
end wiki_LocalHostDomain

function wiki_AstralFromLocalhost localhostDomain
   if localhostDomain = "localhost" then return "localhost"
   if localhostDomain = "astralship.localhost" then return "astralship.wiki"
   --
   set the itemdelimiter to "."
   if item -1 of localhostDomain = "localhost" then
      put "astralship.wiki" into item -1 of localhostDomain
   end if
   return localhostDomain
end wiki_AstralFromLocalhost


--> Wiki | Folder | List | Empty
-
function wiki_ListEmptyLocalFolders pListShort
   put wiki_RootFolder() into rootFolder
   put _NotTheseWikiFolders into notThese
   put wiki_ListEmptyFolders (rootFolder, pListShort, notThese) into wikiFolders
   return wikiFolders
end wiki_ListEmptyLocalFolders

function wiki_ListEmptyFolders pRootFolder, pListShort, pNotTheseShortFolders
   if pRootFolder is empty then put wiki_RootFolder() into pRootFolder
   put folder_ShortList (pRootFolder) into notSymLinkedFolderNames
   --
   put _TidyNotThese (pNotTheseShortFolders) into cleanNotTheseShortFolders
   repeat for each line shortWikiFolder in notSymLinkedFolderNames
      if shortWikiFolder is among the lines of cleanNotTheseShortFolders then
         next repeat
      end if
      --
      put pRootFolder & shortWikiFolder & slash into wikiFolder
      put wiki_FolderHasNoPages (wikiFolder) into noPages
      if noPages is true then
         put wikiFolder & CR after emptyFolders
         put shortWikiFolder & CR after emptyShortFolders
      else
         next repeat
      end if
   end repeat
   delete char -1 of emptyShortFolders
   delete char -1 of emptyFolders
   
   if pListShort is true then
      url_SortDomainIndex emptyShortFolders
      return emptyShortFolders
   else
      return emptyFolders
   end if
end wiki_ListEmptyFolders


--> Wiki | Folders | List
-
function wiki_ListFolders pRootFolder, pNotTheseShortFolders
   if pRootFolder is empty then put wiki_RootFolder() into pRootFolder
   -- put folder_ListLong (pRootFolder) into wikiFolders
   put folder_ListNonSymLinked (pRootFolder) into wikiFolders
   --
   put _StripNotThese (wikiFolders, pNotTheseShortFolders) into goodWikiFolders
   return goodWikiFolders
end wiki_ListFolders

function wiki_ListShortFolders pRootFolder, pNotTheseShortFolders
   if pRootFolder is empty then put wiki_RootFolder() into pRootFolder
   --
   put folder_ListShort (pRootFolder) into shortWikiFolders
   put _StripNotThese (shortWikiFolders, pNotTheseShortFolders) into goodShortFolders
   --
   url_SortDomainIndex goodShortFolders
   return goodShortFolders
end wiki_ListShortFolders

private function _StripNotThese longOrShortFolders, pNotTheseShortFolders
   -- works with long or short folders
   
   # Not these
   put _TidyNotThese (pNotTheseShortFolders) into cleanNotTheseShortFolders
   
   set the itemdelimiter to slash
   repeat for each line longOrShortFolder in longOrShortFolders
      get item -1 of longOrShortFolder
      switch
         case char 1 of longOrShortFolder = "_"
            next repeat
         case it is among the lines of cleanNotTheseShortFolders
            next repeat
         default
            put longOrShortFolder & CR after goodLongOrShortFolders
      end switch
   end repeat
   delete char -1 of goodLongOrShortFolders
   return goodLongOrShortFolders
end _StripNotThese

private function _TidyNotThese pNotTheseShortFolders
   replace comma with CR in pNotTheseShortFolders
   repeat for each line notThisShortFolder in pNotTheseShortFolders
      put word 1 to -1 of notThisShortFolder into notThisShortFolder
      if char -1 of notThisShortFolder is slash then delete char -1 of notThisShortFolder
      put notThisShortFolder & CR after cleanNotTheseShortFolders
   end repeat
   delete char -1 of cleanNotTheseShortFolders
   return cleanNotTheseShortFolders
end _TidyNotThese


--> Fedwiki | Model
-
private command _FilterAndSort @wikiFolders, pFilter
   if pFilter is not empty then filter wikiFolders with pFilter
   url_SortDomainIndex wikiFolders
end _FilterAndSort


--> Fedwiki | Local | Files
-
function fedwiki_ConstructSitemapPath wikiDomain
   -- see "atopia_ConstructSitemapPath"
   put fedwiki_GetLocalWikiFolder (wikiDomain) into localWikiFolder
   put localWikiFolder & "status/sitemap.json" into siteMapFile
   return siteMapFile
end fedwiki_ConstructSitemapPath

function fedwiki_LocalPageJsonFile pageSlug, wikiDomain
   put fedwiki_LocalPagesFolder (wikiDomain) into localPagesFolder
   put localPagesFolder & pageSlug into someFile
   return someFile
end fedwiki_LocalPageJsonFile

-- function fedwiki_LocalPageJsonFile pageSlug, pFedwikiDomain, pCreateFolder, pLocalWikiFolder
put fedwiki_LocalPagesFolder (pFedwikiDomain, pLocalWikiFolder) into localPagesFolder
if pCreateFolder is true then
   folder_CreateNested localPagesFolder
end if
put localPagesFolder & pageSlug into someFile
return someFile
end fedwiki_LocalPageJsonFile


--> Fedwiki | Local | Folders
-
function fedwiki_LocalAssetsFolder pFedwikiDomain
   put fedwiki_GetLocalWikiFolder (pFedwikiDomain) into wikiFolder
   put wikiFolder & "assets/" into assetsFolder
   return assetsFolder
end fedwiki_LocalAssetsFolder

function fedwiki_LocalPagesFolder pFedwikiDomain
   -- fedwiki_PagesFolder
   put fedwiki_GetLocalWikiFolder (pFedwikiDomain) into wikiRootFolder
   put wikiRootFolder & "pages/" into localPagesFolder
   return localPagesFolder
end fedwiki_LocalPagesFolder

function fedwiki_LocalStatusFolder pFedwikiDomain
   put fedwiki_GetLocalWikiFolder (pFedwikiDomain) into wikiFolder
   put wikiFolder & "status/" into wikiPageFolder
   return localStatusFolder
end fedwiki_LocalStatusFolder

function fedwiki_GetLocalWikiFolder pFedwikiDomain
   put fedwiki_GetLocalWikiRoot() into localWikiFolder
   if localWikiFolder is empty then return empty
   
   if pFedwikiDomain is not empty then
      put pFedwikiDomain after localWikiFolder
      folder_Format localWikiFolder
   end if
   return localWikiFolder
end fedwiki_GetLocalWikiFolder

command fedwiki_SetLocalWikiRoot localWikiRoot
   folder_Format localWikiRoot
   put fedwiki_GetLocalData() into localWikiData
   put localWikiRoot into localWikiData ["localWikiRoot"]
   fedwiki_SetLocalData localWikiData
end fedwiki_SetLocalWikiRoot

function fedwiki_GetLocalWikiRoot
   put fedwiki_GetLocalData() into localWikiData
   put localWikiData ["localWikiRoot"] into localWikiRoot
   --
   if localWikiRoot is empty then
      put "~/.wiki/" into localWikiRoot -- this is the default root for a wiki-node server on OSX and Linux
   end if
   return localWikiRoot
end fedwiki_GetLocalWikiRoot


--> Fedwiki | Local | Model
-
function fedwiki_GetLocalData
   put the model_Data of me into localWikiData
   return localWikiData
end fedwiki_GetLocalData

command fedwiki_SetLocalData localWikiData
   set the model_Data of me to localWikiData
   put the result into modelFile
   return modelFile
end fedwiki_SetLocalData

