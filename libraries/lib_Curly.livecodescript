script "lib_Curly"
--> MetaData
-
license: GPLv3
name: lib_Curly
type: library
version: 0.1


--> PageData
-
/*
PageData = pageArray + metadata
In particular we add curlyData to allow access to items by name not simply id or itemNum
Not entirey sure how useful this aproach is yet - seems over-complicated
*/

function pageData_GetText pageData, varName
   put pageData_GetItemArray (pageData, varName) into itemArray
   return itemArray ["text"]
end pageData_GetText

function pageData_GetItemArray pageData, varName
   put pageData ["pageItem"][varName] into itemID
   put pageArray_FindItemID (itemID, pageData) into itemNum
   put pageData ["story"][itemNum] into itemArray
   return itemArray
end pageData_GetItemArray


--> Working on
-
function wiki_Merge someText
   -- old
   replace "[" with "{{{" in someText
   replace "]" with "}}}" in someText
   put merge (someText) into mergedText
   replace "{{{" with "[" in mergedText
   replace "}}}" with "]" in mergedText
   return mergedText
end wiki_Merge


--> Curly | Merge
-
command curly_ReplacePageArray @pageArray, curlyKey, curlyReplacement
   put pageArray ["story"] into storyArray
   repeat with itemNum = 1 to item 2 of the extents of storyArray
      get storyArray [itemNum]["text"]
      put it into itemText
      curly_ReplaceText itemText, curlyKey, curlyReplacement
      if itemText is not it then
         put itemText into pageArray ["story"][itemNum]["text"]
         put itemNum & comma after updateditemNums
      end if
   end repeat
   delete char -1 of updateditemNums
   return updateditemNums
end curly_ReplacePageArray

command curly_MergeAll @pageArray, curlyData
   -- curly merge every story items text
   put curlyData ["all"] into curlyArray
   put pageArray ["story"] into storyArray
   repeat with itemNum = 1 to item 2 of the extents of storyArray
      put storyArray [itemNum]["text"] into itemText
      curly_Merge itemText, curlyArray
      put itemText into pageArray ["story"][itemNum]["text"]
   end repeat
end curly_MergeAll

command curly_Merge @someText, curlyArray
   repeat for each key curlyKey in curlyArray
      put curlyArray [curlyKey] into curlyReplacement
      curly_ReplaceText someText, curlyKey, curlyReplacement
   end repeat
end curly_Merge

command curly_ReplaceText @someText, curlyKey, curlyReplacement
   -- put "(\{\{\s*" & curlyKey & "\s*\}\})" into someReg
   put "(?Uim)\{\{\s*" & curlyKey & "\s*\}\}" into someReg
   -- text_StripReg someText, someReg, curlyReplacement
   put replacetext (someText, someReg, curlyReplacement) into someText
end curly_ReplaceText


--> Curly | PageArray
-
command curly_MergePageArray @pageArray, curlyData
   # Merge specific item ids
   put curlyData ["id"] into curlyIdArray
   curly_SetPageItems pageArray, curlyIdArray
   
   # Replace any sections such as ref-item arrays
   curly_ReplacePageItems pageArray, curlyData
   
   # Merge everything looping through every story item
   curly_MergeAll pageArray, curlyData
end curly_MergePageArray

command curly_ReplacePageItems @pageArray, curlyData
   put curlyData ["replace"] into replaceArray
   repeat for each key itemID in replaceArray
      put replaceArray [itemID] into itemArray
      pageArray_SetItemArray pageArray, itemID, itemArray
   end repeat
end curly_ReplacePageItems

command curly_SetPageItems @pageArray, curlyIdArray
   repeat for each key itemID in curlyIdArray
      put curlyIdArray [itemID] into itemText
      pageArray_SetItemText pageArray, itemID, itemText
   end repeat
end curly_SetPageItems


--> Curly
-
function curly_GetData curlyData, varName
   put curlyData ["pageItem"][varName] into itemID
   put curlyData ["id"][itemID] into varText
   return varText
end curly_GetData

command curly_SetData @curlyData, varName, varText
   -- curlyData should already have been prepped with "curly_SetItemIDArray"
   put curlyData ["pageItem"][varName] into itemID
   put varText into curlyData ["id"][itemID]
end curly_SetData

command curly_SetItemIDArray @curlyData, varName, pageItemID
   -- creates a lookup table itemName => itemID
   put pageItemID into curlyData ["pageItem"][varName]
end curly_SetItemIDArray

command curly_SetReplaceArray @curlyData, itemArray, itemID, pNewItemID
   -- stores an itemArray to replace an item id in pageArray
   if pNewItemID is not true then
      put itemID into itemArray ["id"]
   end if
   put itemArray into curlyData ["replace"][itemID]
end curly_SetReplaceArray


--> WikiText
-
function wikiText_ExtractInternalLinks wikiText
   local linkArray
   wikiText_AddToInternalLinkArray linkArray, wikiText
   put keys (linkArray) into internalLinks
   sort internalLinks
   return internalLinks
end wikiText_ExtractInternalLinks

command wikiText_AddToInternalLinkArray @linkArray, wikiText, itemID
   local sNum, eNum
   -- put "(\[\[.+\]\])" into someReg
   put "[^\]]*" into notClosingBracket
   put "(\[\[" & notClosingBracket & "\]\])" into someReg
   repeat
      get matchchunk (wikiText, someReg, sNum, eNum) 
      if it is false then return true
      
      put char sNum to eNum of wikiText into internalLink
      delete char 1to 2 of internalLink
      delete char -2 to -1 of internalLink
      put itemID into linkArray [internalLink]
      delete char 1 to eNum of wikiText
   end repeat
end wikiText_AddToInternalLinkArray

function wikitext_ExtractExternalLinks wikiText
   local extLinkArray
   wikiText_AddToExternalLinkArray extLinkArray, wikiText
   put the result into extLinkURLs
   return extLinkURLs
end wikitext_ExtractExternalLinks

function wikiText_ExtractExternalLinkArray wikiText
   local extLinkArray
   wikiText_AddToExternalLinkArray extLinkArray, wikiText
   put the result into extLinkURLs
   return extLinkArray
end wikiText_ExtractExternalLinkArray

command wikiText_AddToExternalLinkArray @extLinkArray, wikiText, itemID
   -- todo: add search for markdown links
   local sNum, eNum
   put "[^\]]*" into notClosingBracket
   put "(\[http" & notClosingBracket & "\])" into someReg
   put 1 into indexNum
   repeat
      get matchchunk (wikiText, someReg, sNum, eNum) 
      if it is false then
         put keys (tempArray) into extLinkURLs
         return extLinkURLs
      end if
      
      put char sNum to eNum of wikiText into extLinkText
      delete char - 1 of extLinkText
      delete char 1 of extLinkText
      put word 1 of extLinkText into extLinkURL
      put word 2 to -1 of extLinkText into extLinkText
      --
      put extLinkText into extLinkArray [indexNum]["text"]
      put extLinkURL into extLinkArray [indexNum]["url"]
      put itemID into extLinkArray [indexNum]["id"]
      put empty into tempArray [extLinkURL]
      --
      delete char 1 to eNum of wikiText
      add 1 to indexNum
   end repeat
end wikiText_AddToExternalLinkArray
