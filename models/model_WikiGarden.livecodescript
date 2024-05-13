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
function wikiGarden_ConstructFolder gardenName, pEcoName
   if pEcoName is empty then
      
   else
      put wikiGarden_GetEcoFolder (pEcoName) into ecoFolder
      put ecoFolder & gardenName & slash into gardenFolder
   end if
   return gardenFolder
end wikiGarden_ConstructFolder


--> WikiGarden | Folder
-
function wikiGarden_GetEcoFolder pEcoName
   put wikiGarden_GetModel() into ecoData
   put _GetEcoFolder (ecoData, pEcoName) into ecoFolder
   return ecoFolder
end wikiGarden_GetEcoFolder

command wikiGarden_SetEcoFolder ecoFolder, pEcoName
   if pEcoName is empty then put WikiFarm_DefaultEcoName into pEcoName
   
   put wikiGarden_GetModel() into ecoData
   _SetEcoFolder ecoData, ecoFolder, pEcoName
   wikiGarden_SetModel ecoData
   --
   return ecoData
end wikiGarden_SetEcoFolder


--> Init
-
command wikiGarden_Close
   wikiGarden_SetEcoData empty
   wikiFarm_SetDomains empty
   wikiRouter_SetFolderArray empty
   wikiGarden_SetDomainData empty
end wikiGarden_Close
   
command wikiGarden_Init pUpdateModel
   if pUpdateModel is true then
      wikiGarden_UpdateEcoData
      put the result into ecoData
   else
      put wikiGarden_GetModel() into ecoData
   end if
   wikiGarden_SetEcoData ecoData
   
   # Fast Router_FolderArray (essentail)
   put ecoData ["Farm"]["folder"] into farmFolder
   -- wikiFarm_SetFolder farmFolder
   
   # Get default farm domains from folder
   put wikiFarm_DomainsFromFolder (farmFolder) into farmDomains
   wikiFarm_SetDomains farmDomains
   
   # Add default farmDomain to gardenDomainData
   repeat for each line farmDomain in farmDomains
      put "Farm" into gardenDomainData [farmDomain]["gardenName"]
      put wikiFolder_ConstructFromFarm (farmDomain) into farmFolder
      put farmFolder into gardenDomainData [farmDomain]["folder"]
   end repeat
   
   # Construct and store routerFolderArray
   put wikiGarden_ConstructRouterArray (ecoData) into routerFolderArray
   wikiRouter_SetFolderArray routerFolderArray
   
   # Construct Garden gardenDomainData
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
end wikiGarden_Init

command wikiGarden_UpdateEcoData pEcoFolders
   -- does not load local variables to models (use init)
   local ecoArray
   --
   put wikiGarden_GetModel() into ecoData
   if pEcoFolders is empty then
      put wikiGarden_ListEcoFolders (ecoData) into pEcoFolders
   end if
   
   # Construct ecoArray from folders
   set the itemdelimiter to slash
   repeat for each line ecoFolder in pEcoFolders
      if there is a folder ecoFolder then
         put item -1 of ecoFolder into ecoName
         --
         put ecoFolder into ecoArray [ecoName]["folder"]
         put folder_ListShort (ecoFolder) into gardenNames
         repeat for each line gardenName in gardenNames
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
private function _GetEcoFolder ecoData, pEcoName
   if pEcoName is empty then put WikiFarm_DefaultEcoName into pEcoName
   --
   put ecoData ["Eco"][pEcoName]["folder"] into ecoFolder
   return ecoFolder
end _GetEcoFolder

private command _SetEcoFolder @ecoData, ecoFolder, pEcoName
   if pEcoName is empty then put WikiFarm_DefaultEcoName into pEcoName
   text_AddTrailing ecoFolder, slash
   --
   put ecoFolder into ecoData ["Eco"][pEcoName]["folder"]
end _SetEcoFolder
