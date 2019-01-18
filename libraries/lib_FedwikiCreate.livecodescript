script "lib_FedwikiCreate"
--> MetaData
-
license: GPLv3
name: lib_FedwikiCreate
type: library
version: 0.1

/*
This is a library for creating fedwiki pages and sites
*/


--> Fedwiki | Template
-
function fedwiki_GetStoryItemText @pageArray, itemID
   put fedwiki_FindStoryItemNum (itemID, pageArray) into itemNum
   put pageArray ["story"][itemNum]["text"] into itemText
   return itemText
end fedwiki_GetStoryItemText

command fedwiki_SetStoryItemText @pageArray, itemID, itemText
   put fedwiki_FindStoryItemNum (itemID, pageArray) into itemNum
   put itemText into pageArray ["story"][itemNum]["text"]
   return itemNum
end fedwiki_SetStoryItemText

function fedwiki_GetStoryItemType @pageArray, itemID
   put fedwiki_FindStoryItemNum (itemID, pageArray) into itemNum
   put pageArray ["story"][itemNum]["type"] into itemText
   return itemText
end fedwiki_GetStoryItemType

command fedwiki_SetStoryItemType @pageArray, itemID, itemText
   put fedwiki_FindStoryItemNum (itemID, pageArray) into itemNum
   put itemText into pageArray ["story"][itemNum]["type"]
   return itemNum
end fedwiki_SetStoryItemType


--> Fedwiki | Template
-
function fedwiki_FindStoryItemNum itemID, pageArray
   put pageArray ["story"] into storyArray
   put item 2 of the extents of storyArray into maxItem
   repeat with itemNum = 1 to maxItem
      put storyArray [itemNum]["id"] into testID
      if testID = itemID then
         return itemNum
      end if
   end repeat
   return 0
end fedwiki_FindStoryItemNum



