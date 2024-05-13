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
local Garden_DomainData
local Farm_Domains


--> Working on
-
function wikiFarm_EarthFolder
   -- moved location of default node wikifarm
   put env_GetRepoFolder() into sFolder
   set the itemdelimiter to slash
   put "Earth" into item -1 of sFolder
   return sFolder
end wikiFarm_EarthFolder


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


--> WikiGarden | List
-
function wikiGarden_ListDomains pGardenName
   switch pGardenName
      case empty
         return wikiGarden_ListAllDomains()
      case "Farm"
         return wikiFarm_GetDomains()
      default
         put wikiRouter_GetFolderArray() into routerFolderArray
         set the itemdelimiter to slash
         repeat for each key wikiDomain in routerFolderArray
            put routerFolderArray [wikiDomain] into wikiFolder
            put item -2 of wikiFolder into testName
            if testName = pGardenName then
               put wikiDomain & CR after gardenDomains
            end if
         end repeat
         delete char -1 of gardenDomains
         url_SortDomainIndex gardenDomains
         return gardenDomains
   end switch
end wikiGarden_ListDomains

function wikiGarden_ListAllDomains pFilterDomain
   put wikiGarden_GetDomainData() into gardenDomainData
   put keys (gardenDomainData) into wikiDomains
   
   url_FilterDomains wikiDomains, pFilterDomain
   url_SortDomainIndex wikiDomains
   return wikiDomains
end wikiGarden_ListAllDomains


--> WikiGarden | List
-
function wikiGarden_ListUniqueNames
   local ecoGardenData
   
   put wikiGarden_GetEcoData() into ecoData
   put ecoData ["Eco"] into ecoFolderArray
   repeat for each key ecoName in ecoFolderArray
      put ecoFolderArray [ecoName]["Gardens"] into gardenData
      union ecoGardenData with gardenData
   end repeat
   put keys (ecoGardenData) into gardenNames
   sort gardenNames
   return gardenNames
end wikiGarden_ListUniqueNames

function wikiGarden_ListEcoFolders pEcoData
   if pEcoData is not an array then
      put wikiGarden_GetModel() into pEcoData
   end if
   
   put pEcoData ["Eco"] into ecoNameArray
   repeat for each key ecoName in ecoNameArray
      put ecoNameArray [ecoName]["folder"] into ecoFolder
      put ecoFolder & CR after ecoFolders
   end repeat
   delete char -1 of ecoFolders
   return ecoFolders
end wikiGarden_ListEcoFolders


--> WikiGarden | Folder | Find
-
function wikiGarden_FindGardenFolder gardenName
   put wikiGarden_GetEcoData() into ecoData
   repeat for each key ecoName in ecoData ["Eco"]
      put ecoData ["Eco"][ecoName] into gardenData
      put ecoData ["Eco"][ecoName]["folder"] into ecoFolder
      repeat for each key foundGardenName in gardenData ["Gardens"]
         if foundGardenName = gardenName then
            return ecoFolder & gardenName & slash
         end if
      end repeat
   end repeat
end wikiGarden_FindGardenFolder

function wikiGarden_FindEcoFolder ecoName
   put wikiGarden_GetEcoData() into ecoData
   repeat for each key foundEcoName in ecoData ["Eco"]
      if ecoName = foundEcoName then
         put ecoData ["Eco"][ecoName]["folder"] into ecoFolder
      end if
   end repeat
   return ecoFolder
end wikiGarden_FindEcoFolder



--> WikiFarm
-
command wikiGarden_AddEcoFolder ecoFolder
   put wikiGarden_ListEcoFolders() into ecoFolders
   if folder_Within (ecoFolder, ecoFolders) is false then
      return "Error, ecoFolder is within existing ecoFolders:" && ecoFolder
   end if
   --
   line_Add ecoFolder, ecoFolders
   wikiGarden_UpdateEcoData ecoFolders
   put the result into ecoData
   wikiGarden_Init false
   return ecoData
end wikiGarden_AddEcoFolder


--> DomainData | Model | Local
-
function wikiGarden_GetDomainData
   return Garden_DomainData
end wikiGarden_GetDomainData

command wikiGarden_SetDomainData gardenDomainData
   put gardenDomainData into Garden_DomainData
end wikiGarden_SetDomainData


--> Private
-
private function _ConstructGardenDomainArray ecoFolderArray
   local domainArray
   repeat for each key ecoName in ecoFolderArray
      put ecoFolderArray [ecoName] into ecoNameArray
      put ecoNameArray ["Gardens"] into gardenNameArray
      repeat for each key gardenName in gardenNameArray
         put gardenNameArray [gardenName] into domainArray
         union domainArray with gardenArray
      end repeat
   end repeat
   return domainArray
end _ConstructGardenDomainArray
