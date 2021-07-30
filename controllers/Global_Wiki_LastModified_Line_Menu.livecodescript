script "Global | Wiki | LastModified | Line | Menu"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: Global | Wiki | LastModified | Line | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray


--> Menu | Init
-
on menu_Init tObject   
   -- do something when the menu first loads
   
   put the display_View of tObject into displayView
   --
   put the data_Array of displayView into LocalArray ["dataArray"]
end menu_Init

function _SelectedWikiDomain displayView
   put item 2 of the selected_Path of displayView into wikiDomain
   return wikiDomain
end _SelectedWikiDomain


--> Global | Wiki | LastModified | Line | Menu
-
on menu_CheckTree displayView
   put _SelectedWikiDomain (displayView) into wikiDomain
   --
   put fedwiki_GetlastModified (wikiDomain) into sitemapLastModified
   put atopia_GetWikiLastModified (wikiDomain) into treeLastModified
end menu_CheckTree

on _
end _

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Dev | Menu
-
on menu_Experiment displayView
   put displayView
end menu_Experiment


--> Deps
-
