﻿script "Global | Wiki | Server | Menu"
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

private function _DaemonIsRunning
   -- put the daemon_IsRunning of wikiView into sBoolean
   put wikiServer_NodeIsRunning() is false into sBoolean
   return sBoolean
end _DaemonIsRunning

getprop checked_SetLogging
   get the behavior of stack "behavior_WikiRouter"
   put it is not empty into isLogging
   return isLogging
end checked_SetLogging

getprop checked_StartWiki [wikiView]
   put _DaemonIsRunning (wikiView) into sBoolean
   return sBoolean is false
end checked_StartWiki


--> Global | Wiki | Server | Menu
-
-- on menu_StartWiki
if _DaemonIsRunning (wsView) is true then
   set the daemon_IsRunning of wsView to false
   wikiServer_StartNode
else
   wikiServer_StopNode
   set the daemon_IsRunning of wsView to true
end if
end menu_StartWiki

on menu_CloseOpenSockets
   socket_CloseOpen
end menu_CloseOpenSockets

private on _
end _

on menu_LaunchEtcHosts
   launch_EtcHosts
   if the shiftKey is "Down" then
      display_EtcHosts
   end if
end menu_LaunchEtcHosts

on menu_UpdateEtcHosts
   put hosts_NewText (localHosts) into hostsText
   -- hosts_Set hostsText
   display_Text hostsText, "/etc/hosts"
end menu_UpdateEtcHosts

on menu_DisplayLog
   display_ViewTemplate "View|Wiki|Server"
end menu_DisplayLog

private on __
end __

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

on menu_DisplayWikiEcoData
   display_WikiEcoData
end menu_DisplayWikiEcoData

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

on submenu_InstallWiki
   return "Global | Wiki | Install | Menu"
end submenu_InstallWiki

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Server | Menu")
end submenu_Dev