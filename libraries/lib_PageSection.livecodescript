﻿script "lib_PageSection"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: lib_PageSection
type: library
version: 0.1

/*Some help*/


--> Working on
-
command pageArray_ReplaceSection @pArray, sTitle, storyArray
   pageArray_DeleteSection pArray, sTitle
   if the result = 0 then return 0
   put item 1 of the result - 1 into beforeTitleNum
   --
   pageArray_InsertAfter pArray, storyArray, beforeTitleNum
   return beforeTitleNum
end pageArray_ReplaceSection

command pageArray_ReplaceSectionMarkdown @pArray, sTitle, sMarkdown
   local startItemNum, endItemNum
   
   pageArray_DeleteSection pArray, sTitle
   if the result = 0 then return 0
   put item 1 of the result - 1 into beforeTitleNum
   --
   put "#" && sTitle & CR&CR before sMarkdown 
   get storyArray_ConstructItem (sMarkdown, "markdown")
   put it into sArray[1]
   --
   breakpoint
   pageArray_InsertAfter pArray, sArray, beforeTitleNum
   --
   return itemNumsToDelete
end pageArray_ReplaceSectionMarkdown

command pageArray_ReplaceSectionBody @pageArray, sectionTitle, storyArray
   pageArray_DeleteSection pageArray, sectionTitle, true
   if the result = 0 then return 0
   put item 1 of the result - 1 into titleNum
   --
   pageArray_InsertAfter pageArray, storyArray, titleNum
   return titleNum
end pageArray_ReplaceSectionBody


--> PageArray | Section | Edit
-
command pageArray_InsertAfter @pageArray, storyArray, afterItemNum
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
end pageArray_InsertAfter

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
   storyArray_InsertInto storyArray, toItemNum, itemArray
   put storyArray into pageArray ["story"]
   
   -- update journal
   put storyArray_ExtractorderedIDArray (storyArray) into oderedIDArray
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
   if itemNumsToDelete = 0 then return false
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
   return true
end pageArray_DeleteItem


--> PageArray | Section
-
function pageArray_GetSectionItemText  itemType, pageArray, sectionTitle
   put pageArray_GetSectionItemArray (itemType, pageArray, sectionTitle) into itemArray
   return itemArray ["text"]
end pageArray_GetSectionItemText

function pageArray_GetSectionItemArray itemType, pageArray, sectionTitle
   put pageArray_GetSection (sectionTitle, pageArray) into sectionStory
   --
   put item 2 of the extents of sectionStory into maxItem
   repeat with itemNum = 1 to maxItem
      put sectionStory [itemNum] into itemArray
      put itemArray ["type"] into testType
      if itemType = testType then
         return itemArray
      end if
   end repeat
   return empty
end pageArray_GetSectionItemArray

function pageArray_SectionData pageArray
   -- being a bit lazy with numbering of section items
   put pageArray ["story"] into storyArray
   --
   put "Untitled" into sectionTitle
   put 1 into sectionNum
   put sectionTitle into sectionData [sectionNum]["sectionTitle"]
   put 0 into sectionData [sectionNum]["titleItemNum"]
   --
   repeat with itemNum = 1 to item 2 of the extents of storyArray
      put storyArray [itemNum] into itemArray 
      put itemArray_GetSectionTitle (itemArray) into sectionTitle
      if sectionTitle is empty then
         put itemArray into sectionData [sectionNum]["section"][itemNum]
      else
         add 1 to sectionNum
         put sectionTitle into sectionData [sectionNum]["sectionTitle"]
         put itemNum into sectionData [sectionNum]["titleItemNum"]
         --
         get itemArray ["text"] 
         put word 1 to -1 of line 2 to -1 of it into sectionTextUnderTitle
         if sectionTextUnderTitle is not empty then
            put sectionTextUnderTitle into itemArray ["text"]
            put itemArray into sectionData [sectionNum]["section"][itemNum]
         end if
      end if
   end repeat
   return sectionData
end pageArray_SectionData


--> Page | Section
-
function pageArray_FindFirstSectionItem sectionTitle, itemType, pageArray
   get pageArray_GetSectionItemNums (sectionTitle, pageArray)
   put item 1 of it into sNum
   put item -1 of it into eNum
   repeat with itemNum = (sNum + 1) to eNum
      get pageArray ["story"][itemNum]["type"]
      if it = itemType then
         return itemNum
      end if
   end repeat
   return 0
end pageArray_FindFirstSectionItem

function pageArray_GetSectionItemNums sectionTitle, pageArray
   local startItemNum, endItemNum
   pageArray_SetSectionOffsets sectionTitle, pageArray, startItemNum, endItemNum
   if the result is false then return 0
   repeat with itemNum = startItemNum to endItemNum
      put itemNum & comma after itemNums
   end repeat
   delete char -1 of itemNums
   return itemNums
end pageArray_GetSectionItemNums

command pageArray_SetSectionOffsets sectionTitle, pageArray, @startItemNum, @endItemNum
   if sectionTitle is empty then
      put 1 into startItemNum
   else
      put pageArray_FindTitle (pageArray, sectionTitle) into startItemNum
      if startItemNum is 0 then
         put 0 into secondItemNum
         return false
      end if
   end if
   
   put pageArray_FindTitle (pageArray, "*", startItemNum) into itemNum
   if itemNum = 0 then
      put pageArray ["story"] into storyArray
      put item 2 of the extents of storyArray into endItemNum
   else
      put itemNum-1 into endItemNum
   end if
   return true
end pageArray_SetSectionOffsets


--> PageArray | Section
-
function pageArray_GetSection sectionTitle, pageArray
   local startItemNum, endItemNum, newStory
   --
   pageArray_SetSectionOffsets sectionTitle, pageArray, startItemNum, endItemNum
   if the result is false then return 0
   --
   put 1 into newItemNum
   repeat with itemNum = startItemNum to endItemNum
      put pageArray ["story"][itemNum] into newStory [newItemNum]
      add 1 to newItemNum
   end repeat
   return newStory
end pageArray_GetSection

command pageArray_EditSectionTitleText @pageArray, sectionTitle, someMarkDown
   pageArray_ReplaceSectionMarkdown pageArray, sectionTitle, someMarkDown
   --
   pageArray_StripJournal pageArray
   pageArray_AddFork pageArray, "fedwiki.org,roster.fedwiki.org,sites.fedwiki.org"
   return sectionTitleID
end pageArray_EditSectionTitleText

command pageArray_DeleteSection @pageArray, sectionTitle, pNotTitle
   pageArray_SetSectionOffsets sectionTitle, pageArray, startItemNum, endItemNum
   if the result is false then return 0
   
   if pNotTitle is true then
      if startItemNum = endItemNum then
         -- let's delete any text below the title of the markdown item
         get pageArray ["story"][startItemNum]["text"]
         put word 1 to -1 of line 1 of it into pageArray ["story"][startItemNum]["text"]
         return startItemNum + 1 -- hack that seems illogical
      else
         add 1 to startItemNum
      end if
   end if
   
   repeat with itemNum = startItemNum to endItemNum
      put itemNum & comma after itemNumsToDelete
   end repeat
   delete char -1 of itemNumsToDelete
   --
   pageArray_DeleteItem pageArray, itemNumsToDelete
   --
   return itemNumsToDelete
end pageArray_DeleteSection