script "lib_FedwikiRoster"
--> MetaData
-
license: GPLv3
name: lib_FedwikiRoster
type: library
version: 0.3

/*
This library is designed to make it easy to programtically generate rosters from a Fedwiki server.

Rosters are the prefered way of storing lists of domains. 
For more complicated data for which using page-json is suitable, we can use the JSON plugin.
*/


--> Working on
-

--> Roster | Compare
-
function atopia_CheckMissingSiteDomains
   put atopia_FetchRoster() into rosterDomains
   delete line 1 to 2 of rosterDomains
   put atopia_ListSitePages() into sitePages
   --
   put the number of lines of sitePages && the number of lines of rosterDomains
   line_DeleteIndex rosterDomains, sitePages
   return rosterDomains
end atopia_CheckMissingSiteDomains

function atopia_CheckMissingRosterDomains
   set the cursor to watch
   put atopia_FetchRoster() into rosterDomains
   delete line 1 to 2 of rosterDomains
   --
   put atopia_FetchServerDomainArray() into atopiaServerDomainArray -- from JSON Plugin
   repeat for each line rosterDomain in rosterDomains
      set the cursor to busy
      put atopiaServerDomainArray [rosterDomain] into domainPageArray
      if domainPageArray is not an array then
         put rosterDomain & CR after missingDomains
      end if
   end repeat
   delete char -1 of missingDomains
   return missingDomains
end atopia_CheckMissingRosterDomains

function atopia_ListSitePages
   put fedwiki_ListSitemapPages ("sites.fedwiki.org") into domainNames
   url_CheckDomainIndex domainNames
   return domainNames
end atopia_ListSitePages

function atopia_FetchNewFolderList
   put atopia_FetchRoster() into alreadyGoodDomains
   if alreadyGoodDomains is empty then
      breakpoint
   end if
   
   put atopia_FetchFilteredFolderLsArray() into remoteFolderArray
   if item 1 of it is "error" then return empty
   -- remove "fedwiki_owners"
   delete variable remoteFolderArray ["fedwiki_owners"]
   
   repeat for each line goodDomainName in alreadyGoodDomains
      set the cursor to busy
      delete variable remoteFolderArray [goodDomainName]
   end repeat
   
   put keys (remoteFolderArray) into newRemoteDomains
   url_SortDomainIndex newRemoteDomains, true
   return newRemoteDomains
end atopia_FetchNewFolderList


--> Atopia | Roster | Fetch
-
function atopia_FetchRoster pFilterDomain, pAddTitle
   -- fetches from roster on wiki specific page (see "atopia_FetchServerDomainJson")
   put roster_Fetch ("server.fedwiki.org", "atopia-domain-index", "741a0fcdd3ff76b2") into atopiaDomains
   if pFilterDomain is not empty then put roster_FilterDomains (atopiaDomains, pFilterDomain, pAddTitle) into atopiaDomains
   if pAddTitle is not true then url_SortDomainIndex atopiaDomains
   return word 1 to -1 of atopiaDomains
end atopia_FetchRoster

command atopia_StoreRoster rosterText
   roster_Store
end atopia_StoreRoster


--> Roster | Filter
-
function roster_SortAndFilter domainArray, pFilterDomains, pAddTitle
   put keys (domainArray) into domainNames
   if pFilterDomains is not empty then put roster_FilterDomains (domainNames, pFilterDomains, pAddTitle) into domainNames
   if pAddTitle is not true then url_SortDomainIndex domainNames
   return domainNames
end roster_SortAndFilter

function roster_FilterDomains domainIndex, pFilterDomains, pAddTitle
   repeat for each item topDomain in pFilterDomains
      put domainIndex into filteredIndex
      put "*." & topDomain into someFilter
      --
      set the wholematches to true
      put topDomain is among the lines of domainIndex into topThere
      filter filteredIndex with someFilter
      if topThere then
         put topDomain & CR before filteredIndex
      end if
      --
      if pAddTitle is true then
         url_SortDomainIndex filteredIndex
         put topDomain & CR & CR after filteredDomainIndex
         put word 1 to -1 of filteredIndex & CR & CR after filteredDomainIndex
      else
         put word 1 to -1 of filteredIndex & CR after filteredDomainIndex
      end if
   end repeat
   delete char -1 of filteredDomainIndex
   return word 1 to -1 of filteredDomainIndex
end roster_FilterDomains

function roster_ConstructPageArray rosterText, pPageTitle
   if pPageTitle is empty then put "Roster Page" into pPageTitle
   replace comma with CR in rosterText
   put pPageTitle into pageArray ["title"]
   fedwiki_AddRosterToPageArray pageArray, rosterText
   fedwiki_StripJournal pageArray
   return pageArray
end roster_ConstructPageArray


--> Roster | Model
-
function roster_Fetch wikiDomain, pageSlug, pItemID
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   if pItemID is empty then
      put fedwiki_FindItemType ("roster", pageArray) into itemNum
      put pageArray ["story"][itemNum]["text"] into rosterDomainText
   else
      put fedwiki_GetStoryItemText (pageArray, pItemID) into rosterDomainText
   end if
   return rosterDomainText
end roster_Fetch

command roster_Store wikiDomain, pageSlug, rosterText, pItemID
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   if pItemID is empty then
      put fedwiki_FindItemType ("roster", pageArray) into itemNum
   else
      put fedwiki_FindItemID (pItemID, pageArray) into itemNum
   end if
   put rosterText into pageArray ["story"][itemNum]["text"]
   
end roster_Store


--> Fedwiki | Roster | Merge
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

function roster_FetchAndUpdate wikiDomain, pageSlug, itemID, rosterDomainText
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   put fedwiki_GetStoryItemText (pageArray, itemID) into oldItemText
   put line 1 of oldItemText & CR & CR & rosterDomainText into itemText
   --
   fedwiki_SetStoryItemText pageArray, itemID, itemText
   fedwiki_StripJournal pageArray
   return pageArray
end roster_FetchAndUpdate
