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

getprop disabled_DisplayLoadedWikiEcoData
   put ecoData_Get() into ecoData
   return ecoData is not an array
end disabled_DisplayLoadedWikiEcoData


--> Global | Wiki | Server | Menu
-
on menu_DisplayCaddyTools
   display_CaddyTools
end menu_DisplayCaddyTools

private on _
end _

on submenu_SimpleServer
   return "Global | Wiki | Server | Simple | Menu"
end submenu_SimpleServer

on submenu_Data
   return "Global | Wiki | Server | Data | Menu"
end submenu_Data

private on __
end __

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

private on ___
end ___

on submenu_InstallWiki
   return "Global | Wiki | Install | Menu"
end submenu_InstallWiki

private on ____
end ____

on menu_CloseOpenSockets
   socket_CloseOpen
end menu_CloseOpenSockets

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Server | Menu")
end submenu_Dev
