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

--> WikiDomain
-
function wikiDomain_GardenFolder wikiDomain
   put wikiDomain_Folder (wikiDomain) into wikiFolder
   set the itemdelimiter to slash
   delete item -1 of wikiFolder
   return wikiFolder
end wikiDomain_GardenFolder

function wikiDomain_List pFilterDomain
   put wikiGarden_GetDomainData() into gardenDomainData
   put keys (gardenDomainData) into wikiDomains
   
   url_FilterDomains wikiDomains, pFilterDomain
   url_SortDomainIndex wikiDomains
   return wikiDomains
end wikiDomain_List

function wikiDomain_Folder wikiDomain
   put wikiGarden_GetDomainData() into gardenDomainData
   put gardenDomainData [wikiDomain]["folder"] into wikiFolder
   file_AddHome wikiFolder
   return wikiFolder
end wikiDomain_Folder

function wikiDomain_ListTop pFilterEmpty
   put wikiGarden_GetDomainData() into gardenDomainData
   repeat for each key wikiDomain in gardenDomainData
      switch
         case wikiDomain = "commons"
            next repeat
         case pFilterEmpty is true
            put gardenDomainData [wikiDomain]["folder"] into wikiFolder
            if wikiFolder_HasNoPages (wikiFolder) is true then
               next repeat
            end if
         default
            put url_GetTLD (wikiDomain) into tldDomain
            put empty into tldArray [tldDomain][someDomain]
      end switch
   end repeat
   put keys (tldArray) into topDomains
   url_SortDomainIndex topDomains
   return topDomains
end wikiDomain_ListTop


--> WikiGarden | List
-
function wikiGarden_ListUniqueNames pReIndex
   if pReIndex is true then
      ecoData_ConstructLoadAndStore
      put the result into ecoData
   else
      put ecoData_Get() into ecoData
   end if
   
   return ecoData_ListGardenNames (ecoData)
end wikiGarden_ListUniqueNames

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


--> WikiGarden | Folder | Find
-
function wikiGarden_Folder gardenName, pEcoName
   put wikiGarden_ConstructFolder (gardenName, pEcoName) into gardenFolder
   if there is a folder gardenFolder then
      return gardenFolder
   else
      return empty
   end if
end wikiGarden_Folder

function wikiGarden_ConstructFolder gardenName, pEcoName
   put ecoData_GetEcoFolder (pEcoName) into ecoFolder
   if ecoFolder is empty then return empty
   --
   put ecoFolder & gardenName & slash into gardenFolder
   return gardenFolder
end wikiGarden_ConstructFolder

function wikiFolder_FromDomain wikiDomain
   put wikiGarden_GetDomainArray (wikiDomain) into gardenDomainArray
   switch gardenDomainArray ["gardenName"]
      case empty
      case "Farm"
         return empty
      default
         put gardenDomainArray ["folder"] into gardenFolder
         return gardenFolder
   end switch
end wikiFolder_FromDomain

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
   return empty
end wikiGarden_FindGardenFolder

function wikiGarden_FindEcoFolder ecoName
   put ecoData_Get() into ecoData
   repeat for each key foundEcoName in ecoData ["Eco"]
      if ecoName = foundEcoName then
         put ecoData ["Eco"][ecoName]["folder"] into ecoFolder
         return ecoFolder
      end if
   end repeat
   return empty
end wikiGarden_FindEcoFolder


--> Ecodata
-
function ecoData_ListGardenNames ecoData
   local ecoGardenData
   
   put ecoData ["Eco"] into ecoFolderArray
   repeat for each key ecoName in ecoFolderArray
      put ecoFolderArray [ecoName]["Gardens"] into gardenData
      union ecoGardenData with gardenData
   end repeat
   put keys (ecoGardenData) into gardenNames
   sort gardenNames
   return gardenNames
end ecoData_ListGardenNames


--> Ecodata | Model
-
function ecoData_GetEcoFolder pEcoName
   if pEcoName is empty then
      # Default to first
      get wikiGarden_ListEcoFolders()
      put line 1 of it into ecoFolder
   else
      put ecoData_Get() into ecoData
      put ecoData ["Eco"][pEcoName]["folder"] into ecoFolder
   end if
   file_AddHome ecoFolder
   return ecoFolder
end ecoData_GetEcoFolder

function ecoData_GetFarmName
   put ecoData_GetFarmFolder() into farmFolder
   set the itemdelimiter to slash
   return item -1 of farmFolder
end ecoData_GetFarmName

function ecoData_GetFarmFolder
   -- see "wikiFarm_GetDefaultFolder"
   put ecoData_Get() into ecoData
   put ecoData ["Farm"]["folder"] into farmFolder
   file_AddHome farmFolder
   return farmFolder
end ecoData_GetFarmFolder

command ecoData_SetFarmFolder farmFolder
   -- see "wikiFarm_SetDefaultFolder"
   if there is a folder farmFolder then
      text_AddTrailing farmFolder, slash
      file_StripHome farmFolder
      
      # Set local variable Garden_EcoData
      put ecoData_Get() into ecoData
      put farmFolder into ecoData ["Farm"]["folder"]
      ecoData_Set ecoData
      --
      return ecoData
   else
      return "Error, eco folder does not exist:" && farmFolder
   end if
end ecoData_SetFarmFolder

function ecodata_ConstructArray ecoFolder
   local ecoArray
   _UpdateEcoArray ecoArray, ecoFolder
   return ecoArray
end ecodata_ConstructArray

function ecoData_Get
   return Garden_EcoData
end ecoData_Get

command ecoData_Set ecoData
   put ecoData into Garden_EcoData
end ecoData_Set


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
private command _UpdateEcoArray @ecoArray, ecoFolder
   if there is a folder ecoFolder then
      put ecoData_GetFarmFolder() into farmFolder -- check avoids duplication (not needed)
      --  
      set the itemdelimiter to slash
      put item -1 of ecoFolder into ecoName
      
      # Add Eco Folder
      text_AddTrailing ecoFolder, slash
      file_StripHome ecoFolder
      put ecoFolder into ecoArray [ecoName]["folder"]
      
      # Repeat for each Garden (short folder)
      put folder_ListShort (ecoFolder) into gardenNames
      repeat for each line gardenName in gardenNames
         file_AddHome ecoFolder
         put ecoFolder & gardenName & slash into gardenFolder
         if gardenFolder = farmFolder then
            -- is indexed when we add farm
            -- happens when farm folder is inside ecofolder
            next repeat
         end if
         
         put empty into ecoArray [ecoName]["Gardens"][gardenName]
         
         put folder_ListShort (gardenFolder) into wikiDomains
         file_StripHome gardenFolder
         repeat for each line wikiDomain in wikiDomains
            put gardenFolder & wikiDomain & slash into wikiFolder
            put wikiFolder into ecoArray [ecoName]["Gardens"][gardenName][wikiDomain]["folder"]
         end repeat
      end repeat
   end if
end _UpdateEcoArray

private command _SetGardenFolder @ecoData, ecoFolder
   if there is a folder ecoFolder then
      text_AddTrailing ecoFolder, slash
      file_StripHome ecoFolder
      put ecoFolder into ecoData ["Eco"][pEcoName]["folder"]
      return empty
   else
      return "Error, eco folder does not exist:" && ecoFolder
   end if
end _SetGardenFolder
