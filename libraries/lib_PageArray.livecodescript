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


--> Atopia | WikiPage | Model
-
command atopia_StoreWikiPageArray fedwikiDomain, pageSlug, pageArray
   put json_FromArray (pageArray) into pageJSON
   atopia_StoreWikiJson fedwikiDomain, pageSlug, pageJSON
   put the result into shellResult
   return shellResult -- should be empty unless an error
end atopia_StoreWikiPageArray

function atopia_FetchWikiJson pageSlug, fedwikiDomain, pUseSSH
   if pUseSSH is true then
      put fedwiki_ConstructPath (fedwikiDomain, pageSlug) into wikiPagePath
      put atopia_FetchData (wikiPagePath) into someJSON
   else
      put fedwiki_FetchPageJson (fedwikiDomain, pageSlug) into someURL
   end if
   return someJSON
end atopia_FetchWikiJson

command atopia_StoreWikiJson fedwikiDomain, pageSlug, pageJSON
   put fedwiki_ConstructPath (fedwikiDomain, pageSlug) into wikiPagePath
   --
   atopia_StoreData wikiPagePath, pageJSON
   put the result into shellResult
   if shellResult is not empty then return shellResult
   
   -- now should update the sitemap
   atopia_DeleteWikiSitemap fedwikiDomain
   return shellResult -- should be empty unless an error
end atopia_StoreWikiJson

command atopia_DeleteWikiJSON fedwikiDomain, pageSlug
   put fedwiki_ConstructPath (fedwikiDomain, pageSlug) into wikiPagePath
   --
   atopia_DeleteFile wikiPagePath
   --
   put the result into shellResult
   return shellResult
end atopia_DeleteWikiJSON

command atopia_DeleteWikiSitemap fedwikiDomain
   put fedwiki_ConstructSitemapPath (fedwikiDomain) into sitemapPath
   --
   atopia_DeleteFile sitemapPath
   --
   put the result into shellResult
   return shellResult
end atopia_DeleteWikiSitemap


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


--> PageArray | Template | Model
-
function pageArray_FetchTemplate fedwikiDomain, pageSlug, curlyKey, curlyValue
   if curlyKey is an array then
      put curlyKey into curlyArray
   else
      put curlyValue into curlyArray [curlyKey]
   end if
   -- some default values
   put pageSlug into curlyArray ["Page Slug"]
   put fedwikiDomain into curlyArray ["Wiki Domain"]
   if curlyArray ["Page Title"] is empty then
      put fedwiki_ConstructTitle (pageSlug) into curlyArray ["Page Title"]
   end if
   --
   put pageArray_Fetch (fedwikiDomain, pageSlug) into pageArray
   _MergeCurlyArray pageArray, curlyArray
   return pageArray
end pageArray_FetchTemplate


--> PageArray | Handler | Help | Model
-
function pageArray_FetchHandler hKey
   _SetHandlerDomainInfo hKey, wikiDomain, pageTitle, pageSlug
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   return pageArray
end pageArray_FetchHandler

command pageArray_StoreHandler hKey, pageArray
   _SetHandlerDomainInfo hKey, wikiDomain, pageTitle, pageSlug
   --
   atopia_StoreWikiPageArray wikiDomain, pageSlug, pageArray
   put the result into shellResult
   return shellResult
end pageArray_StoreHandler


--> PageArray
-
command pageArray_ReplaceGraph @pageArray, dotText
   -- replaces first graph in pageArray
   put fedwiki_FindItemType ("graphviz", pageArray) into itemNum
   if itemNum > 0 then
      put dotText into pageArray ["story"][itemNum]["text"]
   end if
end pageArray_ReplaceGraph


--> PageArray | Curly
-
command pageArray_MergeCurly @pageArray, curlyData
   -- lets merge specific item ids
   put curlyData ["id"] into curlyIdArray
   _MergeCurlyIDArray pageArray, curlyIdArray
   
   -- let's merge everything looping through every story item
   put curlyData ["all"] into curlyArray
   _MergeCurlyArray pageArray, curlyArray
end pageArray_MergeCurly

command pageArray_CurlyMergeItem @pageArray, itemID, curlyArray
   -- applies curly merge to a page-item with id itemID
   put fedwiki_GetStoryItemText (pageArray, itemID) into itemText
   text_MergeCurly itemText, curlyArray
   fedwiki_SetStoryItemText pageArray, itemID, itemText
end pageArray_CurlyMergeItem

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


--> Private
-
private command _MergeCurlyArray @pageArray, curlyArray
   -- curly merge every story items text
   put pageArray ["story"] into storyArray
   repeat with itemNum = 1 to item 2 of the extents of storyArray
      put storyArray [itemNum]["text"] into itemText
      text_MergeCurly itemText, curlyArray
      put itemText into pageArray ["story"][itemNum]["text"]
   end repeat
end _MergeCurlyArray

private command _MergeCurlyIDArray @pageArray, curlyIdArray
   repeat for each key itemID in curlyIdArray
      put curlyIdArray [itemID] into itemText
      -- pageArray_CurlyMergeItem pageArray, itemID, curlyArray
      fedwiki_SetStoryItemText pageArray, itemID, itemText
   end repeat
end _MergeCurlyIDArray

private command _SetHandlerDomainInfo hKey, @wikiDomain, @pageTitle, @pageSlug
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   put "handler.livecode.world" into wikiDomain
   put text_InitialCaps (hName) into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
end _SetHandlerDomainInfo


--> Deps
-
command text_MergeCurly @someText, curlyArray
   repeat for each key curlyLabel in curlyArray
      put curlyArray [curlyLabel] into curlyReplacement
      put "(\{\{\s*" & curlyLabel & "\s*\}\})" into someReg
      text_StripReg someText, someReg, curlyReplacement
   end repeat
end text_MergeCurly

command text_StripReg @wikiText, someReg, pReplaceText
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
