script "Global | Wiki | Local | Data | Line | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Local | Data | Line | Menu
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

command _SetSelected dView, @fromPi, @subDomain
   put the selected_Path of dView into sPath
   put item 1 of sPath into fromPi
   put item 2 of sPath into subDomain
   return sPath
end _SetSelected

on mDoubleUp_WikiLocalData dView, wikiDomain
   -- _DeconstructTitle dView, tldDomian, tldLocalHostName
   _SetSelected dView, fromPi, subDomain
   --
   put pihole_DomainToPiName (wikiDomain) into localHostName
   
   if localHostName = fromPi then
      display_WikiSiteMap wikiDomain
      display_Wiki wikiDomain
   else
      display_WikiPiShortFolders fromPi, wikiDomain
   end if
end mDoubleUp_WikiLocalData

private command _DeconstructTitle dView, @tldDomian, @tldLocalHostName
   get the title_Text of dView
   set the itemdelimiter to "@"
   put item 1 of it into tldDomian
   put item 2 of it into tldLocalHostName
end _DeconstructTitle


--> Global | Wiki | Local | Data | Line | Menu
-
on menu_SetPiDomains dView
   
end menu_SetPiDomains

getprop disabled_SetPiDomains [dView]
   put the selected_Path of dView into sPath
   if the number of items of sPath = 1 then
      return false
   else
      return "Delete"
   end if
end disabled_SetPiDomains

on menu_MoveWiki dView, toPi
   put the selected_Path of dView into sPath
   if the number of items of sPath = 1 then
      lcw_Answer "Move all wikis to [[var]]", dView, toPi
   else
      put item 1 of sPath into fromPi
      put item 2 of sPath into subDomain
      put url_GetTLD(subDomain) into tldDomain
      if subDomain = tldDomain then
         breakpoint
      else
         breakpoint
         pihole_DeleteCustomSubDomain subDomain, fromPi
         pihole_AddCustomSubDomain subDomain, toPi
         wikiCode_MoveFolder subDomain, fromPi, toPi
         --
      end if
   end if
end menu_MoveWiki

getprop disabled_MoveWiki [dView]
   put the selected_Path of dView into sPath
   if the number of items of sPath = 1 then
      return "Delete"
   else
      return false
   end if
end disabled_MoveWiki

getprop moveWiki_Params [dView]
   put the selected_Path of dView into sPath
   put item 1 of sPath into localName
   put pihole_ListLocalNames() into otherPis
   line_Delete localName, otherPis
   return otherPis
end moveWiki_Params

on menu_TrashWiki dView
   _SetSelected dView, fromPi, subDomain
   --
end menu_TrashWiki

private on _
end _

on menu_DisplayOwnerJson dView
   _SetSelected dView, fromPi, subDomain
   display_WikiPiOwner subDomain, fromPi
end menu_DisplayOwnerJson

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Local | Data | Line | Menu")
end submenu_Dev
