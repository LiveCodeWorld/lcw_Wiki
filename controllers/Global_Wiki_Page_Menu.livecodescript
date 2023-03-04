script "Global | Wiki | Page | Menu"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: Global | Wiki | Page | Menu
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
   put the display_View of tObject into displayView
   --
   put the wiki_Domain of displayView into wikiDomain
   put the page_Slug of displayView into pSlug
   put the page_Aray of displayView into pageArray
   --
   return displayView
end menu_Target

on mDoubleUp_WikiPage displayView, someLine
   breakpoint
   put the title_Text of displayView into someTitle
end mDoubleUp_WikiPage


--> Global | Wiki | Page | Menu
-
on menu_PageArray displayView
   put the page_Aray of displayView into pageArray
   display_Data pageArray, "pageArray"
end menu_PageArray

on menu_Refresh displayView
   put the title_Text of displayView into pageTitle
   put the wiki_Domain of displayView into wikiDomain
   put the page_Slug of displayView into pSlug
   put the page_Array of displayView into pageArray
   --
   display_WikiPage wikiDomain, pSlug
end menu_Refresh

on _
end _

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Dev | Menu
-
on _Experiment displayView
   put "fedwiki.org" into wikiDomain
   -- put the wiki_Domain of displayView into wikiDomain
   put lcw_Ask ("What domain?", wikiDomain)into wikiDomain
   put the page_Slug of displayView into pageSlug
   --
   put the time into someData ["Test"]
   --put the page_Array of displayView into someData
   --
   fedwiki_StorePluginData pageSlug, wikiDomain, someData
   put the result into pluginResult
   --
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   display_PageArray pageArray, wikiDomain
   --
   put fedwiki_FetchPluginData (pageSlug, wikiDomain) into pData
   put pluginResult
   display_Data pData
end _Experiment
