script "Global | Wiki | Server | Dev | Menu"
--> MetaData
-
license: GPLv3
name: Global | Wiki | Server | Dev | Menu
type: controller
author: David Bovill
version: 0.1

/*
Here you can describe this developer menu.
Full help text should be provided on the linked wiki.

Consider improving by creating with same menu_Target as no-developer menu is is based on.
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

getprop menu_CheckTarget [mTarget]
   return exists (mTarget)
end menu_CheckTarget


--> Global | Wiki | Server | Dev | Menu
-
on menu_ReloadPluginRouteData wsView
   dispatch "daemon_ClearPluginRouteData" to wsView
   dispatch "daemon_LoadPluginRouteData" to wsView
   --
   put the plugin_RouteData of wsView into PluginRouteData
   --
   display_Data PluginRouteData, "PluginRouteData", "Wiki Routing"
end menu_ReloadPluginRouteData

on menu_DisplaySocketData wsView
   put the socket_Data of wsView into sData
   display_Data  sData, "Socket Data"
end menu_DisplaySocketData

on menu_DisplayStaticTemplate
   put wikiClient_GetStaticHtml() into htmlTemplate
   display_Text htmlTemplate, "static.html", "Wiki Server File"
   put the result into wsView
   display_SetMenu wsView, "Global | Wiki | Default | Static | Menu", "title_Menu", "lcw_Wiki"
end menu_DisplayStaticTemplate

private on _
end _

on menu_EditMiddleware wsView
   edit the script of stack "behavior_DaemonMiddleware"
end menu_EditMiddleware

on menu_SetBehaviors wsView
   menu_ClearBehaviors wsView
   --
   put "behavior_ViewWikiServer,behavior_Daemon,behavior_DaemonMiddleware,behavior_WikiRouter,behavior_DaemonLog" into stackNames
   --
   set the behavior_StackNames of wsView to stackNames
   put the result
end menu_SetBehaviors

on menu_NoLoggingBehaviors wsView
   menu_ClearBehaviors wsView
   --
   put "behavior_ViewWikiServer,behavior_Daemon,behavior_DaemonMiddleware,behavior_WikiRouter" into stackNames
   --
   set the behavior_StackNames of wsView to stackNames
   put the result
end menu_NoLoggingBehaviors

on menu_ClearBehaviors wsView
   put "behavior_ViewWikiServer,behavior_Daemon,behavior_DaemonMiddleware,behavior_WikiRouter,behavior_DaemonLog" into stackNames
   --
   set the behavior_ClearNames of wsView to stackNames
end menu_ClearBehaviors

private on __
end __

on menu_MenuEdit displayView
   menu_Edit "Global | Wiki | Server | Dev | Menu"
end menu_MenuEdit
