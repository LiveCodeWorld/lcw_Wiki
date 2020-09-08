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
command roster_ReturnPageArray wikiDomain, pRosterTitle
   put atopia_FetchRosterDomains (wikiDomain) into wikiDomains
   put roster_ConstructPageArray (wikiDomains, pRosterTitle) into pageArray
   fedwiki_ReturnPageArray pageArray
end roster_ReturnPageArray


--> Federation | Roster
-
function federation_FetchRosterDomains serverName, pDomainFilter
   put atopia_FetchRoster() into atopiaDomains
   roster_StripHeader atopiaDomains
   --
   url_FilterDomainIndex atopiaDomains, pDomainFilter
   --
   return word 1 to -1 of atopiaDomains
end federation_FetchRosterDomains

command federation_StoreRosterDomains wikiDomains
   url_SortDomainIndex wikiDomains
   put "Atopia Domains" & CR&CR & wikiDomains into rosterText
   --
   atopia_StoreRoster rosterText
   --
   put the result into pageArray
   return pageArray
end federation_StoreRosterDomains


--> Atopia | Roster | Header
-
command atopia_AddToRoster wikiDomain
   put atopia_FetchRosterDomains() into rosterDomains
   --
   put CR & wikiDomain after rosterDomains
   url_SortDomainIndex rosterDomains
   --
   atopia_StoreRosterDomains rosterDomains
   return rosterText
end atopia_AddToRoster

command atopia_DeleteFromRoster wikiDomain
   put atopia_FetchRosterDomains() into rosterDomains
   --
   line_Delete wikiDomain, rosterDomains
   --
   atopia_StoreRosterDomains rosterDomains
   return rosterText
end atopia_DeleteFromRoster

function atopia_FetchRosterDomains pDomainFilter
   put atopia_FetchRoster() into atopiaDomains
   roster_StripHeader atopiaDomains
   --
   url_FilterDomainIndex atopiaDomains, pDomainFilter
   --
   return word 1 to -1 of atopiaDomains
end atopia_FetchRosterDomains

command atopia_StoreRosterDomains wikiDomains
   url_SortDomainIndex wikiDomains
   put "Atopia Domains" & CR&CR & wikiDomains into rosterText
   --
   atopia_StoreRoster rosterText
   --
   put the result into pageArray
   return pageArray
end atopia_StoreRosterDomains

function atopia_FetchRoster
   -- fetch the one big domain index roster then filter
   put roster_Fetch ("server.fedwiki.org", "atopia-domain-index", "741a0fcdd3ff76b2") into rosterText
   return word 1 to -1 of rosterText
end atopia_FetchRoster

command atopia_StoreRoster rosterText
   roster_Store "server.fedwiki.org", "atopia-domain-index", rosterText, "741a0fcdd3ff76b2"
   put the result into pageArray
   return pageArray
end atopia_StoreRoster


--> Roster | Header
-
command roster_StripHeader @rosterText
   if word 1 to -1 of line 2 of rosterText is empty then
      delete line 1 to 2 of rosterText
      url_SortDomainIndex rosterText
   end if
end roster_StripHeader

command roster_AddHeader @rosterText, rosterHeader
   if word 1 to -1 of line 2 of rosterText is empty then
      url_SortDomainIndex rosterText
      put rosterHeader & CR & CR before rosterText
      put word 1 to -1 of domainIndex into rosterText
   end if
end roster_AddHeader

command roster_ReplaceHeader @rosterText, newRosterHeader
   if word 1 to -1 of line 2 of rosterText is empty then
      delete line 1 to 2 of rosterText
      url_SortDomainIndex rosterText
      put newRosterHeader & CR & CR before rosterText
   end if
end roster_ReplaceHeader


--> Roster
-
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

function roster_DepStackNames
   -- here just to make updates of multiple roster controllers easy
   return "lib_Fedwiki,lib_FedwikiRoster,lib_PageArray,model_Fedwiki"
   -- return "lib_Fedwiki,lib_PageArray,lib_FedwikiRoster,lib_Federation,model_PageArray,model_Fedwiki"
end roster_DepStackNames

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


--> Roster | PageArray
-
command roster_ReturnPageArray wikiDomain, pFetchLive
   if pFetchLive is true then
      put roster_FetchLivePageArray (wikiDomain) into pageArray
   else
      put atopia_FetchRosterDomains (wikiDomain) into refTable
      put roster_ConstructPageArray (refTable) into pageArray
   end if
   fedwiki_ReturnPageArray pageArray
   return pageArray
end roster_ReturnPageArray

function roster_FetchLivePageArray wikiDomain
   put roster_FetchLive (wikiDomain) into rosterText
   put roster_ConstructPageArray (rosterText) into pageArray
   return pageArray
end roster_FetchLivePageArray

function roster_FetchLive wikiDomain
   -- live version (uses "tree")
   -- see also "atopia_FetchFolders"
   
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
         get item 4 to -2 of rosterLine
         if it is not empty then
            put it & CR after rosterText
         end if
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


--> Roster | Filter
-
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
