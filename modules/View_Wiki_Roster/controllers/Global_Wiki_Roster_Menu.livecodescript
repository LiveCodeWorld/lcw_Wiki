script "Global | Wiki | Roster | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Roster | Menu
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
   -- called once for each menu
   return the display_View of tObject
end menu_Target


--> Global | Wiki | Roster | Menu
-
on menu_TestRoster viewObject
   set the roster_Domains of viewObject to "thought.garden"
end menu_TestRoster

on _
end _

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Dev | Menu
-
on menu_Experiment displayView
   put displayView
end menu_Experiment


--> Deps
-
