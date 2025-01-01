script "Global | Local | Wiki | Domains | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Local | Wiki | Domains | Menu
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
   put the display_View of tObject into LocalArray ["dView"]
   put the displayed_Object of tObject into sObject
   return sObject
end menu_Target

private function _dView
   return LocalArray ["dView"]
end _dView

getprop menu_CheckTarget [dView]
   return exists (dView)
end menu_CheckTarget


--> Global | Local | Wiki | Domains | Menu
-
on menu_LocalWikiDomains dView
   put the title_Text of dView into tldDomain
   -- put url_GetTLD (tldDomain) into tldDomain
   --
   -- put wikiFarm_ListSubdomains (tldDomain)
   put wikiDomain_List (tldDomain, true) into localSubDomains
   set the displayed_Index of dView to localSubDomains
end menu_LocalWikiDomains

private on _
end _

on menu_AddSubdomainsToPihole dView
   put the selected_Line of dView into subDomain
   put url_GetTLD (subDomain) into topWikiDomain
   --
   -- pihole_AddSubDomains topWikiDomain
   breakpoint
   pihole_AddCustomSubDomain subDomain, topWikiDomain
   --
   lcw_Answer "Added all subdomains to Pihole!", dView
end menu_AddSubdomainsToPihole

private on __
end __

on menu_DisplayPiholeAdmin
   display_PiholeAdmin
end menu_DisplayPiholeAdmin

on submenu_Dev
   return menu_DevTitle ("Global | Local | Wiki | Domains | Menu")
end submenu_Dev
