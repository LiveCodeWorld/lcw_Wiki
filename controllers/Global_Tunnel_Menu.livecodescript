script "Global | Tunnel | Menu"
--> MetaData
-
license: GPLv3
name: Global | Tunnel | Menu
type: controller
author: David Bovill
version: 0.1

/*
Here you can describe this menu.
Full help text should be provided on the linked wiki.
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

getprop menu_CheckTarget [cameraView]
   return exists (cameraView)
end menu_CheckTarget

getprop checked_Login
   get shell ("loclx account status")
   put line 2 of it into errorLine -- fragile
   -- Error: you are not logged in, please login using your access token 
   put word 1 of errorLine = "Error:" into isError
   return isError is false
end checked_Login

-- getprop reservedTunnel_Params
put tunnel_ListDomains() into tunnelDomains
return tunnelDomains
end reservedTunnel_Params

getprop checked_TunnelWithConfig [xtermView]
   return tunnel_IsActive()
end checked_TunnelWithConfig


--> Global | Tunnel | Menu
-
on menu_TunnelWithConfig xtermView
   if tunnel_IsActive() is true then
      tunnel_Kill
   else
      tunnel_LaunchFromConfig
   end if
end menu_TunnelWithConfig

on menu_CreateLocalTunnel
   put xterm_FindView() into xtermView
   put LocalArray ["sDomain"] into sDomain
   set the itemdelimiter to "."
   if item 1 of sDomain = "www" then
      delete item 1 of sDomain
      put sDomain into LocalArray ["sDomain"]
   end if
   put "*." & sDomain into wDomain
   put lcw_Ask ("Create wild card tunnel...", wDomain, "LocalExpose", xtermView) into sDomain
   --
   tunnel_Create sDomain, "paste", xtermView
end menu_CreateLocalTunnel

private on _
end _

on menu_EditTunnelConfig
   launch_TunnelConfig
end menu_EditTunnelConfig

on menu_ReservedTunnels dView
   display_ReservedTunnels
end menu_ReservedTunnels

on menu_Login dView
   put line 2 of shell ("loclx account status") into errorLine -- fragile
   if errorLine begins with "Error: you are not logged in, please login using your access token" then
      
   else
      put word 1 of errorLine = "Error:" into isError
      breakpoint
   end if   
end menu_Login

on submenu_Tunnel
   return "Global | Tunnel | Install | Menu"
end submenu_Tunnel

on submenu_Dev
   return menu_DevTitle ("Global | Tunnel | Menu")
end submenu_Dev
