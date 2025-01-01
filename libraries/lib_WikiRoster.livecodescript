script "lib_WikiRoster"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_WikiRoster
type: library
version: 0.3

/*
*/


--> Move
-
function activity_IsKeyWord firstWord
   set the caseSensitive to true
   if firstWord is among the items of "ROSTER,SINCE,NEIGHBORHOOD,TWINS,SORT,SEARCH,MINE,CONVERSATION,NARRATIVE" then
      return true
   else
      return false
   end if
end activity_IsKeyWord


--> Working on
-
function atopia_FetchRoster
   -- fetch the one big domain index roster then filter
   put roster_Fetch ("server.fedwiki.org", "atopia-domain-index", "741a0fcdd3ff76b2") into rosterText
   return word 1 to -1 of rosterText
end atopia_FetchRoster

function roster_FromReferences wikiDomain, pageSlug
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   put pageArray_ListReferenceDomains (pageArray) into refDomains
   return refDomains
end roster_FromReferences

function roster_ConstructReferenceText tldDomain, pTitle
   local rosterText
   put pTitle & CR&CR into rosterText
   put fedwiki_ConstructSlug (pTitle) into sitesSlug
   put merge ("REFERENCES [[tldDomain]]/[[sitesSlug]]") after rosterText
   return rosterText
end roster_ConstructReferenceText

function roster_ConstructText rosterDomains, pRosterTitle
   if pRosterTitle is empty then return rosterDomains
   --
   return pRosterTitle & CR&CR & rosterDomains
end roster_ConstructText


--> Roster | Construct
-
function roster_ConstructSitesPageArray wikiDomain, rosterDomains, pPageTitle, pForkDomains
   put roster_FetchPageArray (wikiDomain, rosterDomains, pPageTitle, pForkDomains) into pageArray
   _UpdateSites pageArray, wikiDomain, pPageTitle
   return pageArray
end roster_ConstructSitesPageArray

function roster_FetchPageArray wikiDomain, rosterDomains, pPageTitle, pForkDomains
   put roster_FetchTemplate (wikiDomain, pPageTitle, pForkDomains) into pageArray
   _SetSitesPageRoster pageArray, pPageTitle, rosterDomains
   return pageArray
end roster_FetchPageArray

function roster_FetchTemplate pWikiDomain, pPageTitle, pForkDomains
   if pForkDomains is empty then put "fedwiki.org,roster.fedwiki.org,sites.fedwiki.org" into pForkDomains
   put "roster.fedwiki.org" into defaultDomain
   --
   switch
      case (pPageTitle is empty) AND (pWikiDomain is empty)
         put defaultDomain into pWikiDomain
         put "Sites Template" into pPageTitle
         break
      case (pPageTitle is empty)
         set the itemdelimiter to "."
         repeat for each item someItem in pWikiDomain
            put text_InitialCaps (someItem) & space after pPageTitle
         end repeat
         put "Sites" after pPageTitle
         break
      case (pWikiDomain is empty)
         put defaultDomain into pWikiDomain
         break
      default
         -- both not empty. Good to go
   end switch
   --
   put fedwiki_ConstructSlug (pPageTitle) into pSlug
   put pageArray_Fetch (pWikiDomain, pSlug) into pageArray
   pageArray_CleanFork pageArray, pForkDomains
   return pageArray
end roster_FetchTemplate

function roster_ConstructPageArray rosterText, pRosterTitle
   if pRosterTitle is empty then
      put "Roster Page" into pageArray ["title"]
   else
      put pRosterTitle into pageArray ["title"]
      put pRosterTitle & CR & CR before rosterText
   end if
   
   replace comma with CR in rosterText
   --
   pageArray_AddRoster pageArray, rosterText
   pageArray_StripJournal pageArray
   return pageArray
end roster_ConstructPageArray


--> Roster | Model 
-
function roster_FetchByTitle wikiDomain, pageSlug, rosterTitle
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   --
   put pageArray ["story"] into storyArray
   repeat with itemNum = 1 to item 2 of the extents of storyArray
      if storyArray [itemNum]["type"] = "roster" then
         put storyArray [itemNum]["text"] into rosterText
         put roster_GetTitle (rosterText) into foundRosterTitle
         if foundRosterTitle = rosterTitle then
            return rosterText
         end if
      end if
   end repeat
   return empty
end roster_FetchByTitle

function roster_Fetch wikiDomain, pageSlug, pItemID
   # Find first roster on page
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   --
   if pItemID is empty then
      put pageArray_FindItemType ("roster", pageArray) into itemNum
      put pageArray ["story"][itemNum]["text"] into rosterText
   else
      put pageArray_GetItemText (pageArray) into rosterText
   end if
   return rosterText
end roster_Fetch

command roster_Store wikiDomain, pageSlug, rosterText, pItemID
   -- store in first roster on page
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   --
   if pItemID is empty then
      put pageArray_FindItemType ("roster", pageArray) into itemNum
   else
      put pageArray_FindItemID (pItemID, pageArray) into itemNum
   end if
   put rosterText into pageArray ["story"][itemNum]["text"]
   --
   pageArray_Set wikiDomain, pageSlug, pageArray
   return pageArray
end roster_Store


--> Roster | Utils 
-
command roster_ParseText rosterText, @rosterTitle, @rosterDomains, @rosterLines, @refLines,   
   put empty into rosterDomains
   put empty into rosterLines
   put empty into refLines
   
   if roster_HasTitle (rosterText) then
      put word 1 to -1 of line 1 of rosterText into rosterTitle
      delete line 1 of rosterText
   else
      put empty into rosterTitle
   end if
   
   set the caseSensitive to true
   repeat for each line sLine in rosterText
      put word 1 to -1 of sLine into sLine
      switch word 1 of sLine
         case empty
            next repeat
         case "REFERENCES"
            put sLine & CR after refLines
            break
         case "ROSTER"
            put sLine & CR after rosterLines
            break
         default
            put sLine & CR after rosterDomains
      end switch
   end repeat
   delete char -1 of refLines
   delete char -1 of rosterLines
   delete char -1 of rosterDomains
end roster_ParseText


--> Roster | Recurse 
-
function roster_ListNested wikiDomain, pSlug, pRosterTitle
   if pRosterTitle is empty then
      put roster_Fetch (wikiDomain, pSlug) into rosterText
   else
      put roster_FetchByTitle( wikiDomain, pSlug, pRosterTitle) into rosterText
   end if
   put roster_EvaluateText (rosterText) into allDomains
   return allDomains
end roster_ListNested

function roster_EvaluateText rosterText
   local domainArray
   roster_ParseText rosterText, rosterTitle, newRosterText, rosterLines, refLines
   
   # Add found roster domains
   _AddRosterToArray domainArray, newRosterText
   
   # Add domains from REFERENCE links
   _FetchRosterReferences refLines, domainArray
   
   # Add domains from ROSTER links
   _FetchRosterRoster rosterLines, domainArray
   
   put keys (domainArray) into allDomains
   return allDomains
end roster_EvaluateText


--> Roster | Title 
-
function roster_GetTitle rosterText
   switch
      case roster_IsKeyWord (word 1 of rosterText)
      case line 1 of rosterText contains "." 
         return empty
      default
         get word 1 to -1 of line 1 of rosterText
         return it
   end switch
end roster_GetTitle

function roster_HasTitle rosterText
   return roster_GetTitle (rosterText) is not empty
end roster_HasTitle

function roster_IsKeyWord firstWord
   set the caseSensitive to true
   if firstWord is among the items of "ROSTER,REFERENCES" then
      return true
   else
      return false
   end if
end roster_IsKeyWord


--> Roster | Domains
-
command roster_AddDomain @rosterText, wikiDomain
   roster_Deconstruct rosterText, rosterDomains, rosterTitle
   put the result into hasTitle
   line_Add wikiDomain, rosterDomains
   put roster_ConstructText (rosterDomains, rosterTitle) into rosterText
   return hasTitle
end roster_AddDomain

command roster_StripDomain @rosterText, wikiDomain
   -- remove domain and subdomains from an index
   set the wholematches to true
   --
   put "*." & wikiDomain into filterString
   filter rosterText without filterString
   --
   put lineOffset (wikiDomain, rosterText) into lineNum
   delete line lineNum of rosterText
end roster_StripDomain

command roster_Deconstruct rosterText, @rosterDomains, @rosterTitle
   put word 1 to -1 of rosterText into rosterText
   --
   if roster_HasTitle (rosterText) then
      put word 1 to -1 of line 1 of rosterText into rosterTitle
      put line 3 to -1 of rosterText into rosterDomains
      return true
   else
      put empty into rosterTitle
      put rosterText into rosterDomains
      return false
   end if
end roster_Deconstruct


--> Roster | Header
-
command roster_StripHeader @rosterText
   if roster_HasTitle (rosterText) then
      delete line 1 of rosterText
      put word 1 to -1 of rosterText into rosterText
      url_SortDomainIndex rosterText
   end if
end roster_StripHeader

command roster_AddHeader @rosterText, rosterHeader
   if roster_HasTitle (rosterText) then
      url_SortDomainIndex rosterText
      put rosterHeader & CR & CR before rosterText
      put word 1 to -1 of domainIndex into rosterText
   end if
end roster_AddHeader

command roster_ReplaceHeader @rosterText, newRosterHeader
   if roster_HasTitle (rosterText) then
      delete line 1 to 2 of rosterText
      url_SortDomainIndex rosterText
      put newRosterHeader & CR & CR before rosterText
   end if
end roster_ReplaceHeader

command roster_DomainFilter @domainIndex, topDomain
   if topDomain is empty then return empty
   --
   put "*." & topDomain into someFilter
   set the wholematches to true
   put topDomain is among the lines of domainIndex into topThere
   filter domainIndex with someFilter
   if topThere then
      put topDomain & CR before domainIndex
   end if
   return someFilter
end roster_DomainFilter


--> Roster | Category
-
function roster_CategorySplit domainIndex, pTopDomains, pAddTitle
   if pTopDomains is empty then
      put url_ListTopDomains (domainIndex) into pTopDomains
   end if
   --
   repeat for each item topDomain in pTopDomains
      put domainIndex into topIndex
      --
      url_FilterDomainIndex topIndex, topDomain
      url_SortDomainIndex topIndex
      if pAddTitle is true then roster_AddHeader topIndex, topDomain
      --
      put word 1 to -1 of topIndex & CR & CR after filteredDomains
   end repeat
   return word 1 to -1 of filteredDomains
end roster_CategorySplit


--> Roster | Merge
-
function roster_Subtract wikiDomain, pageSlug, plusID, minusID
   -- was "fedwiki_SubtractRoster"
   put roster_Fetch (wikiDomain, pageSlug, plusID) into rosterText
   put roster_Fetch (wikiDomain, pageSlug, minusID) into minusText
   --
   set the wholeMatches to true
   repeat for each line minusLine in minusText
      put lineOffset (minusLine, rosterText) into lineNum
      delete line lineNum of rosterText
   end repeat
   return rosterText
end roster_Subtract


--> Roster | Categorised
-
function roster_TidyPageFoldMaker templateDomain, templateSlug, rosterDomains
   put pageArray_Fetch (templateDomain, templateSlug) into fromPageArray
   put fromPageArray ["story"] into fromStoryArray
   
   -- lets start to build newStoryArray
   put pageArray_GetFirstPageFold (fromPageArray) into newStoryArray
   
   -- add first found divider
   put item 2 of the extents of newStoryArray into firstDividerItemNum
   add 1 to firstDividerItemNum
   put fromStoryArray [firstDividerItemNum] into firstDividerItemArray
   put firstDividerItemArray into newStoryArray [firstDividerItemNum]
   
   -- extract refs
   put pageArray_ExtractRefItems (fromPageArray) into refItemStoryArray
   
   -- filter out duplicates
   _StripDuplicateRefStoryArray refItemStoryArray
   
   -- see what is missing
   get _FindExtraMissingArray (refItemStoryArray, rosterDomains)
   put it ["bad"] into badArray
   put it ["missing"] into missingArray
   
   -- delete missingDomainsToAdd
   _DeleteBadArray refItemStoryArray, badArray
   
   -- add extra
   _AddMissingDomains refItemStoryArray, missingArray
   
   -- add to newStoryArray
   storyArray_AddToEnd newStoryArray, refItemStoryArray
   
   -- add last divider
   put storyArray_GetLastPageFold (fromStoryArray) into lastDividerItemNum
   put fromStoryArray [lastDividerItemNum] into lastDividerItemArray
   storyArray_AddDividerToEnd newStoryArray, lastDividerItemArray
   
   -- add footer
   _AddBeforePageFold fromPageArray, newStoryArray, lastDividerItemNum
   put the result into lastDividerItemNum
   
   -- replace story and clean journal
   put newStoryArray into fromPageArray ["story"]
   pageArray_StripJournal fromPageArray
   
   return fromPageArray
end roster_TidyPageFoldMaker

function roster_PagefoldConstruct pageArray
   put pageArray ["story"] into storyArray
   repeat with itemNum = 1 to item 2 of the extents of storyArray
      put storyArray [itemNum] into itemArray
      switch itemArray ["type"]
         case "pagefold"
            get itemArray ["text"]
            put word 1 to -1 of it into sectionTitle
            if sectionTitle = "." then
               put "Unclassified" into sectionTitle
            end if
            put CR & sectionTitle & CR & CR after rosterText
            break
         case "reference"
            put itemArray ["site"] into wikiDomain            
            put wikiDomain & CR after rosterText
            break
         default
            next repeat
      end switch
   end repeat
   put word 1 to -1 of rosterText into rosterText
   if line -1 of rosterText = "Unclassified" then
      delete line -1 of rosterText
      put word 1 to -1 of rosterText into rosterText
   end if
   return rosterText
end roster_PagefoldConstruct


--> Private | Create
-
private command storyArray_AddDividerToEnd @storyArray, lastDividerItemArray
   put item 2 of the extents of newStoryArray into nextItemNum
   add 1 to nextItemNum
   put lastDividerItemArray into newStoryArray [nextItemNum]
   return nextItemNum
end storyArray_AddDividerToEnd

private command _AddBeforePageFold fromPageArray, @newStoryArray, pLastDividerItemNum
   -- add to the end of newStoryArray
   put item 2 of the extents of newStoryArray into nextItemNum
   add 1 to nextItemNum
   put fromPageArray ["story"] into fromStoryArray
   --
   if pLastDividerItemNum is empty then
      -- find the last footer startItemNum
      put storyArray_GetLastPageFold (fromStoryArray) into pLastDividerItemNum
   end if
   add 1 to pLastDividerItemNum
   --
   put item 2 of the extents of fromStoryArray into maxNum
   repeat with itemNum = pLastDividerItemNum to maxNum
      put fromStoryArray [itemNum] into itemArray
      put itemArray into newStoryArray [nextItemNum]
      add 1 to nextItemNum
   end repeat   
   return startItemNum
end _AddBeforePageFold

private function _ConstructPostArray itemID, domainFilter, pageSlug, wikiDomain, minPageNum
   put itemID into postArray ["itemID"]
   put domainFilter into postArray ["domainFilter"]
   put pageSlug into postArray ["pageSlug"]
   put wikiDomain into postArray ["wikiDomain"]
   put minPageNum into postArray ["minPageNum"]
   return postArray
end _ConstructPostArray

private command _AddMissingDomains @refItemStoryArray, missingDomainArray
   put item 2 of the extents of refItemStoryArray into newItemNum
   repeat for each key missingDomain in missingDomainArray
      add 1 to newItemNum
      put itemArray_ConstructReference ("welcome-visitors", missingDomain, missingDomain, "Welcome Visitors") into itemArray
      put itemArray into refItemStoryArray [newItemNum]
   end repeat
end _AddMissingDomains

private command _StripDuplicateRefStoryArray @refItemStoryArray
   repeat with itemNum = 1 to item 2 of the extents of refItemStoryArray
      put refItemStoryArray [itemNum] into itemArray
      put itemArray ["site"] into refDomain
      --
      if doneArray [refDomain] is true then
         
      end if
      --
      add 1 to newItemNum
      put itemArray into filteredArray [newItemNum]
      
   end repeat
   put filteredArray into refItemStoryArray
end _StripDuplicateRefStoryArray

private command _DeleteBadArray @refItemStoryArray, badArray
   put keys (badArray) into badDomainNames
   set the wholeMatches to true
   put 1 into newItemNum
   repeat with itemNum = 1 to item 2 of the extents of refItemStoryArray
      put refItemStoryArray [itemNum] into itemArray
      put itemArray ["site"] into refDomain
      if refDomain is not among the lines of badDomainNames then
         put itemArray into filteredArray [newItemNum]
         add 1 to newItemNum
      end if
   end repeat
   put filteredArray into refItemStoryArray
end _DeleteBadArray

private function _FindExtraMissingArray refItemStoryArray, rosterDomains
   set the wholeMatches to true
   put 1 into goodItemNum
   repeat for each line rosterDomain in rosterDomains
      put true into missingArray [rosterDomain]
   end repeat
   
   repeat with itemNum = 1 to item 2 of the extents of refItemStoryArray
      put refItemStoryArray [itemNum] into itemArray
      put itemArray ["site"] into refDomain
      
      -- remove from missing
      delete variable missingArray [refDomain]
      
      -- is it good or bad?
      put lineoffset (refDomain, rosterDomains) into lineNum
      if lineNum = 0 then
         -- story item is not in actual roster
         put itemArray into extraMissingArray ["bad"][refDomain]
      else
         put itemArray into extraMissingArray ["good"][goodItemNum]
         add 1 to goodItemNum
      end if
   end repeat
   put missingArray into extraMissingArray ["missing"]
   return extraMissingArray
end _FindExtraMissingArray


--> Private
-
private command _SetSitesPageRoster @pageArray, rosterTitle, authorDomains
   pageArray_SetRoster pageArray, authorDomains, rosterTitle
   
   -- could search for a header rather than use fixed itemID
   put pageArray_FindItemID ("94aeb407a09d831b", pageArray) into listItemNum
   if listItemNum > 0 then
      put markdown_LinkedBullets (authorDomains) into markDownList
      put "# List of sites" & CR&CR & markDownList into pageArray ["story"][listItemNum]["text"]
   end if
end _SetSitesPageRoster

private command _UpdateSites @pageArray, wikiDomain, pageTitle
   put word 1 to -2 of pageTitle && "Activity" into activityTitle
   put pageTitle into curlyData ["all"]["pageTitle"]
   put activityTitle into curlyData ["all"]["activityTitle"]
   put wikiDomain into curlyData ["all"]["wikiDomain"]
   --
   curly_MergePageArray pageArray, curlyData
end _UpdateSites

private command _FetchRosterReferences refLines, @domainArray
   set the itemdelimiter to slash
   repeat for each line refLine in refLines
      -- REFERENCES astralship.wiki/beings
      delete word 1 of refLine
      put item 1 of refLine into refDomain
      put item 2 of refLine into refSlug
      --
      put roster_FromReferences (refDomain, refSlug) into moreDomains
      _AddRosterToArray domainArray, moreDomains
   end repeat
end _FetchRosterReferences

private command _FetchRosterRoster rosterLines, @domainArray
   set the itemdelimiter to slash
   repeat for each line rosterLine in rosterLines
      -- ROSTER roster.fedwiki.org/mega-sites
      delete word 1 of rosterLine
      put item 1 of rosterLine into rosterDomain
      put item 2 of rosterLine into rosterSlug
      put roster_Fetch (rosterDomain, rosterSlug) into newRosterText
      --
      roster_ParseText newRosterText, newRosterTitle, moreRosterText, moreRosterLines, moreRefLines
      _AddRosterToArray domainArray, moreRosterText
      --
      -- not recursing (but could do?)
   end repeat
end _FetchRosterRoster

command _AddRosterToArray @domainArray, newRosterText
   roster_ParseText newRosterText, rosterTitle, rosterDomains, rosterLines, refLines
   --
   repeat for each line rosterDomain in rosterDomains
      put empty into domainArray [rosterDomain]
   end repeat
   
   # Fetch REFERENCES
   -- refLines -- not doing
   
   # Recurse nested ROSTERs
   -- rosterLines -- not doing
end _AddRosterToArray
