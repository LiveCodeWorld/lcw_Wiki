script "lib_WikiFolder"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_WikiFolder
type: library
version: 0.2

/*
*/

--> Working on
-
function ecoData_WikiFolder wikiDomain
   -- renamed "wikiFolder_ConstructFromFarm" ???
   
   put ecoData_GetFarmFolder() into wikiFarm
   if there is not a folder wikiFarm then
      -- this check slows things (consider removing)
      breakpoint
      wikiGarden_Update
      put ecoData_GetFarmFolder() into wikiFarm
   end if
   
   put wikiFarm & wikiDomain & slash into wikiFolder
   return wikiFolder
end ecoData_WikiFolder

function wikiFolder_ConstructFromFarm wikiDomain
   put ecoData_GetFarmFolder() into wikiFarm
   if there is not a folder wikiFarm then
      -- this check slows things (consider removing)
      breakpoint
      put wikiFarm_GetDefaultFolder() into wikiFarm
   end if
   
   put wikiFarm & wikiDomain & slash into wikiFolder
   return wikiFolder
end wikiFolder_ConstructFromFarm

command wikipedia_FixText @sText
   replace "‚Äî" with "-" in sText
   replace "‚Äô" with "'" in sText
   replace "‚Äú" with quote in sText
   replace "‚Äù" with quote in sText
   replace "''" with empty in sText
   replace ":__" with "- **" in sText
   replace "__" with "**" in sText
   
   if char 1 of sText = ":" then
      put "- " into char 1 of sText
   end if
end wikipedia_FixText


--> WikiFolder | Fast | WikiRouter
-
function wikiFolder_FromRouter wikiDomain
   put wikiGarden_GetDomainData() into gardenDomainData
   put gardenDomainData [wikiDomain]["folder"] into gardenWikiFolder
     
   if gardenWikiFolder is empty then -- defaults to farm
      put wikiFolder_ConstructFromFarm (wikiDomain) into wikiFolder
      return wikiFolder
   else
      return gardenWikiFolder
   end if
end wikiFolder_FromRouter


--> WikiFolder
-
function wikiFolder_FindLocalHost ecoFolder, farmFolder
   -- from folders (assume arrays are broken)
   -- simply check for existance of "localhost" folder
   if there is not a folder ecoFolder then return "Error, ecofolder does not exist:" && ecoFolder
   
   # farmFolder
   put wikiFarm_GetDefaultFolder() into farmFolder
   if there is not a folder farmFolder then return "Error, farmFolder does not exist:" && farmFolder
   text_AddTrailing farmFolder, slash
   file_AddHome farmFolder
   
   put farmFolder & "localhost/" into localHostFolder
   if there is a folder localHostFolder then return localHostFolder
   
   put folder_ListShort (ecoFolder) into gardenNames
   repeat for each line gardenName in gardenNames
      put ecoFolder & gardenName & slash into testFarmFolder
      put testFarmFolder & "localhost/" into localHostFolder
      if there is a folder localHostFolder then
         return localHostFolder
      end if
   end repeat
   return empty
end wikiFolder_FindLocalHost


--> WikiFolder | List
-
function wikiFolder_ListDomains farmFolder, pNum
   -- see also "wikiFolder_ListNotEmpty"
   text_AddTrailing farmFolder, slash
   put folder_ListShort (farmFolder) into shortWikiFolders
   repeat for each line shortFolder in shortWikiFolders
      set the cursor to busy
      put farmFolder & shortFolder & slash into wikiFolder
      
      switch shortFolder
         case "commons"
            -- put wikiFolder_HasNoPages (wikiFolder, pNum) = empty
            next repeat
            break
         default
            # Skip if no pages
            put wikiFolder_HasNoPages (wikiFolder, pNum) into noPages
            if noPages is true then next repeat
            put shortFolder & CR after wikiDomains
      end switch
   end repeat
   delete char -1 of wikiDomains
   url_SortDomainIndex wikiDomains
   return wikiDomains
end wikiFolder_ListDomains


--> WikiFolder
-
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


--> WikiFolder | List
-
function wikiFolder_ListTopLevel   
   # List Toplevel
   put wikiDomain_List() into wikiDomains
   put url_ListTopLevelDomains (wikiDomains) into toplevelDomains
   
   # Strip notThese
   put wikiFolder_NotThese() into notThese
   put _StripNotThese (toplevelDomains, notThese) into goodShortFolders
   return goodShortFolders
end wikiFolder_ListTopLevel

function wikiFolder_ListShort pRootFolder, pNotTheseShortFolders
   if pRootFolder is empty then put ecoData_GetFarmFolder() into pRootFolder
   if pNotTheseShortFolders is empty then put "commons" into pNotTheseShortFolders
   --
   put folder_ListShort (pRootFolder) into shortWikiFolders
   put _StripNotThese (shortWikiFolders, pNotTheseShortFolders) into goodShortFolders
   --
   url_SortDomainIndex goodShortFolders
   return goodShortFolders
end wikiFolder_ListShort

command wikiFolder_TidyList @shortWikiFolders
   put wikiFolder_NotThese() into notThese
   put _StripNotThese (shortWikiFolders, notThese) into shortWikiFolders
end wikiFolder_TidyList


--> Private
-
function wikiFolder_TidyNotThese pNotTheseShortFolders
   replace comma with CR in pNotTheseShortFolders
   repeat for each line notThisShortFolder in pNotTheseShortFolders
      put word 1 to -1 of notThisShortFolder into notThisShortFolder
      if char -1 of notThisShortFolder is slash then delete char -1 of notThisShortFolder
      put notThisShortFolder & CR after cleanNotTheseShortFolders
   end repeat
   delete char -1 of cleanNotTheseShortFolders
   return cleanNotTheseShortFolders
end wikiFolder_TidyNotThese

function wikiFolder_NotThese
   return "commons,assets"
end wikiFolder_NotThese

private function _StripNotThese longOrShortFolders, pNotTheseShortFolders
   # Not these
   put wikiFolder_TidyNotThese (pNotTheseShortFolders) into cleanNotTheseShortFolders
   
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
   if ".." is among the lines of pageFiles then
      breakpoint -- no longer needed?
      delete line 1 of pageFiles
   end if
   if pageFiles is empty then return 0
   put the number of lines of pageFiles into numOfPages
   return numOfPages
end _NumberOfpages

