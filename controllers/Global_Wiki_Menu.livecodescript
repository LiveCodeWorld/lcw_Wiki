script "Global | Wiki | Menu"
--> MetaData
-
license: GPLv3
name: Global | Wiki | Menu
type: controller
version: 0.5


--> Menu | Props
-
local LocalArray

getprop menu_Target [tObject]   
   put the browser_View of tObject into browserView
   if exists (browserView) then
      return browserView
   else
      put line 1 of display_List ("View|Obeya|Studio") into browserView
      if exists (browserView) then return browserView
      return empty
   end if
end menu_Target

getprop checked_ToggleEtcHosts
   return hosts_IsMinimal()
end checked_ToggleEtcHosts

getprop disabled_ToggleProxyFarm
   return "lib_Caddy" is not among the lines of the stacksinuse
end disabled_ToggleProxyFarm

getprop checked_ToggleProxyFarm
   if "lib_Caddy" is among the lines of the stacksinuse then
      return wikiServer_ProxyFarmIsRunning()
   else
      return false
   end if
end checked_ToggleProxyFarm

getprop checked_ToggleNodeServer
   return wikiServer_NodeIsRunning()
end checked_ToggleNodeServer

getprop checked_ToggleNodeFarm
   return wikiServer_NodeIsRunning()
end checked_ToggleNodeFarm

getprop checked_ToggleNodeFarm
   return wikiServer_NodeIsRunning()
end checked_ToggleNodeFarm

getprop checked_ToggleLiveServer
   return wikiServer_OnlyIsRunning()
end checked_ToggleLiveServer


--> Global | Wiki | Menu
-
on menu_ToggleEtcHosts
   hosts_ToggleEmpty
end menu_ToggleEtcHosts

on menu_ToggleNodeServer wikiView
   if wikiServer_NodeIsRunning() then
      wikiServer_StopNode
   else
      wikiServer_StartNode
      display_Wiki "localhost"
   end if
end menu_ToggleNodeServer

on menu_ToggleNodeFarm
   toggleServer_Node
end menu_ToggleNodeFarm

on menu_ToggleProxyFarm
   toggle_ProxyFarm
end menu_ToggleProxyFarm

on menu_ToggleLiveServer
   toggleServer_LiveOnly
end menu_ToggleLiveServer

private on _
end _

on menu_DisplayEtcHosts
   display_EtcHosts
end menu_DisplayEtcHosts

on menu_DisplayPiholeTools
   display_PiholeTools
end menu_DisplayPiholeTools

on menu_DisplayGardens
   display_WikiGardens
end menu_DisplayGardens

on menu_DisplayWikiFarm
   display_WikiFarm
end menu_DisplayWikiFarm

private on __
end __

on menu_DisplayThought dView
   display_LocalWikis dView, "Local Thought Domains", "*thought*"
end menu_DisplayThought

on menu_DisplayCaddyTools
   display_CaddyTools
end menu_DisplayCaddyTools

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Menu")
end submenu_Dev

