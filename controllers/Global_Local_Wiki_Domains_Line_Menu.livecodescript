script "Global | Local | Wiki | Domains | Line | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Local | Wiki | Domains | Line | Menu
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

on mDoubleUp_LocalWikiDomains displayView, wikiDomain
   -- put the title_Text of displayView into topWikiDomain
   display_Wiki wikiDomain
end mDoubleUp_LocalWikiDomains


--> Global | Local | Wiki | Domains | Line | Menu
-
on menu_MoveWikiFolder
   put the selected_Line of dView into subDomain   
   breakpoint
   --
   codeArray_DoShell codeTemplate, paramArray
   put the result into shellResult
   if shellResult is not empty then
      put shellResult
      breakpoint
   end if
end menu_MoveWikiFolder

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

private on _
end _

on menu_Behavior dView
   put the behavior of dView into bObject
   edit the script of bObject
end menu_Behavior

on menu_ModuleTools dView
   put the view_Name of dView into viewName
   display_ModuleTools viewName
end menu_ModuleTools

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Local | Wiki | Domains | Line | Menu")
end submenu_Dev
