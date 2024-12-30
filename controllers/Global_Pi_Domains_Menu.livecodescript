script "Global | Pi | Domains | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Pi | Domains | Menu
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
   put the display_View of tObject into LocalArray ["dView"]
   put the displayed_Object of tObject into sObject
   return sObject
end menu_Target

private function _dView
   return LocalArray ["dView"]
end _dView

getprop menu_CheckTarget [dView]
   return exists (dView)
end menu_CheckTarget


--> Global | Pi | Domains | Menu
-
on menu_WikiPiStatus dView
   put the title_Text of dView into piLocalHost
   --
   put piServer_Status (piLocalHost)
end menu_WikiPiStatus

getprop checked_WikiPiStatus [dView]
   put the title_Text of dView into piLocalHost
   --
   return piServer_IsRunning (piLocalHost)
end checked_WikiPiStatus

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
   return menu_DevTitle ("Global | Pi | Domains | Menu")
end submenu_Dev
