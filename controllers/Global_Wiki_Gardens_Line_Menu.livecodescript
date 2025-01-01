script "Global | Wiki | Gardens | Line | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Gardens | Line | Menu
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

on mDoubleUp_WikiGardens displayView, gardenName
   if gardenName = "Farm" then
      display_WikiFarm
   else
      display_WikiGarden gardenName
   end if
end mDoubleUp_WikiGardens


--> Global | Wiki | Gardens | Line | Menu
-
on menu_WikiGardensLine dView
   put the params
end menu_WikiGardensLine

private on _
end _

on menu_DisplaySubdomains dView
   put the selected_Line of dView into wikiDomain
   put wikiDomain_SubList (wikiDomain) into subDomains
   put wikiDomain_List (pFilter) into wikiFolders
   
end menu_DisplaySubdomains

on menu_WikiAndSubdomains dView
   put the selected_Line of dView into wikiDomain
   display_LocalWikiDomains wikiDomain
end menu_WikiAndSubdomains

on menu_AddSubdomainsToPihole dView
   breakpoint
   put the selected_Line of dView into wikiDomain
   put wikiDomain_SubList (wikiDomain) into subDomains
   --
   put pihole_ListCNAMEs() into piHoleCNAMEs
   
   set the wholematches to true
   repeat for each line subDomainName in subDomains
      set the cursor to busy
      wait 30 ticks
      if subDomainName is not among the lines of piHoleCNAMEs then
         pihole_AddCustomSubDomain subDomainName, wikiDomain
      else
         -- breakpoint
      end if
   end repeat
   
   lcw_Answer "Added all subdomains to Pihole!", dView
end menu_AddSubdomainsToPihole

private on _
end _

on menu_Refresh dView
   put the title_Text of dView = "Top Level Domains" into isTopLevel
   display_WikiFarm isTopLevel, dView
end menu_Refresh

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Gardens | Line | Menu")
end submenu_Dev
