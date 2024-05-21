script "Global | Wiki | Eco | Line | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Eco | Line | Menu
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


--> Global | Wiki | Eco | Line | Menu
-
on menu_WikiEcoLine dView
   put the selected_Value of dView
end menu_WikiEcoLine

private on _
end _

on menu_DisplayWikiPreferences dView
  display_WikiPage "localhost", "local-preference"
end menu_DisplayWikiPreferences

on menu_ModuleTools dView
   put the view_Name of dView into viewName
   display_ModuleTools viewName
end menu_ModuleTools

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Eco | Line | Menu")
end submenu_Dev
