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
*/

--> Variables
-
constant GardenModelName = "wikigarden.array"
constant WikiFarm_DefaultEcoName = "Thought Gardens"
local Garden_EcoData


--> Working on
-
private function _AskEcoFolder
   put ecoData_GetEcoFolder() into ecoFolder
   answer folder "Where is the eco-folder you keep your wiki farms?" with ecoFolder as sheet
   if it is empty then exit to top
   
   put it into ecoFolder
   text_AddTrailing ecoFolder, slash
   file_SetHome ecoFolder
   return ecoFolder
end _AskEcoFolder

private command _SetGardenFolder @ecoData, ecoFolder
   if there is a folder ecoFolder then
      text_AddTrailing ecoFolder, slash
      file_SetHome ecoFolder
      put ecoFolder into ecoData ["Eco"][pEcoName]["folder"]
      return empty
   else
      return "Error, eco folder does not exist:" && ecoFolder
   end if
end _SetGardenFolder

private command _AddFarmDomains @gardenDomainData, farmDomains
   repeat for each line farmDomain in farmDomains
      put "Farm" into gardenDomainData [farmDomain]["gardenName"]
      put wikiFolder_ConstructFromFarm (farmDomain) into farmFolder
      put farmFolder into gardenDomainData [farmDomain]["folder"]
   end repeat
end _AddFarmDomains


--> Ecodata | Model
-
command ecoData_SetFarmFolder @ecoData, farmFolder
   if there is a folder farmFolder then
      text_AddTrailing farmFolder, slash
      file_SetHome farmFolder
      put farmFolder into ecoData ["Farm"]["folder"]
      return empty
   else
      return "Error, eco folder does not exist:" && farmFolder
   end if
end ecoData_SetFarmFolder

command ecoData_UpdateEcoArray @ecoArray, ecoFolder
   if there is a folder ecoFolder then
      set the itemdelimiter to slash
      put item -1 of ecoFolder into ecoName
      --
      put ecoFolder into ecoArray [ecoName]["folder"]
      put folder_ListShort (ecoFolder) into gardenNames
      repeat for each line gardenName in gardenNames
         put empty into ecoArray [ecoName]["Gardens"][gardenName]
         --
         put wikiGarden_ConstructFolder (gardenName, ecoName) into gardenFolder
         put folder_ListShort (gardenFolder) into wikiDomains
         repeat for each line wikiDomain in wikiDomains
            put gardenFolder & wikiDomain & slash into wikiFolder
            file_SetHome wikiFolder
            put wikiFolder into ecoArray [ecoName]["Gardens"][gardenName][wikiDomain]["folder"]
         end repeat
      end repeat
   end if
end ecoData_UpdateEcoArray

function ecoData_GetEcoFolder pEcoName
   if pEcoName is empty then
      return wikiGarden_GetDefaultEcoFolder()
   else
      # Complicated multiple ecofolder version
      if pEcoName is empty then put WikiFarm_DefaultEcoName into pEcoName
      --
      put wikiGarden_GetModel() into ecoData
      put ecoData ["Eco"][pEcoName]["folder"] into ecoFolder
      return ecoFolder
   end if
end ecoData_GetEcoFolder

command ecoData_SetEcoFolder ecoFolder, pEcoName
   if pEcoName is empty then
      wikiGarden_SetDefaultEcoFolder ecoFolder
      put the result into prefArray
      return prefArray
   else
      put wikiGarden_GetModel() into ecoData
      _SetGardenFolder ecoData, ecoFolder
      wikiGarden_SetModel ecoData
      --
      return ecoData
   end if
end ecoData_SetEcoFolder

function ecoData_Get
   return Garden_EcoData
end ecoData_Get

command ecoData_Set ecoData
   put ecoData into Garden_EcoData
end ecoData_Set


--> WikiGarden | Update
-
command wikiGarden_Update
   -- simple version of "wikiGarden_UpdateEcoData" using wikiPreference that rebuilds from scratch
   local ecoData
   
   put ecoData_GetEcoFolder() into ecoFolder
   if there is not a folder ecoFolder then
      put _AskEcoFolder() into ecoFolder
      ecoData_SetFarmFolder
   end if
   --
   ecoData_SetFarmFolder ecoData, farmFolder
   ecoData_UpdateEcoArray ecoData, ecoFolder
   wikiGarden_SetModel ecoData
   wikiGarden_Init ecoData
   --
   return ecoData
end wikiGarden_Update

command wikiGarden_Init ecoData
   local gardenDomainData
   if ecoData is not an array then
      put wikiGarden_GetModel() into ecoData
   end if
   
   # Get default farm domains from folder
   put ecoData ["Farm"]["folder"] into farmFolder
   put wikiFarm_DomainsFromFolder (farmFolder) into farmDomains
   wikiFarm_SetDomains farmDomains
   
   # Add default farmDomain to gardenDomainData
   _AddFarmDomains gardenDomainData, farmDomains
   
   # Add Garden folders to gardenDomainData
   put ecoData ["Eco"] into ecoFolderArray
   repeat for each key ecoName in ecoFolderArray
      put ecoFolderArray [ecoName] into ecoNameArray
      put ecoNameArray ["Gardens"] into gardenNameArray
      repeat for each key gardenName in gardenNameArray
         put gardenNameArray [gardenName] into gardenArray
         repeat for each key wikiDomain in gardenArray
            put gardenArray [wikiDomain]["folder"] into wikiFolder
            --
            put gardenName into gardenDomainData [wikiDomain]["gardenName"]
            put ecoName into gardenDomainData [wikiDomain]["ecoName"]
            put wikiFolder into gardenDomainData [wikiDomain]["folder"]
         end repeat
      end repeat
   end repeat
   
   # Garden_DomainData (used by "wikiFolder_FromRouter" and "wikiGarden_ListAllDomains")
   wikiGarden_SetDomainData gardenDomainData
   
   # Construct and store routerFolderArray
   put wikiGarden_ConstructRouterArray (ecoData) into routerFolderArray
   wikiRouter_SetArray routerFolderArray
   
   ecoData_Set ecoData
   return ecoData
end wikiGarden_Init


--> WikiGarden | EcoFolder | Update | Multiple (old)
-
command wikiGarden_AddEcoFolder ecoFolder
   text_AddTrailing ecoFolder, slash
   put wikiGarden_ListEcoFolders() into ecoFolders
   -- if folder_Within (ecoFolder, ecoFolders) is false then return "Error, ecoFolder is within existing ecoFolders:" && ecoFolder
   
   # Add Ecofolder
   line_Add ecoFolder, ecoFolders
   wikiGarden_UpdateEcoData ecoFolders
   put the result into ecoData
   --
   wikiGarden_Init ecoData
   return ecoData
end wikiGarden_AddEcoFolder

command wikiGarden_UpdateEcoData pEcoFolders
   -- use "wikiGarden_Update" instead
   -- does not load local variables to models (use init)
   local ecoArray
   --
   if pEcoFolders is empty then
      put wikiGarden_ListEcoFolders (ecoData) into pEcoFolders
   else
      ecoData_SetEcoFolder pEcoFolders
   end if
   put wikiGarden_GetModel() into ecoData
   
   # Construct ecoArray from folders
   repeat for each line ecoFolder in pEcoFolders
      ecoData_UpdateEcoArray ecoArray, ecoFolder
   end repeat
   
   # Save updated ecoData
   put ecoArray into ecoData ["Eco"]
   wikiGarden_SetModel ecoData
   
   if pLoadEcoData is not false then
      wikiGarden_Init ecoData
   end if
   return ecoData
end wikiGarden_UpdateEcoData


--> WikiGarden | EcoFolder
-
function wikiGarden_ListEcoFolders pEcoData
   if pEcoData is not an array then
      -- put wikiGarden_GetModel() into pEcoData
      put ecoData_Get() into pEcoData
   end if
   
   put pEcoData ["Eco"] into ecoNameArray
   repeat for each key ecoName in ecoNameArray
      put ecoNameArray [ecoName]["folder"] into ecoFolder
      put ecoFolder & CR after ecoFolders
   end repeat
   delete char -1 of ecoFolders
   return ecoFolders
end wikiGarden_ListEcoFolders

function wikiGarden_GetDefaultEcoFolder
   put wikiPreference_Get ("Eco Folder") into ecoFolder
   return ecoFolder
end wikiGarden_GetDefaultEcoFolder

command wikiGarden_SetDefaultEcoFolder ecoFolder
   if there is not a folder ecoFolder then
      return "Error, eco folder does not exist:" && ecoFolder
   end if
   wikiPreference_Set "Eco Folder", ecoFolder
   put the result into prefArray
   return prefArray
end wikiGarden_SetDefaultEcoFolder


--> WikiGarden | List
-
function wikiGarden_ListUniqueNames
   local ecoGardenData
   
   put ecoData_Get() into ecoData
   put ecoData ["Eco"] into ecoFolderArray
   repeat for each key ecoName in ecoFolderArray
      put ecoFolderArray [ecoName]["Gardens"] into gardenData
      union ecoGardenData with gardenData
   end repeat
   put keys (ecoGardenData) into gardenNames
   sort gardenNames
   return gardenNames
end wikiGarden_ListUniqueNames


--> WikiGarden | Folder | Find
-
function wikiGarden_FindGardenFolder gardenName
   put ecoData_Get() into ecoData
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
   put ecoData_Get() into ecoData
   repeat for each key foundEcoName in ecoData ["Eco"]
      if ecoName = foundEcoName then
         put ecoData ["Eco"][ecoName]["folder"] into ecoFolder
      end if
   end repeat
   return ecoFolder
end wikiGarden_FindEcoFolder

command wikiGarden_StoreCachedEcoData
   put ecoData_Get() into ecoData
   wikiGarden_SetModel ecoData
   return ecoData
end wikiGarden_StoreCachedEcoData


--> WikiGarden | List
-
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
