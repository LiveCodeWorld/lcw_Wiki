script "Global | Wiki | Owner | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Owner | Menu
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

getprop menu_CheckTarget [dView]
   return exists (dView)
end menu_CheckTarget


--> Global | Wiki | Owner | Menu
-
on menu_DisplayFrinedlyDefault dView
   put wikiServer_FriendlyOwnerData() into ownerData
   set the displayed_Data of dView to ownerData
end menu_DisplayFrinedlyDefault

on menu_SetFriendlyDefault dView
   put the title_Text of dView into wikiDomain
   --
   wikiServer_SetFriendlyData wikiDomain
   --
   lcw_Answer "Set owner.json", dView, pQVar
end menu_SetFriendlyDefault

private on _
end _

on menu_ExportDisplayOwnerData dView
   put the title_Text of dView into wikiDomain
   --
   breakpoint
   put the displayed_Data of dView into ownerData
   wikiServer_SetOwnerData wikiDomain, ownerData
end menu_ExportDisplayOwnerData

on menu_Refresh dView
   put the title_Text of dView into wikiDomain
   --
   display_WikiOwner wikiDomain, dView
end menu_Refresh

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Owner | Menu")
end submenu_Dev
