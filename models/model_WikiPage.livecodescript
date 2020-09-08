script "model_WikiPage"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: model_WikiPage
type: model
version: 0.1

/*
This is a model for fetching, storing Fedwiki pages.
See also "model_WikiPage", "model_AtopiaFiles", "lib_PageArray" and "lib_FedwikiCreate"
*/


--> Working on
-
--> Federation | Home
-
function fedwiki_FetchHomePageArray wikiDomain
   put pageArray_Fetch (wikiDomain, "welcome-visitors") into pageArray
   return pageArray
end fedwiki_FetchHomePageArray


--> Federation | Template
-
command federation_UpdateTemplate pageTitle, wikiDomain, pCurlyData, pForkDomains, pTemplateStem
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put pageTitle into curlyData ["all"]["pageTitle"]
   put pageSlug into curlyData ["all"]["pageSlug"]
   put wikiDomain into curlyData ["all"]["wikiDomain"]
   --
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   if pageArray is empty then
      put federation_FetchTemplateArray (wikiDomain, pageTitle, pForkDomains, pTemplateStem) into pageArray
   end if
   curly_MergePageArray pageArray, pCurlyData
   pageArray_Store wikiDomain, pageSlug, pageArray
   return pageArray
end federation_UpdateTemplate

function federation_FetchTemplateArray wikiDomain, pNewPageTitle, pForkDomains, pTemplateStem
   if pTemplateStem is empty then
      set the itemdelimiter to "."
      put item 1 of wikiDomain into pTemplateStem
   end if
   put tolower (pTemplateStem) & "-" & "template" into pageSlug
   --
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   if pageArray is not an array then return empty
   --
   pageArray_Rename pageArray, pNewPageTitle
   pageArray_StripJournal pageArray
   pageArray_AddFork pageArray, pForkDomains
   return pageArray
end federation_FetchTemplateArray


--> Atopia | Home | Forks
-
command atopia_CleanHomeForks wikiDomain
   put fedwiki_FetchHomePageArray (wikiDomain) into pageArray
   --
   -- pageArray_CleanJournal pageArray, "fork"
   pageArray_CleanJournal pageArray
   --
   atopia_StoreHomePageArray wikiDomain, pageArray
end atopia_CleanHomeForks

command atopia_AddHomeForks wikiDomain, forkDomains, pCleanJournal
   put fedwiki_FetchHomePageArray (wikiDomain) into pageArray
   --
   if pCleanJournal is true then
      pageArray_CleanJournal pageArray
   end if
   pageArray_AddFork pageArray, forkDomains
   pageArray_CleanJournal pageArray, "fork"
   --
   atopia_StoreHomePageArray wikiDomain, pageArray
end atopia_AddHomeForks

function atopia_FetchHomeForkDomains wikiDomain
   put fedwiki_FetchHomePageArray (wikiDomain) into pageArray
   put pageArray_ExtractForkDomains (pageArray) into forkDomains
   return forkDomains
end atopia_FetchHomeForkDomains

command atopia_AddHomeJournalForkDomains wikiDomain, addDomainList
   put fedwiki_FetchHomePageArray (wikiDomain) into pageArray
   put pageArray_ExtractForkDomains (pageArray) into forkDomains
   --
   put line_CombineUnique (forkDomains, addDomainList) into newDomainList
   url_SortDomainIndex newDomainList
   --
   pageArray_StripJournal pageArray
   pageArray_AddFork pageArray, newDomainList
   --
   atopia_StoreHomePageArray wikiDomain, pageArray
end atopia_AddHomeJournalForkDomains

command atopia_SetHomeJournalForkDomains wikiDomain, forkDomainList
   put fedwiki_FetchHomePageArray (wikiDomain) into pageArray
   --
   pageArray_StripJournal pageArray
   pageArray_AddFork pageArray, forkDomainList
   --
   atopia_StoreHomePageArray wikiDomain, pageArray
end atopia_SetHomeJournalForkDomains


--> Atopia | Home
-
command atopia_SetDefaultHome wikiDomain
   -- copies a welcome-visiters page from a domain to the default page location
   put fedwiki_FetchHomePageArray (wikiDomain) into pageArray
   --
   pageArray_StripJournal pageArray
   pageArray_AddFork pageArray, "proto.institute,fedwiki.org,orientation.fedwiki.org"
   --
   atopia_StoreDefaultHomePageArray pageArray
   return the result
end atopia_SetDefaultHome

function atopia_FetchHomePageArray wikiDomain
   put fedwiki_FetchHomePageArray (wikiDomain) into pageArray
   return pageArray
end atopia_FetchHomePageArray

command atopia_StoreHomePageArray wikiDomain, pageArray
   pageArray_Store wikiDomain, "welcome-visitors", pageArray
   return the result
end atopia_StoreHomePageArray

command atopia_StoreDefaultHomePageArray pageArray
   pageArray_StoreDefault "welcome-visitors", pageArray
   return the result
end atopia_StoreDefaultHomePageArray

command atopia_SetDefaultPages wikiDomain
   atopia_SetDefaultPage "changes-to-this-site", wikiDomain
   atopia_SetDefaultPage "federation-activity", "fedwiki.org"
   atopia_SetDefaultPage "fedwiki-tools", "fedwiki.org"
   atopia_SetDefaultPage "filtered-federation-activity", "fedwiki.org"
   atopia_SetDefaultPage "the-federation", "fedwiki.org"
end atopia_SetDefaultPages

command atopia_SetDefaultPage pageSlug, wikiDomain
   -- takes a wiki page from a site, and copies it to the wiki farms
   -- the default location for new sites is something like node_modules/wiki/node_modules/wiki-server/default-data/pages/
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   pageArray_StoreDefault pageSlug, pageArray
   return pageArray
end atopia_SetDefaultPage


--> LCW | Handler | Model
-
/*
Here we reference handlers stared on "handler.livecode.world"
We define a new concept "handerArray" to mean a "pageArray" for handlers.
*/

function lcw_FetchObjectPageArray sObject
   _ObjectDomainInfo sObject, pageTitle, pageSlug, wikiDomain
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   return pageArray
end lcw_FetchObjectPageArray

command lcw_StoreObjectPageArray sObject, pageArray
   _ObjectDomainInfo sObject, pageTitle, pageSlug, wikiDomain
   pageArray_Store wikiDomain, pageSlug, pageArray
   return the result
end lcw_StoreObjectPageArray

function lcw_FetchHandlerArray hKey
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   put fedwiki_ConstructSlug (hName) into pageSlug
   --
   put pageArray_Fetch ("handler.livecode.world", pageSlug) into pageArray
   return pageArray
end lcw_FetchHandlerArray

command lcw_StoreHandlerArray hKey, pageArray
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   put fedwiki_ConstructSlug (hName) into pageSlug
   --
   pageArray_Store "handler.livecode.world", pageSlug, pageArray
   put the result into shellResult
   return shellResult
end lcw_StoreHandlerArray


--> Private
-
private command _ObjectDomainInfo sObject, @pageTitle, @pageSlug, @wikiDomain
   put the stack_Name of sObject into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put the script_Type of sObject into scriptType
   put help_ConstructDomain (scriptType) into wikiDomain
end _ObjectDomainInfo


--> Deps
-
function line_CombineUnique index1, index2
   local nameArray
   put the paramCount into maxNum
   repeat with pNum = 1 to maxNum
      put param (pNum) into someIndex
      line_AddToNameArray nameArray, someIndex   
   end repeat
   put keys (nameArray) into sortedIndex
   sort sortedIndex
   return sortedIndex
end line_CombineUnique
