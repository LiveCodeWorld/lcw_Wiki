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
on menu_Init tObject
   -- called only once for top menu
  pass menu_Init
end menu_Init

--  getprop menu_Target [tObject]
   -- called once for each menu
   put the 
   return tObject
end menu_Target


--> Global | Wiki | Page | Menu
-
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
on menu_Experiment displayView
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
end menu_Experiment
