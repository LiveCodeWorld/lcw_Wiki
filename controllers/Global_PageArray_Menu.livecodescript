script "Global | PageArray | Menu"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: Global | PageArray | Menu
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
   -- called first
   pass menu_Target
end menu_Target

getprop menu_CheckTarget [mTarget]
   -- use to do initialisation
   pass menu_CheckTarget
end menu_CheckTarget

getprop menu_CheckTarget [displayView]
   return true
end menu_CheckTarget


--> Global | PageArray | Menu
-
on menu_CheckDate displayView
   put the page_Array of displayView into pageArray
   put the displayed_Data of displayView into storyArray
   --
   -- put pageArray_GetFormValue ("rssLastUpdated", pageArray) into inputValue
   put pageArray_GetCreationDate (pageArray) into cDate
   put cDate
end menu_CheckDate

on menu_TestRewritePageArray displayView
   put the wiki_Domain of displayView into wikiDomain
   put the page_Slug of displayView into pageSlug
   --
   breakpoint
   put pageArray_Get (wikiDomain, pageSlug) into pageArray
   pageArray_Set wikiDomain, pageSlug, pageArray
   if item 1 of the result is "Error" then
      put the result
   end if
end menu_TestRewritePageArray

on _
end _

on menu_Refresh displayView
   put the title_Text of displayView into pageTitle
   put the page_Array of displayView into pageArray
   put the page_Slug of displayView into pSlug
   put the wiki_Domain of displayView into wikiDomain
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
on menu_RefreshRss displayView
   put the page_Array of displayView into pageArray
   --
   put pageArray_GetFormValue ("rssURL", pageArray) into rssURL
   put rss_GetPageArray (rssURL) into pageArray
   --
   set the displayed_Data of displayView to pageArray ["story"]
   set the page_Array of displayView to pageArray
end menu_RefreshRss

on menu_IdentifyServerError displayView
   put the page_Array of displayView into pageArray
   --
   put pageArray_GetFormValue ("rssURL", pageArray) into rssURL
   put rssURL into jsonArray ["rssURL"]
   put "https://rest.livecode.world/podcast/testRSS" into restUrl
   --
   put rss_GetPageArray (rssURL) into pageArray
   put pageArray ["story"] into storyArray
   repeat with itemNum = 1 to item 2 of the extents of storyArray
      set the cursor to busy
      put itemNum into jsonArray ["itemNum"]
      --
      put jsonrpc_PostArray (jsonArray, restUrl) into resultArray
      if resultArray is empty then
         put pageArray ["story"][itemNum] into itemArray
         put itemArray ["text"]
         put "Item" && itemNum into someTitle
         display_Data itemArray, someTitle, "Error"
         return false
      end if
   end repeat
   lcw_AnswerWarning  "All good!", displayView
   return true
end menu_IdentifyServerError


--> Deps
-
