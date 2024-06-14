script "Global | Wiki | Browser | Edit | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Browser | Edit | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray


--> Menu | Props
-
getprop menu_CheckTarget [wikiView]
   return true
end menu_CheckTarget


--> Global | Wiki | Browser | Edit | Menu
-
on menu_StackInspector wikiView
   put the stack_Object of wikiView into sObject
   display_ObjectProperties sObject
end menu_StackInspector

private on _
end _

on insert_Edit
   return "Global | Menu | Group | Edit | Menu"
end insert_Edit

private on __
end __

on menu_OpenTemplate wikiView
   put the template_Object of wikiView into tObject
   object_GoTo tObject, true
end menu_OpenTemplate

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Browser | Edit | Menu")
end submenu_Dev
