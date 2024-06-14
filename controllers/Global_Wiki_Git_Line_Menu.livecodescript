script "Global | Wiki | Git | Line | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Git | Line | Menu
type: controller
version: 0.2

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_Target [tObject]
   -- return display_MenuTarget(tObject)
   return the display_View of tObject
end menu_Target

getprop menu_CheckTarget [cameraView]
   return exists (cameraView)
end menu_CheckTarget

getprop disabled_TrashGitwikiFolder [dView]
   if the shiftKey is "down" then return false
   --
   put the selected_Line of dView into shortWikiFolder
   put gitwiki_GetFolder (shortWikiFolder) into gitWikiFolder
   return wikiFolder_HasNoPages (gitWikiFolder) is false
end disabled_TrashGitwikiFolder

-- getprop disabled_Register
return LocalArray ["disabled_Register"] is not false
end disabled_Register

private command _DisplayLocalWikis newName, dView
   put _GetFilter (newName) into sFilter
   put display_FindIndexView ("Local Wikis") into dView
   display_LocalWikis dView, sFilter, sFilter
end _DisplayLocalWikis

private function _GetFilter newName
   put newName into sFilter
   set the itemdelimiter to "."
   delete item 1 of sFilter
   put "*" before sFilter
   return sFilter
end _GetFilter


--> Global | Wiki | Git | Line | Menu
-
on menu_MoveToLocal dView
   put the selected_Line of dView into wikiDomain
   put lcw_Ask ("Rename wiki domain...", wikiDomain, "Rename", dView) into newName
   --
   gitwiki_MoveToLocal wikiDomain, true, newName
   --
   menu_Refresh
end menu_MoveToLocal

on menu_RemoveFromHosts dView
   put the selected_Line of dView into wikiDomain
   --
   hosts_Delete wikiDomain
end menu_RemoveFromHosts

private on _
end _

on menu_DisplayLocalhostWiki dView
   put the selected_Line of dView into wikiDomain
   put wiki_ConstructLocalHostDomain (wikiDomain) into localhostDomain
   display_LocalWiki localhostDomain
end menu_DisplayLocalhostWiki

private on __
end __

on menu_RevealGitwikiFolder dView
   put the selected_Line of dView into shortWikiFolder
   put gitwiki_GetFolder (shortWikiFolder) into gitWikiFolder
   --
   finder_Reveal gitWikiFolder
end menu_RevealGitwikiFolder

on menu_TrashGitwikiFolder dView
   put the selected_Line of dView into shortWikiFolder
   put gitwiki_GetFolder (shortWikiFolder) into gitWikiFolder
   --
   revDeleteFolder gitWikiFolder
   --
   set the deleted_Line of dView to shortWikiFolder
   if the displayed_Index of dView is empty then
      diplay_GitWikiFolders
   end if
end menu_TrashGitwikiFolder

private on __
end __

on submenu_Register
   return "Global | Wiki | Git | Line | Register | Menu"
end submenu_Register

on menu_Refresh
   put display_FindView ("Local Wikis") into dView
   if exists (dView) then
      put the wiki_Filter of dView into pFilter
   end if
   display_LocalWikis dView, pFilter, pFilter
   display_GitWikiFolders
end menu_Refresh

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Git | Line | Menu")
end submenu_Dev
