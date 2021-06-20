script "Global | Title | Wiki | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Title | Wiki | Menu
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
   put the view_Object of tObject into vObject
   return vObject
end menu_Target

getprop menu_CheckTarget [mTarget]
   -- use to do initialisation
   pass menu_CheckTarget
end menu_CheckTarget

getprop test_Param [displayView]
   return "b"
end test_Param

getprop test_Params [displayView]
   return "a,b,c"
end test_Params

getprop checked_TestChecked
   return true
end checked_TestChecked

getprop disabled_Test
   return false -- true, "delete"
end disabled_Test


--> Global | Title | Wiki | Menu
-
on menu_SetFlag titleView
   breakpoint
   put "thought.garden" into wikiDomain
   
   /*
   set the wiki_Domain of titleView to wikiDomain
   put the wiki_Domain of titleView into wikiDomain
   put the page_Slug of titleView into pageSlug
   --put fedwiki_FetchFavicon (wikiDomain) into someIMage
   */
   
   put fedwiki_FaviconURL (wikiDomain) into flagURL
   --
   set the flag_URL of titleView to flagURL
end menu_SetFlag

on submenu_Wiki
   return "Global | Wiki | Menu"
end submenu_Wiki

on _
end _

on submenu_View
   return "Global | View | Card | Tools | Menu"
end submenu_View

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Dev | Menu
-
on menu_Test displayView, abc
   put displayView & CR & abc
end menu_Test

on menu_EditMenuButtonScript displayView
   put the long id of btn "Flag Menu" of displayView into mButton
   --
   edit the script of mButton
end menu_EditMenuButtonScript


--> Deps
-
