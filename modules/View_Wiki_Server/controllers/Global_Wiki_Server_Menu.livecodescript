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
   put wikiGarden_GetEcoData() into ecoData
   return ecoData is not an array
end disabled_DisplayLoadedWikiEcoData


--> Global | Wiki | Server | Menu
-
on menu_SetWikiFarmFolder
   put wikiFarm_EarthFolder() into rootFolder
   answer folder "Choose a default folder for wiki..." with rootFolder as sheet
   if it is empty then exit to top
   put it into newFarmFolder
   
   wikiFarm_SetFolder newFarmFolder
   wikiGarden_StoreCachedEcoData
   --
   display_GardenEcodata
   finder_Reveal newRootFolder
end menu_SetWikiFarmFolder

on menu_AddGardenEcoFolder
   put wikiFarm_EarthFolder() into rootFolder
   answer folder "Choose a Garden eco-folder for your Gardens..." with rootFolder as sheet
   if it is empty then exit to top
   put it into ecoFolder
   
   wikiGarden_AddEcoFolder ecoFolder
   --
   display_GardenEcodata
   finder_Reveal ecoFolder
end menu_AddGardenEcoFolder

private on _
end _

on menu_UpdateGardenEcoData
   wikiGarden_UpdateEcoData
   --
   display_GardenEcodata
end menu_UpdateGardenEcoData

on menu_ReloadWikiEcoData
   wikiGarden_Init
   --
   menu_DisplayLoadedWikiEcoData
end menu_ReloadWikiEcoData

on menu_DisplayGardenEcoData
   display_GardenEcodata
end menu_DisplayGardenEcoData

on menu_DisplayLoadedWikiEcoData
   put wikiGarden_GetEcoData() into ecoData
   display_GardenEcodata ecoData
end menu_DisplayLoadedWikiEcoData

private on __
end __

on menu_DisplayWikiRouterArray
   display_WikiRouterArray
end menu_DisplayWikiRouterArray

on menu_DisplayGardenDomainData
   put wikiGarden_GetDomainData() into gardenDomainData
   --
   display_Data gardenDomainData, "wikiGarden_GetDomainData()", "Wiki Garden"
end menu_DisplayGardenDomainData

private on ___
end ___

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

private on ____
end ____

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

private on _____
end _____

on submenu_InstallWiki
   return "Global | Wiki | Install | Menu"
end submenu_InstallWiki

private on ______
end ______

on menu_CloseOpenSockets
   socket_CloseOpen
end menu_CloseOpenSockets

on menu_DisplayStaticTemplate
   put wikiClient_GetStaticHtml() into htmlTemplate
   display_Text htmlTemplate, "static.html", "Wiki Server File"
   put the result into wsView
   display_SetMenu wsView, "Global | Wiki | Default | Static | Menu", "title_Menu", "lcw_Wiki"
end menu_DisplayStaticTemplate

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Server | Menu")
end submenu_Dev
