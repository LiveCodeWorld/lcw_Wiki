script "model_WikiBookmark"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_WikiBookmark
type: model
version: 0.1


--> Variables
-
local Localarray


--> WikiBookMark
-
function wikiBookMark_ListSlugs bookmarkData
   put indexArray_List (bookmarkData, "pageSlug") into pageSlugs
   return pageSlugs
end wikiBookMark_ListSlugs

function wikiBookMark_Find bookmarkData, pageSlug, pWikiDomain
   repeat with itemNum = 1 to item 2 of the extents of bookmarkData
      put bookmarkData [itemNum] into itemArray      
      if itemArray ["pageSlug"] is not pageSlug then next repeat
      
      if pWikiDomain is empty then return itemNum
      if itemArray ["wikiDomain"] = pWikiDomain then
         return itemNum
      end if
   end repeat 
   return 0
end wikiBookMark_Find


--> WikiBookMark | Model
-
command wikiBookmark_Delete pageSlug, pWikiDomain
   put wikiBookmark_GetData() into bookmarkData
   --
   put wikiBookMark_Find (bookmarkData, pageSlug, pWikiDomain) into indexNum
   indexArray_Delete bookmarkData, indexNum
   --
   wikiBookmark_SetData bookmarkData
   return bookmarkData
end wikiBookmark_Delete

function wikiBookmark_Get pageSlug, pWikiDomain
   put wikiBookmark_GetArray (pageSlug, pWikiDomain) into bmArray
   put bmArray ["wikiDomain"] into wikiDomain
   put bmArray ["pageSlug"] into pageSlug
   return wikiDomain,pageSlug
end wikiBookmark_Get

command wikiBookmark_Set pageSlug, wikiDomain
   put wikiBookmark_GetData() into bookmarkData
   --
   put wikiBookMark_Find (bookmarkData, pageSlug, wikiDomain) into indexNum
   if indexNum = 0 then return 0
   
   put wikiDomain into bmArray ["wikiDomain"]
   put pageSlug into bmArray ["pageSlug"]
   indexArray_AddToEnd bookmarkData, bmArray
   --
   wikiBookmark_SetData bookmarkData
   return indexNum
end wikiBookmark_Set

function wikiBookmark_GetArray pageSlug, pWikiDomain
   put wikiBookmark_GetData() into bookmarkData
   --
   put wikiBookMark_Find (bookmarkData, pageSlug, pWikiDomain) into indexNum
   put bookmarkData [indexNum] into bmArray
   return bmArray
end wikiBookmark_GetArray

function wikiBookmark_GetData
   put Localarray ["Bookmarks"] into bookmarkData
   return bookmarkData
end wikiBookmark_GetData

command wikiBookmark_SetData bookmarkData
   put bookmarkData into Localarray ["Bookmarks"]
end wikiBookmark_SetData
