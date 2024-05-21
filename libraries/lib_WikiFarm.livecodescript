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
function wikiFarm_GetFolder
   put ecoData_Get() into ecoData
   return ecoData ["Farm"]["folder"]
end wikiFarm_GetFolder

command wikiFarm_SetFolder pFarmFolder, pSaveEcoData
   if there is not a folder pFarmFolder then
      put _AskFarmFolder() into pFarmFolder
   end if
   text_AddTrailing pFarmFolder, slash
   
   put pFarmFolder & "localhost/" into localHostFolder
   if there is not a folder localHostFolder then
      return "Error, there si not a localhost folder in the farm folder:" && localHostFolder
   end if
   
   # Set EcoData 
   put ecoData_Get() into ecoData
   ecoData_SetFarmFolder ecoData, pFarmFolder
   ecoData_Set ecoData
   
   # Optionally save
   if pSaveEcoData is true then
      wikiGarden_SetModel ecoData
   end if
   return ecoData
end wikiFarm_SetFolder

private function _AskFarmFolder
   put node_DefaultFarmFolder() into farmFolder
   answer folder "Where is the farm folder containing localhost?" with farmFolder as sheet
   if it is empty then exit to top
   put it into farmFolder
   text_AddTrailing farmFolder, slash
   return farmFolder
end _AskFarmFolder


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


--> WikiFarm | Domains
-
function wikiFarm_DomainsFromFolder farmFolder, pFilterDomain, pSimple
   # List Farm
   put folder_ListShort (farmFolder) into shortWikiFolders 
   
   # Tidy
   wikiFolder_TidyList shortWikiFolders
   url_FilterDomains shortWikiFolders, pFilterDomain, pSimple
   
   # Sort
   url_SortDomainIndex shortWikiFolders
   return shortWikiFolders
end wikiFarm_DomainsFromFolder


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


--> WikiFarm | Model
-
function wikiFarm_GetDefaultFolder
   put wikiPreference_Get ("Farm Folder") into farmFolder
   return farmFolder
end wikiFarm_GetDefaultFolder

command wikiFarm_SetDefaultFolder farmFolder
   if there is not a folder farmFolder then
      return "Error, farm folder does not exist:" && farmFolder
   end if
   file_SetHome farmFolder
   wikiPreference_Set "Farm Folder", farmFolder
   put the result into prefArray
   return prefArray
end wikiFarm_SetDefaultFolder
