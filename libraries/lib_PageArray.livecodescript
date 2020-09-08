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


--> PageArray | Dates
-
function pageArray_ExtractFirstAuthorDate pageArray, wikiDomain
   put pageArray ["journal"] into journalArray
   -- put journalArray [1]["date"] into creationDate
   put 1420938220851 into wikiBirthDay -- last edit of standard welcome-visitors page
   
   put journalArray [1]["date"] into creationDate
   put item 2 of the extents of journalArray into maxItem
   repeat with checkItemNum = 2 to maxItem -- forget creation event
      put journalArray [checkItemNum]["date"] into mSeconds
      if mSeconds > wikiBirthDay then
         put mSeconds into creationDate
         put checkItemNum + 1 into nextItemNum
         if nextItemNum > maxItem then
            return creationDate
         end if
         --
         repeat with itemNum = nextItemNum to item 2 of the extents of journalArray
            put journalArray [itemNum]["type"] into actionType
            if actionType = "fork" then
               put journalArray [itemNum]["site"] into forkDomain
               switch
                  case forkDomain is empty
                     next repeat
                     break
                  case forkDomain = wikiDomain
                     put journalArray [itemNum]["date"] into creationDate
                     put true into wasForked
                     break
                  default
                     if wasForked is true then
                        return creationDate
                     else
                        put journalArray [itemNum]["date"] into creationDate
                        put false into wasForked
                     end if
               end switch
            end if
         end repeat
         return creationDate
      end if
   end repeat
   return creationDate
end pageArray_ExtractFirstAuthorDate

function pageArray_GuessFirstWelcomeDate pageArray
   put 1420938220851 into wikiBirthDay -- last edit of standard welcome-visitors page
   put pageArray ["journal"] into journalArray
   repeat with itemNum = 1 to item 2 of the extents of journalArray
      put journalArray [itemNum]["date"] into mSeconds
      if mSeconds > wikiBirthDay then
         return mSeconds
      end if
   end repeat
end pageArray_GuessFirstWelcomeDate

command pageArray_Combine @pageArray, templatePageArray
   put templatePageArray ["story"] into storyArray
   repeat for each key itemNum in storyArray
      put storyArray [itemNum] into itemArray
      put itemArray ["id"] into itemID
      put pageArray_FindItemID (itemID, pageArray) into foundItemNum
      if foundItemNum = 0 then
         pageArray_AddItemArray itemArray, pageArray
      end if
   end repeat
end pageArray_Combine

function pageArray_FetchTemplate wikiDomain, templateTitle, newTitle, pForkDomains
   if pForkDomains is empty then put "fedwiki.org,server.fedwiki.org" into pForkDomains
   
   put fedwiki_ConstructSlug (templateTitle) into pageSlug
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   --
   pageArray_Rename pageArray, newTitle
   pageArray_StripJournal pageArray
   pageArray_AddFork pageArray, pForkDomains
   return pageArray
end pageArray_FetchTemplate

function pageArray_GetTitleText sectionTitle, pageArray
   put pageArray_FindTitle (pageArray, sectionTitle) into itemNum
   put pageArray ["story"][itemNum]["text"] into itemText
   return itemText
end pageArray_GetTitleText


--> PageArray | Forks
-
command pageArray_AddFork @pageArray, wikiDomains, pForkDate
   -- does not add a fork if it is already in the journal
   replace comma with CR in wikiDomains
   put pageArray_ExtractForkDomains (pageArray) into existingForks
   line_DeleteIndex wikiDomains, existingForks
   --
   put pageArray ["journal"] into journalArray
   put item 2 of the extents of journalArray into indexNum
   repeat for each line wikiDomain in wikiDomains
      add 1 to indexNum
      put fedwiki_ConstructForkItemArray (wikiDomain, pForkDate) into itemArray
      put itemArray into journalArray [indexNum]
   end repeat
   put journalArray into pageArray ["journal"]
end pageArray_AddFork

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
   put keys (forkArray) into forkDomains
   url_SortDomainIndex forkDomains
   return forkDomains
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


--> PageArray | Links
-
function pageArray_GetPageLinks pageArray
   put pageArray ["story"] into storyArray
   repeat for each key indexNum in storyArray
      -- put storyArray [indexNum]["type"] into itemType
      put storyArray [indexNum]["text"] into itemText
      put fedwiki_GetLinks (itemText) into itemLinks
      put itemLinks & CR after wikiLinks
   end repeat
   sort wikiLinks
   return word 1 to -1 of wikiLinks
end pageArray_GetPageLinks

function pageArray_GetTitleLinks sectionTitle, pageArray
   put pageArray_GetTitleText (sectionTitle, pageArray) into itemText
   put fedwiki_GetLinks (itemText) into itemLinks
   return itemLinks
end pageArray_GetTitleLinks

function pageArray_GetPageLinkSlugs pageArray
   put pageArray_GetPageLinks (pageArray) into wikiLinks
   --
   repeat for each line pageTitle in wikiLinks
      put fedwiki_ConstructSlug (pageTitle) into pSlug
      put pSlug & CR after pSlugs
   end repeat
   delete char -1 of pSlugs
   return pSlugs
end pageArray_GetPageLinkSlugs


--> PageArray | Section
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
   put pageArray ["journal"] into journalArray
   if pageTitle is empty or "story" is not among the keys of pageArray or journalArray is not an array then
      return false
   else
      return true
   end if
end pageArray_Check


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
command pageArray_StripJournal @pageArray
   -- was "fedwiki_StripJournalToCreate" then "pageArray_StripJournal"
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


--> PageArray | Edit
-
command pageArray_InsertStory @pageArray, storyArray, afterItemNum
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
end pageArray_InsertStory

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
   fedwiki_StoryInsertInto storyArray, toItemNum, itemArray
   put storyArray into pageArray ["story"]
   
   -- update journal
   put fedwiki_StoryExtractOrderedIDArray (storyArray) into oderedIDArray
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
end pageArray_DeleteItem


--> StoryArray | Parts
-
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
