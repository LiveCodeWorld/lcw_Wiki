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
function wikiGarden_ListFolders
   put wikiGarden_GetDomainData() into domainData
   repeat for each key domainName in domainData
      put domainData [domainName]["folder"] into wikiFolder
      put wikiFolder & CR after wikiFolders
   end repeat
   delete char -1 of wikiFolders
   return wikiFolders
end wikiGarden_ListFolders

function wikiGarden_ListDomains pGardenName
   switch pGardenName
      case empty
         return wikiGarden_ListAllDomains()
      case "Farm"
         return wikiFarm_GetDomains()
      default
         put wikiRouter_GetArray() into routerFolderArray
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
