script "Global | Wiki | Browser | Server | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Browser | Server | Menu
type: controller
version: 0.3

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray


--> Menu | Props
-
getprop menu_CheckTarget [wikiView]
   return exists (wikiView)
end menu_CheckTarget

getprop checked_LiveServer
   return wikiServer_IsRunning()
end checked_LiveServer

getprop checked_NodeServer
   return wikiServer_NodeIsRunning()
end checked_NodeServer

getprop securityType_Params
   return wikiServer_ListSecurityTypes(true)
end securityType_Params

getprop securityType_Param [wikiView]
   return wikiServer_GetSecurityType()
end securityType_Param

getprop checked_SetLogging
   get the behavior of stack "behavior_WikiRouter"
   put it is not empty into isLogging
   return isLogging
end checked_SetLogging

getprop checked_AddOwnerJson [wikiView]
   put the wiki_Domain of wikiView into wikiDomain
   return wikiServer_OwnerExists (wikiDomain)
end checked_AddOwnerJson

getprop disabled_AddOwnerJson [wikiView]
   put the wiki_Domain of wikiView into wikiDomain
   switch wikiDomain
      case "localhost"
         return "delete"
      default
         return false
   end switch
end disabled_AddOwnerJson


--> Global | Wiki | Browser | Server | Menu
-
on menu_ToggleProxyFarm.4
   toggle_ProxyFarm
end menu_ToggleProxyFarm.4

getprop checked_ToggleProxyFarm
   return wikiServer_ProxyFarmIsRunning()
end checked_ToggleProxyFarm

on menu_ToggleLiveServer.L
   toggleServer_LiveOnly
end menu_ToggleLiveServer.L

getprop checked_ToggleLiveServer
   return wikiServer_OnlyIsRunning()
end checked_ToggleLiveServer

-- on menu_SwitchServers
   toggleServer_BetweenLiveAndNode
end menu_SwitchServers

-- on menu_StartLiveServer
   wikiServer_StartLocalProxy
end menu_StartLiveServer

private on _____
end _____

on menu_LiveServer
   toggleServer_Live
end menu_LiveServer

on menu_NodeServer wikiView
   toggleServer_Node
end menu_NodeServer

on menu_StartCaddy
   toggleServer_Caddy
end menu_StartCaddy

getprop checked_StartCaddy
   return caddy_IsRunning()
end checked_StartCaddy

private on _
end _

on menu_NodePort wikiView, sPort
   wikiServer_SetNodePort sPort
   
   put the menubar_View of wikiView into mGroup
   -- get the listen_Port of mGroup
   -- set the listen_Port of mGroup to sPort
end menu_NodePort

getprop nodeport_Param [wikiView]
   -- put the listen_Port of wsView into sPort
   -- put wiki_GetPort() into sPort
   put wikiServer_GetNodePort() into sPort
   
   if sPort is empty then
      return 80
   else
      return sPort
   end if
end nodeport_Param

getprop nodeport_Params
   return "3000,8080,9090,-,80"
end nodeport_Params

on menu_SecurityType wikiView, securityType
   wikiServer_SetSecurityType securityType
end menu_SecurityType

private on __
end __

on submenu_Caddy
   return "Global | Caddy | Menu"
end submenu_Caddy

on submenu_SimpleServer
   return "Global | Wiki | Server | Simple | Menu"
end submenu_SimpleServer

on menu_DisplayCaddyTools
   display_CaddyTools
end menu_DisplayCaddyTools

on menu_DisplayXterm
   wikiServer_StartWithXterm
end menu_DisplayXterm

private on ___
end ___

on menu_SetWikiFarmFolder
   put wikiFarm_EarthFolder() into rootFolder
   answer folder "Choose a default folder for wiki..." with rootFolder as sheet
   if it is empty then exit to top
   put it into newFarmFolder
   
   wikiFarm_SetFolder newFarmFolder
   --
   breakpoint
   put ecoData_Get() into ecoData
   wikiGarden_SetModel ecoData
   --
   display_GardenEcodata
   finder_Reveal newFarmFolder
end menu_SetWikiFarmFolder

private on ____
end ____

on menu_AddOwnerJson wikiView
   put the wiki_Domain of wikiView into wikiDomain
   --
   if wikiServer_OwnerExists (wikiDomain) then
      display_WikiOwner wikiDomain
   else
      wikiServer_SetFriendlyData wikiDomain
   end if
end menu_AddOwnerJson

on menu_DisplayOwnerJson wikiView
   put the wiki_Domain of wikiView into wikiDomain
   --
   display_WikiOwner wikiDomain
end menu_DisplayOwnerJson

on submenu_ServerData
   return "Global | Wiki | Server | Menu"
end submenu_ServerData

on menu_DisplayServerLog
   display_ViewTemplate "View|Wiki|Server"
end menu_DisplayServerLog

on menu_SetLogging wsView
   put the behavior of stack "behavior_WikiRouter" is not empty into isLogging
   if isLogging is true then
      set the behavior of stack "behavior_WikiRouter" to empty
   else
      put the name of stack "behavior_DaemonLog" into bObject
      set the behavior of stack "behavior_WikiRouter" to bObject
   end if
end menu_SetLogging

on menu_SetEcofolder
   wikiPreference_SetDefaultEcoFolder
   put the result into ecoFolder
end menu_SetEcofolder

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

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Browser | Server | Menu")
end submenu_Dev
