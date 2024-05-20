script "lib_WikiFarm"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_WikiFarm
type: library
version: 0.2

/*
Some help
*/

--> Variables
-
local Farm_Domains


--> Working on
-

--> Display
-
on mDoubleUp_WikiEco displayView, wikiFolder
   put someLine &CR& the title_Text of displayView
end mDoubleUp_WikiEco

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


--> WikiFarm
-
function wikiFarm_EarthFolder
   -- moved location of default node wikifarm
   put env_GetRepoFolder() into sFolder
   set the itemdelimiter to slash
   put "Earth" into item -1 of sFolder
   return sFolder
end wikiFarm_EarthFolder

function wikiFarm_GardenName
   put wikiFarm_GetFolder() into farmFolder
   set the itemdelimiter to slash
   put item -1 of farmFolder into farmGardenName
   return farmGardenName
end wikiFarm_GardenName


--> FarmDomains | Model | Local
-
function wikiFarm_GetDomains
   return Farm_Domains
end wikiFarm_GetDomains

command wikiFarm_SetDomains farmDomains
   url_SortDomainIndex farmDomains
   --
   put farmDomains into Farm_Domains
end wikiFarm_SetDomains


--> WikiFarm | Domains
-
function wikiFarm_DomainsFromFolder farmFolder, pFilterDomain, pSimple
   # List Farm
   put folder_ListShortAll (farmFolder) into shortWikiFolders 
   
   # Tidy
   wikiFolder_TidyList shortWikiFolders
   url_FilterDomains shortWikiFolders, pFilterDomain, pSimple
   
   # Sort
   url_SortDomainIndex shortWikiFolders
   return shortWikiFolders
end wikiFarm_DomainsFromFolder
