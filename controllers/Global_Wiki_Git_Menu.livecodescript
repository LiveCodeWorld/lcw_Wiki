script "Global | Wiki | Git | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Git | Menu
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
   -- return display_MenuTarget(tObject)
   return the display_View of tObject
end menu_Target

getprop menu_CheckTarget [cameraView]
   return exists (cameraView)
end menu_CheckTarget


--> Global | Wiki | Git | Menu
-
on menu_AddDisplayedSubdomains
   put the displayed_index of displayView
end menu_AddDisplayedSubdomains

on menu_Filter displayView
   put lcw_Ask ("Filter domains...", "*platform.earth", "Wiki Filter", displayView) into wikiFilter
   diplay_GitWikiFolders displayView, wikiFilter
end menu_Filter

private on _
end _

on menu_EmptyLocalWikis dView
   display_EmptyLocalWikis dView
end menu_EmptyLocalWikis

on menu_EmptyGitWikis dView
   put gitwiki_ListEmptyFolders (true) into emptyFolders
   display_GitWikis emptyFolders, dView, "none", "Empty Git Folders"
end menu_EmptyGitWikis

private on __
end __

on menu_Refresh dView
   diplay_GitWikiFolders
end menu_Refresh

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Git | Menu")
end submenu_Dev
