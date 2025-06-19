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
function wiki_ListMediaPhotos pListShort
   put wiki_MediaAssetFolder() into rootFolder
   if pListShort is true then
      return file_ListShort (rootFolder)
   else
      return file_ListLong (rootFolder)
   end if
end wiki_ListMediaPhotos

function wiki_MediaAssetFolder
   put wikiFolder_Get ("media.localhost") into mediaWikiFolder
   put mediaWikiFolder & "assets/plugins/image/" into mediaAssetFolder
   if there is a folder mediaAssetFolder then
      return mediaAssetFolder
   else
      return empty
   end if
end wiki_MediaAssetFolder


--> WikiPage | Model
-
function wikiPage_FetchText wikiDomain, pSlug, pPort, pProtocol
   put pageArray_Fetch (wikiDomain, pSlug, pPort, pProtocol) into pageArray
   put pageArray_ToText (pageArray) into sText
   return sText
end wikiPage_FetchText

function wikiPage_GetText wikiDomain, pageSlug
   put pageArray_Get (wikiDomain, pageSlug) into pageArray
   put pageArray_ToText (pageArray) into sText
   return sText
end wikiPage_GetText
