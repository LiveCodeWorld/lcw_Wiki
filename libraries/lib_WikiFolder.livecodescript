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

--> Move
-
function ecoData_WikiFolder wikiDomain
   -- renamed "wikiFolder_ConstructFromFarm" ???
   
   put ecoData_GetFarmFolder() into wikiFarm
   if there is not a folder wikiFarm then
      -- this check slows things (consider removing)
      breakpoint
      ecoData_ConstructLoadAndStore
      put ecoData_GetFarmFolder() into wikiFarm
   end if
   
   put wikiFarm & wikiDomain & slash into wikiFolder
   return wikiFolder
end ecoData_WikiFolder

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


--> Working on
-
function handler_AssetFolder pShortFolder
   put handler_ConstructDomain() into handlerDomain 
   put wikiFolder_ConstructAssets (handlerDomain, pShortFolder) into handlerAssetFolder
   return handlerAssetFolder
end handler_AssetFolder

function wikiFolder_ConstructAssets wikiDomain, pShortFolder
   put wikiFolder_FromRouter (wikiDomain) into wikiFolder
   put wikiFolder & "assets/" into assetsFolder
   --
   if pShortFolder is not empty then
      text_AddTrailing pShortFolder, slash
      put pShortFolder after assetsFolder
   end if
   return assetsFolder
end wikiFolder_ConstructAssets


--> WikiFarm | Default | Model
-
/*
This is the fallback for restarting and reconstituting the routing table. 
Saved in the ecodata project array.*/

function wikiFarm_GetDefaultFolder
   -- wee "ecoData_GetFarmFolder"
   put wikiGarden_GetModel() into ecoData
   put ecoData ["Farm"]["folder"] into farmFolder
   --
   file_AddHome farmFolder
   return farmFolder
end wikiFarm_GetDefaultFolder

command wikiFarm_SetDefaultFolder farmFolder
   if there is not a folder farmFolder then
      return "Error, farm folder does not exist:" && farmFolder
   end if
   file_StripHome farmFolder
   -- wikiPreference_Set "Farm Folder", farmFolder -- recursive
   
   put wikiGarden_GetModel() into ecoData
   put farmFolder into ecoData ["Farm"]["folder"]
   wikiGarden_SetModel ecoData
   --
   return ecoData
end wikiFarm_SetDefaultFolder


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

function wikiFolder_LocalHost
   put wikiFolder_ConstructLocalHost() into localhostFolder
   if there is a localhostFolder then
      return localhostFolder
   else
      return empty
   end if
end wikiFolder_LocalHost

function wikiFolder_ConstructLocalHost
   put wikiFarm_GetDefaultFolder() into farmFolder
   put farmFolder & "localhost/" into localHostFolder
   return localHostFolder
end wikiFolder_ConstructLocalHost

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

function wikiFolder_ConstructLocalPages
   put wikiFolder_ConstructLocalHost() into localhostFolder
   return localhostFolder & "pages/"
end wikiFolder_ConstructLocalPages


--> WikiFolder
-
function wikiFolder_Client pRelFolderPath
   put wikiFolder_ConstructClient() into wikiClientFolder
   put pRelFolderPath after wikiClientFolder
   text_AddTrailing wikiClientFolder, slash
   
   if there is a folder wikiClientFolder then
      return wikiClientFolder
   else
      return empty
   end if
end wikiFolder_Client

function wikiFolder_Recycled wikiDomain
   put wikiFolder_ConstructRecycled (wikiDomain) into wikiRecycleFolder
   if there is a folder wikiRecycleFolder then
      return wikiRecycleFolder
   else
      return empty
   end if
end wikiFolder_Recycled

function wikiFolder_Pages wikiDomain
   put wikiFolder_FromRouter (wikiDomain) into wikiFolder 
   put wikiFolder & "pages/" into wikiPagesFolder
   if there is a folder wikiPagesFolder then
      return wikiPagesFolder
   else
      return empty
   end if
end wikiFolder_Pages


--> WikiFolder | Construct
-
function wikiFolder_ConstructClient
   put wikiFolder_Modules() & "wiki-client/" into wikiClientFolder
   return wikiClientFolder
end wikiFolder_ConstructClient

function wikiFolder_ConstructCommons pWikiDomain
   put ecoData_GetFarmFolder (pWikiDomain) into wikiRoot
   put wikiRoot & "commons/" into wikiCommonsFolder
   return wikiCommonsFolder
end wikiFolder_ConstructCommons

function wikiFolder_ConstructPageAssets pageSlug, wikiDomain
   put wikiFolder_ConstructAssets (wikiDomain) into assetsFolder
   put assetFolder & pageSlug & slash into oggFolder
   return oggFolder
end wikiFolder_ConstructPageAssets

function wikiFolder_ConstructImageAssets wikiDomain
   put wikiFolder_FromRouter (wikiDomain) into wikiFolder
   put wikiFolder & "assets/plugins/image/" into imageAssetsFolder
   return imageAssetsFolder
end wikiFolder_ConstructImageAssets


--> Wikifolder | List
-
function wikiFolder_ConstructFromFarm wikiDomain
   put ecoData_GetFarmFolder() into wikiFarm
   if there is not a folder wikiFarm then
      -- this check slows things (consider removing)
      -- breakpoint
      put wikiFarm_GetDefaultFolder() into wikiFarm
   end if
   
   put wikiFarm & wikiDomain & slash into wikiFolder
   return wikiFolder
end wikiFolder_ConstructFromFarm


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


--> WikiFolder | List
-
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

function wikiFolder_ListDomains farmFolder, pNum
   -- see also "wikiFolder_ListNotEmpty" in lib_WikiEmpty
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
            if noPages is true then
               next repeat
            end if
            put shortFolder & CR after wikiDomains
      end switch
   end repeat
   delete char -1 of wikiDomains
   url_SortDomainIndex wikiDomains
   return wikiDomains
end wikiFolder_ListDomains

function wikiFolder_ListTopLevel   
   # List Toplevel
   put wikiDomain_List() into wikiDomains
   put url_ListTopLevelDomains (wikiDomains) into toplevelDomains
   
   # Strip notThese
   put wikiFolder_NotThese() into notThese
   put _StripNotThese (toplevelDomains, notThese) into goodShortFolders
   return goodShortFolders
end wikiFolder_ListTopLevel

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


--> Nvm & Node | Paths
-
function node_GetModulesFolder pUseNpm
   if Node_ModulesFolder is empty then
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
      if there is not a folder nodeModulesFolder then
         return "Error, folder" && nodeModulesFolder && "does not exist"
      end if
   end if
   
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


--> Private
-
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

