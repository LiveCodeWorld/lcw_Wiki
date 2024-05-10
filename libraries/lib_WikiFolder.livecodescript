script "lib_WikiFolder"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_WikiFolder
type: library
version: 0.1

/*
function wiki_ListLocalShortAll pFilter
   return wikiFarm_ListDomains (pFilter)
end wiki_ListLocalShortAll

function wiki_ListFolders pRootFolder, pNotTheseShortFolders
   if pRootFolder is empty then put wiki_RootFolder() into pRootFolder
   put folder_ListNonSymLinked (pRootFolder) into wikiFolders
   --
   put _StripNotThese (wikiFolders, pNotTheseShortFolders) into goodWikiFolders
   return goodWikiFolders
end wiki_ListFolders
*/


--> Working on
-
function wikiFolder_ListTopLevel pRootFolder
   
   # List Toplevel
   put url_ListTopLevelDomains (wikiDomains) into toplevelDomains
   
   # Strip notThese
   put _NotThese() into notThese
   put _StripNotThese (toplevelDomains, notThese) into goodShortFolders
   return goodShortFolders
end wikiFolder_ListTopLevel


--> WikiFarm | List
-
function wikiFarm_ListDomains pFilterDomain, pSimple
   put wiki_RootFolder() into farmFolder
   put wikiFarm_DomainsFromFolder (farmFolder, pFilterDomain, pSimple) into shortWikiFolders
   return shortWikiFolders
end wikiFarm_ListDomains

function wikiFarm_DomainsFromFolder farmFolder, pFilterDomain, pSimple
   # List Farm
   put folder_ListShortAll (farmFolder) into shortWikiFolders 
   put pFilterDomain is among the lines of shortWikiFolders into addTLD
   
   # Tidy
   wikiFolder_TidyList shortWikiFolders
   wikiFolder_FilterList shortWikiFolders, pFilterDomain, pSimple
   
   # Add Root
   set the wholeMatches to true
   if addTLD then
      put pFilterDomain & CR before shortWikiFolders
   end if
   
   # Sort
   url_SortDomainIndex shortWikiFolders
   return shortWikiFolders
end wikiFarm_DomainsFromFolder

function wiki_ListShortFolders pRootFolder, pNotTheseShortFolders
   if pRootFolder is empty then put wikiFarm_GetRoot() into pRootFolder
   if pNotTheseShortFolders is empty then put "commons" into pNotTheseShortFolders
   --
   put folder_ListShort (pRootFolder) into shortWikiFolders
   put _StripNotThese (shortWikiFolders, pNotTheseShortFolders) into goodShortFolders
   --
   url_SortDomainIndex goodShortFolders
   return goodShortFolders
end wiki_ListShortFolders


--> WikiFolder | List | Empty
-
function wiki_ListEmptyLocalFolders pListShort
   put wiki_RootFolder() into rootFolder
   put _NotThese into notThese
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


--> WikiFolder | Tidy
-
command wikiFolder_TidyList @shortWikiFolders
   put _NotThese() into notThese
   put _StripNotThese (shortWikiFolders, notThese) into shortWikiFolders
end wikiFolder_TidyList

command wikiFolder_FilterList @shortWikiFolders, pFilter, pSimple
   if pFilter is not empty then
      if pSimple is true then
         filter shortWikiFolders with pFilter
      else
         put "*." & pFilter into sFilter
         filter shortWikiFolders with sFilter
      end if
   end if
end wikiFolder_FilterList


--> Private
-
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

private function _StripNotThese longOrShortFolders, pNotTheseShortFolders
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

function _NotThese
   return "commons,assets"
end _NotThese
