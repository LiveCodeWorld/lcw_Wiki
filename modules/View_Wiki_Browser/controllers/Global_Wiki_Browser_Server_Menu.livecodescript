script "Global | Wiki | Browser | Server | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Browser | Server | Menu
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

getprop checked_StartServer
   return wikiServer_IsRunning()
end checked_StartServer

getprop checked_UseNodeServer
   return wikiServer_NodeIsRunning()
end checked_UseNodeServer


--> Global | Wiki | Browser | Server | Menu
-
on menu_StartServer.0 wikiView
   if wikiServer_IsRunning() is true then
      wikiServer_Stop
   else
      wikiServer_StopNode
      wikiServer_Start
   end if
end menu_StartServer.0

on menu_UseNodeServer.9
   if wikiServer_NodeIsRunning() then
      wikiServer_StopNode
   else
      wikiServer_Stop
      wikiServer_StartNode
   end if
end menu_UseNodeServer.9

on menu_StartWikiWithXterm
   wikiServer_StartWithXterm
end menu_StartWikiWithXterm

private on _
end _

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
   return "friends,cookie,passport,-,legacy"
end securityType_Params

getprop securityType_Param [wikiView]
   return wikiServer_GetSecurityType()
end securityType_Param

on menu_Port wsView, sPort
   -- wiki_SetPort sPort
   set the listen_Port of wsView to sPort
end menu_Port

on menu_SecurityType wikiView, securityType
   wikiServer_SetSecurityType securityType
end menu_SecurityType

private on __
end __

on submenu_ServerTools
   return "Global | Wiki | Server | Menu"
end submenu_ServerTools

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Browser | Server | Menu")
end submenu_Dev
