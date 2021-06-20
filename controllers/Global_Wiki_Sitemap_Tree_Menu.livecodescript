script "Global | Wiki | Sitemap | Tree | Menu"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: Global | Wiki | Sitemap | Tree | Menu
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
end menu_Init

getprop test_Param [mTarget]
   return "b"
end test_Param

getprop test_Params [mTarget]
   return "a,b,c"
end test_Params

getprop menu_CheckTarget [mTarget]
   return true
end menu_CheckTarget

getprop checked_TestChecked
   return true
end checked_TestChecked

getprop disabled_Test
   return false -- true, "delete"
end disabled_Test


--> Global | Wiki | Sitemap | Tree | Menu
-
on menu_TodaysPages displayView
   put the title_Text of displayView into wikiDomain
   --
   display_PageTitleArray wikiDomain, "1 day"
end menu_TodaysPages

on menu_OneHour displayView
   put the title_Text of displayView into wikiDomain
   --
   display_PageTitleArray wikiDomain, "1 hour"
end menu_OneHour

on _
end _

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Dev | Menu
-
on menu_StoredSitePageArray displayView
   set the site_PageArray of displayView to sitePageArray
   display_Date sitePageArray, "the site_PageArray"
end menu_StoredSitePageArray


--> Deps
-
