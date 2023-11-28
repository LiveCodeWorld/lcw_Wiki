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
on menu_FetchPageArray arrayView
   put the title_Text of arrayView into wikiDomain
   put _GetSlug (arrayView) into pSlug
   --
   put pageArray_Fetch (wikiDomain, pSlug) into pageArray
   --
   display_PageArray pageArray, wikiDomain
end menu_FetchPageArray

on menu_SaveToDefaultPages arrayView
   put the title_Text of arrayView into wikiDomain
   put _GetSlug (arrayView) into pSlug
   --
   put pageArray_Fetch (wikiDomain, pSlug) into pageArray
   --
   pageArray_SetDefault pageArray
end menu_SaveToDefaultPages

on menu_SetDefaultHome arrayView
   put the title_Text of arrayView into wikiDomain
   put _GetSlug (arrayView) into pSlug
   --
   put empty into forkDomains
   fedwiki_SetDefaultHome arrayView, forkDomains
end menu_SetDefaultHome

