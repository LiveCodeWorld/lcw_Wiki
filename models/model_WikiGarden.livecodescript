script "model_WikiGarden"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_WikiGarden
type: model
version: 0.1

--> Working on
-
command display_WikiGardenModel
   put wikiGarden_GetModel() into wikiGardenModel
   
   display_Data wikiGardenModel, "Wiki Garden", "Model"
   put the result into displayView
   return displayView
end display_WikiGardenModel


--> WikiGarden | Model | Update
-
command wikiGarden_UpdateEcoFolder pEcoFolder
   local wikiEcoData
   if pEcoFolder is empty then
      put wikiGarden_GetEcoFolder() into pEcoFolder
   else
      wikiGarden_SetEcoFolder pEcoFolder
   end if
   
   put folder_ListShort (pEcoFolder) into gardenNames
   repeat for each line gardenName in gardenNames
      wikiGarden_Update gardenName
      put the result into routerArray
      union wikiEcoData with routerArray
   end repeat
   display_Data wikiEcoData
   return wikiEcoData
end wikiGarden_UpdateEcoFolder

command wikiGarden_Update gardenName
   
     set the project_Array of stack "lcw_Wiki" to projectArray
   
   return Router_FolderArray
end wikiGarden_Update

function wikiGarden_DataFromFile gardenName
   put wikiGarden_ConstructFolder (gardenName) into gardenFolder
   if there is not a folder gardenFolder then return "Error, garden folder does not exist:" && gardenFolder
   
   put the project_Array of stack "lcw_Wiki" into projectArray
   
   put folder_ListShort (gardenFolder) into wikiDomains
   repeat for each line wikiDomain in wikiDomains
      put gardenFolder into Router_FolderArray [wikiDomain]
      put gardenFolder into projectArray ["redirectArray"][wikiDomain]
   end repeat
   
end wikiGarden_DataFromFile


--> WikiGarden | Model
-
function wikiGarden_GetFolder wikiDomain
   # Must be fast
   _InitRouterFolderArray -- when empty only
   
   # Translate Fast
   put Router_FolderArray [wikiDomain] into wikiFolder
   return wikiFolder
end wikiGarden_GetFolder

command wikiGarden_SetFolder wikiDomain, wikiFolder, pStore
   put wikiFolder into Router_FolderArray [wikiDomain]
   
   if pStore is not false then
      put the project_Array of stack "lcw_Wiki" into projectArray
      put wikiFolder into projectArray ["redirectArray"][wikiDomain]
      set the project_Array of stack "lcw_Wiki" to projectArray
   end if
   return redirectArray
end wikiGarden_SetFolder

command wikiGarden_RemoveFromModel wikiDomain
   put wikiGarden_GetModel() into redirectArray
   delete variable redirectArray [wikiDomain]
   wikiGarden_SetModel redirectArray
   return redirectArray
end wikiGarden_RemoveFromModel

command wikiGarden_DeleteModel
   put the project_Array of stack "lcw_Wiki" into projectArray
   delete variable projectArray ["redirectArray"]
   set the project_Array of stack "lcw_Wiki" to projectArray
   return projectArray
end wikiGarden_DeleteModel

function wikiGarden_GetModel
   put the model_Array ["wikigarden.array"] of stack "lcw_Wiki" into wikiGardenData
   return wikiGardenData
   
   put the project_Array of stack "lcw_Wiki" into projectArray
   return projectArray ["redirectArray"]
end wikiGarden_GetModel

command wikiGarden_SetModel redirectArray
   set the model_Array ["wikigarden.array"] of stack "lcw_Wiki" to redirectArray
   
   put the project_Array of stack "lcw_Wiki" into projectArray
   put redirectArray into projectArray ["redirectArray"]
   set the project_Array of stack "lcw_Wiki" to projectArray
   return the result
end wikiGarden_SetModel
