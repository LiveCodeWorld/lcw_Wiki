script "lib_PageArray"
--> MetaData
-
license: GPLv3
name: lib_PageArray
type: library
version: 0.1

/*
This is a library for manipulating Fedwiki page-array structures derived from the page-json schema.
See also "lib_PageArray", "model_PageArray" and "lib_FedwikiCreate"
*/


--> PageData
-
/*
PageData = pageArray + metadata
In particular we add curlyData to allow access to tiems by name not simply id or itemNum
*/

function pageData_GetText pageData, varName
   put pageData_GetItemArray (pageData, varName) into itemArray
   return itemArray ["text"]
end pageData_GetText

function pageData_GetItemArray pageData, varName
   put pageData ["pageItem"][varName] into itemID
   put fedwiki_FindItemID (itemID, pageData) into itemNum
   put pageData ["story"][itemNum] into itemArray
   return itemArray
end pageData_GetItemArray


--> PageArray | Video
-
command pageArray_AddVideo @pageArray, videoID, videoType, videoDescription, pID
   -- videoID can be "webm http://xxx"
   if videoID is empty then return false
   put pageArray_ConstructVideoArray (videoID, videoType, videoDescription, pID) into itemArray
   fedwiki_AddItemArrayToStoryEnd itemArray, pageArray
   return true
end pageArray_AddVideo

function pageArray_ConstructVideoArray videoID, videoType, videoDescription, pID
   fedwiki_SetID pID
   put toUpper (videoType) && videoID & CR & line 1 of videoDescription into itemArray ["text"]
   put "video" into itemArray ["type"]
   put pID into itemArray ["id"]
   return itemArray
end pageArray_ConstructVideoArray


--> PageArray
-
command pageArray_ReplaceGraph @pageArray, dotText
   -- replaces first graph in pageArray
   put fedwiki_FindItemType ("graphviz", pageArray) into itemNum
   if itemNum > 0 then
      put dotText into pageArray ["story"][itemNum]["text"]
   end if
end pageArray_ReplaceGraph

function pageArray_ExtractRefItems fromPageArray
   put fromPageArray ["story"] into fromStoryArray
   put 1 into newItemNum
   repeat with itemNum = 1 to item 2 of the extents of fromStoryArray
      put fromStoryArray [itemNum] into itemArray
      if itemArray ["type"] = "reference" then
         put itemArray into refItemStoryArray [newItemNum]
         add 1 to newItemNum
      end if
   end repeat
   return refItemStoryArray
end pageArray_ExtractRefItems

function pageArray_GetFirstPageFold pageArray
   put pageArray ["story"] into storyArray
   repeat with itemNum = 1 to item 2 of the extents of storyArray
      put storyArray [itemNum] into itemArray
      if itemArray ["type"] = "pagefold" then exit repeat
      
      put itemArray into storyArrayHeader [itemNum]
   end repeat
   return storyArrayHeader
end pageArray_GetFirstPageFold

function storyArray_GetLastPageFold storyArray
   -- was "fedwiki_FindLastStoryArrayDivider"
   put item 2 of the extents of storyArray into maxNum
   repeat with itemNum = maxNum down to 1
      put storyArray [itemNum] into itemArray
      if itemArray ["type"] = "pagefold" then
         return itemNum
      end if
   end repeat
   return 0
end storyArray_GetLastPageFold


--> Curly
-
function curly_GetData curlyData, varName
   put curlyData ["pageItem"][varName] into itemID
   put curlyData ["id"][itemID] into varText
   return varText
end curly_GetData

command curly_SetData @curlyData, varName, varText
   -- curlyData should already have been prepped with "curly_SetPageItemArray"
   put curlyData ["pageItem"][varName] into itemID
   put varText into curlyData ["id"][itemID]
end curly_SetData

command curly_SetPageItemArray @curlyData, varName, pageItemID
   put pageItemID into curlyData ["pageItem"][varName]
end curly_SetPageItemArray

command curly_MergePageArray @pageArray, curlyData
   -- lets merge specific item ids
   put curlyData ["id"] into curlyIdArray
   curly_SetPageItems pageArray, curlyIdArray
   
   -- let's merge everything looping through every story item
   curly_MergeAll pageArray, curlyData
end curly_MergePageArray

command curly_SetPageItems @pageArray, curlyIdArray
   repeat for each key itemID in curlyIdArray
      put curlyIdArray [itemID] into itemText
      fedwiki_SetStoryItemText pageArray, itemID, itemText
   end repeat
end curly_SetPageItems

command curly_MergeAll @pageArray, curlyData
   put curlyData ["all"] into curlyArray
   
   -- curly merge every story items text
   put pageArray ["story"] into storyArray
   repeat with itemNum = 1 to item 2 of the extents of storyArray
      put storyArray [itemNum]["text"] into itemText
      curly_Merge itemText, curlyArray
      put itemText into pageArray ["story"][itemNum]["text"]
   end repeat
end curly_MergeAll

command curly_Merge @someText, curlyArray
   repeat for each key curlyLabel in curlyArray
      put curlyArray [curlyLabel] into curlyReplacement
      put "(\{\{\s*" & curlyLabel & "\s*\}\})" into someReg
      text_StripReg someText, someReg, curlyReplacement
   end repeat
end curly_Merge


--> Private | Deps
-
private command text_StripReg @wikiText, someReg, pReplaceText
   local refStart, refEnd
   put 0 into indexNum
   repeat
      get matchchunk (wikiText, someReg, sNum, eNum)
      if sNum is not a number then
         put the result into testResult
         -- breakpoint
         exit repeat -- regExp bug???
      end if
      
      if it is true then
         -- this bit not needed (remove for speed)
         -- put char refStart to refEnd of wikiText into someTest
         put sNum into stripResultArray [indexNum]["sNum"]
         put eNum into stripResultArray [indexNum]["eNum"]
         add 1 to indexNum
         --
         -- delete char sNum to eNum of wikiText
         put pReplaceText into char sNum to eNum of wikiText
      else
         exit repeat
      end if
   end repeat
   return stripResultArray
end text_StripReg
