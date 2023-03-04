script "model_PageArray"
--> MetaData
-
license: GPLv3
name: model_PageArray
type: model
version: 0.3

/*
Should use "textDecode" every time we fetch text?

This is a model for fetching, storing Fedwiki page-array structures derived from the page-json schema.
It also provides hanlders to to CRUD operations of page-json files.

See also "model_WikiPage", "model_AtopiaFiles", "lib_PageArray" and "lib_FedwikiCreate"

We also provide wrappers for specific types of page-array, such as LCW hander-array's.
We can use these handlers to fetch json and arrays from anywhere in the federation,
but naturally we can only write to wiki-domains that we have permission to write to.
For now this means domains on the Atopia server.
*/


--> Working on
-
function pageArray_FetchItem wikiDomain, pageSlug, itemID
   -- note use of "textDecode"
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   put pageArray_GetItemText (pageArray, itemID) into binaryData
   put textDecode (binaryData, "utf8") into sText
   return sText
end pageArray_FetchItem

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


--> Atopia | PageJson | Model
-
/*
These handlers are not used very much, except by pageArray_Fetch, pageArray_Store, pageArray_Delete
*/

function pageJson_Fetch wikiDomain, pSlug
   -- was "pageJson_Fetch"
   put pageJson_ConstructUrl (wikiDomain, pSlug) into someUrl
   put url someUrl into someJSON
   return someJSON
end pageJson_Fetch

function pageJson_ConstructUrl fedwikiDomain, pSlug
   put tolower (pSlug) into pSlug -- just in case
   if pSlug is empty then
      -- http://c0de.academy/welcome-visitors.json?random=95b9c89e
      put "http://" & fedwikiDomain & "/welcome-visitors.json" into someUrl
   else
      -- put url "http://c0de.academy/currently-working-on.json?random=32c053a"
      put "http://" & fedwikiDomain & "/" & pSlug & ".json" into someUrl
   end if
   put "?random=" & the milliseconds after someUrl
   return someUrl
end pageJson_ConstructUrl

command pageJson_Store wikiDomain, pageSlug, pageJSON, pDeleteSiteMap
   put atopia_ConstructPagePath (wikiDomain, pageSlug) into wikiPagePath
   --
   atopia_StoreData wikiPagePath, pageJSON
   --
   put the result into shellResult
   if shellResult is not empty then return shellResult
   if pDeleteSiteMap is not false then -- deleting sitemap is the lazy way to update it
      atopia_DeleteWikiSitemap wikiDomain
   end if
   return shellResult -- should be empty unless an error
end pageJson_Store

command pageJson_Delete wikiDomain, pageSlug
   put atopia_ConstructPagePath (wikiDomain, pageSlug) into wikiPagePath
   --
   atopia_DeleteFile wikiPagePath
   --
   put the result into shellResult
   return shellResult
end pageJson_Delete


--> PageArray | Image
-
function pageArray_ConstructImage imageURL, pPageTitle, pPageDescription, pLinkURL, pImageCaption
   local pageArray
   if pPageTitle is empty then put "Imported Image" into pPageTitle
   if pPageDescription is empty then
      put "This [[ghost-page]] has not been saved yet. Drag the map off this page if you want to keep it." into pPageDescription
   end if
   --
   put pPageTitle into pageArray ["title"]
   put pageArray_ConstructJournal (pPageTitle) into pageArray ["journal"] 
   /*
   if pImageCaption is empty then put "This is [[thumbnail image]]" into pImageCaption
   pageArray_AddThumbnail pageArray, imageURL, pImageCaption
   */
   pageArray_AddMarkdown pageArray, pPageDescription
   --
   if pImageCaption is empty then put "This is a [[full width image]]" into pImageCaption
   pageArray_AddImage pageArray, imageURL, pImageCaption
   --
   return pageArray
end pageArray_ConstructImage

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
   pageArray_AddItemArray imageArray, pageArray
end pageArray_AddEmbeddedImage

command pageArray_AddImage @pageArray, imageURL, pImageCaption, pLinkURL
   if pageArray is not an array then return false
   if imageURL is  empty then return false
   _SetImageDescription pImageCaption, pLinkURL, imageURL
   --
   put fedwiki_ConstructImageHtml (imageURL, pImageCaption, pLinkURL) into imageHTML
   pageArray_AddHtml pageArray, imageHTML
   return true
end pageArray_AddImage

command pageArray_AddThumbnail @pageArray, imageURL, pImageCaption, pLinkURL
   if pageArray is not an array then return false
   if imageURL is  empty then return false
   _SetImageDescription pImageCaption, pLinkURL, imageURL
   --
   put fedwiki_ConstructThumbHtml (imageURL, pImageCaption, pLinkURL) into imageHTML
   pageArray_AddHtml pageArray, imageHTML
   return true
end pageArray_AddThumbnail

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


--> PageArray | Construct
-
function pageArray_Construct pageTitle, someMarkdown
   -- was "fedwiki_ConstructSimplePageArray"
   put pageTitle into pageArray ["title"]
   pageArray_AddMarkdown pageArray, someMarkdown
   put pageArray_ConstructJournal (pageTitle) into pageArray ["journal"] 
   return pageArray
end pageArray_Construct

function pageArray_ConstructFactory pID
   pageArray_AssignID pID
   put "factory" into factoryArray ["type"]
   put pID into factoryArray ["id"]
   return factoryArray
end pageArray_ConstructFactory

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
   pageArray_Store wikiDomain, pSlug, pageArray, true
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
   put storyArray_ConstructItem (rosterText, "roster", pID) into itemArray
   pageArray_AddItemArray itemArray, pageArray
   return true
end pageArray_AddRoster


--> Fedwiki | Page
-
command fedwiki_UpdatePageItem itemText, itemID, pageSlug, wikiDomain
   put pageArray_Fetch (wikiDomain) into pageArray
   pageArray_SetItemText pageArray, itemID, itemText
   pageArray_Store wikiDomain, pageSlug, pageArray
   return pageArray
end fedwiki_UpdatePageItem


--> PageArray | Video
-
function vimeo_ConstructWatchUrl videoID
   put "https://vimeo.com/" & videoID into vimeoURL
   return vimeoURL
end vimeo_ConstructWatchUrl

function youtube_ConstructWatchUrl videoID
   put "https://www.youtube.com/watch?v=" & videoID into youtubeURL
   return youtubeURL
end youtube_ConstructWatchUrl


--> PageArray | Model
-
function pageArray_FetchByTitle wikiDomain, pTitle
   put fedwiki_ConstructSlug (pTitle) into pSlug
   put pageArray_Fetch (wikiDomain, pSlug, true) into pageArray
   return pageArray
end pageArray_FetchByTitle

function pageArray_Fetch wikiDomain, pSlug, pDontCheck
   -- checks for title, journal, and story
   put pageJson_Fetch (wikiDomain, pSlug) into pageJson
   --
   if pageJson is empty then return empty
   put json_ToArray (pageJson) into pageArray
   if pDontCheck is true then return pageArray
   if pageArray_Check (pageArray) then
      return pageArray
   else
      return empty
   end if
end pageArray_Fetch

command pageArray_Store wikiDomain, pageSlug, pageArray, pDeleteSiteMap
   put json_FromArray (pageArray) into pageJSON
   pageJson_Store wikiDomain, pageSlug, pageJSON
   put the result into shellResult
   --
   if pDeleteSiteMap then
      atopia_DeleteWikiSitemap wikiDomain
   end if
   --
   if shellResult is empty then
      put fedwiki_ConstructUrlFromSlug (wikiDomain, pageSlug) into wikiURL
      return wikiURL
   else
      return "Error," && shellResult
   end if
end pageArray_Store

command pageArray_Delete wikiDomain, pageSlug
   pageJson_Delete wikiDomain, pageSlug
   put the result into shellResult
   if shellResult is not empty then return shellResult
   --
   atopia_DeleteWikiSitemap wikiDomain
   return empty
end pageArray_Delete

function pageArray_Check pageArray
   if pageArray is not an array then return false
   --
   put pageArray ["title"] into pageTitle
   put pageArray ["journal"] into journalArray
   if pageTitle is empty or "story" is not among the keys of pageArray or journalArray is not an array then
      return false
   else
      return true
   end if
end pageArray_Check


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
   array_AddToEndOfIndex actionArray, journalArray
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
   array_AddToEndOfIndex actionArray, journalArray
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
   array_AddToEndOfIndex actionArray, journalArray
   put journalArray into pageArray ["journal"]
end pageArray_AddDeleteAction


--> PageArray | Add
-
command pageArray_AddItemArray itemArray, @pageArray
   -- was "fedwiki_AddItemArrayToStoryEnd"
   if itemArray is not an array then return 0
   
   put pageArray ["story"] into storyArray
   put pageArray ["journal"] into journalArray
   put itemArray ["id"] into itemID
   
   -- add the item to the end of the story
   array_AddToEndOfIndex itemArray, storyArray
   -- figure out what we just added it after
   -- this can be empty if it is the first entry
   put the result into afterID
   put storyArray into pageArray ["story"]
   
   -- 3) Now let's add the edit or add to the journal
   -- make the factory have the same id as the item we will add to the story
   put pageArray_ConstructFactory (itemID) into factoryArray
   -- now add a journal entry for adding after the id of the end paragraph
   journalArray_Add journalArray, factoryArray, "add", afterID
   
   -- finally add the journal entry for editing the factory
   journalArray_Add journalArray, itemArray, "edit"
   put journalArray into pageArray ["journal"]
   
   put pageArray ["story"] into storyArray
   put item 2 of the extents of storyArray into lastItemNum
   return lastItemNum
end pageArray_AddItemArray

command pageArray_AddButton @pageArray, buttonName, postURL, pHiddenKeyValueArray, pLabel, pAlign, pBgColor, pID
   put fedwiki_ConstructButtonForm (buttonName, postURL, pHiddenKeyValueArray, pLabel, pAlign, pBgColor) into formHTML
   pageArray_AddHTML pageArray, formHTML, pID
   return formHTML
end pageArray_AddButton

command pageArray_AddMarkdown @pageArray, someMarkdown, pID
   if someMarkdown is empty then return 0
   put storyArray_ConstructItem (someMarkdown, "markdown", pID) into itemArray
   pageArray_AddItemArray itemArray, pageArray
   return the result
end pageArray_AddMarkdown

command pageArray_AddText @pageArray, someText, pID
   if someText is  empty then return 0
   put word 1 to -1 of someText into someText
   put storyArray_ConstructItem (someText, "paragraph", pID) into itemArray
   pageArray_AddItemArray itemArray, pageArray
   return the result
end pageArray_AddText

command pageArray_AddHtml @pageArray, someHtml, pID
   if someCode is  empty then return 0
   put storyArray_ConstructItem (someHtml, "html", pID) into itemArray
   pageArray_AddItemArray itemArray, pageArray
   return the result
end pageArray_AddHtml

command pageArray_AddReference @pageArray, pageSlug, wikiDomain, refText, pageTitle, pID
   if pageSlug is empty then return 0
   put storyArray_ConstructReference (pageSlug, wikiDomain, refText, pageTitle, pID) into itemArray
   pageArray_AddItemArray itemArray, pageArray
   return the result
end pageArray_AddReference

command pageArray_AddFactory @pageArray, pID
   put pageArray_ConstructFactory (pID) into itemArray
   pageArray_AddItemArray itemArray, pageArray
   return the result
end pageArray_AddFactory

command pageArray_AddPagefold @pageArray, someText, pID
   if someText is  empty then return 0
   put word 1 to -1 of someText into someText
   put storyArray_ConstructItem (someText, "pagefold", pID) into itemArray
   pageArray_AddItemArray itemArray, pageArray
   return the result
end pageArray_AddPagefold

command pageArray_AddCode @pageArray, someCode, pID
   if someCode is  empty then return false
   put storyArray_ConstructItem (someCode, "code", pID) into itemArray
   pageArray_AddItemArray itemArray, pageArray
   return true
end pageArray_AddCode

command pageArray_AddVideo @pageArray, videoID, videoType, videoDescription, pID
   -- videoID can be "webm http://xxx"
   if videoID is empty then return 0
   put storyArray_ConstructVideo (videoID, videoType, videoDescription, pID) into itemArray
   pageArray_AddItemArray itemArray, pageArray
   return the result
end pageArray_AddVideo

command pageArray_AddAudio @pageArray, audioUrl, someText, pID
   if audioUrl is  empty then return false
   put storyArray_ConstructAudio (audioUrl, someText, pID) into itemArray
   pageArray_AddItemArray itemArray, pageArray
   return true
end pageArray_AddAudio

command pageArray_AddTransport @pageArray, pTransportLine, pID
   if pTransportLine is  empty then return 0
   if pTransportLine is empty then
      put "POST https://rest.livecode.world/imagine" into pTransportLine
   end if
   put storyArray_ConstructTransport (pTransportLine, pID) into itemArray
   pageArray_AddItemArray itemArray, pageArray
   return the result
end pageArray_AddTransport


--> StoryArray | Construct
-
function storyArray_ConstructCreate pageTitle, pMilliseconds, pSourceArray
   if pMilliseconds is not a number then put the milliseconds into pMilliseconds
   put "create" into createArray ["type"]
   put pMilliseconds into createArray ["date"]
   put pageTitle into createArray ["item"]["title"]
   put empty into createArray ["item"]["story"]
   if pSourceArray is an array then put pSourceArray into createArray ["source"]
   return createArray
end storyArray_ConstructCreate

function storyArray_ConstructReference pageSlug, wikiDomain, refText, pageTitle, pID
   -- was "pageArray_ConstructReference"
   pageArray_AssignID pID   
   put audioUrl & CR & someText into itemArray ["text"]
   
   put wikiDomain into itemArray ["site"]
   put pageTitle into itemArray ["title"]
   put pageSlug into itemArray ["slug"]
   put refText into itemArray ["text"]
   --
   put "reference" into itemArray ["type"]
   put pID into itemArray ["id"]
   return itemArray
end storyArray_ConstructReference

function storyArray_ConstructTransport transportLine, pID
   -- was "pageArray_ConstructTransport"
   pageArray_AssignID pID
   put transportLine into itemArray ["text"]
   put "transport" into itemArray ["type"]
   put pID into itemArray ["id"]
   return itemArray
end storyArray_ConstructTransport

function storyArray_ConstructVideo videoID, videoType, videoDescription, pID
   -- was "pageArray_ConstructVideoArray"
   pageArray_AssignID pID
   put toUpper (videoType) && videoID & CR & line 1 of videoDescription into itemArray ["text"]
   put "video" into itemArray ["type"]
   put pID into itemArray ["id"]
   return itemArray
end storyArray_ConstructVideo

function storyArray_ConstructAudio audioUrl, someText, pID
   -- was "pageArray_ConstructAudio"
   pageArray_AssignID pID   
   put audioUrl & CR & someText into itemArray ["text"]
   put "audio" into itemArray ["type"]
   put pID into itemArray ["id"]
   return itemArray
end storyArray_ConstructAudio

function storyArray_ConstructItem someText, itemType, pID
   -- was "pageArray_ConstructItemArray"
   pageArray_AssignID pID   
   put someText into itemArray ["text"]
   put itemType into itemArray ["type"]
   put pID into itemArray ["id"]
   return itemArray
end storyArray_ConstructItem


--> Deps
-
command journalArray_Add @journalArray, itemArray, journalType, pAfterID, pMilliseconds
   if pMilliseconds is empty then put the milliseconds into pMilliseconds
   if pAfterID is not empty then
      put pAfterID into journalEntryArray ["after"]
   end if
   put pMilliseconds into journalEntryArray ["date"]
   put itemArray ["id"] into journalEntryArray ["id"]
   put itemArray into journalEntryArray ["item"]
   put journalType into journalEntryArray ["type"]
   
   array_AddToEndOfIndex journalEntryArray, journalArray
end journalArray_Add

command array_AddToEndOfIndex dataOrArray, @indexArray
   -- any indexed array. Could be story or journal
   put item 2 of the extents of indexArray into indexNum
   put indexArray [indexNum]["id"] into afterID
   add 1 to indexNum
   put dataOrArray into indexArray [indexNum]
   return afterID -- figure out what we just added it after
end array_AddToEndOfIndex

command line_AddToNameArray @nameArray, someIndex
   replace comma with CR in someIndex
   repeat for each line someLine in someIndex
      put word 1 to -1 of someLine into someLine
      if someLine is empty then next repeat
      put empty into nameArray [someLine]
   end repeat
end line_AddToNameArray
