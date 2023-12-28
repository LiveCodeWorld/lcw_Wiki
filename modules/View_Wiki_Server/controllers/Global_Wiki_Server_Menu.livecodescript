script "Global | Wiki | Server | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Server | Menu
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


--> Global | Wiki | Server | Menu
-
on menu_WikiServer dView
   put the params
end menu_WikiServer

private on _
end _

on menu_DisplayStaticTemplate
   put wikiClient_GetStaticHtml() into htmlTemplate
   display_Text htmlTemplate, "static.html", "Wiki Server File"
   put the result into dView
   display_SetMenu dView, "Global | Wiki | Default | Static | Menu", "title_Menu", "lcw_Wiki"
end menu_DisplayStaticTemplate

on menu_SetBehaviors dView
   set the behavior_StackNames of dView to "behavior_ViewWikiServer,behavior_Daemon,behavior_DaemonMiddleware,behavior_WikiRouter,behavior_DaemonLog"
   put the result
end menu_SetBehaviors

on menu_ModuleTools dView
   put the view_Name of dView into viewName
   display_ModuleTools viewName
end menu_ModuleTools

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Server | Menu")
end submenu_Dev
