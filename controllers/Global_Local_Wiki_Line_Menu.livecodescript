script "Global | Local | Wiki | Line | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Local | Wiki | Line | Menu
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

on mDoubleUp_LocalWiki displayView, gardenName
   if gardenName = "Farm" then
      display_WikiFarm
   else
      display_WikiGarden gardenName
   end if
end mDoubleUp_LocalWiki


--> Global | Local | Wiki | Line | Menu
-
on menu_AddTopLevelDomain dView, piName
   put the selected_Line of dView into subDomain
   put url_GetTLD (subDomain) into topDomain
   put lcw_Ask ("What top-level domain would you like to add?", topDomain, dView) into domainName
   --
   pihole_AddDomaintoNamedPi domainName, piName
end menu_AddTopLevelDomain

getprop addTopLevelDomain_Params
   return pihole_ListNames()
end addTopLevelDomain_Params
      
private on _
end _

-- on menu_DisplaySubdomains dView
   put the selected_Line of dView into wikiDomain
   put wikiDomain_SubList (wikiDomain) into subDomains
   put wikiDomain_List (pFilter) into wikiFolders
   --
end menu_DisplaySubdomains

on menu_WikiAndSubdomains dView
   put the selected_Line of dView into wikiDomain
   display_LocalWikiDomains wikiDomain
end menu_WikiAndSubdomains

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

on menu_Refresh dView
   put the title_Text of dView = "Top Level Domains" into isTopLevel
   display_WikiFarm isTopLevel, dView
end menu_Refresh

private on ___
end ___

on submenu_Dev
   return menu_DevTitle ("Global | Local | Wiki | Line | Menu")
end submenu_Dev
