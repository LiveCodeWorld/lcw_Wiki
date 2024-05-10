script "model_WikiGarden"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_WikiGarden
type: model
version: 0.2

/*
When we load the Garden Model, we load the following variables used by this library:

- WikiFarm_RootFolder
- Router_FolderArray
*/

--> Variables
-
constant GardenModelName = "wikigarden.array"
constant WikiFarm_DefaultEcoName = "Thought Gardens"


--> Working on
-
on mDoubleUp_WikiEco displayView, wikiFolder
   put someLine &CR& the title_Text of displayView
end mDoubleUp_WikiEco

command display_WikiEcoData
   put wikiGarden_GetModel() into ecoData
   
   display_Tools ecoData, "Eco Data", "Wiki | Eco", "Wiki", "lcw_Wiki"
   return the result
end display_WikiEcoData


--> WikiGarden | Model | List
-
function wikiGarden_ListDomains pGardenName
   switch pGardenName
      case empty
         return wikiGarden_ListAllDomains()
      case "Farm"
         return wikiFarm_ListDomains()
      default
         return wikiRouter_ListDomains (pGardenName)
   end switch
end wikiGarden_ListDomains

function wikiGarden_ListAllDomains pUseRouter
   put wikiFarm_ListDomains() into wikiDomains
   
   put CR after wikiDomains
   if pUseRouter is not false then
      put wikiRouter_ListDomains() after wikiDomains
   else
      put wikiGarden_GetEcoFolderArray() into ecoFolderArray
      put wikiGarden_ConstructDomainArray (ecoFolderArray) into domainArray
      put keys (domainArray) after wikiDomains
   end if
   --
   url_SortDomainIndex wikiDomains
   return wikiDomains
end wikiGarden_ListAllDomains

function wikiGarden_ConstructDomainArray ecoFolderArray
   local domainArray
   repeat for each key ecoName in ecoFolderArray
      put ecoFolderArray [ecoName] into ecoNameArray
      put ecoNameArray ["Gardens"] into gardenNameArray
      repeat for each key gardenName in gardenNameArray
         put gardenNameArray [gardenName] into gardenArray
         union domainArray with gardenArray
      end repeat
   end repeat
   return domainArray
end wikiGarden_ConstructDomainArray

function wikiGarden_ListEcoNames
   put wikiGarden_GetEcoFolderArray() into ecoNameArray
   put keys (ecoNameArray) into ecoNames
   sort ecoNames
   return ecoNames
end wikiGarden_ListEcoNames


--> WikiGarden | Model | Update
-
command wikiGarden_UpdateEcoData
   put wikiGarden_GetModel() into ecoData
   --
   put ecoData ["Eco"] into ecoNameArray
   repeat for each key ecoName in ecoNameArray
      put ecoNameArray [ecoName]["folder"] into ecoFolder
      if there is not a folder ecoFolder then next repeat
      
      put folder_ListShort (ecoFolder) into gardenNames
      repeat for each line gardenName in gardenNames
         put wikiGarden_ConstructFolder (gardenName, ecoName) into gardenFolder
         if there is not a folder gardenFolder then return "Error, gardenFolder does not exist:" && gardenFolder
         
         put folder_ListShort (gardenFolder) into wikiDomains
         repeat for each line wikiDomain in wikiDomains
            put gardenFolder & wikiDomain & slash into wikiFolder
            put wikiFolder into ecoData ["Eco"][ecoName]["Gardens"][gardenName][wikiDomain]["folder"]
         end repeat
      end repeat
   end repeat
   --
   wikiGarden_SetModel ecoData
   return ecoData
end wikiGarden_UpdateEcoData

function wikiGarden_ConstructFolder gardenName, pEcoName
   put wikiGarden_GetEcoFolder (pEcoName) into ecoFolder
   put ecoFolder & gardenName & slash into gardenFolder
   return gardenFolder
end wikiGarden_ConstructFolder

function wikiGarden_GetEcoFolderArray
   put wikiGarden_GetModel() into ecoData
   put ecoData ["Eco"] into ecoNameArray
   return ecoNameArray
end wikiGarden_GetEcoFolderArray

function wikiGarden_GetEcoFolder pEcoName
   put wikiGarden_GetModel() into ecoData
   put _GetEcoFolder (ecoData, pEcoName) into ecoFolder
   return ecoFolder
end wikiGarden_GetEcoFolder

command wikiGarden_SetEcoFolder ecoFolder, pEcoName
   if pEcoName is empty then put WikiFarm_DefaultEcoName into pEcoName
   _NormEcoFolder ecoFolder
   
   put wikiGarden_GetModel() into ecoData
   --
   _SetEcoFolder ecoData, ecoFolder, pEcoName
   wikiGarden_SetModel ecoData
   --
   return ecoData
end wikiGarden_SetEcoFolder

function wikiGarden_GetFarmFolder
   put wikiGarden_GetModel() into ecoData
   put _GetFarmFolder (ecoData) into farmFolder
   return farmFolder
end wikiGarden_GetFarmFolder

command wikiGarden_SetFarmFolder farmFolder
   -- put wikiFarm_EarthRoot() into farmFolder
   _NormEcoFolder farmFolder
   
   put wikiGarden_GetModel() into ecoData
   --
   _SetFarmFolder ecoData, farmFolder
   wikiGarden_SetModel ecoData
   --
   return ecoData
end wikiGarden_SetFarmFolder


--> WikiGarden | Model
-
function wikiGarden_GetModel
   put the model_Array [GardenModelName] of stack "lcw_Wiki" into ecoData
   return ecoData
end wikiGarden_GetModel

command wikiGarden_SetModel ecoData
   set the model_Array [GardenModelName] of stack "lcw_Wiki" to ecoData
   return the result
end wikiGarden_SetModel

command wikiGarden_DeleteModel
   project_DeleteArray GardenModelName
   return the result
end wikiGarden_DeleteModel

command wikiGarden_RemoveFromModel wikiDomain
   put wikiGarden_GetModel() into redirectArray
   delete variable redirectArray [wikiDomain]
   wikiGarden_SetModel redirectArray
   return redirectArray
end wikiGarden_RemoveFromModel


--> Private
-
private command _NormEcoFolder @ecoFolder
   text_AddTrailing ecoFolder, slash
   if there is a folder ecoFolder then
      put ecoFolder into ecoFolder
   else
      put empty into ecoFolder
   end if
end _NormEcoFolder

private function _GetFarmFolder ecoData
   put ecoData ["Farm"]["folder"] into farmFolder
   return farmFolder
end _GetFarmFolder

private command _SetFarmFolder @ecoData, farmFolder
   put farmFolder into ecoData ["Farm"]["folder"]
end _SetFarmFolder

private function _GetEcoFolder ecoData, pEcoName
   if pEcoName is empty then put WikiFarm_DefaultEcoName into pEcoName
   --
   put ecoData ["Eco"][pEcoName]["folder"] into ecoFolder
   return ecoFolder
end _GetEcoFolder

private command _SetEcoFolder @ecoData, ecoFolder, pEcoName
   if pEcoName is empty then put WikiFarm_DefaultEcoName into pEcoName
   --
   put ecoFolder into ecoData ["Eco"][pEcoName]["folder"]
end _SetEcoFolder
