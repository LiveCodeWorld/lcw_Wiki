script "lib_PageSection"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_PageSection
type: library
version: 0.2

/* A "section" is a set of wiki page-items bounded by markdown titles.

The exception is the first and last sections which do not require an initial title or an ending title.
You can refer to sections by index or title.
*/


--> Working on
-
function pageArray_GetFirstCode pageArray
   put pageArray ["story"] into storyArray
   repeat with itemNum = 1 to item 2 of the extents of storyArray
      put storyArray [itemNum] into itemArray
      if itemArray ["type"] = "code" then
         put storyArray [itemNum]["text"] into itemText
         return itemText
      end if
   end repeat
   return empty
end pageArray_GetFirstCode

command pageArray_SetFirstCode @pageArray, codeText
   put pageArray ["story"] into storyArray
   repeat with itemNum = 1 to item 2 of the extents of storyArray
      put storyArray [itemNum] into itemArray
      if itemArray ["type"] = "code" then
         put storyArray [itemNum]["text"] into oldCodeText
         put codeText into pageArray ["story"][itemNum]["text"]
         return oldCodeText
      end if
   end repeat
   return empty
end pageArray_SetFirstCode


--> PageArray | BulletIndex
-
command pageArray_SetSectionBulletIndex @pageArray, sectionTitle, bulletIndex, pIntroText
   put markdown_LinkedBullets (bulletIndex) into sMarkdown
   if pIntroText is not empty then
      put pIntroText &CR&CR before sMarkdown
   end if
   --
   pageArray_ReplaceSectionMarkdown pageArray, sectionTitle, sMarkdown
   --
   put the result into itemNumsToDelete
   return itemNumsToDelete
end pageArray_SetSectionBulletIndex

command pageArray_ReplaceSectionMarkdown @pArray, sTitle, sMarkdown
   local startItemNum, endItemNum
   
   pageArray_DeleteSection pArray, sTitle
   if the result = 0 then return 0
   put item 1 of the result - 1 into beforeTitleNum
   --
   put "#" && sTitle & CR&CR before sMarkdown 
   get itemArray_Construct ("markdown", "", sMarkdown)
   put it into sArray[1]
   --
   pageArray_InsertStoryAfter pArray, sArray, beforeTitleNum
   --
   return itemNumsToDelete
end pageArray_ReplaceSectionMarkdown


--> PageArray | Section
-
command pageArray_AddSection @pageArray, storyArray, sectionTitle, pAfterSectionTitle
   pageArray_SetSectionOffsets sectionTitle, pageArray, startItemNum, endItemNum
   if the result is true then
      # Replace section
      pageArray_ReplaceSection pageArray, sectionTitle, storyArray
      return "replaced"
   end if
   
   if pAfterSectionTitle is empty then
      pageArray_AddStory pageArray, storyArray
      return "end"
   else
      pageArray_SetSectionOffsets pAfterSectionTitle, pageArray, startItemNum, endItemNum
      if the result is true then
         pageArray_InsertStoryAfter pageArray, storyArray, endItemNum
         return "after"
      else
         pageArray_AddStory pageArray, storyArray
         return "end"
      end if
   end if
end pageArray_AddSection

function pageArray_GetSectionBulletIndex pageArray, sectionTitle
   put pageArray_GetSection (sectionTitle, pageArray) into sectionStory
   --
   put item 2 of the extents of sectionStory into maxItem
   repeat with itemNum = 2 to maxItem
      put sectionStory [itemNum] into itemArray
      if itemArray ["type"] is not "markdown" then next repeat
      --
      put itemArray ["text"] & CR into itemText
      filter itemText with "- *"
      put CR after itemText
      replace "- [[" with empty in itemText
      replace ("]]" & CR) with CR in itemText
      put itemText after bulletLines
   end repeat
   return word 1 to -1 of bulletLines
end pageArray_GetSectionBulletIndex

function pageArray_GetSectionText pageArray
   put pageArray_GetSection (sectionTitle, pageArray) into sectionStory
   --
   put item 2 of the extents of sectionStory into maxItem
   repeat with itemNum = 2 to maxItem
      put sectionStory [itemNum] into itemArray
      put itemArray ["text"] into itemText
      put itemText & CR&CR after sectionText
   end repeat
   return word 1 to -1 of sectionText
end pageArray_GetSectionText


--> PageArray | PageFold
-
command pageArray_TrimToPageFold @pageArray
   put pageArray_FindItemType ("pagefold", pageArray) into storyItemNum
   if storyItemNum = 0 then return false
   put item 2 of the extents of pageArray ["story"] into maxNum
   repeat with itemNum = (storyItemNum + 1) to maxNum
      put pageArray ["story"][itemNum]["id"] into deletedItemID
      pageArray_AddDeleteAction pageArray, deletedItemID
      delete variable pageArray ["story"][itemNum]
   end repeat
end pageArray_TrimToPageFold

function pageArray_GetFirstPageFold pageArray
   put pageArray ["story"] into storyArray
   repeat with itemNum = 1 to item 2 of the extents of storyArray
      put storyArray [itemNum] into itemArray
      if itemArray ["type"] = "pagefold" then exit repeat
      
      put itemArray into storyArrayHeader [itemNum]
   end repeat
   return storyArrayHeader
end pageArray_GetFirstPageFold

function pageArray_GetLastPageFold pageArray
   put pageArray ["story"] into storyArray
   put storyArray_GetLastPageFold (storyArray) into itemNum
   return itemNum
end pageArray_GetLastPageFold


--> PageArray | Section
-
command pageArray_ReplaceSection @pArray, sTitle, storyArray
   pageArray_DeleteSection pArray, sTitle
   if the result = 0 then return 0
   put item 1 of the result - 1 into beforeTitleNum
   --
   pageArray_InsertStoryAfter pArray, storyArray, beforeTitleNum
   return beforeTitleNum
end pageArray_ReplaceSection

command pageArray_ReplaceSectionBody @pageArray, sectionTitle, storyArray
   pageArray_DeleteSection pageArray, sectionTitle, true
   if the result = 0 then return 0
   put item 1 of the result - 1 into titleNum
   --
   pageArray_InsertStoryAfter pageArray, storyArray, titleNum
   return titleNum
end pageArray_ReplaceSectionBody


--> PageArray | Section | Edit
-
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
   itemArray_NormalizeID pID
   
   put pageArray ["journal"] into journalArray
   put "move" into journalEntryArray ["type"]
   put pMilliseconds into journalEntryArray ["date"]
   put pID into journalEntryArray ["id"]
   put oderedIDArray into journalEntryArray ["order"]
   itemArray_AddToEnd journalEntryArray, journalArray
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
