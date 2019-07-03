script "lib_PageArray"
--> MetaData
-
license: GPLv3
name: lib_PageArray
type: library
version: 0.2

/*
This is a library for manipulating Fedwiki page-array structures derived from the page-json schema.
See also "lib_PageArray", "model_PageArray" and "lib_FedwikiCreate"
*/


--> Working on
-
command pageArray_DeleteSectionBody @pageArray, sectionTitle
   pageArray_SetSectionOffsets sectionTitle, pageArray, startItemNum, endItemNum
   if the result is false then return 0
   put startItemNum + 1 into bodyStartNum
   repeat with itemNum = bodyStartNum to endItemNum
      put itemNum & comma after itemNumsToDelete
   end repeat
   delete char -1 of itemNumsToDelete
   pageArray_DeleteItem pageArray, itemNumsToDelete
   return startItemNum
end pageArray_DeleteSectionBody

command pageArray_DeleteSection @pageArray, sectionTitle
   pageArray_SetSectionOffsets sectionTitle, pageArray, startItemNum, endItemNum
   if the result is false then return 0
   repeat with itemNum = startItemNum to endItemNum
      put itemNum & comma after itemNumsToDelete
   end repeat
   delete char -1 of itemNumsToDelete
   pageArray_DeleteItem pageArray, itemNumsToDelete
   return startItemNum
end pageArray_DeleteSection

command pageArray_SetSectionOffsets sectionTitle, pageArray, @startItemNum, @endItemNum
   put pageArray_FindTitle (pageArray, sectionTitle) into startItemNum
   if startItemNum is 0 then
      put 0 into secondItemNum
      return false
   end if
   
   put pageArray_FindTitle (pageArray, "*", startItemNum) into itemNum
   if itemNum = 0 then
      put pageArray ["story]"] into storyArray
      put item 2 of the extents of storyArray into endItemNum
   else
      put itemNum-1 into endItemNum
   end if
   return true
end pageArray_SetSectionOffsets

function pageArray_FindTitle pageArray, someTitle, pAfterItemNum
   if pAfterItemNum is not a number then put 0 into pAfterItemNum
   repeat
      put pageArray_FindItemType ("markdown", pageArray, pAfterItemNum) into itemNum
      if itemNum = 0 then return 0
      put pageArray ["story"][itemNum]["text"] into markDownText
      put word 1 to -1 of line 1 of markDownText into maybeTitle
      
      switch
         case someTitle = "*" and char 1 to 2 of maybeTitle = "# "
         case maybeTitle = "#" && someTitle
            return itemNum
         default
            put itemNum into pAfterItemNum
      end switch
   end repeat
   return 0
end pageArray_FindTitle

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

command storyArray_AddDividerToEnd @storyArray, lastDividerItemArray
   put item 2 of the extents of newStoryArray into nextItemNum
   add 1 to nextItemNum
   put lastDividerItemArray into newStoryArray [nextItemNum]
   return nextItemNum
end storyArray_AddDividerToEnd


--> PageArray | Transport
-
command pageArray_CompactRefs @pageArray
   -- this command takes and ref-items and adds them to a "# See also" section 
   put pageArray ["title"] into pageTitle
   put pageArray ["story"] into storyArray
   if storyArray is not an array then
      put "This is not a single wiki page. Only drop references to single pages on this transporter." &CR&CR& droppedURL into errorText
      fedwiki_ExitAndReturnError errorText
   end if
   
   put 1 into newItemNum
   put item 2 of the extents of storyArray into maxItemNum
   repeat with itemNum = 1 to maxItemNum
      put storyArray [itemNum] into itemArray
      put itemArray ["type"] into itemType
      if itemType = "reference" then
         put itemArray ["site"] into someSite
         put itemArray ["slug"] into someSlug
         put itemArray ["title"] into someTitle
         
         put "- [[" & someTitle & "]]" & CR after markDownLinks
         put itemNum & comma after itemNumsToDelete
      else
         put itemArray into newStoryArray [ itemNum]
      end if
   end repeat
   delete char -1 of itemNumsToDelete
   delete char -1 of markDownLinks
   --
   if markDownLinks is not empty then
      pageArray_DeleteItem pageArray, itemNumsToDelete
      
      put pageArray_FindTitle (pageArray, "See also") into storyItemNum
      if storyItemNum = 0 then
         pageArray_AddMarkdown pageArray, "# See also"
      end if
      pageArray_AddMarkdown pageArray, markDownLinks
   end if
end pageArray_CompactRefs


--> PageArray | Check
-
function pageArray_Check pageArray
   if pageArray is not an array then return false
   --
   put pageArray ["title"] into pageTitle
   put pageArray ["story"] into storyArray
   put pageArray ["journal"] into journalArray
   if pageTitle is empty or storyArray is not an array or journalArray is not an array then
      return false
   else
      return true
   end if
end pageArray_Check


--> PageArray | Construct
-
function pageArray_Construct pageTitle, someMarkdown
   -- was "fedwiki_ConstructSimplePageArray"
   put pageTitle into pageArray ["title"]
   pageArray_AddMarkdown pageArray, someMarkdown
   put pageArray_ConstructJournal (pageTitle) into pageArray ["journal"] 
   return pageArray
end pageArray_Construct

function pageArray_ConstructFactory pID
   pageArray_AssignID pID
   put "factory" into factoryArray ["type"]
   put pID into factoryArray ["id"]
   return factoryArray
end pageArray_ConstructFactory

function pageArray_ConstructJournal pageTitle, pSourceArray, pMilliseconds
   put pageArray_ConstructCreateArray (pageTitle, pSourceArray, pMilliseconds) into createArray
   put createArray into journalArray [1]
   return journalArray
end pageArray_ConstructJournal

function pageArray_ConstructCreateArray pageTitle, pMilliseconds, pSourceArray
   if pMilliseconds is not a number then put the milliseconds into pMilliseconds
   put "create" into createArray ["type"]
   put pMilliseconds into createArray ["date"]
   put pageTitle into createArray ["item"]["title"]
   put empty into createArray ["item"]["story"]
   if pSourceArray is an array then put pSourceArray into createArray ["source"]
   return createArray
end pageArray_ConstructCreateArray

function pageArray_ConstructReference pageSlug, wikiDomain, refText, pageTitle, pID
   pageArray_AssignID pID   
   put audioUrl & CR & someText into itemArray ["text"]
   
   put wikiDomain into itemArray ["site"]
   put pageTitle into itemArray ["title"]
   put pageSlug into itemArray ["slug"]
   put refText into itemArray ["text"]
   --
   put "reference" into itemArray ["type"]
   put pID into itemArray ["id"]
   return itemArray
end pageArray_ConstructReference

function pageArray_ConstructTransport transportLine, pID
   pageArray_AssignID pID
   put transportLine into itemArray ["text"]
   put "transport" into itemArray ["type"]
   put pID into itemArray ["id"]
   return itemArray
end pageArray_ConstructTransport

function pageArray_ConstructMap mapLat, mapLong, mapText, mapZoom, pPinText, pTileType, pID
   pageArray_AssignID pID
   put pID into itemArray ["id"]
   if mapLat is not empty then
      put mapLat into itemArray ["latlng"]["lat"]
      put mapLong into itemArray ["latlng"]["lng"]
   end if
   
   if mapText is empty then put "Map" into mapText
   if pPinText is not empty then
      -- "text": "Map\n52.207483, 0.115771 Master's Garden"
      put CR & mapLat & comma && mapLong && pPinText after mapText
   end if
   put mapText into itemArray ["text"]
   
   switch pTileType
      case "fsd"
         -- "tile": "http://stamen-tiles-{s}.a.ssl.fastly.net/toner/{z}/{x}/{y}.png",
         break
   end switch
   
   put "map" into itemArray ["type"]
   put mapZoom into itemArray ["zoom"]
   return itemArray
end pageArray_ConstructMap

function pageArray_ConstructAudio audioUrl, someText, pID
   pageArray_AssignID pID   
   put audioUrl & CR & someText into itemArray ["text"]
   put "audio" into itemArray ["type"]
   put pID into itemArray ["id"]
   return itemArray
end pageArray_ConstructAudio

function pageArray_ConstructItemArray someText, itemType, pID  
   pageArray_AssignID pID   
   put someText into itemArray ["text"]
   put itemType into itemArray ["type"]
   put pID into itemArray ["id"]
   return itemArray
end pageArray_ConstructItemArray


--> PageArray | Add
-
command pageArray_SetTitle @pageArray, someTitle, pID
   if someTitle is  empty then return false
   put "#" && someTitle into someMarkdown
   pageArray_AddMarkdown pageArray, someMarkdown, pID
   return true
end pageArray_SetTitle

command pageArray_AddMarkdown @pageArray, someMarkdown, pID
   if someMarkdown is  empty then return false
   put pageArray_ConstructItemArray (someMarkdown, "markdown", pID) into itemArray
   pageArray_AddItemArray itemArray, pageArray
   return true
end pageArray_AddMarkdown

command pageArray_AddText @pageArray, someText, pID
   if someText is  empty then return false
   put word 1 to -1 of someText into someText
   put pageArray_ConstructItemArray (someText, "paragraph", pID) into itemArray
   pageArray_AddItemArray itemArray, pageArray
   return true
end pageArray_AddText

command pageArray_AddHtml @pageArray, someHtml, pID
   if someCode is  empty then return false
   put pageArray_ConstructItemArray (someHtml, "html", pID) into itemArray
   pageArray_AddItemArray itemArray, pageArray
   return true
end pageArray_AddHtml

command pageArray_AddRoster @pageArray, rosterText, pID
   if rosterText is empty then return false
   put pageArray_ConstructItemArray (rosterText, "roster", pID) into itemArray
   pageArray_AddItemArray itemArray, pageArray
   return true
end pageArray_AddRoster

command pageArray_AddReference @pageArray, pageSlug, wikiDomain, refText, pageTitle, pID
   if pageSlug is empty then return false
   put pageArray_ConstructReference (pageSlug, wikiDomain, refText, pageTitle, pID) into itemArray
   pageArray_AddItemArray itemArray, pageArray
   return true
end pageArray_AddReference

command pageArray_AddFactory @pageArray, pID
   put pageArray_ConstructFactory (pID) into itemArray
   pageArray_AddItemArray itemArray, pageArray
   return true
end pageArray_AddFactory

command pageArray_AddPagefold @pageArray, someText, pID
   if someText is  empty then return false
   put word 1 to -1 of someText into someText
   put pageArray_ConstructItemArray (someText, "pagefold", pID) into itemArray
   pageArray_AddItemArray itemArray, pageArray
   return true
end pageArray_AddPagefold

command pageArray_AddCode @pageArray, someCode, pID
   if someCode is  empty then return false
   put pageArray_ConstructItemArray (someCode, "code", pID) into itemArray
   pageArray_AddItemArray itemArray, pageArray
   return true
end pageArray_AddCode

command pageArray_AddAudio @pageArray, audioUrl, someText, pID
   if audioUrl is  empty then return false
   put pageArray_ConstructAudio (audioUrl, someText, pID) into itemArray
   pageArray_AddItemArray itemArray, pageArray
   return true
end pageArray_AddAudio

command pageArray_AddMap @pageArray, mapLat, mapLong, mapText, mapZoom, pPinText, pTileType, pID
   if mapLat is  empty then return false
   put pageArray_ConstructMap (mapLat, mapLong, mapText, mapZoom, pPinText, pTileType, pID) into itemArray
   pageArray_AddItemArray itemArray, pageArray
   return true
end pageArray_AddMap

command pageArray_AddTransport @pageArray, pTransportLine, pID
   if pTransportLine is  empty then return false
   if pTransportLine is empty then
      put "POST https://rest.livecode.world/imagine" into pTransportLine
   end if
   put pageArray_ConstructTransport (pTransportLine, pID) into itemArray
   pageArray_AddItemArray itemArray, pageArray
   return true
end pageArray_AddTransport


--> PageArray | Story
-
command pageArray_AddItemArray itemArray, @pageArray
   -- was "fedwiki_AddItemArrayToStoryEnd"
   if itemArray is not an array then return 0
   
   put pageArray ["story"] into storyArray
   put pageArray ["journal"] into journalArray
   put itemArray ["id"] into itemID
   
   -- add the item to the end of the story
   array_AddToEndOfIndex itemArray, storyArray
   -- figure out what we just added it after
   -- this can be empty if it is the first entry
   put the result into afterID
   put storyArray into pageArray ["story"]
   
   -- 3) Now let's add the edit or add to the journal
   -- make the factory have the same id as the item we will add to the story
   put pageArray_ConstructFactory (itemID) into factoryArray
   -- now add a journal entry for adding after the id of the end paragraph
   journalArray_Add journalArray, factoryArray, "add", afterID
   
   -- finally add the journal entry for editing the factory
   journalArray_Add journalArray, itemArray, "edit"
   put journalArray into pageArray ["journal"]
   
   put pageArray ["story"] into storyArray
   put item 2 of the extents of storyArray into lastItemNum
   return lastItemNum
end pageArray_AddItemArray

command pageArray_AssignID @pID
   if pID is empty then 
      put uuid () into pID
   end if
end pageArray_AssignID


--> PageArray | Edit
-
command pageArray_AddFork @pageArray, wikiDomains, pForkDate
   -- was "fedwiki_AddJournal"
   replace comma with CR in wikiDomains
   put pageArray ["journal"] into journalArray
   put item 2 of the extents of journalArray into indexNum
   repeat for each line wikiDomain in wikiDomains
      add 1 to indexNum
      put fedwiki_ConstructForkItemArray (wikiDomain, pForkDate) into itemArray
      put itemArray into journalArray [indexNum]
   end repeat
   put journalArray into pageArray ["journal"]
end pageArray_AddFork

command pageArray_StripJournal @pageArray
   -- was "fedwiki_StripJournalToCreate" then "fedwiki_StripJournal"
   -- reconstruct a new creation array with new time deleting old journal history
   put pageArray ["title"] into pageTitle
   put pageArray_ConstructCreateArray (pageTitle) into newCreationArray
   delete variable pageArray ["journal"]
   put newCreationArray into pageArray ["journal"][1]
end pageArray_StripJournal

command pageArray_CleanJournal @pageArray, pPreserveActions
   switch pPreserveActions
      case empty
         pageArray_StripJournal pageArray
         break
      default
         put pageArray ["journal"] into journalArray
         put item 2 of the extents of journalArray into lastJournalNum
         put 1 into newItemNum
         repeat with jNum = 1 to lastJournalNum
            put journalArray [jNum] into itemArray
            if itemArray ["type"] is among the items of pPreserveActions then
               put itemArray into newJournalArray [newItemNum]
               add 1 to newItemNum
            end if
         end repeat
         put newJournalArray into pageArray ["journal"]
   end switch
end pageArray_CleanJournal

command pageArray_Rename @pageArray, newPageTitle
   if newPageTitle is empty then return false
   put newPageTitle into pageArray ["title"]
   put newPageTitle into pageArray ["journal"][1]["item"]["title"]
   return true
end pageArray_Rename

function pageArray_GetCreationDate pageArray
   put pageArray ["journal"][1]["date"] into creationDate
   return creationDate
end pageArray_GetCreationDate

command pageArray_SetCreationDate @pageArray, pMilliseconds
   if pMilliseconds is not a number then put the milliseconds into pMilliseconds
   put pMilliseconds into pageArray ["journal"][1]["date"]
end pageArray_SetCreationDate


--> PageArray
-
function pageArray_GetItemText @pageArray, itemID
   -- was "fedwiki_GetStoryItemText"
   put pageArray_FindItemID (itemID, pageArray) into itemNum
   if itemNum = 0 then return empty
   put pageArray ["story"][itemNum]["text"] into itemText
   return itemText
end pageArray_GetItemText

command pageArray_SetItemText @pageArray, itemID, itemText
   put pageArray_FindItemID (itemID, pageArray) into itemNum
   if itemNum = 0 then return 0
   put itemText into pageArray ["story"][itemNum]["text"]
   return itemNum
end pageArray_SetItemText

function pageArray_GetItemType @pageArray, itemID
   put pageArray_FindItemID (itemID, pageArray) into itemNum
   put pageArray ["story"][itemNum]["type"] into itemText
   return itemText
end pageArray_GetItemType

command pageArray_SetItemType @pageArray, itemID, itemText
   put pageArray_FindItemID (itemID, pageArray) into itemNum
   put itemText into pageArray ["story"][itemNum]["type"]
   return itemNum
end pageArray_SetItemType


--> Fedwiki | Item | Find
-
/*
These "find" handlers all return an itemNum, from which it is easy to derive any other attribute.
*/

function pageArray_FindItemType itemType, pageArray, pAfterIndexNum
   if pAfterIndexNum is a number then
      put pAfterIndexNum + 1 into startIndexNum
   else
      put 1 into startIndexNum
   end if
   put pageArray ["story"] into storyArray
   put item 2 of the extents of storyArray into maxItem
   repeat with itemNum = startIndexNum to maxItem
      put storyArray [itemNum]["type"] into testType
      if itemType = testType then
         return itemNum
      end if
   end repeat
   return 0
end pageArray_FindItemType

function pageArray_FindItemID itemID, pageArray
   put pageArray ["story"] into storyArray
   put item 2 of the extents of storyArray into maxItem
   repeat with itemNum = 1 to maxItem
      put storyArray [itemNum]["id"] into testID
      if testID = itemID then
         return itemNum
      end if
   end repeat
   return 0
end pageArray_FindItemID


--> PageArray | Extract
-
function pageArray_ExtractLinkArray pageArray
   get pageArray_ExtractForkArray (pageArray)
   if it is an array then put it into linkArray ["fork"]
   --
   put pageArray ["story"] into storyArray
   put 1 into refIndexNum
   repeat for each key indexNum in storyArray
      put storyArray [indexNum] into itemArray
      switch itemArray ["type"]
         case "reference"
            put itemArray ["site"] into wikiDomain
            put itemArray ["slug"] into pageSlug
            put itemArray ["title"] into pageTitle
            put itemArray ["text"] into refText
            --
            put itemArray into linkArray ["reference"][refIndexNum]
            add 1 to refIndexNum
            break
         case "text"
         case "markdown"
         case "html"
            put itemArray ["id"] into itemID
            put itemArray ["text"] into wikiText
            wikiText_AddToInternalLinkArray intLinkArray, wikiText, itemID
            wikiText_AddToExternalLinkArray extLinkArray, wikiText, itemID
            break
         default
      end switch
   end repeat
   --
   if intLinkArray is an array then put intLinkArray into linkArray ["internal"]
   if extLinkArray is an array then put extLinkArray into linkArray ["external"]
   --
   return linkArray
end pageArray_ExtractLinkArray

function pageArray_ExtractForkDomains pageArray
   -- extract unique sorted index of fork domains regardless of data
   put pageArray ["journal"] into journalArray
   repeat for each key jNum in journalArray
      put journalArray [jNum] into itemArray
      if itemArray ["type"] = "fork" then
         put itemArray ["site"] into forkSite
         put itemArray ["date"] into forkDate
         if forkSite is empty then next repeat -- self-fork
         --
         put itemArray into forkArray [forkSite]
      end if
   end repeat
   put keys (forkSite) into forkDoamins
   url_SortDomainIndex forkDoamins
   return forkDoamins
end pageArray_ExtractForkDomains

function pageArray_ExtractForkArray pageArray
   -- extract all external fork events as an indexed array
   put pageArray ["journal"] into journalArray
   put 1 into indexNum
   repeat for each key jNum in journalArray
      put journalArray [jNum] into itemArray
      if itemArray ["type"] = "fork" then
         put itemArray ["site"] into forkSite
         put itemArray ["date"] into forkDate
         if forkSite is empty then next repeat -- self-fork
         --
         put itemArray into forkArray [indexNum]
         add 1 to indexNum
      end if
   end repeat
   return forkArray
end pageArray_ExtractForkArray


--> PageArray | Video
-
command pageArray_AddVideo @pageArray, videoID, videoType, videoDescription, pID
   -- videoID can be "webm http://xxx"
   if videoID is empty then return false
   put pageArray_ConstructVideoArray (videoID, videoType, videoDescription, pID) into itemArray
   pageArray_AddItemArray itemArray, pageArray
   return true
end pageArray_AddVideo

function pageArray_ConstructVideoArray videoID, videoType, videoDescription, pID
   pageArray_AssignID pID
   put toUpper (videoType) && videoID & CR & line 1 of videoDescription into itemArray ["text"]
   put "video" into itemArray ["type"]
   put pID into itemArray ["id"]
   return itemArray
end pageArray_ConstructVideoArray


--> PageArray
-
command pageArray_ReplaceGraph @pageArray, dotText
   -- replaces first graph in pageArray
   put pageArray_FindItemType ("graphviz", pageArray) into itemNum
   if itemNum > 0 then
      put dotText into pageArray ["story"][itemNum]["text"]
   end if
end pageArray_ReplaceGraph

command pageArray_ReplaceItem @pageArray, itemID, itemArray
   put pageArray_FindItemID (itemID, pageArray) into itemNum
   if itemNum > 0 then
      put itemArray into pageArray ["story"][itemNum]
   end if
end pageArray_ReplaceItem

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


--> PageArray | Parts
-
command storyArray_DeleteItem @storyArray, itemNumToDelete
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

command journalArray_Add @journalArray, itemArray, journalType, pAfterID, pMilliseconds
   if pMilliseconds is empty then put the milliseconds into pMilliseconds
   if pAfterID is not empty then
      put pAfterID into journalEntryArray ["after"]
   end if
   put pMilliseconds into journalEntryArray ["date"]
   put itemArray ["id"] into journalEntryArray ["id"]
   put itemArray into journalEntryArray ["item"]
   put journalType into journalEntryArray ["type"]
   
   array_AddToEndOfIndex journalEntryArray, journalArray
end journalArray_Add

command array_AddToEndOfIndex dataOrArray, @indexArray
   -- any indexed array. Could be story or journal
   put item 2 of the extents of indexArray into indexNum
   put indexArray [indexNum]["id"] into afterID
   add 1 to indexNum
   put dataOrArray into indexArray [indexNum]
   return afterID -- figure out what we just added it after
end array_AddToEndOfIndex
