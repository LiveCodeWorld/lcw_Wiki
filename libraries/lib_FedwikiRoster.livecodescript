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
function roster_FetchLivePageArray wikiDomain
   put roster_FetchLive (wikiDomain) into rosterText
   put roster_ConstructPageArray (rosterText) into pageArray
   return pageArray
end roster_FetchLivePageArray

function roster_FetchLive wikiDomain
   -- live version ("atopia_FetchFolders")
   -- put atopia_FetchRoster ("proto.institute") into rosterText
   -- put "ssh root@fedwiki.org ls /root/.wiki/" into remoteShell
   -- roster_DomainFilter rosterText, wikiDomain
   
   put merge ("ssh root@fedwiki.org tree /root/.wiki/*[[wikiDomain]]/status -d") into remoteShell
   put word 1 to -1 of shell (remoteShell) into folderLines
   if folderLines contains "[error opening dir]" then 
      put remoteShell into rosterText
   else
      delete line -1 of folderLines
      put word 1 to -1 of folderLines into folderLines
      -- replace "/root/.wiki/" with empty in rosterText
      
      set the itemdelimiter to slash
      repeat for each line rosterLine in folderLines
         -- /root/.wiki/david.proto.institute/status
         put item 4 to -2 of rosterLine & CR after rosterText
      end repeat
      delete char -1 of rosterText
   end if
   return rosterText
end roster_FetchLive


--> Roster | Fetch
-
function roster_FetchDomains pSlug
   if pSlug is empty then
      put "visible-federation" into pSlug
   else
      put tolower (word 1 of pSlug) & "-sites" into pSlug
   end if
   put roster_Fetch ("roster.fedwiki.org", pSlug) into rosterText
   put roster_EvaluateText (rosterText) into fedDomains
   return fedDomains
end roster_FetchDomains

function roster_CategorySplit domainIndex, pTopDomains, pAddTitle
   if pTopDomains is empty then
      put url_ListTopDomains (domainIndex) into pTopDomains
   end if
   --
   repeat for each item topDomain in pTopDomains
      put domainIndex into topIndex
      --
      roster_DomainFilter topIndex, topDomain
      url_SortDomainIndex topIndex
      if pAddTitle is true then roster_AddTitle topIndex, topDomain
      --
      put word 1 to -1 of topIndex & CR & CR after filteredDomains
   end repeat
   return word 1 to -1 of filteredDomains
end roster_CategorySplit

function roster_GetTop wikiDomains
   put url_ListTopDomains (wikiDomains) into topDomains
   url_SortDomainIndex topDomains
   return topDomains
end roster_GetTop

command roster_AddTitle @domainIndex, someTitle
   put someTitle & CR & CR before domainIndex
   put word 1 to -1 of domainIndex into domainIndex
end roster_AddTitle

command roster_DomainFilter @domainIndex, topDomain
   if topDomain is empty then return empty
   put "*." & topDomain into someFilter
   set the wholematches to true
   put topDomain is among the lines of domainIndex into topThere
   filter domainIndex with someFilter
   if topThere then
      put topDomain & CR before domainIndex
   end if
   return someFilter
end roster_DomainFilter

function roster_EvaluateText rosterText
   set the itemdelimiter to slash
   --
   get rosterText
   filter it with "REFERENCES *"
   repeat for each line rosterLine in it
      -- ROSTER roster.fedwiki.org/mega-sites
      delete word 1 of rosterLine
      put item 1 of rosterLine into refDomain
      put item 2 of rosterLine into refSlug
      -- go get ref items
      -- not done yet
   end repeat
   --
   get rosterText
   filter it with "ROSTER *"
   repeat for each line rosterLine in it
      -- ROSTER roster.fedwiki.org/mega-sites
      delete word 1 of rosterLine
      put item 1 of rosterLine into rosterDomain
      put item 2 of rosterLine into rosterSlug
      put roster_Fetch (rosterDomain, rosterSlug) into rosterDomains
      -- roster_Clean rosterDomains
      if rosterDomains is not empty then
         put rosterDomains & CR after allDomains
      end if
   end repeat
   --
   filter rosterText without "ROSTER *"
   filter rosterText without "REFERENCES *"
   if rosterText is not empty then
      put rosterText & CR after allDomains
   end if
   roster_Clean allDomains
   return allDomains
end roster_EvaluateText


--> Roster | Model
-
function roster_Fetch wikiDomain, pageSlug, pItemID
   -- find in first roster on page
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   if pItemID is empty then
      put pageArray_FindItemType ("roster", pageArray) into itemNum
      put pageArray ["story"][itemNum]["text"] into rosterDomainText
   else
      put pageArray_GetItemText (pageArray, pItemID) into rosterDomainText
   end if
   return rosterDomainText
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
   pageArray_Store wikiDomain, pageSlug, pageArray
   return pageArray
end roster_Store


--> Atopia | Roster | Fetch
-
function atopia_FetchRoster pFilterDomain, pAllowTitle
   put roster_Fetch ("server.fedwiki.org", "atopia-domain-index", "741a0fcdd3ff76b2") into atopiaDomains
   if pFilterDomain is not empty then put roster_CategorySplit (atopiaDomains, pFilterDomain, pAddTitle) into atopiaDomains
   if pAllowTitle is not true then
      roster_StripHeader atopiaDomains
      url_SortDomainIndex atopiaDomains
   end if
   return word 1 to -1 of atopiaDomains
end atopia_FetchRoster

command atopia_StoreRoster rosterText
   roster_Store "server.fedwiki.org", "atopia-domain-index", rosterText, "741a0fcdd3ff76b2"
   put the result into pageArray
   return pageArray
end atopia_StoreRoster


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
   put atopia_FetchFedray() into atopiaServerDomainArray -- from JSON Plugin
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


--> Roster | Filter
-
command roster_StripHeader @rosterText
   if word 1 to -1 of line 2 of rosterText is empty then
      delete line 1 to 2 of rosterText
   end if
end roster_StripHeader

command roster_Clean @rosterText
   -- strip out all title entries (assume they are the lines without ".")
   set the itemdelimiter to "."
   repeat for each line wikiDomain in rosterText
      put word 1 to -1 of wikiDomain into wikiDomain
      if item 1 of wikiDomain = "www" then
         delete item 1 of wikiDomain
      end if
      if the number of items of wikiDomain > 1 then
         put empty into domainArray [wikiDomain]
      end if
   end repeat
   put keys (domainArray) into goodDomains
   url_SortDomainIndex goodDomains
   put goodDomains into rosterText
end roster_Clean

function roster_ConstructPageArray rosterText, pPageTitle
   if pPageTitle is empty then put "Roster Page" into pPageTitle
   replace comma with CR in rosterText
   put pPageTitle into pageArray ["title"]
   pageArray_AddRoster pageArray, rosterText
   pageArray_StripJournal pageArray
   return pageArray
end roster_ConstructPageArray


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
