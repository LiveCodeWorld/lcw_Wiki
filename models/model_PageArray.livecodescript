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

--> Working on
-
function pageArray_FetchDefault pageSlug
   put atopia_DefaultWikiPagePath (pageSlug) into defaultPath
   put atopia_FetchData (defaultPath) into pageJSON
   put json_ToArray (pageJSON) into pageArray
   return pageArray
end pageArray_FetchDefault

command pageArray_StoreDefault pageSlug, pageArray
   put json_FromArray (pageArray) into pageJSON
   put atopia_DefaultWikiPagePath (pageSlug) into defaultPath
   atopia_StoreData defaultPath, pageJSON
   put the result into shellResult
   return shellResult
end pageArray_StoreDefault


--> LCW | Handler | Model
-
/*
Here we reference handlers stared on "handler.livecode.world"
We define a new concept "handerArray" to mean a "pageArray" for handlers.
*/

function lcw_FetchObjectPageArray sObject
   _ObjectDomainInfo sObject, pageTitle, pageSlug, wikiDomain
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   return pageArray
end lcw_FetchObjectPageArray

command lcw_StoreObjectPageArray sObject, pageArray
   _ObjectDomainInfo sObject, pageTitle, pageSlug, wikiDomain
   pageArray_Store wikiDomain, pageSlug, pageArray
   return the result
end lcw_StoreObjectPageArray

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


--> PageArray | Edit
-
command pageArray_InsertStory @pageArray, storyArray, afterItemNum
   -- Insert story and reindex. Quick and dirty.
   -- We do not check story item ids, nor do we journal individual edits
   -- Should check itemIDs with "pageArray_CheckUniqueItemIds" beforehand
   put pageArray ["story"] into oldStoryArray
   
   -- add first bit of old story
   repeat with itemNum = 1 to afterItemNum
      put oldStoryArray [itemNum] into newStoryArray [itemNum]
   end repeat
   
   -- insert new story
   put item 2 of the extents of storyArray into lastStoryItemNum
   put itemNum into insertItemNum
   repeat with itemNum = 1 to lastStoryItemNum
      put newStoryArray [insertItemNum]["id"] into afterID
      add 1 to insertItemNum
      --
      put storyArray [itemNum] into itemArray
      put itemArray into newStoryArray [insertItemNum]
      --
      pageArray_AddAddAction pageArray, itemArray, afterID
      -- put the result into actionArray
   end repeat
   
   -- add last bit of old story
   put afterItemNum + 1 into oldStart
   put item 2 of the extents of oldStoryArray into oldEnd
   repeat with itemNum = oldStart to oldEnd
      add 1 to insertItemNum
      put oldStoryArray [itemNum] into newStoryArray [insertItemNum]
   end repeat
   --
   put newStoryArray into pageArray ["story"]
   return newStoryArray
end pageArray_InsertStory

command pageArray_MoveItem @pageArray, fromItemNum, toItemNum
   -- was "fedwiki_MoveStoryItem"
   -- should check if fromItemNum and toItemNum are within bounds first
   if fromItemNum = toItemNum then return false
   if fromItemNum = 0 or toItemNum = 0 then return false
   if fromItemNum is not a number or toItemNum is not a number then return false
   
   local pID
   put pageArray ["story"] into storyArray
   
   -- delete item
   storyArray_DeleteItem storyArray, fromItemNum
   put the result into itemArray
   if itemArray is empty then return false
   
   -- insert item
   fedwiki_StoryInsertInto storyArray, toItemNum, itemArray
   put storyArray into pageArray ["story"]
   
   -- update journal
   put fedwiki_StoryExtractOrderedIDArray (storyArray) into oderedIDArray
   put the milliseconds into pMilliseconds
   pageArray_AssignID pID
   
   put pageArray ["journal"] into journalArray
   put "move" into journalEntryArray ["type"]
   put pMilliseconds into journalEntryArray ["date"]
   put pID into journalEntryArray ["id"]
   put oderedIDArray into journalEntryArray ["order"]
   array_AddToEndOfIndex journalEntryArray, journalArray
   put journalArray into pageArray ["journal"]
   
   return true
end pageArray_MoveItem

command pageArray_DeleteItem @pageArray, itemNumsToDelete
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
end pageArray_DeleteItem


--> PageArray | Journal | Actions
-
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


--> PageArray | Model
-
function pageArray_Fetch wikiDomain, pSlug, pDontCheck
   -- checks for title, journal, and story
   put pageJson_Fetch (wikiDomain, pSlug) into pageJson
   if pageJson is empty then return empty
   put json_ToArray (pageJson) into pageArray
   if pDontCheck is true then return pageArray
   if pageArray_Check (pageArray) then
      return pageArray
   else
      return empty
   end if
end pageArray_Fetch

command pageArray_Store wikiDomain, pageSlug, pageArray
   put json_FromArray (pageArray) into pageJSON
   pageJson_Store wikiDomain, pageSlug, pageJSON
   put the result into shellResult
   return shellResult -- should be empty unless an error
end pageArray_Store


--> PageJson | Model
-
function pageJson_Fetch wikiDomain, pSlug
   -- was "fedwiki_FetchPageArray"
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


--> Private
-
private command _ObjectDomainInfo sObject, @pageTitle, @pageSlug, @wikiDomain
   put the stack_Name of sObject into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put the script_Type of sObject into scriptType
   put help_ConstructDomain (scriptType) into wikiDomain
end _ObjectDomainInfo
