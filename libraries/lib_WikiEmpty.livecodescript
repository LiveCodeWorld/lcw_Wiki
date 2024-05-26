script "lib_WikiEmpty"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_WikiEmpty
type: library
version: 0.1

/*Some help*/


--> Working on
-
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
      wikiFolder_TrashEmpty wikiFolder
      set the deleted_Line of pDisplayView to lineNum
   end repeat
end wiki_TrashEmpty

command wikiFolder_TrashEmpty wikiFolder
   if there is not a folder wikiFolder then return "Error, wiki-folder does not exist:" && wikiFolder
   
   if wikiFolder_HasNoPages (wikiFolder) then
      revDeleteFolder wikiFolder
      return true
   else
      return false
   end if
end wikiFolder_TrashEmpty

command display_EmptyWikiFolders
   /*
   -- put wikiPage_EmptyDomains (wikiDomain) into pageArray
   -- put wiki_ListEmptyLocalFolders (true) into emptyFolders
   put wikiDomain_ListEmptyFolders (wikiDomain, true) into emptyDomains
   put wikiFarm_ListEmptyFolders (pFarmFolder, pListShort, pNotTheseShortFolders)
   put wikiGarden_ListEmptyFolders (pGardenName, pListShort, pNum)
   put wikiFolder_ListEmpty (wikiFolders, pListShort)
   */
   put wikiFarm_ListEmpty (true) into emptyFolders
   --
   display_Tools emptyFolders, "Empty Farm Wikis", "Wiki | Local", "Wiki"
   -- display_WikiFolders emptyFolders, "Wiki | Local", pDisplayView, pFilter, "Empty Local Wikis", "Local Wikis"
   put the result into dView
   return dView
end display_EmptyWikiFolders

command display_WikiFolders wikiFolders, menuBit, pDisplayView, pWikiFilter, pTitle, pStackLabel
   if pStackLabel is empty then put "Wiki" into pStackLabel
   if exists (pDisplayView) is false then
      put display_FindIndexView ("Wiki", "Git Folders") into pDisplayView
   end if
   --
   if exists (pDisplayView) is true then
      if pWikiFilter is "none" then
         put empty into pWikiFilter
      else if pWikiFilter is empty then
         put the wiki_Filter of pDisplayView into pWikiFilter
      end if
   end if
   --
   if pWikiFilter is not empty then
      filter wikiFolders with pWikiFilter
   end if
   --
   lock screen
   display_Data wikiFolders, pTitle, pStackLabel, pDisplayView
   put the result into dView
   -- set the coloured_lines ["red"] of dView to dynadot_ListEarthWikis()
   unlock screen
   --
   set the wiki_Filter of dView to pWikiFilter
   --
   display_SetToolMenus menuBit, dView, "lcw_Wiki"
   return dView
end display_WikiFolders


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


--> Wiki | Empty
-
function wikiFarm_ListEmpty pListShort
   put ecoData_GetFarmFolder() into farmFolder   
   put wikiFolder_NotThese() into notThese
   put wikiFarm_ListEmptyFolders (farmFolder, pListShort, notThese) into wikiFolders
   return wikiFolders
end wikiFarm_ListEmpty

function wikiDomain_ListEmptyFolders wikiDomain, pListShort
   -- sister folders within same garden
   put wikiDomain_GardenFolder (wikiDomain) into gardenFolder
   put folder_ListLong (gardenFolder) into wikiFolders
   put wikiFolder_ListEmpty (wikiFolders, pListShort) into emptyFolders
   if pListShort is true then
      url_SortDomainIndex emptyFolders
   end if
   return emptyFolders
end wikiDomain_ListEmptyFolders

function wikiFarm_ListEmptyFolders pFarmFolder, pListShort, pNotTheseShortFolders
   -- see also "wikiFolder_ListEmpty"
   if pFarmFolder is empty then put ecoData_GetFarmFolder() into pFarmFolder
   put folder_ShortList (pFarmFolder) into notSymLinkedFolderNames
   --
   put wikiFolder_TidyNotThese (pNotTheseShortFolders) into cleanNotTheseShortFolders
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
end wikiFarm_ListEmptyFolders

function wikiGarden_ListEmptyFolders pGardenName, pListShort, pNum
   if pNum is empty then put 0 into pNum
   put wikiGarden_ListFolders (pGardenName) into wikiFolders
   --
   put wikiFolder_ListEmpty (wikiFolders) into emptyFolders
   url_SortDomainIndex emptyFolders
   return emptyFolders
end wikiGarden_ListEmptyFolders


--> WikiFolder | List
-
function wikiFolder_HasNoPages wikiFolder, pNum
   if pNum is not a number then put 1 into pNum
   put wikiFolder_NumberOfPages (wikiFolder) into numOfPages
   if numOfPages is empty then return empty -- not a wiki
   return numOfPages <= pNum
end wikiFolder_HasNoPages

function wikiFolder_ListNotEmpty wikiFolders
   set the itemdelimiter to slash
   repeat for each line wikiFolder in wikiFolders
      set the cursor to busy
      put wikiFolder_HasNoPages (wikiFolder, pNum) into noPages
      if noPages is true then next repeat
      
      if pListShort is true then
         put item -1 of wikiFolder & CR after goodFolders
      else
         put wikiFolder & CR after goodFolders
      end if
   end repeat
   delete char -1 of goodFolders
   return goodFolders
end wikiFolder_ListNotEmpty

function wikiFolder_ListEmpty wikiFolders, pListShort
   -- see "wikiFarm_ListEmptyFolders"
   set the itemdelimiter to slash
   repeat for each line wikiFolder in wikiFolders
      set the cursor to busy
      put item -1 of wikiFolder into wikiDomain
      if wikiDomain = "commons" then next repeat
      
      put wikiFolder_HasNoPages (wikiFolder, pNum) into noPages
      if noPages is false then next repeat
      
      if pListShort is true then
         put item -1 of wikiFolder & CR after emptyFolders
      else
         put wikiFolder & CR after emptyFolders
      end if
   end repeat
   delete char -1 of emptyFolders
   return emptyFolders
end wikiFolder_ListEmpty


--> WikiFolder | List | Tidy
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
