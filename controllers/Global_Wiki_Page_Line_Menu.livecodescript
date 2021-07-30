script "Global | Wiki | Page | Line | Menu"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: Global | Wiki | Page | Line | Menu
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
   -- called once for each menu
   return the view_Object of tObject
end menu_Target


--> Global | Wiki | Page | Line | Menu
-
on menu_DisplayJson displayView
   put the page_Slug of displayView into pageSlug
   -- put the stack_Label of displayView into wikiDomain
   put the wiki_Domain of displayView into wikiDomain
   --
   put fedwiki_FetchPluginData (pageSlug, wikiDomain) into pData
   put fedwiki_FetchPluginJSON (pageSlug, wikiDomain) into pluginJSON
   
   put the top_Array ["id"] of displayView into itemID
   put the page_Array of displayView into pageArray
   --
   put pageArray_GetItemArray (pageArray, itemID) into itemArray
   --
   put the title_Text of displayView into pageTitle
   display_Data itemArray, itemID, pageTitle
   put the result into displayView
   --
   set the wiki_Domain of displayView to wikiDomain
end menu_DisplayJson

on menu_StoreJson displayView
   put the page_Slug of displayView into pageSlug
   put the wiki_Domain of displayView into wikiDomain
   put the page_Array of displayView into someData
   --
   put "roster.fedwiki.org" into wikiDomain
   fedwiki_StorePluginData pageSlug, wikiDomain, someData
   put the result into pluginResult
   put fedwiki_FetchPluginData (pageSlug, wikiDomain) into pData
   --
   put the title_Text of displayView into pageTitle
   put the top_Array ["id"] of displayView into itemID
   display_Data itemArray, itemID, pageTitle
   put the result into displayView
   --
   display_WikiPage wikiDomain, pageSlug 
end menu_StoreJson

on menu_WritePluginJson displayView
   put the page_Array of displayView into pageArray
   put "The time is" && the time into jsonArray ["Test"]
   --
   pageArray_AddJsonArray pageArray, jsonArray, "This is a Livecode Test"
   --
   display_PageArray pageArray
end menu_WritePluginJson

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
   display_PageArray pageArray
   --
   put fedwiki_FetchPluginData (pageSlug, wikiDomain) into pData
   put pluginResult
   display_Data pData
end menu_Experiment


--> Deps
-
