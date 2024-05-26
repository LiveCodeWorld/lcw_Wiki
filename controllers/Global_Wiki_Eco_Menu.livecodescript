script "Global | Wiki | Eco | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Eco | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_Target [tObject]
   -- put display_MenuTarget (tObject) into dView
   put the display_View of tObject into dView
   return dView
end menu_Target

getprop menu_CheckTarget [dView]
   return exists (dView)
end menu_CheckTarget

getprop disabled_FixFarm
   put wikiFarm_GetDefaultFolder() into farmFolder
   return there is not a folder farmFolder
end disabled_FixFarm


--> Global | Wiki | Eco | Menu
-
on menu_FixFarm dView
   put "Find localhost folder in eco-garden folder and set temporary farm ecodata?" into sQuestion
   put wikiPreference_GetDefaultEcoFolder() into defaultEcoFolder
   if there is not a folder defaultEcoFolder then
      put wikiFarm_GetDefaultFolder() into defaultEcoFolder 
   end if
   answer folder sQuestion with defaultEcoFolder as sheet
   if it is empty then exit to top
   --
   # ecoFolder
   put it into ecoFolder
   text_AddTrailing ecoFolder, slash
   file_AddHome ecoFolder
   
   put wikiFolder_FindLocalHost (ecoFolder) into localhostFolder
   put localhostFolder into farmFolder
   set the itemDelimiter to slash
   delete item -1 of farmFolder
   --
   if there is a folder farmFolder then
      # Fix and reload
      ecoData_SetFarmFolder farmFolder
      wikiGarden_SimpleRefresh farmFolder
   end if
end menu_FixFarm

private command _
end _

on insert_Data
   return "Global | Wiki | Server | Data | Menu"
end insert_Data

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Eco | Menu")
end submenu_Dev
