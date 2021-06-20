script "Global | Wiki | Lineup | Line | Menu"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: Global | Wiki | Lineup | Line | Menu
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
   -- called first
   put the display_View of tObject into displayView
   put the displayed_Data of displayView into LocalArray ["dataArray"]
   --
   return displayView
end menu_Target

getprop menu_CheckTarget [mTarget]
   -- use to do initialisation
   pass menu_CheckTarget
end menu_CheckTarget

getprop test_Param [displayView]
  return "b"
end test_Param

getprop test_Params [displayView]
   return "a,b,c"
end test_Params

getprop checked_TestChecked
   return true
end checked_TestChecked

getprop disabled_Test
  return false -- true, "delete"
end disabled_Test


--> Global | Wiki | Lineup | Line | Menu
-
on menu_Test displayView, abc
   put displayView & CR & abc
end menu_Test

on menu_TestChecked
  put menu_GetChecked (the params)
end menu_TestChecked

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
