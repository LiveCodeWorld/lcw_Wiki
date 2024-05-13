script "lib_WikiFolder"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_WikiFolder
type: library
version: 0.1

/*
*/


--> Working on
-
function wikiFolder_ListTopLevel
   put wikiGarden_ListAllDomains() into wikiDomains
   
   # List Toplevel
   put url_ListTopLevelDomains (wikiDomains) into toplevelDomains
   
   # Strip notThese
   put _NotThese() into notThese
   put _StripNotThese (toplevelDomains, notThese) into goodShortFolders
   return goodShortFolders
end wikiFolder_ListTopLevel

function wiki_ListShortFolders pRootFolder, pNotTheseShortFolders
   if pRootFolder is empty then put wikiFarm_GetFolder() into pRootFolder
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
   put wikiFarm_GetFolder() into farmFolder
   put _NotThese into notThese
   put wiki_ListEmptyFolders (farmFolder, pListShort, notThese) into wikiFolders
   return wikiFolders
end wiki_ListEmptyLocalFolders

function wiki_ListEmptyFolders pFarmFolder, pListShort, pNotTheseShortFolders
   if pFarmFolder is empty then put wikiFarm_GetFolder() into pFarmFolder
   put folder_ShortList (pFarmFolder) into notSymLinkedFolderNames
   --
   put _TidyNotThese (pNotTheseShortFolders) into cleanNotTheseShortFolders
   repeat for each line shortWikiFolder in notSymLinkedFolderNames
      set the cursor to busy
      if shortWikiFolder is among the lines of cleanNotTheseShortFolders then
         next repeat
      end if
      --
      put pFarmFolder & shortWikiFolder & slash into wikiFolder
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
