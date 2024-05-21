script "Global | Wiki | Server | Data | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Server | Data | Menu
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
   put the display_View of tObject into dView
   return dView
end menu_Target


--> Global | Wiki | Server | Data | Menu
-
on menu_UpdateGardenEcoData
   wikiGarden_Update
   --
   display_GardenEcodata
end menu_UpdateGardenEcoData

on menu_ReloadWikiEcoData
   wikiGarden_Init
   --
   menu_DisplayLoadedWikiEcoData
end menu_ReloadWikiEcoData

private on _
end _

on menu_DisplayGardenEcoData
   display_GardenEcodata
end menu_DisplayGardenEcoData

on menu_DisplayLoadedWikiEcoData
   put ecoData_Get() into ecoData
   display_GardenEcodata ecoData
end menu_DisplayLoadedWikiEcoData

on menu_StoreDisplayedEcoData wikiView
   put the displaye_Data of wikiView into ecoData
   wikiGarden_SetModel ecoData
end menu_StoreDisplayedEcoData

on menu_StoreEcoFolder
   put ecoData_GetEcoFolder() into ecoFolder
   file_SetHome ecoFolder
   wikiPreference_Set "Eco Folder", ecoFolder
   --
   put wikiFarm_GetFolder() into farmFolder
   file_SetHome ecoFolder
   wikiPreference_Set "Farm Folder", farmFolder
end menu_StoreEcoFolder

private on __
end __

on menu_InitWikiGarden dView
   wikiGarden_Init
end menu_InitWikiGarden

private on ___
end ___

on menu_DisplayRouterFolderArray
   display_RouterFolderArray
end menu_DisplayRouterFolderArray

on menu_ConstructRouterFolderArray dView
   put wikiGarden_ConstructRouterArray() into routerArray
   display_Data routerArray, "routerArray"
end menu_ConstructRouterFolderArray

on menu_PrefArray wikiview
   put "Hello" into prefArray ["World"]
   put "One" into prefArray ["Key"]
   put "Two" into prefArray ["Another Key"]
   --
   put wikiPreference_ConstructPageArray (prefArray) into pageArray
   set the ghost_PageArray of wikiview to pageArray
end menu_PrefArray

private on ____
end ____

on menu_DisplayWikiRouterArray
   display_WikiRouterArray
end menu_DisplayWikiRouterArray

on menu_DisplayGardenDomainData
   put wikiGarden_GetDomainData() into gardenDomainData
   --
   display_Data gardenDomainData, "wikiGarden_GetDomainData()", "Wiki Garden"
end menu_DisplayGardenDomainData

private on _____
end _____

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Server | Data | Menu")
end submenu_Dev
