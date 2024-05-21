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
command display_WikiOwner wikiDomain, pDisplayView
   -- display_OwnerJson
   put wikiServer_GetOwnerData (wikiDomain) into ownerData
   display_Tool ownerData, wikiDomain, "Wiki Owner", pDisplayView
   put the result into dView
   return dVIEW
end display_WikiOwner


--> Display
-
command display_WikiRouterArray
   put wikiRouter_GetArray() into routerArray
   --
   display_Data routerArray, "wikiRouter_GetArray()", "Wiki Router"
end display_WikiRouterArray

on mDoubleUp_WikiEco displayView, wikiFolder
   put someLine &CR& the title_Text of displayView
end mDoubleUp_WikiEco

command display_ServerData
   put wikiServer_GetData() into wsData
   display_Array wsData, "WikiServer_Data", "Wiki"
   put the result into dView
   return dView
end display_ServerData

command display_GardenEcodata pEcoData
   if pEcoData is not an array then
      put wikiGarden_GetModel() into pEcoData
   end if
   
   display_Tools pEcoData, "Eco Data", "Wiki | Eco", "Wiki", "lcw_Wiki"
   return the result
end display_GardenEcodata

command display_RouterFolderArray
   put wikiRouter_FolderArray() into routerFolderArray
   
   display_Data routerFolderArray, "WikiRouter_FolderArray", "Wiki"
   return the result
end display_RouterFolderArray


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
