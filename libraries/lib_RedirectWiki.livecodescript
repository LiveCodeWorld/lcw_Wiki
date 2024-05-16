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

- Router_Array
*/

--> Variables
-
local Router_Array


--> Working on
-
command display_WikiRouterArray
   put wikiRouter_GetArray() into routerArray
   --
   display_Data routerArray, "wikiRouter_GetArray()", "Wiki Router"
end display_WikiRouterArray

function wikiFarm_GetFolder
   put wikiGarden_GetEcoData() into ecoData
   return ecoData ["Farm"]["folder"]
end wikiFarm_GetFolder

command wikiFarm_SetFolder pFarmFolder
   if pFarmFolder is empty then put node_DefaultFarmFolder() into pFarmFolder
   text_AddTrailing pFarmFolder, slash
   
   put wikiGarden_GetEcoData() into ecoData
   put pFarmFolder into ecoData ["Farm"]["folder"]
   wikiGarden_SetEcoData ecoData
   return ecoData
end wikiFarm_SetFolder


--> WikiRouter | Model | Local
-
function wikiRouter_GetArray
   -- if Router_Array is not an array then wikiGarden_Init true
   --
   return Router_Array
end wikiRouter_GetArray

command wikiRouter_SetArray routerFolderArray
   put routerFolderArray into Router_Array
end wikiRouter_SetArray


--> Deps
-
function node_DefaultFarmFolder
   -- default location of node wikifarm
   put $HOME & "/.wiki/" into wikiRootFolder
   return wikiRootFolder
end node_DefaultFarmFolder
