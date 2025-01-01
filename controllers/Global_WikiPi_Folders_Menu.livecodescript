script "Global | WikiPi | Folders | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | WikiPi | Folders | Menu
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

private command _DeconstructTitle dView, @tldDomian, @tldLocalHostName
   get the title_Text of dView
   set the itemdelimiter to "@"
   put item 1 of it into tldDomian
   put item 2 of it into tldLocalHostName
end _DeconstructTitle


--> Global | WikiPi | Folders | Menu
-
on menu_AddPiDomains dView
   _DeconstructTitle dView, wikiDomian, piHost
   put url_GetTLD (wikiDomian) into tldDomain
   lcw_Answer "Add domain and subdomains of '[[tldDomain]]' to '[[piHost]]'?", dView, tldDomain, piHost
   --
   put the displayed_Index of dView into subDomains
   line_Delete tldDomain, subDomains
   --
   wikipi_AddDomains tldDomain, piHost, subDomains
   --
   -- menu_Refresh dView
   display_PiholeSubdomains tldDomain
end menu_AddPiDomains

private on _
end _

on menu_FilterDisplayed dView
   _DeconstructTitle dView, wikiDomian, piHost
   --
   put the displayed_Index of dView into wikiFolders
   put lcw_Ask ("Filter displayed wiki-folders...", "*livecode.world", dView) into sFilter
   filter wikiFolders with sFilter into filteredFolders
   --
   put sFilter & "@" & piHost into newTitle
   set the displayed_Index [newTitle] of dView to filteredFolders
end menu_FilterDisplayed

on menu_AllWikiFolders dView
   _DeconstructTitle dView, wikiDomian, piHost
   --
   display_WikiPiShortFolders piHost
end menu_AllWikiFolders

on menu_TopLevelFolders dView
   _DeconstructTitle dView, wikiDomian, piHost
   --
   display_WikiPiShortFolders piHost, "TLD"
end menu_TopLevelFolders

on menu_Refresh dView
   _DeconstructTitle dView, tldDomian, piLocalHostName
   display_WikiPiShortFolders piLocalHostName, tldDomian
end menu_Refresh

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | WikiPi | Folders | Menu")
end submenu_Dev
