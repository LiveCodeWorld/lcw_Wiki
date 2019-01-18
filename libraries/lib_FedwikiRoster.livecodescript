script "lib_FedwikiRoster"
--> MetaData
-
license: GPLv3
name: lib_FedwikiRoster
type: library
version: 0.1

/*
This library is designed to make it easy to programtically generate rosters from a Fedwiki server.
*/


--> Fedwiki | Roster
-
function fedwiki_ConstructRosterPageJson topDomain
   put atopia_FetchStoredDomains (topDomain) into refTable
   put fedwiki_ConstructRosterPageArray (refTable) into pageArray
   put json_FromArray (pageArray) into someJSON
   return someJSON
end fedwiki_ConstructRosterPageJson

function fedwiki_ConstructRosterPageArray rosterText, pPageTitle
   if pPageTitle is empty then put "Roster Page" into pPageTitle
   replace comma with CR in rosterText
   -- replace CR with comma in rosterText
   -- replace comma with "\n" in rosterText
   --
   put pPageTitle into pageArray ["title"]
   fedwiki_AddRosterToPageArray pageArray, rosterText
   fedwiki_StripJournalToCreate pageArray
   return pageArray
end fedwiki_ConstructRosterPageArray

function atopia_FilterDomain domainIndex, topDomain
   put "*." & topDomain into someFilter
   --
   set the wholematches to true
   put topDomain is among the lines of domainIndex into topThere
   filter domainIndex with someFilter
   if topThere then
      put topDomain & CR before domainIndex
      put word 1 to -1 of domainIndex into domainIndex
   end if
   return domainIndex
end atopia_FilterDomain


--> Atopia | JSON | Domains
-
/*
Let's store domain index to a wiki page
*/

function atopia_FetchStoredDomains pFilterDomain
   put atopia_FetchServerJSON ("Atopia Domains") into someJSON
   put _DeconstructJsonIndex (someJSON) into domainIndex
   if pFilterDomain is not empty then
      put atopia_FilterDomain (domainIndex, pFilterDomain) into domainIndex
   end if
   return domainIndex
end atopia_FetchStoredDomains

command atopia_SaveDomainIndex domainIndex
   put _ConstructJsonIndex (domainIndex) into someJSON
   --
   atopia_StoreServerJSON "Atopia Domains", someJSON
   put the result into putError
   return putError
end atopia_SaveDomainIndex


--> Atopia | JSON
-
function atopia_FetchServerJSON whichJson
   _SetSlugDomain whichJson, pageSlug, wikiDomain
   put fedwiki_FetchPluginJSON (pageSlug, wikiDomain) into someJSON
   return someJSON
end atopia_FetchServerJSON

command atopia_StoreServerJSON whichJson, someJSON
   _SetSlugDomain whichJson, pageSlug, wikiDomain
   put atopia_GetJsonSecret() into apiKey
   fedwiki_PutPluginJSON someJSON, pageSlug, wikiDomain, apiKey
   put the result into putError
   return putError
end atopia_StoreServerJSON


--> Fedwiki | JSON Plugin
-
function fedwiki_FetchPluginJSON pageSlug, wikiDomain
   put fedwiki_ConstructPluginJsonUrl (pageSlug, wikiDomain) into restURL
   put url restURL into someJSON
   return someJSON
end fedwiki_FetchPluginJSON

command fedwiki_PutPluginJSON someJSON, pageSlug, wikiDomain, apiKey
   -- for http://admin.fedwiki.org/json-plugin.html
   
   put fedwiki_ConstructPluginJsonUrl (pageSlug, wikiDomain) into restURL
   --
   put "Content-type: application/json" into newHeaders
   put CR & "Accept: application/json" after newHeaders
   put CR & "Accept-Charset: utf-8" after newHeaders
   put CR & "X-Api-Key:" && apiKey after newHeaders
   set the httpheaders to newHeaders
   --
   -- replace "'" with quote in someJSON
   --
   put someJSON into url restURL
   --
   put the result into putResult
   /*
   -- this should return, but is returning only error msg I think
   {
   "status": "ok",
   "writes": 3330,
   "interval": 299524,
   "length": 17736
   }
   */
   return putResult
end fedwiki_PutPluginJSON

function fedwiki_ConstructPluginJsonUrl pageSlug, wikiDomain
   -- http://admin.fedwiki.org/plugin/json/atopia-fedwiki-sites
   put "http://" & wikiDomain & "/plugin/json/" & pageSlug into restURL
   return restURL
end fedwiki_ConstructPluginJsonUrl


--> Atopia | JSON | Secret
-
function atopia_GetJsonSecret
   put secret_Get ("AtopiaJsonApiKey", "jsonApiKey") into apiKey
   return apiKey
end atopia_GetJsonSecret

command atopia_SetJsonSecret apiKey
   secret_Set "AtopiaJsonApiKey", "jsonApiKey", apiKey
   return the result
end atopia_SetJsonSecret


--> Private
-
private function _DeconstructJsonIndex someJSON
   put json_ToArray (someJSON) into jsonArray
   put jsonArray ["domains"] into domainIndex
   replace comma with CR in domainIndex
   return domainIndex
end _DeconstructJsonIndex

private function _ConstructJsonIndex domainIndex
   replace CR with comma in domainIndex
   put domainIndex into jsonArray ["domains"]
   put json_FromArray (jsonArray) into someJSON
   return someJSON
end _ConstructJsonIndex

private command _SetSlugDomain whichJson, @pageSlug, @wikiDomain
   switch whichJson
      case "Servers"
         put "site-of-servers" into pageSlug
         put "server.fedwiki.org" into wikiDomain
         break
      default -- "Atopia Domains"
         put "atopia-domain-index" into pageSlug
         put "sites.fedwiki.org" into wikiDomain
   end switch
end _SetSlugDomain
