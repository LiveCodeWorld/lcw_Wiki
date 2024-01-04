script "Global | Wiki | Sitemap | Line | Menu"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: Global | Wiki | Sitemap | Line | Menu
type: controller
version: 0.2

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

private function _GetSlug arrayView
   put _GetTopData (arrayView) into topData
   put keys (topData) into pageTitle
   put topData [pageTitle] into pageData
   --
   return pageData ["slug"]
end _GetSlug

private function _GetTopData arrayView
   put the selected_TopData of arrayView into topData
   return topData
end _GetTopData


--> Global | Wiki | Sitemap | Line | Menu
-
on menu_StripJournal displayView
   put the title_Text of displayView into wikiDomain
   put _GetSlug (displayView) into pageSlug
   --
   put pageArray_Get (wikiDomain, pageSlug) into pageArray
   pageArray_StripJournal pageArray
   --
   if the shiftkey is "Up" then
      display_PageArray pageArray, wikiDomain
      put the result into displayView
      set the wiki_Domain of displayView to wikiDomain
      set the page_Slug of displayView to pageSlug
   else
      pageArray_Set wikiDomain, pageSlug, pageArray
      if item 1 of the result is "Error" then
         put the result
      end if
   end if
end menu_StripJournal

private on _
end _

on menu_FetchPageArray arrayView
   put the title_Text of arrayView into wikiDomain
   put _GetSlug (arrayView) into pageSlug
   --
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   --
   display_PageArray pageArray, wikiDomain
   put the result into displayView
   set the wiki_Domain of displayView to wikiDomain
   set the page_Slug of displayView to pageSlug
end menu_FetchPageArray

on menu_GetPageArray arrayView
   put the title_Text of arrayView into wikiDomain
   put _GetSlug (arrayView) into pageSlug
   --
   put pageArray_Get (wikiDomain, pageSlug) into pageArray
   --
   display_PageArray pageArray, wikiDomain
   put the result into displayView
   set the wiki_Domain of displayView to wikiDomain
   set the page_Slug of displayView to pageSlug
end menu_GetPageArray

private on __
end __

on menu_SaveToDefaultPages arrayView
   put the title_Text of arrayView into wikiDomain
   put _GetSlug (arrayView) into pSlug
   --
   put pageArray_Fetch (wikiDomain, pSlug) into pageArray
   --
   wikiServer_SetPageArray pageArray
end menu_SaveToDefaultPages

on menu_SetDefaultHome arrayView
   put the title_Text of arrayView into wikiDomain
   put _GetSlug (arrayView) into pSlug
   --
   put empty into forkDomains
   wikiServer_CopyHomeToDefault arrayView, forkDomains
end menu_SetDefaultHome

