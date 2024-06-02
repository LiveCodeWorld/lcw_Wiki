script "Global | Wiki | Future | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Future | Menu
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


--> Global | Wiki | Future | Menu
-
on menu_WikiFuture dView
   -- set the create_MenuTitles of mGroup to "default"
end menu_WikiFuture

private on _
end _

on submenu_Menu
   return "Global | Menu | Group | Menu"
end submenu_Menu

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Future | Menu")
end submenu_Dev
