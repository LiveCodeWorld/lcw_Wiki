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


--> Working on (see lib_WikiRoster)
-
function roster_DepStackNames
   -- here just to make updates of multiple roster controllers easy
   return "lib_Fedwiki,lib_FedwikiRoster,lib_PageArray,model_Fedwiki"
   -- return "lib_Fedwiki,lib_PageArray,lib_FedwikiRoster,lib_Federation,model_PageArray,model_Fedwiki"
end roster_DepStackNames

command roster_Clean @rosterText
   -- ugly and not used
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

command atopia_ReturnRoster wikiDomains, pTitle, pRosterTitle
   switch the environment
      case "development"
         put wikiGarden_ListAllDomains ("thought.garden") into localFolders
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
command atopia_ReturnSitesPageArray wikiDomain, pPageTitle
   -- put atopia_ListWelcomeFolders (wikiDomain) into rosterDomains
   put federation_ListDomains (wikiDomain) into rosterDomains
   put roster_ConstructSitesPageArray (wikiDomain, rosterDomains, pPageTitle) into pageArray
   --
   transport_ReturnPageArray pageArray
end atopia_ReturnSitesPageArray

command roster_ReturnAtopiaPageArray wikiDomain, pTitle, pRosterTitle
   put federation_ListDomains (wikiDomain) into wikiDomains
   --
   roster_ReturnFiltered wikiDomains, pTitle, pRosterTitle
end roster_ReturnAtopiaPageArray


--> Roster | PageArray
-
command roster_ReturnPageArray wikiDomain, pFetchLive
   if pFetchLive is true then
      put roster_FetchLivePageArray (wikiDomain) into pageArray
   else
      put atopia_FetchRosterDomains (wikiDomain) into refTable
      put roster_ConstructPageArray (refTable) into pageArray
   end if
   transport_ReturnPageArray pageArray
   return pageArray
end roster_ReturnPageArray

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

function roster_FetchLivePageArray wikiDomain
   put roster_FetchLive (wikiDomain) into rosterText
   put roster_ConstructPageArray (rosterText) into pageArray
   return pageArray
end roster_FetchLivePageArray


--> Roster | Fetch
-
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

command roster_ReturnFiltered wikiDomains, pTitle, pRosterTitle
   put roster_ConstructPageArray (wikiDomains, pRosterTitle) into pageArray
   transport_ReturnPageArray pageArray
end roster_ReturnFiltered

command roster_ReturnPageArray wikiDomain, pTitle, pRosterTitle
   -- should return to "federation_ReturnRoster"
   put fedray_FetchDomains (wikiDomain) into wikiDomains
   roster_ReturnFiltered wikiDomains, pTitle, pRosterTitle
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

command federation_ReturnSitesPageArray wikiDomain, pPageTitle
   put federation_ListDomains (wikiDomain) into rosterDomains
   put roster_ConstructSitesPageArray (wikiDomain, rosterDomains, pPageTitle) into pageArray
   --
   transport_ReturnPageArray pageArray
end federation_ReturnSitesPageArray

command federation_ReturnActivityRoster rosterTitle, pSincePeriod
   put federation_ListRecentDomains (pSincePeriod) into rosterText
   put rosterTitle & CR & CR before rosterText
   put roster_ConstructPageArray (rosterText) into pageArray
   transport_ReturnPageArray pageArray
end federation_ReturnActivityRoster
