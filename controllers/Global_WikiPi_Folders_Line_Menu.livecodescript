script "Global | WikiPi | Folders | Line | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | WikiPi | Folders | Line | Menu
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

on mDoubleUp_WikiPiFolders dView, wikiDomain
   _DeconstructTitle dView, tldDomian, tldLocalHostName
   
   put pageJson_Get (wikiDomain) into pageJSON
   if pageJSON is empty then
      breakpoint
      display_WikiAndSubdomains tldDomian
      --
      display_PiholeSubdomains tldDomian
   else
      display_Wiki wikiDomain
   end if
end mDoubleUp_WikiPiFolders

private command _DeconstructTitle dView, @tldDomian, @tldLocalHostName
   get the title_Text of dView
   set the itemdelimiter to "@"
   put item 1 of it into tldDomian
   put item 2 of it into tldLocalHostName
end _DeconstructTitle


--> Global | WikiPi | Folders | Line | Menu
-
on menu_DisplayPageSlugs dView
   _DeconstructTitle dView, tldDomian, piLocalHostName
   put the selected_Line of dView into wikiDomain
   
   display_WikiPiSlugs piLocalHostName, wikiDomain
end menu_DisplayPageSlugs

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
   return menu_DevTitle ("Global | WikiPi | Folders | Line | Menu")
end submenu_Dev
