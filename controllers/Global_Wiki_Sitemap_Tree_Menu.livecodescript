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
getprop menu_CheckTarget [mTarget]
   return true
end menu_CheckTarget


--> Global | Wiki | Sitemap | Tree | Menu
-
on menu_TodaysPages displayView
   put the title_Text of displayView into wikiDomain
   --
   display_SitemapArray wikiDomain, "1 day"
end menu_TodaysPages

on menu_OneHour displayView
   put the title_Text of displayView into wikiDomain
   --
   display_SitemapArray wikiDomain, "1 hour"
end menu_OneHour

on _
end _

on menu_StoredSitePageArray displayView
   set the site_PageArray of displayView to sitePageArray
   display_Date sitePageArray, "the site_PageArray"
end menu_StoredSitePageArray

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Sitemap | Tree | Menu")
end submenu_Dev
