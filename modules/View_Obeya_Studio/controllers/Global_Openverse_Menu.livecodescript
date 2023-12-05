script "Global | Openverse | Menu"
--> MetaData
-
license: GPLv3
name: Global | Openverse | Menu
type: controller
author: David Bovill
version: 0.1

/*
Here you can describe this menu.
Full help text should be provided on the linked wiki.
*/

--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_Target [tObject]
   -- return display_MenuTarget(tObject)
   return the display_View of tObject
end menu_Target

getprop menu_CheckTarget [cameraView]
   return exists (cameraView)
end menu_CheckTarget


--> Global | Openverse | Menu
-
on menu_Behavior displayView
   put the behavior of displayView into bObject
   edit the script of bObject
end menu_Behavior

private on _
end _

on menu_Register displayView
   openverse_Register "david@regovern.org", "Platform Earth", "A project to create an platform.earth microservice around commons creation of wiki content."
end menu_Register

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Openverse | Menu")
end submenu_Dev
