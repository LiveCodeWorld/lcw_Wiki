script "Global | Wiki | Local | Data | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Local | Data | Menu
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


--> Global | Wiki | Local | Data | Menu
-
on menu_AddDomains dView
   _DeconstructTitle dView, tldDomian, tldLocalHostName
   put the displayed_Array of dView into wikiLocalData
   put the keys of wikiLocalData [tldLocalHostName] into subDomains
   --
   wikipi_AddDomains tldDomian, tldLocalHostName, subDomains
end menu_AddDomains

private on _
end _

on menu_DisplayOwnerJson dView
   _DeconstructTitle dView, wikiDomain, pPiLocalHost
   display_WikiPiOwner wikiDomain, pPiLocalHost
end menu_DisplayOwnerJson

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Local | Data | Menu")
end submenu_Dev
