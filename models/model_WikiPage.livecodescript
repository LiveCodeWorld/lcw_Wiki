script "model_WikiPage"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_WikiPage
type: model
version: 0.3

/*
This is a model for fetching, storing Fedwiki pages.
See also "model_AtopiaWikiPage", "model_AtopiaFiles", "lib_PageArray" and "lib_FedwikiCreate"
*/


--> Working on
-


--> Wiki | List
-
function wiki_ListMediaPhotos pListShort
   put wiki_MediaAssetFolder() into rootFolder
   if pListShort is true then
      return file_ListShort (rootFolder)
   else
      return file_ListLong (rootFolder)
   end if
end wiki_ListMediaPhotos

function wiki_MediaAssetFolder
   put wiki_GetFolder ("media.localhost") into mediaWikiFolder
   put mediaWikiFolder & "assets/plugins/image/" into mediaAssetFolder
   if there is a folder mediaAssetFolder then
      return mediaAssetFolder
   else
      return empty
   end if
end wiki_MediaAssetFolder


--> PageArray | Fetch
-
function pageArray_FetchItem wikiDomain, pageSlug, itemID
   -- note use of "textDecode"
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   put pageArray_GetItemText (pageArray, itemID) into binaryData
   put textDecode (binaryData, "utf8") into sText
   return sText
end pageArray_FetchItem

function pageArray_FetchByTitle wikiDomain, pTitle
   put fedwiki_ConstructSlug (pTitle) into pSlug
   put pageArray_Fetch (wikiDomain, pSlug, true) into pageArray
   return pageArray
end pageArray_FetchByTitle

function pageArray_Fetch wikiDomain, pSlug, pPort
   put pageJson_Fetch (wikiDomain, pSlug, pPort) into pageJson
   --
   if pageJson is empty then return empty
   put json_ToArray (pageJson) into pageArray
   return pageArray
end pageArray_Fetch

function pageArray_Check pageArray
   if pageArray is not an array then return false
   --
   put pageArray ["title"] into pageTitle
   put pageArray ["journal"] into journalArray
   if pageTitle is empty or "story" is not among the keys of pageArray or journalArray is not an array then
      return empty
   else
      return pageArray
   end if
end pageArray_Check
