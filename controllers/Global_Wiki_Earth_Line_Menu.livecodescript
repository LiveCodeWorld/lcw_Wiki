script "Global | Wiki | Earth | Line | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Earth | Line | Menu
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
   -- return display_MenuTarget(tObject)
   return the display_View of tObject
end menu_Target

getprop menu_CheckTarget [cameraView]
   return exists (cameraView)
end menu_CheckTarget


--> Global | Wiki | Earth | Line | Menu
-
on menu_RegisterLocalXpose displayView
   breakpoint
   set the itemdelimiter to "."
   put the selected_Line of displayView into gitWikiDomain
   put item -2 to -1 of gitWikiDomain into tlDomain
   --
   tunnel_ReserveLocalDomain tlDomain, "eu"
   put the result into mainTunnel
   --
   put "*." & tlDomain into starDomain
   tunnel_ReserveLocalDomain starDomain, "eu"
   put the result into subTunnel
   --
   dynadot_SetMainDomain tlDomain, mainTunnel
   dynadot_AddSubdomain tlDomain, "*", subTunnel
   
   -- gitwiki_CreateSymLink tlDomain, tlDomain
   --
   display_EarthWikis
   diplay_GitWikiFolders
end menu_RegisterLocalXpose

on menu_CreateTunnel displayView
   put the selected_Line of displayView into sDomain
   tunnel_Create sDomain
end menu_CreateTunnel

private on _
end _

on menu_MenuEdit displayView
   menu_Edit "Global | Wiki | Earth | Line | Menu"
end menu_MenuEdit

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Earth | Line | Menu")
end submenu_Dev

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Earth | Line | Menu")
end submenu_Dev
