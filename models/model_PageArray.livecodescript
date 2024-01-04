script "model_PageArray"
--> MetaData
-
license: GPLv3
name: model_PageArray
type: model
version: 0.4

/*
Should use "textDecode" every time we fetch text?

This is a model for fetching, storing Fedwiki page-array structures derived from the page-json schema.
It also provides hanlders to to CRUD operations of page-json files.

See also "model_WikiPage", "model_AtopiaFiles", "lib_PageArray" and "lib_FedwikiCreate"

We also provide wrappers for specific types of page-array, such as LCW hander-array's.
We can use these handlers to fetch json and arrays from anywhere in the federation,
but naturally we can only write to wiki-domains that we have permission to write to.
For now this means domains on the Atopia server.

"location": {"latitude": "52.20755","longitude": "0.11588"
*/


--> Working on
- 

--> PageArray
-
command pageArray_AddReferenceIndex @pageArray, wikiDomains
   repeat for each line wikiDomain in wikiDomains
      pageArray_AddReference pageArray, wikiDomain, wikiDomain, wikiDomain, "welcome-visitors"
   end repeat
   delete char -1 of sMarkdown
   return sMarkdown
end pageArray_AddReferenceIndex

command pageArray_AddReference @pageArray, pageTitle, wikiDomain, refText, pPageSlug, pID
   if pPageSlug is empty then put fedwiki_ConstructSlug (pageTitle) into pPageSlug
   put itemArray_ConstructReference (pPageSlug, wikiDomain, refText, pageTitle, pID) into itemArray
   itemArray_Add itemArray, pageArray
   return the result
end pageArray_AddReference


--> PageArray | Construct
-
function pageArray_ConstructImageCaption pImageCaption, pImageSourceUrl, pImageURL
   if pImageCaption is empty then put "This is a [[full width image]]" into pImageCaption
   _SetImageDescription pImageCaption, pImageSourceUrl, pImageURL
   return pImageCaption
end pageArray_ConstructImageCaption

function pageArray_ConstructImage imageURL, pPageTitle, pPageDescription, pImageCaption, pImageSourceUrl, iWidth, iHeight, iSize, pLat, pLong
   put pageArray_ConstructImageCaption (pImageCaption, pImageSourceUrl, imageURL) into sCaption
   put _ConstructImagePageArray (pPageTitle, pPageDescription) into pageArray
   put _ConstructImageItemArray (imageURL, pImageSourceUrl, iWidth, iHeight, iSize, sCaption, pLat, pLong) into itemArray
   itemArray_Add itemArray, pageArray
   --
   return pageArray
end pageArray_ConstructImage

function pageArray_ConstructHtmlImage imageURL, pPageTitle, pPageDescription, pLinkURL, pImageCaption
   put _ConstructImagePageArray (pPageTitle, pPageDescription) into pageArray
   --
   if pImageCaption is empty then put "This is a [[full width image]]" into pImageCaption
   pageArray_AddImage pageArray, imageURL, pImageCaption
   --
   return pageArray
end pageArray_ConstructHtmlImage

command pageArray_AddActivity @pageArray, rosterTitle, pSinceWhen, pConversationItem, pID
   put itemArray_ConstructActivity (rosterTitle, pSinceWhen, pConversationItem, pID) into itemArray
   itemArray_Add itemArray, pageArray
   return the result
end pageArray_AddActivity

command pageArray_AddImage @pageArray, imageURL, pImageCaption, pLinkURL
   if pageArray is not an array then return false
   if imageURL is  empty then return false
   _SetImageDescription pImageCaption, pLinkURL, imageURL
   --
   put fedwiki_ConstructImageHtml (imageURL, pImageCaption, pLinkURL) into imageHTML
   pageArray_AddHtml pageArray, imageHTML
   return true
end pageArray_AddImage

command pageArray_AddJsonArray @pageArray, jsonArray, pDescription, pID
   put pageArray_FindItemType ("json", pageArray) into itemNum
   if itemNum = 0 then
      get the extents of pageArray ["story"]
      put item 2 of it + 1 into itemNum
      --
      put "json" into pageArray ["story"][itemNum]["type"]
      put uuid () into pageArray ["story"][itemNum]["id"]
      --
      if pDescription is empty then
         put line 1 of the keys of jsonArray into pDescription
      end if
      put pDescription into pageArray ["story"][itemNum]["text"]
   else
      if pDescription is empty then
         put pageArray ["story"][itemNum]["text"] into pDescription
         if pDescription is empty then
            put line 1 of the keys of jsonArray into pDescription
            put pDescription into pageArray ["story"][itemNum]["text"]
         end if
      else
         put pDescription into pageArray ["story"][itemNum]["text"]
      end if
   end if
   --
   put jsonArray into pageArray ["story"][itemNum]["resource"]
   --
   put "Livecode" into pageArray ["story"][itemNum]["writer"] -- "writer": "goaljam"
   --
   put pageArray ["Title"] into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pSlug
   put pSlug into pageArray ["story"][itemNum]["slug"] -- "slug": "junk",
   --
   -- "interval": 115324
   put the milliseconds  into milliNow
   put pageArray ["story"][itemNum]["written"] into lastWritten
   if lastWritten is a number then
      put milliNow - lastWritten into pageArray ["story"][itemNum]["interval"]
   else
      put 0 into pageArray ["story"][itemNum]["interval"]    
   end if
   put milliNow into pageArray ["story"][itemNum]["written"] -- "written": 1620833478309,
   --
   put pageArray ["story"][itemNum]["writes"] into lastWriteNum
   if lastWriteNum is a number then
      put lastWriteNum + 1 into pageArray ["story"][itemNum]["writes"]
   else
      put 1 into pageArray ["story"][itemNum]["writes"]
   end if
   --
   return the result
end pageArray_AddJsonArray


--> PageArray | Image
-
function pageArray_ConstructImageEditPage imageURL, imageAttributeArray, pAddMetaData
   html_DeconstructImageArray imageAttributeArray, srcURL, imageCaption, imageWidth, imageHeight, imageClass
   if imageCaption is empty then put "This is a full width image" into imageCaption
   --
   put pageArray_FetchTemplate ("fedwiki.org", "edit-image-template", "Edit Image Tool", "fedwiki.org") into pageArray
   --
   curly_ReplacePageArray pageArray, "ImageURL", imageURL
   --
   put fedwiki_ConstructExternalLink (imageURL) into imageLink
   curly_ReplacePageArray pageArray, "ImageLink", imageLink
   --
   curly_ReplacePageArray pageArray, "ImageCaption", imageCaption
   
   /*
   pageArray_AddImage pageArray, imageURL, imageCaption
   --
   if imageCaption is empty then put "This is an [[full thumbnail image]]" into imageCaption
   pageArray_AddThumbnail pageArray, imageURL, imageCaption
   */
   
   if pAddMetaData is not false then
      -- this fetches the image a second time with curl
      pageArray_AddImageMetadata pageArray, imageURL
   end if
   --
   return pageArray
end pageArray_ConstructImageEditPage

function pageArray_ConstructGoogleImagePage imageURL, imageAttributeArray
   html_DeconstructImageArray imageAttributeArray, srcURL, imageCaption, imageWidth, imageHeight, imageClass
   --
   put "Your Dropped Image" into pageTitle
   put "Here is a simple image you dropped on to wiki. From here you can do several things." into pageText
   put " Below is a simple [[full width image]], that uses the [[about html plugin]] to display the image using html." after pageText
   put pageArray_Construct (pageTitle, pageText) into pageArray
   put empty into linkURL
   --
   put srcURL into dataURL
   --
   if imageCaption is empty then put "This is an [[full width image]]" into imageCaption
   pageArray_AddImage pageArray, dataURL, imageCaption
   --
   if imageCaption is empty then put "This is an [[full thumbnail image]]" into imageCaption
   pageArray_AddThumbnail pageArray, dataURL, imageCaption
   --
   return pageArray
end pageArray_ConstructGoogleImagePage

command pageArray_AddEmbeddedImage @pageArray, someImage, pImageCaption, pImageType
   if pImageType is empty then put image_DetectType (someImage) into pImageType
   --
   put fedwiki_ConstructEncodedImageArray (someImage, pImageType, pImageCaption) into imageArray
   itemArray_Add imageArray, pageArray
end pageArray_AddEmbeddedImage

command pageArray_AddThumbnail @pageArray, imageURL, pImageCaption, pLinkURL
   if pageArray is not an array then return false
   if imageURL is  empty then return false
   _SetImageDescription pImageCaption, pLinkURL, imageURL
   --
   put fedwiki_ConstructThumbHtml (imageURL, pImageCaption, pLinkURL) into imageHTML
   pageArray_AddHtml pageArray, imageHTML
   return true
end pageArray_AddThumbnail


--> PageArray | Construct
-
function pageArray_Construct pageTitle, someMarkdown
   -- was "fedwiki_ConstructSimplePageArray"
   put pageTitle into pageArray ["title"]
   pageArray_AddMarkdown pageArray, someMarkdown
   put pageArray_ConstructJournal (pageTitle) into pageArray ["journal"] 
   return pageArray
end pageArray_Construct

function pageArray_ConstructJournal pageTitle, pSourceArray, pMilliseconds
   put storyArray_ConstructCreate (pageTitle, pSourceArray, pMilliseconds) into createArray
   put createArray into journalArray [1]
   return journalArray
end pageArray_ConstructJournal


--> PageArray | LastUpdated
-
function pageArray_FetchLastUpdated wikiDomain, pSlug
   put pageArray_Fetch (wikiDomain, pSlug) into pageArray
   --
   get pageArray_GetFirstItem (pageArray, "code")
   set the itemdelimiter to ":"
   delete item 1 of it
   put word 1 to -1 of it into lastUpDate
   --
   convert lastUpDate from internet date to seconds
   return lastUpDate
end pageArray_FetchLastUpdated

command pageArray_StoreLastUpdated wikiDomain, pSlug, pDateInSeconds
   if pDateInSeconds is empty then put the seconds into pDateInSeconds
   --
   convert pDateInSeconds from seconds to internet date
   put "Last updated:" && pDateInSeconds into lastUpDate
   --
   put pageArray_Fetch (wikiDomain, pSlug) into pageArray
   pageArray_SetFirstItem pageArray, "code", lastUpDate
   --
   pageArray_Set wikiDomain, pSlug, pageArray, true
   return the result
end pageArray_StoreLastUpdated


--> PageArray | Roster
-
command pageArray_AddToRoster @pageArray, newDomain
   put pageArray_FindItemType ("roster", pageArray) into itemNum
   if itemNum = 0 then return 0
   --
   put pageArray ["story"][itemNum]["text"] into rosterText
   roster_AddDomain rosterText, newDomain
   put rosterText into pageArray ["story"][itemNum]["text"]
   return itemNum
end pageArray_AddToRoster

function pageArray_GetFirstRoster pageArray
   put pageArray_FindItemType ("roster", pageArray) into firstRosterItemNum
   if firstRosterItemNum = 0 then return empty
   
   put pageArray ["story"][firstRosterItemNum]["text"] into rosterText
   return rosterText
end pageArray_GetFirstRoster

command pageArray_SetRoster @pageArray, rosterDomains, rosterTitle
   put pageArray_FindItemType ("roster", pageArray) into firstRosterItemNum
   if firstRosterItemNum > 0 then
      put word 1 to -1 of (rosterTitle & CR & CR & rosterDomains) into rosterText
      put rosterText into pageArray ["story"][firstRosterItemNum]["text"]
   end if
end pageArray_SetRoster

command pageArray_AddRoster @pageArray, rosterText, pID
   if rosterText is empty then return false
   put itemArray_Construct ("roster", pID, rosterText) into itemArray
   itemArray_Add itemArray, pageArray
   return true
end pageArray_AddRoster


--> PageArray | Set
-
command pageArray_SetTitle @pageArray, someTitle, pID
   if someTitle is  empty then return false
   put "#" && someTitle into someMarkdown
   pageArray_AddMarkdown pageArray, someMarkdown, pID
   put the result into itemNum
   --
   put pageArray ["story"][itemNum] into newItemArray
   pageArray_AddEditAction pageArray, itemNum
   return true
end pageArray_SetTitle

command pageArray_EditItem @pageArray, sText, itemNum, pMilliseconds
   put sText into pageArray ["story"][itemNum]["text"]
   pageArray_AddedEditAction pageArray, itemNum, pMilliseconds
   put the result into actionArray
   return actionArray
end pageArray_EditItem

command pageArray_AddedEditAction @pageArray, itemNum, pMilliseconds
   if pMilliseconds is empty then put the milliseconds into pMilliseconds
   put pageArray ["story"][itemNum] into newItemArray
   put newItemArray ["id"] into itemID
   pageArray_AddEditAction pageArray, newItemArray, itemID, pMilliseconds
   put the result into actionArray
   return actionArray
end pageArray_AddedEditAction


--> PageArray | Actions
-
command pageArray_AddEditAction @pageArray, newItemArray, itemID, pMilliseconds
   if pMilliseconds is empty then put the milliseconds into pMilliseconds
   put pageArray ["journal"] into journalArray
   --
   put "edit" into actionArray ["type"]
   put pMilliseconds into actionArray ["date"]
   put itemID into actionArray ["id"]
   put newItemArray into actionArray ["item"]
   --
   itemArray_AddToEnd actionArray, journalArray
   put journalArray into pageArray ["journal"]
   return actionArray
end pageArray_AddEditAction

command pageArray_AddAddAction @pageArray, itemArray, afterID, pMilliseconds
   if pMilliseconds is empty then put the milliseconds into pMilliseconds
   put pageArray ["journal"] into journalArray
   --
   put "add" into actionArray ["type"]
   put afterID into actionArray ["after"]
   put itemArray into actionArray ["item"]
   put itemArray ["id"] into actionArray ["id"]
   put pMilliseconds into actionArray ["date"]
   --
   itemArray_AddToEnd actionArray, journalArray
   put journalArray into pageArray ["journal"]
   return actionArray
end pageArray_AddAddAction

command pageArray_AddDeleteAction @pageArray, deletedItemID, pMilliseconds
   if pMilliseconds is empty then put the milliseconds into pMilliseconds
   put pageArray ["journal"] into journalArray
   --
   put "remove" into actionArray ["type"]
   put pMilliseconds into actionArray ["date"]
   put deletedItemID into actionArray ["id"]
   --
   itemArray_AddToEnd actionArray, journalArray
   put journalArray into pageArray ["journal"]
end pageArray_AddDeleteAction


--> PageArray | Add
-
command pageArray_AddButton @pageArray, buttonName, postURL, pHiddenKeyValueArray, pLabel, pAlign, pBgColor, pID
   put fedwiki_ConstructButtonForm (buttonName, postURL, pHiddenKeyValueArray, pLabel, pAlign, pBgColor) into formHTML
   pageArray_AddHTML pageArray, formHTML, pID
   return formHTML
end pageArray_AddButton

command pageArray_AddMarkdown @pageArray, someMarkdown, pID
   if someMarkdown is empty then return 0
   put itemArray_Construct ("markdown", pID, someMarkdown) into itemArray
   itemArray_Add itemArray, pageArray
   return the result
end pageArray_AddMarkdown

command pageArray_AddText @pageArray, someText, pID
   if someText is  empty then return 0
   put word 1 to -1 of someText into someText
   put itemArray_Construct ("paragraph", pID, someText) into itemArray
   itemArray_Add itemArray, pageArray
   return the result
end pageArray_AddText

command pageArray_AddHtml @pageArray, someHtml, pID
   if someCode is  empty then return 0
   put itemArray_Construct ("html", pID, someHtml) into itemArray
   itemArray_Add itemArray, pageArray
   return the result
end pageArray_AddHtml

command pageArray_AddFactory @pageArray, pID
   put itemArray_ConstructFactory (pID) into itemArray
   itemArray_Add itemArray, pageArray
   return the result
end pageArray_AddFactory

command pageArray_AddPagefold @pageArray, someText, pID
   if someText is  empty then return 0
   put word 1 to -1 of someText into someText
   put itemArray_Construct ("pagefold", pID, someText) into itemArray
   itemArray_Add itemArray, pageArray
   return the result
end pageArray_AddPagefold

command pageArray_AddCode @pageArray, someCode, pID
   if someCode is  empty then return false
   put itemArray_Construct ("code", pID, someCode) into itemArray
   itemArray_Add itemArray, pageArray
   return true
end pageArray_AddCode

command pageArray_AddVideo @pageArray, videoID, videoType, videoDescription, pID
   -- videoID can be "webm http://xxx"
   if videoID is empty then return 0
   put itemArray_ConstructVideo (videoID, videoType, videoDescription, pID) into itemArray
   itemArray_Add itemArray, pageArray
   return the result
end pageArray_AddVideo

command pageArray_AddAudio @pageArray, audioUrl, someText, pID
   if audioUrl is  empty then return false
   put itemArray_ConstructAudio (audioUrl, someText, pID) into itemArray
   itemArray_Add itemArray, pageArray
   return true
end pageArray_AddAudio

command pageArray_AddTransport @pageArray, pTransportLine, pID
   if pTransportLine is  empty then return 0
   if pTransportLine is empty then
      put "POST https://rest.livecode.world/imagine" into pTransportLine
   end if
   put itemArray_ConstructTransport (pTransportLine, pID) into itemArray
   itemArray_Add itemArray, pageArray
   return the result
end pageArray_AddTransport


--> Private
-
private command _SetImageDescription @pImageCaption, @pLinkURL, imageURL
   if pImageCaption is empty then put "This is an image" into pImageCaption
   if pLinkURL is empty then
      if imageURL begins with "data:image/" then
         put empty into pLinkURL
      else
         put imageURL into pLinkURL
      end if
   end if
end _SetImageDescription

private function _ConstructImagePageArray pPageTitle, pPageDescription
   local pageArray
   if pPageTitle is empty then put "Imported Image" into pPageTitle
   if pPageDescription is empty then
      put "This [[ghost-page]] has not been saved yet. Drag the map off this page if you want to keep it." into pPageDescription
   end if
   --
   put pPageTitle into pageArray ["title"]
   put pageArray_ConstructJournal (pPageTitle) into pageArray ["journal"] 
   pageArray_AddMarkdown pageArray, pPageDescription
   --
   return pageArray
end _ConstructImagePageArray

private function _ConstructImageItemArray imageURL, iSource, iWidth, iHeight, iSize, pCaption, pLat, pLong, pID
   itemArray_SetID pID
   put pID into itemArray ["id"]
   
   put "image" into itemArray ["type"]
   --
   put imageURL into itemArray ["url"]
   put iSource into itemArray ["source"]
   put pCaption into itemArray ["text"]
   --
   put iSize into itemArray ["size"]
   put iWidth into itemArray ["width"]
   put iHeight into itemArray ["height"]
   
   # Add Geo
   if pLat is not empty then
      put pLat into itemArray ["location"]["latitude"]
      put pLong into itemArray ["location"]["longitude"]
   end if
   return itemArray
end _ConstructImageItemArray


--> Deps
-
command line_AddToNameArray @nameArray, someIndex
   replace comma with CR in someIndex
   repeat for each line someLine in someIndex
      put word 1 to -1 of someLine into someLine
      if someLine is empty then next repeat
      put empty into nameArray [someLine]
   end repeat
end line_AddToNameArray
