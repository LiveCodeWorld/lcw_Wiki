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
   display_WikiSitePageArray wikiDomain, "1 day"
end menu_TodaysPages

on menu_OneHour displayView
   put the title_Text of displayView into wikiDomain
   --
   display_WikiSitePageArray wikiDomain, "1 hour"
end menu_OneHour

on menu_UpdateWikiSitemap displayView
   put the title_Text of displayView into wikiDomain
   --
   put wikiSiteMap_Construct (wikiDomain) into siteMapArray
   wikiSiteMap_SetArray sitemapArray, wikiDomain
end menu_UpdateWikiSitemap

on _
end _

on menu_LocalSitemapArray displayView
   put the title_Text of displayView into wikiDomain
   --
   display_LocalSiteMapArray wikiDomain, "", displayView
end menu_LocalSitemapArray

on menu_FetchSitePageArray displayView
   put the title_Text of displayView into wikiDomain
   --
   display_WikiSitePageArray wikiDomain, "", displayView
end menu_FetchSitePageArray

on menu_FetchSitemapArray displayView
   put the title_Text of displayView into wikiDomain
   --
   put fedwiki_FetchSitemapArray (wikiDomain) into siteMapArray
   display_Data siteMapArray, "fedwiki_FetchSitemapArray()", wikiDomain
end menu_FetchSitemapArray

on __
end __

on menu_StoredSitePageArray displayView
   put the site_PageArray of displayView into sitePageArray
   display_Data sitePageArray, "the site_PageArray"
end menu_StoredSitePageArray

on menu_ConstructSitemapArray displayView
   put the title_Text of displayView into wikiDomain
   --
   put wikiSiteMap_Construct (wikiDomain) into siteMapArray
   display_Data siteMapArray, "wikiSiteMap_Construct()", wikiDomain
end menu_ConstructSitemapArray

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Sitemap | Tree | Menu")
end submenu_Dev
