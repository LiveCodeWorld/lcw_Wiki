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
   put url_GetTLD (wikiDomian) into tldDomian
   lcw_Answer "Add domain and subdomains of '[[tldDomian]]' to '[[piHost]]'?", dView, tldDomian, piHost
   put the displayed_Index of dView into subDomains
   --
   wikipi_AddDomains tldDomian, pPiHost, pSubDomains
   --
   menu_Refresh dView
end menu_AddPiDomains

private on _
end _

on menu_Refresh dView
   _DeconstructTitle dView, tldDomian, piLocalHostName
   display_WikiPiShortFolders piLocalHostName, tldDomian
end menu_Refresh

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | WikiPi | Folders | Menu")
end submenu_Dev
