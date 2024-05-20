script "lib_StoryArray"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_StoryArray
type: library
version: 0.2

/*Some help*/


--> Working on
-

--> PageArray | Story
-
command pageArray_AddStory @pageArray, moreStoryItemArray
   if moreStoryItemArray is not an array then return false
   -- add multiple new storyItemArrays from moreStoryItemArray to end of pageArray story
   put pageArray ["story"] into storyItemArray
   storyArray_AddToEnd storyItemArray, moreStoryItemArray
   put storyItemArray into pageArray ["story"]
   --
   pageArray_StripJournal pageArray
   return true
end pageArray_AddStory

command pageArray_InsertStoryAfter @pageArray, storyArray, afterItemNum
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
end pageArray_InsertStoryAfter


--> StoryArray
-
function storyArray_GetBefore storyArray, startItemNum
   repeat with itemNum = 1 to (startItemNum - 1)
      put storyArray [itemNum] into beforeStoryArray [itemNum]
   end repeat
   return beforeStoryArray
end storyArray_GetBefore

function storyArray_GetAfter storyArray, endItemNum
   put 1 into afterItemNum
   repeat with itemNum = (endItemNum+1) to item 2 of the extents of storyArray
      put pageArray [story][itemNum] into afterStoryArray [afterItemNum]
   end repeat
   return afterStoryArray
end storyArray_GetAfter

function storyArray_GetLastPageFold storyArray
   -- was "fedwiki_FindLastStoryArrayDivider" then "storyArray_GetLastPageFold"
   put item 2 of the extents of storyArray into maxNum
   repeat with itemNum = maxNum down to 1
      put storyArray [itemNum] into itemArray
      if itemArray ["type"] = "pagefold" then
         return itemNum
      end if
   end repeat
   return 0
end storyArray_GetLastPageFold

command storyArray_AddGraphviz @storyArray, graphText, pDot, pSVG, pItemID
   put itemArray_ConstructGraphviz (graphText, pDot, pSVG, pItemID) into itemArray
   itemArray_AddToEnd itemArray, storyArray
end storyArray_AddGraphviz

command storyArray_AddMarkdown @storyArray, mdText, pID
   storyArray_AddItemArray storyArray, "markdown", mdText, pID
end storyArray_AddMarkdown

command storyArray_AddItemArray @storyArray, itemType, itemText, pID
   put itemArray_Construct (itemType, pID, itemText) into itemArray
   itemArray_AddToEnd itemArray, storyArray
end storyArray_AddItemArray

function storyArray_ExtractOrderedIDArray storyArray
   put item 2 of the extents of storyArray into maxItem
   repeat with itemNum = 1 to maxItem
      put storyArray [itemNum]["id"] into storyID
      put storyID into oderedIdArray [itemNum]
   end repeat
   return oderedIDArray
end storyArray_ExtractOrderedIDArray


--> StoryArray | Model
-
command storyArray_InsertAfter @storyArray, afterNum, itemArray
   put afterNum + 1 into intoNum
   storyArray_InsertInto storyArray, intoNum, itemArray
end storyArray_InsertAfter

command storyArray_InsertInto @storyArray, intoNum, itemArray
   put item 2 of the extents of storyArray into maxItem
   
   # Move items below intoNum down 1
   repeat with itemNumToMove = maxItem down to intoNum
      put itemNumToMove + 1 into itemNumDestination
      put storyArray [itemNumToMove] into storyArray [itemNumDestination]
   end repeat
   
   # Insert itemArray into item intoNum of storyArray
   put itemArray into storyArray [intoNum]
end storyArray_InsertInto

command storyArray_AddToEnd @storyItemArray, moreStoryItemArray
   if moreStoryItemArray is not an array then return false
   repeat with storyItemNum = 1 to item 2 of the extents of moreStoryItemArray
      put moreStoryItemArray [storyItemNum] into itemArray
      itemArray_AddToEnd itemArray, storyItemArray
   end repeat
   return true
end storyArray_AddToEnd

command storyArray_DeleteItem @storyArray, itemNumToDelete
   put storyArray [ItemNumToDelete] into deletedItemArray
   --
   indexArray_Delete storyArray, itemNumToDelete 
   return deletedItemArray
end storyArray_DeleteItem
