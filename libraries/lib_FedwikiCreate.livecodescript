script "lib_FedwikiCreate"
--> MetaData
-
license: GPLv3
name: lib_FedwikiCreate
type: library
version: 0.2

/*
This is a library for creating fedwiki pages and sites.
See also "lib_PageArray" and "model_PageArray"

For now it contains handlers used by "roster.lc" (the Roster Transport).
Should be called ""lib_RosterCreate""
*/

--> Working on
-
function roster_CreateActivityPage wikiDomain
   -- used by "roster.lc" (nothing else yet)
   
   set the itemdelimiter to "."
   put text_InitialCaps (item 1 of wikiDomain) into rosterTitle
   
   put atopia_FetchRoster (wikiDomain, false) into domainNames
   
   put fedwiki_MarkdownIndex (domainNames) into markdownIndex
   
   put rosterTitle into curlyArray ["rosterTitle"]
   put wikiDomain into curlyArray ["wikiDomain"]
   put rosterDomains into curlyArray ["rosterText"]
   put markdownIndex into curlyArray ["rosterIndex"]
   --
   -- put pageArray_FetchTemplate ("roster.fedwiki.org", "roster-template", curlyArray) into pageArray
   put pageSlug into curlyArray ["Page Slug"]
   put fedwikiDomain into curlyArray ["Wiki Domain"]
   put fedwiki_ConstructTitle (pageSlug) into curlyArray ["Page Title"]
   put pageArray_Fetch ("roster.fedwiki.org", "roster-template") into pageArray
   --
   put curlyArray into curlyData ["all"]
   curly_MergeAll pageArray, curlyData
   --
   put rosterTitle && "Activity" into pageTitle
   put pageTitle into pageArray ["title"]
   --
   return pageArray
end roster_CreateActivityPage

function roster_FetchUpdatedPageArray domainFilter, templateDomain, templateSlug, pItemID
   if domainFilter = "top" then
      put atopia_FetchRoster() into domainNames
      put url_ListTopDomains (domainNames) into domainNames
   else
      put atopia_FetchRoster (domainFilter, false) into domainNames
   end if
   --
   put pageArray_Fetch (templateDomain, templateSlug) into pageArray
   if pageArray is empty then
      put merge ("Could not find page '[[templateSlug]]' of wiki '[[templateDomain]]'.") into someText
      put pageArray_Construct ("Missing Page!", someText) into pageArray
      fedwiki_ReturnPageArray pageArray
      exit to top
   end if
   
   put fedwiki_ConstructTitle (templateSlug) into pageTitle
   put pageTitle & CR & CR & domainNames into rosterText
   --
   if pItemID is empty then
      put pageArray_FindItemType ("roster", pageArray) into itemNum
      put rosterText into pageArray ["story"][itemNum]["text"]
   else
      pageArray_SetItemText pageArray, pItemID, rosterText
   end if
   --
   pageArray_StripJournal pageArray
   return pageArray
end roster_FetchUpdatedPageArray


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
   fedwiki_AddToStoryArrayItems newStoryArray, refItemStoryArray
   
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


--> Private
-
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


--> More
-
private command _AddMissingDomains @refItemStoryArray, missingDomainArray
   put item 2 of the extents of refItemStoryArray into newItemNum
   repeat for each key missingDomain in missingDomainArray
      add 1 to newItemNum
      put storyArray_ConstructReference ("welcome-visitors", missingDomain, missingDomain, "Welcome Visitors") into itemArray
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
      put itemArray ["site"] into refDomain -- "livecode.world"
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
      put itemArray ["site"] into refDomain -- "livecode.world"
      
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
