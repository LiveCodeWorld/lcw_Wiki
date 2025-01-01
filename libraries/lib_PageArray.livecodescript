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
function dot_FetchHandlerGraphData hName, pJsonType
   -- https://graphviz.org/docs/outputs/json/
   if pJsonType is empty then put "json" into pJsonType -- "json0,dot_json,xdot_json"
   put platform_RestDomain() into restDomain
   put merge ("curl -s 'http://[[restDomain]]/graph/viz/[[hName]]' | dot -T[[pJsonType]]") into someShell
   put shell (someShell) into dotJSON
   put json_ToArray (dotJSON) into hGraphData
   return hGraphData
end dot_FetchHandlerGraphData

function dot_GetArray hkey
   /*
   The output produced by these follows the json schema shown below. 
   Note that the objects array has all of the subgraphs first, followed by all of the nodes. 
   The _gvid value is the index of the subgraph or node in the objects array. 
   This also holds true for the edges in the objects array. 
   Note that this format allows clustered graphs, where edges can connect clusters as well as nodes.
   */
   
   put hkey_DotFile (hKey, "hierarchical") into dotFile
   -- put url ("file:" & someFile) into dotJSON
   
   -- https://graphviz.org/docs/outputs/json/
   -- put "dot -Txdot_json -ogrpaph.json" && kwote (someFile) into someShell
   put "dot -Txdot_json" && kwote (dotFile) into someShell
   put shell (someShell) into dotJSON
   --
   put json_ToArray (dotJSON) into dotArray
   return dotArray
end dot_GetArray


--> PageItem
-
function pageItem_GetFirstImage itemHTML
   -- "data-imagestyle='fullwiki'"
   
   -- lets do a bit of hacking first
   put html_ExtractOpeningTag ("img", itemHTML) into imgTag
   xhtml_TidyNode imgTag
   --
   put html_GetImageArray (imgTag) into imageArray
   if imageArray is an array is false then return empty
   --
   --  display_Data imageArray, "html_GetImageArray()"
   put imageArray ["data-imagestyle"] into dataImagestyle
   put "<div style='padding: 12px; background:#eee; width:96%; align=centered;'>" into oldStandardDiv
   switch
      case dataImagestyle is not empty
      case sHTML contains oldStandardDiv
         return imageArray ["src"]
      default
         return imageArray ["src"]
         -- return empty
   end switch
end pageItem_GetFirstImage

function pageItem_ParseCode firstCode
   put firstCode into codeArray ["text"]
   
   put line 1 of firstCode into firstLine
   put firstLine into codeArray ["code"]
   
   # Find lines that look like " [[toPi]]       = pi5.local" 
   filter firstCode with regex pattern (" +\[\[.+\]\] += *")
   
   # Assume each line has a one word key (token 3)
   set the itemdelimiter to "="
   repeat for each line sLine in firstCode
      put token 3 of word 1 to -1 of item 1 of sLine into firstKey
      put word 1 to -1 of item 2 of sLine into firstValue
      put firstValue into paramArray [firstKey]
   end repeat
   --
   put paramArray into codeArray ["params"]
   return codeArray
end pageItem_ParseCode



--> PageArray | List
-
function pageArray_ListReferenceDomains pageArray
   put pageArray ["story"] into storyArray
   repeat with itemNum = 1 to item 2 of the extents of storyArray
      if storyArray [itemNum]["type"] = "reference" then
         put storyArray [itemNum]["site"] into refDomain
         put refDomain & CR after refDomains
      end if
   end repeat
   delete char -1 of refDomains
   return refDomains
end pageArray_ListReferenceDomains

function pageArray_ExtractRefItems fromPageArray
   put pageArray_ExtractItems (fromPageArray, "reference") into refItemStoryArray
   return refItemStoryArray
end pageArray_ExtractRefItems

function pageArray_ExtractItems fromPageArray, itemKind
   put fromPageArray ["story"] into fromStoryArray
   put 1 into newItemNum
   repeat with itemNum = 1 to item 2 of the extents of fromStoryArray
      put fromStoryArray [itemNum] into itemArray
      if itemArray ["type"] = itemKind then
         put itemArray into refItemStoryArray [newItemNum]
         add 1 to newItemNum
      end if
   end repeat
   return refItemStoryArray
end pageArray_ExtractItems

function pageArray_ReferenceLinkArray pageArray, fromSlug, fromDomain
   put fromDomain & "/" & fromSlug into fromLink
   put pageArray ["story"] into storyArray
   repeat for each key nodeNum in storyArray
      put storyArray [nodeNum] into nodeArray
      put nodeArray ["type"] into nodeType
      if nodeType = "reference" then
         put nodeArray ["site"] into toDomain
         put nodeArray ["slug"] into toSlug
         
         -- a bit archaic (should use nested arrays I think)
         put toDomain & "/" & toSlug into toLink
         if toDomain = fromDomain then
            put nodeArray into linkArray ["internal"][fromLink][toLink]
         else
            put nodeArray into linkArray ["external"][fromLink][toLink]
         end if
      end if
   end repeat
   return linkArray
end pageArray_ReferenceLinkArray

function pageArray_ForkLinks pageArray, fromSlug, fromDomain
   -- was "fedwiki_ExtractForkLinks"
   put fromDomain & "/" & fromSlug into fromLink
   put pageArray ["journal"] into journalArray
   
   put item 2 of the extents of journalArray into maxNum
   put 1 into forkNum
   repeat with nodeNum = 1 to maxNum
      put journalArray [nodeNum] into nodeArray
      put nodeArray ["type"] into nodeType
      if nodeType = "fork" then
         put nodeArray ["site"] into toDomain
         
         if toDomain is fromDomain or toDomain is empty then
            -- going to assume it's a self-fork
            put fromDomain into toDomain
            next repeat -- not bothering storing this information (it's sort of useful for bugs?)
         end if
         
         -- a bit archaic (should use nested arrays I think)
         put toDomain & "/" & fromSlug into toLink -- a fork has the same slug
         put nodeArray into linkArray [forkNum][fromLink][toLink]
         add 1 to forkNum
      end if
   end repeat
   return linkArray
end pageArray_ForkLinks


--> PageArray | First
-
function pageArray_GetFirstCode pageArray
   put pageArray_FindItemType ("code", pageArray) into firstItemNum
   if firstItemNum = 0 then return empty
   
   put pageArray ["story"][firstItemNum]["text"] into sText
   return sText
end pageArray_GetFirstCode

function pageArray_GetFirstRoster pageArray
   put pageArray_FindItemType ("roster", pageArray) into firstRosterItemNum
   if firstRosterItemNum = 0 then return empty
   
   put pageArray ["story"][firstRosterItemNum]["text"] into rosterText
   return rosterText
end pageArray_GetFirstRoster

function pageArray_GetFirstHtml pageArray
   return pageArray_GetFirstItemValue (pageArray, "html", "text")
end pageArray_GetFirstHtml

function pageArray_GetFirstItem pageArray, itemType
   put pageArray_FindItemType (itemType, pageArray) into itemNum
   put pageArray ["story"][itemNum]["text"] into itemText
   return itemText
end pageArray_GetFirstItem

command pageArray_SetFirstItem @pageArray, itemType, itemText
   put pageArray_FindItemType (itemType, pageArray) into itemNum
   if itemNum = 0 then return 0
   put itemText into pageArray ["story"][itemNum]["text"]
   return itemNum
end pageArray_SetFirstItem

function pageArray_GetFirstItemValue pageArray, itemType, pItemProp
   if pItemProp is empty then put "text" into pItemProp
   put pageArray_FindItemType (itemType, pageArray) into firstItemNum
   if firstItemNum = 0 then return empty
   
   put pageArray ["story"][firstItemNum][pItemProp] into itemText
   return itemText
end pageArray_GetFirstItemValue


--> Fedwiki | Item | Find
-
/*
These "find" handlers all return an itemNum, from which it is easy to derive any other attribute.
*/

function pageArray_FindItemOfType sText, itemType, pageArray, pAfterIndexNum
   if pAfterIndexNum is a number then
      put pAfterIndexNum + 1 into startIndexNum
   else
      put 1 into startIndexNum
   end if
   put pageArray ["story"] into storyArray
   put item 2 of the extents of storyArray into maxItem
   repeat with itemNum = startIndexNum to maxItem
      put storyArray [itemNum]["type"] into testType
      if itemType is not testType then next repeat
      
      if storyArray [itemNum]["text"] contains sText then
         return itemNum
      end if
   end repeat
   return 0
end pageArray_FindItemOfType

function pageArray_FindItemText itemType, pageArray, pAfterIndexNum
   put pageArray_FindItemType (itemType, pageArray, pAfterIndexNum) into itemNum
   put pageArray ["story"][itemNum]["text"] into itemText
   return itemText
end pageArray_FindItemText

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


--> PageArray | Date
-
function pageArray_GetLastModified pageArray
   put pageArray ["journal"] into journalArray
   put item 2 of the extents of journalArray into lastItemNum
   put journalArray [lastItemNum]["date"] into lastModifiedDate
   return lastModifiedDate
end pageArray_GetLastModified

function pageArray_GetCreationDate pageArray
   put pageArray ["journal"][1]["date"] into creationDate
   return creationDate
end pageArray_GetCreationDate

command pageArray_SetCreationDate @pageArray, pMilliseconds
   if pMilliseconds is not a number then put the milliseconds into pMilliseconds
   put pMilliseconds into pageArray ["journal"][1]["date"]
end pageArray_SetCreationDate


--> PageArray | Graph
-
function pageArray_GetSvg pageArray
   return pageArray_GetGraph (pageArray, "svg")
end pageArray_GetSvg

function pageArray_GetGraph pageArray, pType
   if pType is empty then put "dot" into pType
   put pageArray_FindItemType ("graphviz", pageArray) into itemNum
   if itemNum = 0 then return empty
   return pageArray ["story"][itemNum][pType]
end pageArray_GetGraph

command pageArray_ReplaceGraph @pageArray, dotText
   -- replaces first graph in pageArray
   put pageArray_FindItemType ("graphviz", pageArray) into itemNum
   if itemNum > 0 then
      put dotText into pageArray ["story"][itemNum]["text"]
   end if
end pageArray_ReplaceGraph

command pageArray_Trim @pageArray, maxTrimNum
   put pageArray ["story"] into storyArray
   put item 2 of the extents of storyArray into maxItemNum
   repeat with itemNum = (maxTrimNum + 1) to maxItemNum
      delete variable pageArray ["story"][itemNum]
   end repeat
end pageArray_Trim


--> PageArray | Form
-
function pageArray_GetFormValue inputKey, pageArray
   -- for simple carefully crafted forms
   put "[\" & quote & "\'" & quote & "]" into someQuote -- https://www.metaltoad.com/blog/regex-quoted-string-escapable-quotes
   put merge ("<input name='[[inputKey]]' value='(.+)' type='hidden'>") into regExp
   replace "'" with someQuote in regExp
   
   put pageArray ["story"] into storyArray
   repeat with itemNum =1 to item 2 of the extents of storyArray
      if storyArray [itemNum]["type"] is not "html" then next repeat
      --
      put storyArray [itemNum]["text"] into someHTML
      if matchText (someHTML, regExp, inputValue) is true then
         return inputValue
      end if
   end repeat
   return empty
end pageArray_GetFormValue


--> PageArray | Dates
-
command pageArray_Combine @pageArray, templatePageArray
   put templatePageArray ["story"] into storyArray
   repeat for each key itemNum in storyArray
      put storyArray [itemNum] into itemArray
      put itemArray ["id"] into itemID
      put pageArray_FindItemID (itemID, pageArray) into foundItemNum
      if foundItemNum = 0 then
         itemArray_Add itemArray, pageArray
      end if
   end repeat
end pageArray_Combine

function pageArray_GetTitleText sectionTitle, pageArray
   put pageArray_FindTitle (pageArray, sectionTitle) into itemNum
   put pageArray ["story"][itemNum]["text"] into itemText
   return itemText
end pageArray_GetTitleText


--> PageArray | Forks
-
command pageArray_SetFork @pageArray, wikiDomain, pForkDate
   put pageArray ["journal"] into journalArray
   put item 2 of the extents of journalArray into indexNum
   add 1 to indexNum
   put itemArray_ConstructFork (wikiDomain, pForkDate) into itemArray
   put itemArray into journalArray [indexNum]
   put journalArray into pageArray ["journal"]
end pageArray_SetFork

command pageArray_CleanFork @pageArray, pForkDomains
   pageArray_StripJournal pageArray
   pageArray_AddFork pageArray, pForkDomains
end pageArray_CleanFork

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
      put itemArray_ConstructFork (wikiDomain, pForkDate) into itemArray
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


--> PageArray | Transport
-
command pageArray_CompactRefs @pageArray
   -- this command takes and ref-items and adds them to a "# See also" section 
   put pageArray ["title"] into pageTitle
   put pageArray ["story"] into storyArray
   if storyArray is not an array then
      put "This is not a single wiki page. Only drop references to single pages on this transporter." &CR&CR& droppedURL into errorText
      transport_ExitAndReturnError errorText
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


--> PageArray | Edit
-
command pageArray_CleanJournal @pageArray, pPreserveActions
   -- ie pPreserveActions = "fork"
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

command pageArray_Rename @pageArray, newPageTitle, pForkDomains
   if newPageTitle is empty then return false
   put newPageTitle into pageArray ["title"]
   put newPageTitle into pageArray ["journal"][1]["item"]["title"]
   --
   if pForkDomains is not empty then
      pageArray_StripJournal pageArray
      pageArray_AddFork pageArray, pForkDomains
   end if
   return true
end pageArray_Rename


--> PageArray
-
function pageArray_GetItemText pageArray, itemID
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

function pageArray_GetItemType pageArray, itemID
   put pageArray_FindItemID (itemID, pageArray) into itemNum
   put pageArray ["story"][itemNum]["type"] into itemType
   return itemType
end pageArray_GetItemType

command pageArray_SetItemType @pageArray, itemID, itemType
   put pageArray_FindItemID (itemID, pageArray) into itemNum
   put itemType into pageArray ["story"][itemNum]["type"]
   return itemNum
end pageArray_SetItemType


--> Fedwiki | Item | Find
-
function pageArray_GetItemArray pageArray, itemID
   put pageArray_FindItemID (itemID, pageArray) into itemNum
   put pageArray ["story"][itemNum] into itemArray
   return itemArray
end pageArray_GetItemArray

command pageArray_SetItemArray @pageArray, itemID, itemArray
   -- was "pageArray_SetItemArray"
   put pageArray_FindItemID (itemID, pageArray) into itemNum
   if itemNum > 0 then
      put itemArray into pageArray ["story"][itemNum]
   end if
end pageArray_SetItemArray


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


--> PageArray | Find
-
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
