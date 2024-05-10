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
When we load the Garden Model, we load the following variables used by this library:

- WikiFarm_RootFolder
- Router_FolderArray
*/

local WikiFarm_RootFolder
local Router_FolderArray


--> Working on
-
command display_RouterFolderArray
   put wiki_RouterFolderArray() into routerFolderArray
   
   display_Data routerFolderArray, "WikiFarm_RootFolder", "Wiki"
   return the result
end display_RouterFolderArray


--> WikiRouter
-
function wikiRouter_ListGardenNames
   set the itemdelimiter to slash
   repeat for each element gardenFolder in Router_FolderArray
      put item -1 of gardenFolder into shortGardenFolder
      put empty into gardenArray [shortGardenFolder]
   end repeat
   put keys(gardenArray) into gardenNames
   sort gardenNames
   return gardenNames
end wikiRouter_ListGardenNames

function wikiRouter_ListFolders
   repeat for each element gardenFolder in Router_FolderArray
      put empty into gardenArray [gardenFolder]
   end repeat
   put keys(gardenArray) into gardenFolders
   sort gardenFolders
   return gardenFolders
end wikiRouter_ListFolders

function wikiRouter_ListDomains pGardenName
   if pGardenName is empty then
      put keys (Router_FolderArray) into routerDomains
   else
      set the itemdelimiter to slash
      repeat for each key wikiDomain in Router_FolderArray
         put Router_FolderArray [wikiDomain] into wikiFolder
         put item -2 of wikiFolder into testName
         if testName = pGardenName then
            put empty into folderArray [wikiDomain]
         end if
      end repeat
      put keys (folderArray) into routerDomains
   end if
   
   url_SortDomainIndex routerDomains
   return routerDomains
end wikiRouter_ListDomains


--> WikiFolder
-
function wikiFolder_Construct pWikiDomain
   put wikiGarden_GetFolder (pWikiDomain) into wikiFolder
   if wikiFolder is empty then
      put WikiFarm_RootFolder & pWikiDomain & slash into wikiFolder
   end if
   return wikiFolder
end wikiFolder_Construct


--> WikiGarden | Model
-
function wiki_RootFolder pWikiDomain
   # Must be fast -- should use wikiGarden_GetFolder() directy
   if pWikiDomain is not empty then
      put wikiGarden_GetFolder (pWikiDomain) into rootFolder
      if rootFolder is not empty then
         set the itemdelimiter to slash
         delete item -1 of rootFolder
         return rootFolder
      end if 
   end if
   
   # Default
   return WikiFarm_RootFolder
end wiki_RootFolder

function wikiGarden_GetFolder wikiDomain
   # Must be fast
   if Router_FolderArray is empty then
      wikiGarden_Init
   end if
   
   # Translate Fast
   put Router_FolderArray [wikiDomain] into wikiFolder
   return wikiFolder
end wikiGarden_GetFolder

command wikiGarden_SetFolder wikiDomain, wikiFolder, pStore
   put wikiFolder into Router_FolderArray [wikiDomain]
   
   if pStore is not false then
      put the project_Array of stack "lcw_Wiki" into projectArray
      put wikiFolder into projectArray ["redirectArray"][wikiDomain]
      set the project_Array of stack "lcw_Wiki" to projectArray
   end if
   return redirectArray
end wikiGarden_SetFolder


--> WikiGarden | Router
-
function wiki_RouterFolderArray
   return Router_FolderArray
end wiki_RouterFolderArray

command wikiGarden_Init
   put wikiGarden_GetModel() into ecoData
   put ecoData ["Farm"]["folder"] into WikiFarm_RootFolder
   put wikiGarden_ConstructRouterArray (ecoData) into Router_FolderArray
end wikiGarden_Init

function wikiGarden_ConstructRouterArray ecoData
   repeat for each key ecoName in ecoData ["Eco"]
      put ecoData ["Eco"][ecoName]["Gardens"] into gardenData
      repeat for each key gardenName in gardenData
         put gardenData [gardenName] into gardenArray
         repeat for each key wikiDomain in gardenArray
            put gardenArray [wikiDomain]["folder"] into wikiFolder
            put wikiFolder into routerArray [wikiDOmain]
         end repeat
      end repeat
   end repeat
   return routerArray
end wikiGarden_ConstructRouterArray


--> WikiFarm | Folders
-
function wikiFarm_GetRoot
   if WikiFarm_RootFolder is empty then
      put wikiFarm_RootFolder() into WikiFarm_RootFolder
   end if
   
   return WikiFarm_RootFolder
end wikiFarm_GetRoot

command wikiFarm_SetRoot farmFolder, pSave
   text_AddTrailing farmFolder, slash
   if there is a folder farmFolder then
      put farmFolder into WikiFarm_RootFolder
   else
      put empty into WikiFarm_RootFolder
   end if
   
   # Store it
   if pSave is not false then
      put wikiGarden_GetModel() into ecoData
      put farmFolder into ecoData ["Farm"]["folder"]
      wikiGarden_SetModel ecoData
   end if
end wikiFarm_SetRoot

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
