script "lib_ItemArray"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_ItemArray
type: library
version: 0.1

/*Some help*/


--> Working on
-
command itemArray_AddToEnd itemArray, @indexArray
   -- indexArray_AddToEnd indexArray, itemArray
   -- put the result into indexNum
   
   # Figure out what we just added it after
   put item 2 of the extents of indexArray into indexNum
   put indexArray [indexNum]["id"] into afterID
   
   # Add itemArray to end
   add 1 to indexNum
   put itemArray into indexArray [indexNum]
   return afterID
end itemArray_AddToEnd


--> JournalArray
-
command journalArray_Add @journalArray, itemArray, journalType, pAfterID, pMilliseconds
   if pMilliseconds is empty then put the milliseconds into pMilliseconds
   if pAfterID is not empty then
      put pAfterID into journalEntryArray ["after"]
   end if
   put pMilliseconds into journalEntryArray ["date"]
   put itemArray ["id"] into journalEntryArray ["id"]
   put itemArray into journalEntryArray ["item"]
   put journalType into journalEntryArray ["type"]
   
   itemArray_AddToEnd journalEntryArray, journalArray
end journalArray_Add


--> Forks
-
command pageArray_SetFork @pageArray, wikiDomain, pForkDate
   put pageArray ["journal"] into journalArray
   put item 2 of the extents of journalArray into indexNum
   add 1 to indexNum
   put itemArray_ConstructFork (wikiDomain, pForkDate) into itemArray
   put itemArray into journalArray [indexNum]
   put journalArray into pageArray ["journal"]
end pageArray_SetFork

function itemArray_ConstructFork wikiDomain, pForkDate, pItemID
   if pForkDate is empty then put the milliseconds into pForkDate
   --
   put itemArray_Construct ("fork", pItemID) into itemArray
   put pForkDate into itemArray ["date"]
   if wikiDomain is not empty then
      put wikiDomain into itemArray ["site"]
   end if
   return itemArray
end itemArray_ConstructFork

function itemArray_ConstructFactory pID
   put itemArray_Construct ("factory", pID) into factoryArray
   return factoryArray
end itemArray_ConstructFactory

function itemArray_Construct itemType, pID, pText
   itemArray_NormalizeID pID
   put pID into itemArray ["id"]
   --
   put itemType into itemArray ["type"]
   --
   if pText is not empty then  
      put pText into itemArray ["text"]
   end if
   return itemArray
end itemArray_Construct

command itemArray_NormalizeID @pID
   if pID is empty then 
      put uuid () into pID
   end if
end itemArray_NormalizeID


--> ItemArray | Add
-
command itemArray_Add itemArray, @pageArray
   if itemArray is not an array then return 0
   
   put pageArray ["story"] into storyArray
   put pageArray ["journal"] into journalArray
   put itemArray ["id"] into itemID
   
   # Add the item to the end of the story
   itemArray_AddToEnd itemArray, storyArray
   put the result into afterID -- this can be empty if it is the first entry
   put storyArray into pageArray ["story"]
   
   # Now let's add the edit or add to the journal
   put itemArray_ConstructFactory (itemID) into factoryArray
   journalArray_Add journalArray, factoryArray, "add", afterID -- after the id of the end paragraph
   
   # Finally add the journal entry for editing the factory
   journalArray_Add journalArray, itemArray, "edit"
   put journalArray into pageArray ["journal"]
   
   put pageArray ["story"] into storyArray
   put item 2 of the extents of storyArray into lastItemNum
   return lastItemNum
end itemArray_Add


--> ItemArray
-
function itemArray_ConstructReference pageSlug, wikiDomain, refText, pageTitle, pID
   itemArray_NormalizeID pID   
   put pID into itemArray ["id"]
   put "reference" into itemArray ["type"]
   --
   put wikiDomain into itemArray ["site"]
   put pageTitle into itemArray ["title"]
   put pageSlug into itemArray ["slug"]
   put refText into itemArray ["text"]
   --
   return itemArray
end itemArray_ConstructReference

function itemArray_ConstructActivity rosterTitle, pSinceWhen, pConversationItem, pID
   if pSinceWhen is empty then
      put "1 week" into pSinceWhen
   end if
   if pConversationItems is empty then
      put "CONVERSATION" into pConversationItem
   end if
   --
   put "ROSTER" && rosterTitle & CR into activityText
   put CR & pConversationItem after activityText
   put CR & "SINCE" && pSinceWhen after activityText
   --
   put itemArray_Construct ("activity", pID, activityText) into itemArray
   return itemArray
end itemArray_ConstructActivity

function itemArray_ConstructTransport transportLine, pID
   -- was "pageArray_ConstructTransport"
   itemArray_NormalizeID pID
   put transportLine into itemArray ["text"]
   put "transport" into itemArray ["type"]
   put pID into itemArray ["id"]
   return itemArray
end itemArray_ConstructTransport

function itemArray_ConstructVideo videoID, videoType, videoDescription, pID
   -- was "pageArray_ConstructVideoArray"
   itemArray_NormalizeID pID
   put toUpper (videoType) && videoID & CR & line 1 of videoDescription into itemArray ["text"]
   put "video" into itemArray ["type"]
   put pID into itemArray ["id"]
   return itemArray
end itemArray_ConstructVideo

function itemArray_ConstructAudio audioUrl, someText, pID
   -- was "pageArray_ConstructAudio"
   itemArray_NormalizeID pID   
   put audioUrl & CR & someText into itemArray ["text"]
   put "audio" into itemArray ["type"]
   put pID into itemArray ["id"]
   return itemArray
end itemArray_ConstructAudio
