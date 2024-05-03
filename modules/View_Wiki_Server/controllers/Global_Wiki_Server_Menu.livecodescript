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
   -- put display_MenuTarget (tObject) into wsView
   put the display_View of tObject into wsView
   return wsView
end menu_Target

getprop menu_CheckTarget [wsView]
   return exists (wsView)
end menu_CheckTarget

getprop checked_SetLogging
   get the behavior of stack "behavior_WikiRouter"
   put it is not empty into isLogging
   return isLogging
end checked_SetLogging

getprop port_Param [wsView]
   put the daemon_Port of wsView into sPort
   if sPort is empty then
      return 80
   else
      return sPort
   end if
end port_Param

getprop port_Params
   return "3000,8080,9090,-,80"
end port_Params

getprop checked_StartWiki [wikiView]
   put _DaemonIsRunning (wikiView) into sBoolean
   return sBoolean is false
end checked_StartWiki

private function _DaemonIsRunning wikiView
   -- put the daemon_IsRunning of wikiView into sBoolean
   put wiki_NodeServerIsRunning() is false into sBoolean
   return sBoolean
end _DaemonIsRunning


--> Global | Wiki | Server | Menu
-
on menu_StartWiki wikiView   
   if _DaemonIsRunning (wikiView) is true then
      set the daemon_IsRunning of wikiView to false
      wiki_StartNodeServer
   else
      wiki_StopNodeServer
      set the daemon_IsRunning of wikiView to true
   end if
end menu_StartWiki

on menu_CloseOpenSockets
   socket_CloseOpen
end menu_CloseOpenSockets

on menu_Port wsView, sPort
   set the daemon_Port of wsView to sPort
end menu_Port
   
private on _
end _

on menu_DisplayStaticTemplate
   put wikiClient_GetStaticHtml() into htmlTemplate
   display_Text htmlTemplate, "static.html", "Wiki Server File"
   put the result into wsView
   display_SetMenu wsView, "Global | Wiki | Default | Static | Menu", "title_Menu", "lcw_Wiki"
end menu_DisplayStaticTemplate

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

private on __
end __

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

on menu_SetLogging wsView
   put the behavior of stack "behavior_WikiRouter" is not empty into isLogging
   if isLogging is true then
      set the behavior of stack "behavior_WikiRouter" to empty
   else
      put the name of stack "behavior_DaemonLog" into bObject
      set the behavior of stack "behavior_WikiRouter" to bObject
   end if
end menu_SetLogging

private on ___
end ___

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Server | Menu")
end submenu_Dev
