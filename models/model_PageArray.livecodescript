script "model_PageArray"
--> MetaData
-
license: GPLv3
name: model_PageArray
type: model
version: 0.2

/*
This is a model for fetching, storing Fedwiki page-array structures derived from the page-json schema.
It also provides hanlders to to CRUD operations of page-json files.

We also provide wrappers for specific types of page-array, such as LCW hander-array's.
We can use these handlers to fetch json and arrays from anywhere in the federation,
but naturally we can only write to wiki-domains that we have permission to write to.
For now this means domains on the Atopia server.

Aim to carefully move handlers here from lib_Fedwiki. See also "model_AtopiaFiles", "lib_PageArray" and "lib_FedwikiCreate"
*/


--> LCW | Handler | Model
-
/*
Here we reference handlers stared on "handler.livecode.world"
We define a new concept "handerArray" to mean a "pageArray" for handlers.
*/

function lcw_FetchObjectPageArray sObject
   _ObjectDomainInfo sObject, pageTitle, pageSlug, wikiDomain
   put pageArray_Fetch (wikiDomain, pSlug) into pageArray
   return pageArray
end lcw_FetchObjectPageArray

command lcw_StoreObjectPageArray sObject, pageArray
   _ObjectDomainInfo sObject, pageTitle, pageSlug, wikiDomain
   pageArray_Store wikiDomain, pageSlug, pageArray
   return the result
end lcw_StoreObjectPageArray

private command _ObjectDomainInfo sObject, @pageTitle, @pageSlug, @wikiDomain
   put the stack_Name of sObject into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put the script_Type of sObject into scriptType
   put help_ConstructObjectDomain (scriptType) into wikiDomain
end _ObjectDomainInfo

function lcw_FetchHandlerArray hKey
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   put fedwiki_ConstructSlug (hName) into pageSlug
   --
   put pageArray_Fetch ("handler.livecode.world", pageSlug) into pageArray
   return pageArray
end lcw_FetchHandlerArray

command lcw_StoreHandlerArray hKey, pageArray
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   put fedwiki_ConstructSlug (hName) into pageSlug
   --
   pageArray_Store "handler.livecode.world", pageSlug, pageArray
   put the result into shellResult
   return shellResult
end lcw_StoreHandlerArray


--> PageJson | Model
-
function pageJson_Fetch wikiDomain, pSlug
   put fedwiki_PageJsonUrl (wikiDomain, pSlug) into someUrl
   put url someUrl into someJSON
   return someJSON
end pageJson_Fetch

command pageJson_Store wikiDomain, pageSlug, pageJSON, pDeleteSiteMap
   put fedwiki_ConstructPath (wikiDomain, pageSlug) into wikiPagePath
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
   put fedwiki_ConstructPath (wikiDomain, pageSlug) into wikiPagePath
   atopia_DeleteFile wikiPagePath
   put the result into shellResult
   return shellResult
end pageJson_Delete


--> PageArray | Model
-
function pageArray_Fetch wikiDomain, pSlug
   -- can be any wiki (we simply get page-json)
   put pageJson_Fetch (wikiDomain, pSlug) into pageJson
   put json_ToArray (pageJson) into pageArray
   return pageArray
end pageArray_Fetch

command pageArray_Store fedwikiDomain, pageSlug, pageArray
   put json_FromArray (pageArray) into pageJSON
   pageJson_Store fedwikiDomain, pageSlug, pageJSON
   put the result into shellResult
   return shellResult -- should be empty unless an error
end pageArray_Store


--> PageArray | Edit
-
command pageArray_MoveStoryItem @fedwikiPageArray, fromItemNum, toItemNum
   -- was "fedwiki_MoveStoryItem"
   -- should check if fromItemNum and toItemNum are within bounds first
   if fromItemNum = toItemNum then return false
   if fromItemNum = 0 or toItemNum = 0 then return false
   if fromItemNum is not a number or toItemNum is not a number then return false
   
   local pID
   put fedwikiPageArray ["story"] into storyArray
   
   -- delete item
   storyArray_DeleteItem storyArray, fromItemNum
   put the result into itemArray
   if itemArray is empty then return false
   
   -- insert item
   fedwiki_StoryInsertInto storyArray, toItemNum, itemArray
   put storyArray into fedwikiPageArray ["story"]
   
   -- update journal
   put fedwiki_StoryExtractOrderedIDArray (storyArray) into oderedIDArray
   put the milliseconds into pMilliseconds
   fedwiki_SetID pID
   
   put fedwikiPageArray ["journal"] into journalArray
   put "move" into journalEntryArray ["type"]
   put pMilliseconds into journalEntryArray ["date"]
   put pID into journalEntryArray ["id"]
   put oderedIDArray into journalEntryArray ["order"]
   fedwiki_AddToEndOfIndexArray journalEntryArray, journalArray
   put journalArray into fedwikiPageArray ["journal"]
   
   return true
end pageArray_MoveStoryItem

command pageArray_DeleteStoryItem @pageArray, itemNumsToDelete
   replace CR with comma in itemNumsToDelete
   put pageArray ["story"] into storyArray
   sort numeric items of itemNumsToDelete
   repeat with itemNum = the number of items of itemNumsToDelete down to 1
      put item itemNum of itemNumsToDelete into itemNumToDelete
      storyArray_DeleteItem storyArray, itemNumToDelete
      put the result into deletedItemArray
      put deletedItemArray ["id"] into deletedItemID
      pageArray_AddDeleteAction pageArray, deletedItemID
   end repeat
   put storyArray into pageArray ["story"]
end pageArray_DeleteStoryItem

command pageArray_AddDeleteAction @pageArray, deletedItemID, pMilliseconds
   /*
   {
   "type": "remove",
   "id": "1b37631a8f5e5302",
   "date": 1551202848877
   }
   */
   if pMilliseconds is empty then put the milliseconds into pMilliseconds
   put pageArray ["journal"] into journalArray
   --
   put "remove" into deleteActionArray ["type"]
   put pMilliseconds into deleteActionArray ["date"]
   put deletedItemID into deleteActionArray ["id"]
   fedwiki_AddToEndOfIndexArray deleteActionArray, journalArray
   --
   put journalArray into pageArray ["journal"]
end pageArray_AddDeleteAction


--> Private
-
private command storyArray_DeleteItem @storyArray, itemNumToDelete
   put storyArray [ItemNumToDelete] into deletedItemArray
   put item 2 of the extents of storyArray into maxItem
   if maxItem is not a number then return empty
   repeat with itemNumToMove = (itemNumToDelete + 1) to maxItem
      put itemNumToMove - 1 into itemNumDestination
      put storyArray [itemNumToMove] into storyArray [itemNumDestination]
   end repeat
   delete variable storyArray [maxItem]
   return deletedItemArray
end storyArray_DeleteItem
