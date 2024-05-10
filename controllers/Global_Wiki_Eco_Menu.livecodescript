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


--> Global | Wiki | Eco | Menu
-
on menu_DisplayRouterFolderArray
   display_RouterFolderArray
end menu_DisplayRouterFolderArray

private on _
end _

on menu_InitWikiGarden dView
   wikiGarden_Init
end menu_InitWikiGarden

private on __
end __

on menu_ConstructRouterFolderArray dView
   put wikiGarden_ConstructRouterArray() into routerArray
   display_Data routerArray, "routerArray"
end menu_ConstructRouterFolderArray

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Eco | Menu")
end submenu_Dev
