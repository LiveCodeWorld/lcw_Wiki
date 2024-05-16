script "Global | Wiki | Browser | Server | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Browser | Server | Menu
type: controller
version: 0.2

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

getprop checked_StartServer
   return wikiServer_IsRunning()
end checked_StartServer

getprop checked_UseNodeServer
   return wikiServer_NodeIsRunning()
end checked_UseNodeServer

getprop port_Param [wsView]
   put the listen_Port of wsView into sPort
   -- put wiki_GetPort() into sPort
   
   if sPort is empty then
      return 80
   else
      return sPort
   end if
end port_Param

getprop port_Params
   return "3000,8080,9090,-,80"
end port_Params

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

private command _RefreshMenu wikiView
   put the menubar_View of wikiView into mGroup
   --
   put the live_Menu of mGroup into isLive
   if isLive is false then
      set the menuButton_Refresh of mGroup to "Server"
   end if
end _RefreshMenu


--> Global | Wiki | Browser | Server | Menu
-
on menu_StartServer.5 wikiView
   wikiServer_Toggle wikiView
   --
   _RefreshMenu wikiView
end menu_StartServer.5

on menu_UseNodeServer.4 wikiView
   if wikiServer_NodeIsRunning() then
      wikiServer_StopNode
   else
      wikiServer_Stop
      wikiServer_StartNode
   end if
   --
   _RefreshMenu wikiView
end menu_UseNodeServer.4

on menu_StopServer.8 wikiView
   if wikiServer_NodeIsRunning() then
      wikiServer_StopNode
   else
      wikiServer_Stop
   end if
   --
   _RefreshMenu wikiView
end menu_StopServer.8

private on _
end _

on menu_Port wikiView, sPort
   put the menubar_View of wikiView into mGroup
   --
   -- wiki_SetPort sPort
   set the listen_Port of mGroup to sPort
   --
   _RefreshMenu wikiView
end menu_Port

on menu_SecurityType wikiView, securityType
   wikiServer_SetSecurityType securityType
   --
   _RefreshMenu wikiView
end menu_SecurityType

private on __
end __

on menu_DisplayXterm
   wikiServer_StartWithXterm
end menu_DisplayXterm

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
   --
   _RefreshMenu wikiView
end menu_SetLogging

on submenu_ServerTools
   return "Global | Wiki | Server | Menu"
end submenu_ServerTools

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Browser | Server | Menu")
end submenu_Dev
