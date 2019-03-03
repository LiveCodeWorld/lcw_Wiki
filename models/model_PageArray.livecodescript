script "model_PageArray"
--> MetaData
-
license: GPLv3
name: model_PageArray
type: model
version: 0.1

/*
This is a model for fetching, storing (and constructing?) Fedwiki page-array structures derived from the page-json schema.

Aim to move handlers here slowly from lib_Fedwiki. See also "lib_PageArray" and "lib_FedwikiCreate"
*/


--> PageArray | Move
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


--> PageArray | Delete
-
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


--> PageArray | Model
-
function pageArray_Fetch wikiDomain, pSlug
   -- was "pageArray_Fetch"
   put fedwiki_FetchPageJson (wikiDomain, pSlug) into pageJson
   put json_ToArray (pageJson) into pageArray
   return pageArray
end pageArray_Fetch

command pageArray_Store wikiDomain, pageSlug, 
   
end pageArray_Store

function fedwiki_FetchPageJson wikiDomain, pSlug
   put fedwiki_PageJsonUrl (wikiDomain, pSlug) into someUrl
   put url someUrl into someJSON
   return someJSON
end fedwiki_FetchPageJson


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
