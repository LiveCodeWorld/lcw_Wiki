script "Global | Wiki | Pages | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Pages | Menu
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
   return tObject
end menu_Target


--> Global | Wiki | Pages | Menu
-
on menu_Refresh displayView
   put the title_Text of displayView into wikiDomain
   --
   display_WikiDomain wikiDomain
end menu_Refresh

on _
end _

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Dev | Menu
-
on menu_TestGoalJunk displayView
   -- put "tools.goaljam.org" into wikiDomain
   put "spacenet.work" into wikiDomain
   --
   put lcw_Ask ("What domain?", wikiDomain)into wikiDomain
   put "junk" into pageSlug
   put the time into someData ["Test"]
   --
   _TestWrite pageSlug, wikiDomain, someData
end menu_TestGoalJunk

on menu_TestRosterJunk displayView
   put "roster.fedwiki.org" into wikiDomain
   --
   put lcw_Ask ("What domain?", wikiDomain)into wikiDomain
   put "junk" into pageSlug
   put the time into someData ["Test"]
   --
   _TestWrite pageSlug, wikiDomain, someData
end menu_TestRosterJunk

private command _TestWrite pageSlug, wikiDomain, someData
   fedwiki_StorePluginData pageSlug, wikiDomain, someData
   put the result into pluginResult
   put pluginResult
   --
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   display_PageArray pageArray, wikiDomain
   --
   put fedwiki_FetchPluginData (pageSlug, wikiDomain) into pData
   display_Data pData, pageSlug, "fedwiki_FetchPluginData()"
end _TestWrite
