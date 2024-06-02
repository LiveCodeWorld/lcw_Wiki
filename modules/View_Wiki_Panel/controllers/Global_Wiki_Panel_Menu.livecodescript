script "Global | Wiki | Panel | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Panel | Menu
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
   -- put the display_View of tObject into dView
   put display_MenuTarget (tObject) into panelView
   -- put the panel_View of tObject into panelView
   put the module_View of tObject into panelView
   return panelView
end menu_Target

getprop menu_CheckTarget [dView]
   return exists (dView)
end menu_CheckTarget


--> Global | Wiki | Panel | Menu
-
on menu_WikiPanel vObject
   put the name of vObject
end menu_WikiPanel

private on _
end _

on menu_Behavior dView
   put the behavior of dView into bObject
   edit the script of bObject
end menu_Behavior

on menu_ModuleTools dView
   put the view_Name of dView into viewName
   display_ModuleTools viewName
end menu_ModuleTools

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Panel | Menu")
end submenu_Dev
