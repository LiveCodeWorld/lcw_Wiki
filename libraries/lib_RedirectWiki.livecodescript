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

- Router_FolderArray
*/

--> Variables
-
local Router_FolderArray


--> Working on
-
function wikiFile_ConstructConfig pWikiDomain
   put wikiFolder_ConstructFromFarm (pWikiDomain) into farmFolder
   put farmFolder & "config.json" into wikiConfigFile
   return wikiConfigFile
end wikiFile_ConstructConfig

command wikiFarm_StoreFolder farmFolder
   if there is not a folder farmFolder then return "Error, folder does not exist." && farmFolder
   text_AddTrailing farmFolder, slash
   --
   put wikiGarden_GetModel() into ecoData
   put farmFolder into ecoData ["Farm"]["folder"]
   wikiGarden_SetModel ecoData
   return ecoData
end wikiFarm_StoreFolder


--> WikiRouter | Fast | WikiFolder
-
function wikiFolder_FromRouter wikiDomain
   -- put wikiGarden_GetDomainData() into gardenDomainData
   -- put gardenDomainData [wikiDomain]["folder"] into wikiFolder
   
   put wikiRouter_GetFolderArray() into routerFolderArray
   put routerFolderArray [wikiDomain] into gardenWikiFolder
   if gardenWikiFolder is empty then -- defaults to farm
      put wikiFolder_ConstructFromFarm (wikiDomain) into wikiFolder
      return wikiFolder
   else
      return gardenWikiFolder
   end if
end wikiFolder_FromRouter


--> WikiGarden | FarmFolder | Model | Local
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

function wikiFarm_GetFolder
   put wikiGarden_GetEcoData() into ecoData
   return ecoData ["Farm"]["folder"]
end wikiFarm_GetFolder

command wikiFarm_SetFolder pFarmFolder
   if pFarmFolder is empty then put node_DefaultFarmFolder() into pFarmFolder
   text_AddTrailing farmFolder, slash
   
   put wikiGarden_GetEcoData() into ecoData
   put pFarmFolder into ecoData ["Farm"]["folder"]
   wikiGarden_SetEcoData ecoData
end wikiFarm_SetFolder


--> WikiRouter | Model | Local
-
function wikiRouter_GetFolderArray
   return Router_FolderArray
end wikiRouter_GetFolderArray

command wikiRouter_SetFolderArray routerFolderArray
   put routerFolderArray into Router_FolderArray
end wikiRouter_SetFolderArray


--> Deps
-
function node_DefaultFarmFolder
   -- default location of node wikifarm
   put $HOME & "/.wiki/" into wikiRootFolder
   return wikiRootFolder
end node_DefaultFarmFolder
