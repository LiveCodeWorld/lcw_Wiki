script "Global | Browser | Menu"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: Global | Browser | Menu
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
   put the display_View of tObject into displayView
   if exists (displayView) is false then return empty
   --
   put the displayed_ViewObject of displayView into displayedObject
   return displayedObject
end menu_Target


--> Global | Browser | Menu
-
on menu_GoToUrl displayedObject
   put lcw_Ask ("What url would you like to view...", "http://thought.garden", displayedObject) into someURL
   set the browser_URL of displayedObject to someURL
end menu_GoToUrl

on submenu_Wiki
   return "Global | Wiki | Menu"
end submenu_Wiki

on submenu_Story
   return "Global | Wiki | Story | Menu"
end submenu_Story

on _
end _

on submenu_Frame
   return "Global | Frame | Menu"
end submenu_Frame

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Dev | Menu
-
on menu_EditBehavior displayedObject
   put the behavior of displayedObject into bObject
   edit the script of bObject
end menu_EditBehavior


--> Deps
-
