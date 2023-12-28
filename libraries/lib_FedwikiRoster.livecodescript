script "lib_FedwikiRoster"
--> MetaData
-
license: GPLv3
name: lib_FedwikiRoster
type: library
version: 0.3

/*
Experimental libreary. Moving code to better named libs like "model_Atopia" and "model_Fedray"

This library is designed to make it easy to programtically generate rosters from a Fedwiki server.

Rosters are the prefered way of storing lists of domains. 
For more complicated data for which using page-json is suitable, we can use the JSON plugin.
*/


--> Working on
-
command atopia_ReturnRoster wikiDomains, pTitle, pRosterTitle
   switch the environment
      case "development"
         put wiki_ListLocalShortAll("*thought.garden") into localFolders
         repeat for each line wikiDomain in localFolders
            put wikiDomain & ":3000" & CR after filteredLocalDomains
         end repeat
         delete char -1 of filteredLocalDomains
         --
         roster_ReturnFiltered filteredLocalDomains, pTitle, pRosterTitle
         break
      default
         -- put atopia_ListWelcomeFolders (wikiDomains) into filteredAtopiaDomains
         put federation_ListDomains (wikiDomains) into filteredAtopiaDomains
         roster_ReturnFiltered filteredAtopiaDomains, pTitle, pRosterTitle
   end switch
end atopia_ReturnRoster


--> Roster | Return
-
command roster_ReturnFiltered wikiDomains, pTitle, pRosterTitle
   put roster_ConstructPageArray (wikiDomains, pRosterTitle) into pageArray
   fedwiki_ReturnPageArray pageArray
end roster_ReturnFiltered

command atopia_ReturnSitesPageArray wikiDomain, pPageTitle
   -- put atopia_ListWelcomeFolders (wikiDomain) into rosterDomains
   put federation_ListDomains (wikiDomain) into rosterDomains
   put roster_ConstructSitesPageArray (wikiDomain, rosterDomains, pPageTitle) into pageArray
   --
   fedwiki_ReturnPageArray pageArray
end atopia_ReturnSitesPageArray

command roster_ReturnPageArray wikiDomain, pTitle, pRosterTitle
   -- should return to "federation_ReturnRoster"
   put fedray_FetchDomains (wikiDomain) into wikiDomains
   roster_ReturnFiltered wikiDomains, pTitle, pRosterTitle
end roster_ReturnPageArray

command roster_ReturnAtopiaPageArray wikiDomain, pTitle, pRosterTitle
   put federation_ListDomains (wikiDomain) into wikiDomains
   --
   roster_ReturnFiltered wikiDomains, pTitle, pRosterTitle
end roster_ReturnAtopiaPageArray


--> Roster | Fetch
-
function roster_FetchTemplate pWikiDomain, pPageTitle, pForkDomains
   if pForkDomains is empty then put "fedwiki.org,roster.fedwiki.org,sites.fedwiki.org" into pForkDomains
   --
   switch
      case (pPageTitle is empty) AND (pWikiDomain is empty)
         put "roster.fedwiki.org" into pWikiDomain
         put "Sites Template" into pPageTitle
         break
      case (pPageTitle is empty)
         put _ConstructSitesTitle (pWikiDomain) into pPageTitle
         break
      case (pWikiDomain is empty)
         put "roster.fedwiki.org" into pWikiDomain
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

command federation_ReturnSitesPageArray wikiDomain, pPageTitle
   put federation_ListDomains (wikiDomain) into rosterDomains
   put roster_ConstructSitesPageArray (wikiDomain, rosterDomains, pPageTitle) into pageArray
   --
   fedwiki_ReturnPageArray pageArray
end federation_ReturnSitesPageArray

command federation_ReturnActivityRoster rosterTitle, pSincePeriod
   put federation_ListRecentDomains (pSincePeriod) into rosterText
   put rosterTitle & CR & CR before rosterText
   put roster_ConstructPageArray (rosterText) into pageArray
   fedwiki_ReturnPageArray pageArray
end federation_ReturnActivityRoster


--> Roster | Domains
-
command roster_AddDomain @rosterText, wikiDomain
   roster_Deconstruct rosterText, rosterDomains, rosterTitle
   put the result into hasTitle
   line_Add wikiDomain, rosterDomains
   put roster_Reconstruct (rosterDomains, rosterTitle) into rosterText
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

function roster_Reconstruct rosterDomains, pRosterTitle
   if pRosterTitle is empty then return rosterDomains
   --
   return pRosterTitle & CR&CR & rosterDomains
end roster_Reconstruct

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

function roster_HasTitle rosterText
   if line 1 of rosterText contains "." then return false
   -- 
   if word 1 to -1 of line 2 of rosterText is empty then
      return true
   else
      return false
   end if
end roster_HasTitle


--> Roster | Header
-
command roster_StripHeader @rosterText
   if roster_HasTitle (rosterText) then
      delete line 1 to 2 of rosterText
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


--> Roster | Filter
-
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


--> Private
-
private command _SetSitesPageRoster @pageArray, rosterTitle, authorDomains
   pageArray_SetRoster pageArray, authorDomains, rosterTitle
   
   -- could search for a header rather than use fixed itemID
   put pageArray_FindItemID ("94aeb407a09d831b", pageArray) into listItemNum
   if listItemNum > 0 then
      put fedwiki_MarkdownIndex (authorDomains) into markDownList
      put "# List of sites" & CR&CR & markDownList into pageArray ["story"][listItemNum]["text"]
   end if
end _SetSitesPageRoster

private function _ConstructSitesTitle wikiDomain
   set the itemdelimiter to "."
   repeat for each item someItem in wikiDomain
      put text_InitialCaps (someItem) & space after pageTitle
   end repeat
   put "Sites" after pageTitle
   return pageTitle
end _ConstructSitesTitle

private command _UpdateSites @pageArray, wikiDomain, pageTitle
   put word 1 to -2 of pageTitle && "Activity" into activityTitle
   put pageTitle into curlyData ["all"]["pageTitle"]
   put activityTitle into curlyData ["all"]["activityTitle"]
   put wikiDomain into curlyData ["all"]["wikiDomain"]
   --
   curly_MergePageArray pageArray, curlyData
end _UpdateSites
