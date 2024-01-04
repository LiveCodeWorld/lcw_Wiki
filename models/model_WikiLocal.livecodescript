script "model_WikiLocal"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_WikiLocal
type: model
version: 0.2

--> Variable
-
local LocalArray


--> Working on
-
function wiki_ListTopLevelDomains pRootFolder, pNotTheseShortFolders
   if pRootFolder is empty then put wiki_RootFolder() into pRootFolder
   --
   put folder_ListShort (pRootFolder) into wikiDomains
   set the itemdelimiter to "."
   repeat for each line wikiDomain in wikiDomains
      if the number of items of wikiDomain is not 2 then next repeat
      --
      put wikiDomain & CR after toplevelDomains
   end repeat
   return toplevelDomains
end wiki_ListTopLevelDomains

function wiki_ListShortFolders pRootFolder, pNotTheseShortFolders
   if pRootFolder is empty then put wiki_RootFolder() into pRootFolder
   --
   put folder_ListShort (pRootFolder) into shortWikiFolders
   put wiki_StripNotThese (shortWikiFolders, pNotTheseShortFolders) into goodShortFolders
   --
   url_SortDomainIndex goodShortFolders
   return goodShortFolders
end wiki_ListShortFolders


--> Wiki | Folders | List
-
function wiki_ListLocalShortAll pFilter
   put wiki_RootFolder() into wikiFolder
   put folder_ListShortAll (wikiFolder) into shortWikiFolders
   put _NotTheseWikiFolders() into notThese
   put wiki_StripNotThese (shortWikiFolders, notThese) into goodShortFolders
   --
   if pFilter is not empty then filter goodShortFolders with pFilter
   url_SortDomainIndex goodShortFolders
   --
   return goodShortFolders
end wiki_ListLocalShortAll

function wiki_ListFolders pRootFolder, pNotTheseShortFolders
   if pRootFolder is empty then put wiki_RootFolder() into pRootFolder
   put folder_ListNonSymLinked (pRootFolder) into wikiFolders
   --
   put wiki_StripNotThese (wikiFolders, pNotTheseShortFolders) into goodWikiFolders
   return goodWikiFolders
end wiki_ListFolders


--> Wiki | Construct
-
function wiki_ConstructLocalHostDomain wikidomain
   set the itemdelimiter to "."
   if the number of items of wikidomain = 2 then
      put "wiki." & item 1 of wikidomain & ".localhost" into wikidomain
   else
      put "localhost" into item -1 of wikidomain
   end if
   return wikidomain
end wiki_ConstructLocalHostDomain

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


--> Wiki | Port
-
command wiki_AddPortToDomain @wikiDomain, pPort
   if pPort is empty then put wiki_GetPort() into pPort
   if pPort is not empty then
      put ":" & pPort after wikiDomain
   end if
end wiki_AddPortToDomain

command wiki_NormailzePort @sPort
   if sPort is empty then
      put wiki_GetPort() into sPort
   end if
end wiki_NormailzePort

function wiki_GetPort
   put LocalArray ["sPort"] into sPort
   if sPort is empty then put 80 into sPort
   --
   return sPort
end wiki_GetPort

command wiki_SetPort sPort
   put sPort into LocalArray ["sPort"]
end wiki_SetPort


--> Wiki | Url
-
function wiki_ConstructUrl wikiDomain, pPort, pProtocol
   if pPort is empty then put wiki_GetPort() into pPort
   return url_Construct (wikiDomain, pPort, pProtocol)
end wiki_ConstructUrl

function wiki_LocalhostUrl pWikiDomain
   if pWikiDomain is empty then put "localhost" into pWikiDomain
   put wiki_ConstructLocalHostDomain (pWikiDomain) into localhostDomain
   put wiki_ConstructUrl (localhostDomain) into localhostURL
   return localhostURL
end wiki_LocalhostUrl

function wiki_DefaultLocalUrl
   put "http://localhost:3000" into wikiURL
   return wikiURL
end wiki_DefaultLocalUrl


--> Wiki | Pages
-
function wiki_FolderHasNoPages wikiFolder, pNum
   if pNum is not a number then put 1 into pNum
   put wiki_NumberOfpages (wikiFolder) into numOfPages
   if numOfPages is empty then return empty -- not a wiki
   return numOfPages < pNum
end wiki_FolderHasNoPages

function wiki_NumberOfpages wikiFolder, pUseSymLinked
   if pUseSymLinked is true then
      put symlink_Destination (wikiFolder) into destFolder
      if destFolder is empty then
         put _NumberOfpages (wikiFolder) into numOfPages
      else
         put _NumberOfpages (destFolder) into numOfPages
      end if
   else
      put _NumberOfpages (wikiFolder) into numOfPages
   end if
   return numOfPages
end wiki_NumberOfpages


--> Wiki | Local | Folders | Empty
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
      set the cursor to busy
      if shortWikiFolder is among the lines of cleanNotTheseShortFolders then
         next repeat
      end if
      --
      put pRootFolder & shortWikiFolder & slash into wikiFolder
      --
      put wiki_FolderHasNoPages (wikiFolder) into noPages -- symlinked version
      --
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


--> Fedwiki | Local | Folders
-
function fedwiki_LocalAssetsFolder pFedwikiDomain
   put wiki_GetFolder (pFedwikiDomain) into wikiFolder
   put wikiFolder & "assets/" into assetsFolder
   return assetsFolder
end fedwiki_LocalAssetsFolder

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


--> Private
-
private function _NotTheseWikiFolders
   return "commons,assets"
end _NotTheseWikiFolders

function wiki_StripNotThese longOrShortFolders, pNotTheseShortFolders
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
end wiki_StripNotThese

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
