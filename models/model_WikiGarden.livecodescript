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
command display_GardenEcodata
   put wikiGarden_GetModel() into ecoData
   display_Array ecoData, "wikiGarden_GetModel()", "Ecodata"
   put the result into dView
   return dView
end display_GardenEcodata

function wikiGarden_ConstructFolder gardenName, pEcoName
   if pEcoName is empty then
      
   else
      put wikiGarden_GetEcoFolder (pEcoName) into ecoFolder
      put ecoFolder & gardenName & slash into gardenFolder
   end if
   return gardenFolder
end wikiGarden_ConstructFolder

command wikiGarden_Close
   wikiGarden_SetEcoData empty
   wikiFarm_SetDomains empty
   wikiRouter_SetArray empty
   wikiGarden_SetDomainData empty
end wikiGarden_Close


--> WikiGarden | EcoFolder
-
command wikiGarden_AddEcoFolder ecoFolder
   text_AddTrailing ecoFolder, slash
   put wikiGarden_ListEcoFolders() into ecoFolders
   if folder_Within (ecoFolder, ecoFolders) is false then
      return "Error, ecoFolder is within existing ecoFolders:" && ecoFolder
   end if
   --
   line_Add ecoFolder, ecoFolders
   wikiGarden_UpdateEcoData ecoFolders
   put the result into ecoData
   --
   wikiGarden_Init ecoData
   return ecoData
end wikiGarden_AddEcoFolder


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
      -- put wikiGarden_GetModel() into pEcoData
      put wikiGarden_GetEcoData() into pEcoData
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


--> WikiGarden | Folder
-
function wikiGarden_GetEcoFolder pEcoName
   if pEcoName is empty then put WikiFarm_DefaultEcoName into pEcoName
   --
   put wikiGarden_GetModel() into ecoData
   put ecoData ["Eco"][pEcoName]["folder"] into ecoFolder
   return ecoFolder
end wikiGarden_GetEcoFolder

command wikiGarden_SetEcoFolder ecoFolder, pEcoName
   if pEcoName is empty then put WikiFarm_DefaultEcoName into pEcoName
   text_AddTrailing ecoFolder, slash
   
   put wikiGarden_GetModel() into ecoData
   put ecoFolder into ecoData ["Eco"][pEcoName]["folder"]
   wikiGarden_SetModel ecoData
   --
   return ecoData
end wikiGarden_SetEcoFolder


--> WikiGarden | Init
-
command wikiGarden_Init ecoData
   if ecoData is not an array then
      put wikiGarden_GetModel() into ecoData
   end if
   
   # Get default farm domains from folder
   put ecoData ["Farm"]["folder"] into farmFolder
   put wikiFarm_DomainsFromFolder (farmFolder) into farmDomains
   wikiFarm_SetDomains farmDomains
   
   # Add default farmDomain to gardenDomainData
   repeat for each line farmDomain in farmDomains
      put "Farm" into gardenDomainData [farmDomain]["gardenName"]
      put wikiFolder_ConstructFromFarm (farmDomain) into farmFolder
      put farmFolder into gardenDomainData [farmDomain]["folder"]
   end repeat
   
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
   
   wikiGarden_SetEcoData ecoData
   return ecoData
end wikiGarden_Init

command wikiGarden_UpdateEcoData pEcoFolders
   -- does not load local variables to models (use init)
   local ecoArray
   --
   if pEcoFolders is empty then
      put wikiGarden_ListEcoFolders (ecoData) into pEcoFolders
   else
      wikiGarden_SetEcoFolder pEcoFolders
   end if
   put wikiGarden_GetModel() into ecoData
   
   # Construct ecoArray from folders
   set the itemdelimiter to slash
   repeat for each line ecoFolder in pEcoFolders
      if there is a folder ecoFolder then
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
               put wikiFolder into ecoArray [ecoName]["Gardens"][gardenName][wikiDomain]["folder"]
            end repeat
         end repeat
      end if
   end repeat
   
   # Save updated ecoData
   put ecoArray into ecoData ["Eco"]
   wikiGarden_SetModel ecoData
   
   if pLoadEcoData is not false then
      wikiGarden_Init ecoData
   end if
   return ecoData
end wikiGarden_UpdateEcoData


--> WikiGarden | Ecodata | Model | Local
-
function wikiGarden_GetEcoData
   return Garden_EcoData
end wikiGarden_GetEcoData

command wikiGarden_SetEcoData ecoData
   put ecoData into Garden_EcoData
end wikiGarden_SetEcoData

command wikiGarden_StoreCachedEcoData
   put wikiGarden_GetEcoData() into ecoData
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
