script "model_PageArray"
--> MetaData
-
license: GPLv3
name: model_PageArray
type: model
version: 0.2

/*
This is a model for fetching, storing Fedwiki page-array structures derived from the page-json schema.
It also provides hanlders to to CRUD operations of page-json files.

See also "model_WikiPage", "model_AtopiaFiles", "lib_PageArray" and "lib_FedwikiCreate"

We also provide wrappers for specific types of page-array, such as LCW hander-array's.
We can use these handlers to fetch json and arrays from anywhere in the federation,
but naturally we can only write to wiki-domains that we have permission to write to.
For now this means domains on the Atopia server.
*/


--> Working on
-

--> PageArray | Model
-
function pageArray_Fetch wikiDomain, pSlug, pDontCheck
   -- checks for title, journal, and story
   put pageJson_Fetch (wikiDomain, pSlug) into pageJson
   --
   if pageJson is empty then return empty
   put json_ToArray (pageJson) into pageArray
   if pDontCheck is true then return pageArray
   if pageArray_Check (pageArray) then
      return pageArray
   else
      return empty
   end if
end pageArray_Fetch

command pageArray_Store wikiDomain, pageSlug, pageArray
   put json_FromArray (pageArray) into pageJSON
   pageJson_Store wikiDomain, pageSlug, pageJSON
   put the result into shellResult
   return shellResult -- should be empty unless an error
end pageArray_Store

command pageArray_Delete wikiDomain, pageSlug
   pageJson_Delete wikiDomain, pageSlug
end pageArray_Delete


--> PageJson | Model
-
/*
These handlers are not used very much, except by pageArray_Fetch, pageArray_Store, pageArray_Delete
*/

function pageJson_Fetch wikiDomain, pSlug
   -- was "pageJson_Fetch"
   put pageJson_ConstructUrl (wikiDomain, pSlug) into someUrl
   put url someUrl into someJSON
   return someJSON
end pageJson_Fetch

command pageJson_Store wikiDomain, pageSlug, pageJSON, pDeleteSiteMap
   -- was "fedwiki_StorePageJson"
   put fedwiki_ConstructPath (wikiDomain, pageSlug) into wikiPagePath
   --
   atopia_StoreData wikiPagePath, pageJSON
   --
   put the result into shellResult
   if shellResult is not empty then return shellResult
   if pDeleteSiteMap is not false then -- deleting sitemap is the lazy way to update it
      atopia_DeleteWikiSitemap wikiDomain
   end if
   return shellResult -- should be empty unless an error
end pageJson_Store

command pageJson_Delete wikiDomain, pageSlug
   -- was "fedwiki_DeletePageJson"
   put fedwiki_ConstructPath (wikiDomain, pageSlug) into wikiPagePath
   --
   atopia_DeleteFile wikiPagePath
   --
   put the result into shellResult
   return shellResult
end pageJson_Delete

function pageJson_ConstructUrl fedwikiDomain, pSlug
   if pSlug is empty then
      -- http://c0de.academy/welcome-visitors.json?random=95b9c89e
      put "http://" & fedwikiDomain & "/welcome-visitors.json" into someUrl
   else
      -- put url "http://c0de.academy/currently-working-on.json?random=32c053a"
      put "http://" & fedwikiDomain & "/" & pSlug & ".json" into someUrl
   end if
   put "?random=" & the milliseconds after someUrl
   return someUrl
end pageJson_ConstructUrl


--> PageArray | Default | Model
-
function pageArray_FetchDefault pageSlug
   put atopia_DefaultWikiPagePath (pageSlug) into defaultPath
   put atopia_FetchData (defaultPath) into pageJSON
   put json_ToArray (pageJSON) into pageArray
   return pageArray
end pageArray_FetchDefault

command pageArray_StoreDefault pageSlug, pageArray
   put json_FromArray (pageArray) into pageJSON
   put atopia_DefaultWikiPagePath (pageSlug) into defaultPath
   atopia_StoreData defaultPath, pageJSON
   put the result into shellResult
   return shellResult
end pageArray_StoreDefault


--> PageArray | Add
-
command pageArray_AddAddAction @pageArray, itemArray, afterID, pMilliseconds
   if pMilliseconds is empty then put the milliseconds into pMilliseconds
   put pageArray ["journal"] into journalArray
   --
   put "add" into actionArray ["type"]
   put afterID into actionArray ["after"]
   put itemArray into actionArray ["item"]
   put itemArray ["id"] into actionArray ["id"]
   put pMilliseconds into actionArray ["date"]
   --
   array_AddToEndOfIndex actionArray, journalArray
   put journalArray into pageArray ["journal"]
   return actionArray
end pageArray_AddAddAction

command pageArray_AddDeleteAction @pageArray, deletedItemID, pMilliseconds
   if pMilliseconds is empty then put the milliseconds into pMilliseconds
   put pageArray ["journal"] into journalArray
   --
   put "remove" into actionArray ["type"]
   put pMilliseconds into actionArray ["date"]
   put deletedItemID into actionArray ["id"]
   --
   array_AddToEndOfIndex actionArray, journalArray
   put journalArray into pageArray ["journal"]
end pageArray_AddDeleteAction

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


--> Deps
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

command line_AddToNameArray @nameArray, someIndex
   replace comma with CR in someIndex
   repeat for each line someLine in someIndex
      put word 1 to -1 of someLine into someLine
      if someLine is empty then next repeat
      put empty into nameArray [someLine]
   end repeat
end line_AddToNameArray

