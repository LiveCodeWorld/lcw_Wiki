script "Global | Tunnel | Install | Menu"
--> MetaData
-
license: GPLv3
name: Global | Tunnel | Install | Menu
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


--> Global | Tunnel | Install | Menu
-
on menu_ReserveLocalDomain dView
   put xterm_FindView() into xtermView
   put "eu" into sRegion
   put LocalArray ["sDomain"] into sDomain
   if sDomain is empty then put "www.astralship.wiki" into sDomain
   --
   put lcw_Ask ("Domin name to reserve...", sDomain, "LocalExpose", xtermView) into sDomain
   put sDomain into LocalArray ["sDomain"]
   put merge ("loclx domain reserve --domain [[sDomain]] --region [[sRegion]]") into someShell
   --
   shell_Do someShell, "paste", xtermView
end menu_ReserveLocalDomain

on menu_CreateWildCardDomain
   put xterm_FindView() into xtermView
   put LocalArray ["sDomain"] into sDomain
   put "*." & sDomain into wDomain
   put lcw_Ask ("Enter wild card domain...", wDomain, "LocalExpose", xtermView) into wDomain
   --
   put merge ("loclx domain reserve --domain '[[wDomain]]'") into someShell
   replace "'" with quote in someShell
   --
   shell_Do someShell, "paste", xtermView
end menu_CreateWildCardDomain

private on _
end _

on menu_VerifyCname
   put xterm_FindView() into xtermView
   put LocalArray ["sDomain"] into sDomain
   put lcw_Ask ("Domin name to verify...", sDomain, "LocalExpose", xtermView) into sDomain
   put "loclx domain status --domain" && sDomain into someShell
   --
   shell_Do someShell, "paste", xtermView
end menu_VerifyCname

private on __
end __

on menu_InitTunnelConfig
   put the model_Folder of stack "lib_Tunnel" into serverModelFolder
   put the defaultFolder into oDefaultFolder
   set the defaultfolder to serverModelFolder
   --
   put shell ("loclx tunnel config init") into sResult
   put word -1 of sResult into yamlFile
   if there is a file yamlFile then
      tunnel_SetYamlFile yamlFile
   else 
      breakpoint
   end if
   --
   set the defaultfolder to oDefaultFolder
   put sResult
end menu_InitTunnelConfig

on menu_EditTunnelConfig
   launch_TunnelConfig
end menu_EditTunnelConfig

on menu_ConstructTunnelConfig
   put tunnel_ConstructAstralConfig ("*.astralship.wiki") into sYaml
   tunnel_SetYaml sYaml
   --
   menu_EditTunnelConfig
end menu_ConstructTunnelConfig

on menu_XtermTunnelWithConfig xtermView
   put tunnel_GetYamlFile() into yamlFile
   --
   put the model_Folder of stack "lib_Tunnel" into serverModelFolder
   put the defaultFolder into oDefaultFolder
   set the defaultfolder to serverModelFolder
   --
   put "cd" && kwote (serverModelFolder) into someShell
   shell_Do someShell, "execute", xtermView
   --
   put "loclx tunnel config -f" && kwote (yamlFile) into someShell
   shell_Do someShell, "paste", xtermView
   ---
   set the defaultfolder to oDefaultFolder
end menu_XtermTunnelWithConfig

private on ___
end ___

on menu_InstallLocalTunnel xtermView
   -- put shell ("npm install -g localtunnel")
   display_Xterm xtermView
   put the result into xtermView
   --
   ttyd_Paste "npm install -g localtunnel", xtermView
end menu_InstallLocalTunnel

on menu_SetLocalTunnel xtermView
   put lcw_Ask ("What subdomain would you like to use?", "astral", "LocalTunnel", xtermView) into subDomain
   put merge ("lt --port 80 --subdomain [[subDomain]]") into someShell
   --
   ttyd_Paste someShell, xtermView
end menu_SetLocalTunnel

on submenu_Dev
   return menu_DevTitle ("Global | Tunnel | Install | Menu")
end submenu_Dev
