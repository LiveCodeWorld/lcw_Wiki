script "lib_RedirectWiki"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_RedirectWiki
type: library
version: 0.2

/*
This library organises federated wiki sites into folders we term "gardens".
*/

local WikiFarm_RootFolder
local WikiGarden_EcoFolder
local Router_FolderArray


--> Working on
-
function url_FilterByItem testItem, sDomains
   set the itemdelimiter to "."
   repeat for each line sDomain in sDomains
      if testItem is among the items of sDomain then
         put sDomain & CR after fDomains
      end if
   end repeat
   delete char -1 of fDomains
   return fDomains
end url_FilterByItem

function wikiGarden_DomainData
   put wikiFarm_GetRoot() into farmRootFolder
   --
   put folders (farmRootFolder) into shortFolders
   repeat for each line wikiDomain in shortFolders
      if char 1 of wikiDomain = "." then next repeat
      put farmRootFolder & wikiDomain & slash into wikiFolder
      put wikiFolder into wikiGardenData ["Farm"][wikiDomain]
   end repeat
   
   set the itemdelimiter to slash
   repeat for each key wikiDomain in Router_FolderArray
      put Router_FolderArray [wikiDomain] into wikiFolder
      put item -2 of wikiFolder into gardenName
      put wikiFolder into wikiGardenData [gardenName][wikiDomain]
   end repeat
   display_Data wikiGardenData
   return wikiGardenData
end wikiGarden_DomainData


--> Wiki | List
-
function wiki_ListTopLevelDomains pRootFolder
   if pRootFolder is empty then put wikiFarm_GetRoot() into pRootFolder
   --
   put folder_ListShort (pRootFolder) into wikiDomains
   put CR & wikiGarden_ListAllEcoDomains() after wikiDomains
   
   set the itemdelimiter to "."
   repeat for each line wikiDomain in wikiDomains
      if the number of items of wikiDomain is not 2 then next repeat
      --
      put wikiDomain & CR after toplevelDomains
   end repeat
   url_SortDomainIndex toplevelDomains
   return toplevelDomains
end wiki_ListTopLevelDomains

function wiki_ListShortFolders pRootFolder, pNotTheseShortFolders
   if pRootFolder is empty then put wikiFarm_GetRoot() into pRootFolder
   if pNotTheseShortFolders is empty then put "commons" into pNotTheseShortFolders
   --
   put folder_ListShort (pRootFolder) into shortWikiFolders
   put wiki_StripNotThese (shortWikiFolders, pNotTheseShortFolders) into goodShortFolders
   --
   url_SortDomainIndex goodShortFolders
   return goodShortFolders
end wiki_ListShortFolders


--> Wiki | Folder
-
function wiki_RootFolder pWikiDomain
   # Must be fast
   if pWikiDomain is not empty then
      put wikiGarden_GetFolder (pWikiDomain) into rootFolder
      if rootFolder is not empty then
         return rootFolder
      end if 
   end if
   
   # Default
   return WikiFarm_RootFolder
end wiki_RootFolder


--> WikiFarm
-
function wikiFarm_RootFolder
   -- default location of node wikifarm
   put $HOME & "/.wiki/" into wikiRootFolder
   return wikiRootFolder
end wikiFarm_RootFolder

function wikiFarm_EarthRoot
   -- moved location of default node wikifarm
   put env_GetRepoFolder() into sFolder
   set the itemdelimiter to slash
   put "Earth" into item -1 of sFolder
   return sFolder
end wikiFarm_EarthRoot

function wikiFarm_GetRoot
   if WikiFarm_RootFolder is empty then
      put wikiFarm_RootFolder() into WikiFarm_RootFolder
   end if
   return WikiFarm_RootFolder
end wikiFarm_GetRoot

command wikiFarm_SetRoot rootFolder
   text_AddTrailing rootFolder, slash
   if there is a folder rootFolder then
      put rootFolder into WikiFarm_RootFolder
   else
      put empty into WikiFarm_RootFolder
   end if
end wikiFarm_SetRoot


--> WikiGarden | List
-
function wikiGarden_ListAllEcoDomains
   put keys (Router_FolderArray) into ecoDomains
   url_SortDomainIndex ecoDomains
   return ecoDomains
end wikiGarden_ListAllEcoDomains

function wikiGarden_ListDomains gardenName
   if gardenName is empty then
      put wiki_ListShortFolders() into defaultFarmDomains
      return defaultFarmDomains
   end if
   
   set the itemdelimiter to slash
   repeat for each key wikiDomain in Router_FolderArray
      put Router_FolderArray [wikiDomain] into rootFolder
      put item -1 of rootFolder into testName
      if testName = gardenName then
         put empty into folderArray [wikiDomain]
      end if
   end repeat
   put keys (folderArray) into gardenDomains
   sort gardenDomains
   return gardenDomains
end wikiGarden_ListDomains

function wikiGarden_ListFolders
   repeat for each element gardenFolder in Router_FolderArray
      put empty into gardenArray [gardenFolder]
   end repeat
   put keys(gardenArray) into gardenFolders
   sort gardenFolders
   return gardenFolders
end wikiGarden_ListFolders

function wikiGarden_ListNames
   set the itemdelimiter to slash
   repeat for each element gardenFolder in Router_FolderArray
      put item -1 of gardenFolder into shortGardenFolder
      put empty into gardenArray [shortGardenFolder]
   end repeat
   put keys(gardenArray) into gardenNames
   sort gardenNames
   return gardenNames
end wikiGarden_ListNames


--> WikiGarden | Folder
-
function wikiGarden_Folder gardenName
   put wikiGarden_ConstructFolder (gardenName) into gardenFolder
   if there is a folder gardenFolder then
      return gardenFolder
   else
      return empty
   end if
end wikiGarden_Folder

function wikiGarden_ConstructFolder gardenName
   put wikiGarden_GetEcoFolder() & gardenName & slash into gardenFolder
   return gardenFolder
end wikiGarden_ConstructFolder

function wikiGarden_GetEcoFolder
   if WikiGarden_EcoFolder is empty then
      put wikiGarden_EcoFolder() into WikiGarden_EcoFolder
   end if
   return WikiGarden_EcoFolder
end wikiGarden_GetEcoFolder

command wikiGarden_SetEcoFolder ecoFolder
   text_AddTrailing ecoFolder, slash
   if there is a folder ecoFolder then
      put ecoFolder into WikiGarden_EcoFolder
   else
      put empty into WikiGarden_EcoFolder
   end if
end wikiGarden_SetEcoFolder


--> Private
-
command _InitRouterFolderArray
   if Router_FolderArray is not an array then
      # Fetch Router_FolderArray from project_Array of lcw_Wiki
      put wikiGarden_GetModel() into Router_FolderArray
   end if
end _InitRouterFolderArray

