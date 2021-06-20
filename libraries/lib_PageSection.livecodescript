script "lib_PageSection"
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

command pageArray_ReplaceSection @pageArray, sectionTitle, someMarkDown
   -- see also "pageArray_ReplaceSectionBody"
   -- use on markdown titles that include text after the title
   local startItemNum, endItemNum
   
   pageArray_DeleteSection pageArray, sectionTitle
   put the result into itemNumsToDelete
   --
   put "#" && sectionTitle & CR&CR & someMarkDown into itemText
   put storyArray_ConstructItem (itemText, "markdown", sectionTitleID) into itemArray
   put itemArray into storyArray [1]
   --
   put item 1 of itemNumsToDelete into titleItemNum
   pageArray_InsertStory pageArray, storyArray, titleItemNum
   --
   return itemNumsToDelete
end pageArray_ReplaceSection

command pageArray_EditSectionTitleText @pageArray, sectionTitle, someMarkDown
   pageArray_ReplaceSection pageArray, sectionTitle, someMarkDown
   --
   pageArray_StripJournal pageArray
   pageArray_AddFork pageArray, "fedwiki.org,roster.fedwiki.org,sites.fedwiki.org"
   return sectionTitleID
end pageArray_EditSectionTitleText

command pageArray_ReplaceSectionBody @pageArray, sectionTitle, storyArray
   pageArray_DeleteSection pageArray, sectionTitle 
   put item 1 of the result into titleItemNum
   subtract 1 from titleItemNum
   pageArray_InsertStory pageArray, storyArray, titleItemNum
   return titleItemNum
end pageArray_ReplaceSectionBody

command pageArray_DeleteSection @pageArray, sectionTitle
   pageArray_SetSectionOffsets sectionTitle, pageArray, startItemNum, endItemNum
   if the result is false then return 0
   repeat with itemNum = startItemNum to endItemNum
      put itemNum & comma after itemNumsToDelete
   end repeat
   delete char -1 of itemNumsToDelete
   --
   pageArray_DeleteItem pageArray, itemNumsToDelete
   --
   return itemNumsToDelete
end pageArray_DeleteSection
