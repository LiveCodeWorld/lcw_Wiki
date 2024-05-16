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


--> Move
-
command platform_DeleteEmptyWikis browserView
   lcw_Answer "Are you sure you want to delete these empty wiki folders?", browserView
   --
   wiki_TrashEmpty
end platform_DeleteEmptyWikis

command platform_RefreshEmptyWikis browserView
   put wikiPage_EmptyLocalFolders() into pageArray
   set the ghost_PageArray of browserView to pageArray
   return pageArray
end platform_RefreshEmptyWikis

command wiki_TrashEmpty pEmptyLocalDomains, pDisplayView
   if pEmptyLocalDomains is empty then
      put wikiFarm_ListEmptyFolders (true) into pEmptyLocalDomains
   end if
   --
   repeat for each line wikiDomain in pEmptyLocalDomains
      display_Spin wikiDomain, pDisplayView, "red"
      put the result into lineNum
      --
      put wikiFolder_Get (wikiDomain) into wikiFolder
      if there is a folder wikiFolder then
         if wikiFolder_NumberOfPages (wikiFolder) < 1 then
            revDeleteFolder wikiFolder
            if exists (pDisplayView) then
               set the deleted_Line of pDisplayView to lineNum
            end if
         else
            breakpoint
         end if
      else
         breakpoint
      end if
   end repeat
end wiki_TrashEmpty


--> Working on
-
function wikiFolder_HasNoPages wikiFolder, pNum
   if pNum is not a number then put 1 into pNum
   put wikiFolder_NumberOfPages (wikiFolder) into numOfPages
   if numOfPages is empty then return empty -- not a wiki
   return numOfPages < pNum
end wikiFolder_HasNoPages

function wikiFolder_NumberOfPages wikiFolder, pUseSymLinked
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
end wikiFolder_NumberOfPages


--> List | Empty
-
function wikiGarden_ListEmptyFolders pListShort
   put wikiGarden_ListFolders() into wikiFolders
   --
   set the itemdelimiter to slash
   repeat for each line wikiFolder in wikiFolders
      set the cursor to busy
      put wikiFolder_HasNoPages (wikiFolder) into noPages
      if noPages is false then next repeat
      
      if pListShort is true then
         put item -1 of wikiFolder & CR after emptyFolders
      else
         put wikiFolder & CR after emptyFolders
      end if
   end repeat
   delete char -1 of emptyFolders
   
   url_SortDomainIndex emptyFolders
   return emptyFolders
end wikiGarden_ListEmptyFolders

function wikiFarm_ListEmptyFolders pListShort
   put wikiFarm_GetFolder() into farmFolder
   put _NotThese into notThese
   put wikiFolder_ListEmpty (farmFolder, pListShort, notThese) into wikiFolders
   return wikiFolders
end wikiFarm_ListEmptyFolders


--> WikiFolder | Fast | WikiRouter
-
function wikiFolder_FromRouter wikiDomain
   put wikiRouter_GetArray() into routerFolderArray
   put routerFolderArray [wikiDomain] into gardenWikiFolder
   if gardenWikiFolder is empty then -- defaults to farm
      put wikiFolder_ConstructFromFarm (wikiDomain) into wikiFolder
      return wikiFolder
   else
      return gardenWikiFolder
   end if
end wikiFolder_FromRouter


--> WikiFolder | Model | Local
-
function wikiFolder_Get wikiDomain
   put wikiFolder_FromRouter (wikiDomain) into wikiFolder
   if there is a folder wikiFolder then 
      return wikiFolder
   else
      return empty
   end if
end wikiFolder_Get

function wikiFolder_ConstructFromFarm wikiDomain
   put wikiFarm_GetFolder() & wikiDomain & slash into wikiFolder
   return wikiFolder
end wikiFolder_ConstructFromFarm

function wikiFolder_ListEmpty pFarmFolder, pListShort, pNotTheseShortFolders
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
      put wikiFolder_HasNoPages (wikiFolder) into noPages -- symlinked version
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
end wikiFolder_ListEmpty

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


--> WikiFolder | Tidy
-
command wikiFolder_CleanIndex @wikiFolders
   put the number of lines of wikiFolders into maxNum
   repeat with lineNum = maxNum down to 1
      set the cursor to busy
      put line lineNum of wikiFolders into wikiFolder
      
      put wikiFolder_HasNoPages (wikiFolder) into noPages      
      if noPages is true then
         delete line lineNum of wikiFolders
         put wikiFolder & CR after emptyFolders
      end if
   end repeat
   delete char -1 of emptyFolders
   return emptyFolders
end wikiFolder_CleanIndex

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

