script "Global | PageArray | Line | Menu"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: Global | PageArray | Line | Menu
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
   pass menu_Target
end menu_Target

getprop menu_CheckTarget [mTarget]
   -- use to do initialisation
   pass menu_CheckTarget
end menu_CheckTarget

getprop menu_CheckTarget [displayView]
  return true
end menu_CheckTarget

getprop checked_TestChecked
   return true
end checked_TestChecked

getprop disabled_Test
  return false -- true, "delete"
end disabled_Test


--> Global | PageArray | Line | Menu
-
on menu_CheckDate
   put displayView & CR & abc
end menu_CheckDate

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
