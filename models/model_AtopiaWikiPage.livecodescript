﻿script "model_AtopiaWikiPage"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_AtopiaWikiPage
type: model
version: 0.1


--> Working on
-


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
      put federation_FetchTemplatePageArray (wikiDomain, pageTitle, pForkDomains, pTemplateStem) into pageArray
   end if
   curly_MergePageArray pageArray, pCurlyData
   pageArray_Set wikiDomain, pageSlug, pageArray
   return pageArray
end federation_UpdateTemplate

function federation_FetchTemplatePageArray wikiDomain, pNewPageTitle, pForkDomains, pTemplateStem
   if pTemplateStem is empty then
      set the itemdelimiter to "."
      put item 1 of wikiDomain into pTemplateStem
   end if
   put tolower (pTemplateStem) & "-" & "template" into pageSlug
   --
   put atopia_FetchTemplatePageArray (pageSlug, wikiDomain, pNewPageTitle, pForkDomains) into pageArray
   return pageArray
end federation_FetchTemplatePageArray

function fedwiki_FetchHomePageArray wikiDomain
   put pageArray_Fetch (wikiDomain, "welcome-visitors") into pageArray
   return pageArray
end fedwiki_FetchHomePageArray


--> Atopia | DefaultPage | Model
-
function atopia_FetchDefaultPageArray pageSlug
   put atopia_DefaultWikiPagePath (pageSlug) into defaultPath
   put atopia_FetchData (defaultPath) into pageJSON
   put json_ToArray (pageJSON) into pageArray
   return pageArray
end atopia_FetchDefaultPageArray

command atopia_StoreDefaultPageArray pageArray
   put pageArray ["title"] into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put atopia_DefaultWikiPagePath (pageSlug) into defaultPagePath
   --
   put json_FromArray (pageArray) into pageJSON
   atopia_StoreData defaultPagePath, pageJSON
   put the result into shellResult
   return shellResult
end atopia_StoreDefaultPageArray

function atopia_DefaultWikiPagePath pageSlug
   put atopia_WikiDefaultPagesFolder() & pageSlug into wikiPagePath
   return wikiPagePath
end atopia_DefaultWikiPagePath

function atopia_FetchTemplatePageArray pageSlug, wikiDomain, pNewPageTitle, pForkDomains
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   if pageArray is not an array then return empty
   --
   if pNewPageTitle is not empty then
      pageArray_Rename pageArray, pNewPageTitle, pForkDomains
   end if
   return pageArray
end atopia_FetchTemplatePageArray


--> Atopia | Node
-
function atopia_GetNodeVersion
   -- can use model, get/set and fetch using "node -v"
   -- put "v6.11.3" into nodeVersion
   put "v12.16.1" into nodeVersion
   return nodeVersion
end atopia_GetNodeVersion


--> Atopia | Home | Model
-
function atopia_ListDefaultPages
   put atopia_WikiDefaultPagesFolder() into remoteFolder
   put "ssh root@fedwiki.org ls" && kwote (remoteFolder) into remoteShell
   put word 1 to -1 of shell (remoteShell) into shortFiles
   /*
   put atopia_FetchLsArray (remoteFolder) into infoArray
   put infoArray ["file"] into fileArray
   put keys (fileArray) into shortFiles
   */
   sort lines of shortFiles
   return shortFiles
end atopia_ListDefaultPages

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


--> Atopia | Home | Template | Model
-
function atopia_ListHomeTemplatePages
   put fedwiki_ListSitemapPages ("welcome.fedwiki.org") into homePages
   line_Delete "Welcome Visitors", homePages
   return homePages
end atopia_ListHomeTemplatePages


--> Atopia | Home | Forks
-
function atopia_ListHomeForkHows wikiDomain
   if wikiDomain is empty then
      put empty into subdomainForks
   else
      put federation_ListDomains (wikiDomain) into subdomainForks
      -- put atopia_ListWelcomeFolders (wikiDomain) into subdomainForks
      line_Delete wikiDomain, subdomainForks
      replace CR with comma in subdomainForks
   end if
   --
   if subdomainForks is empty then
      put "fedwiki.org,orientation.fedwiki.org" into forkEvents
   else
      put subdomainForks & ",-,fedwiki.org,orientation.fedwiki.org" into forkEvents
   end if
   put ",-,Fedwiki,Top Domain,Clean and useful,-,Clean" after forkEvents
   --
   return forkEvents
end atopia_ListHomeForkHows

command atopia_AddHomeForkHow wikiDomain, forkDomain
   switch forkDomain
      case "Clean"
         atopia_CleanHomeForks wikiDomain
         break
      case "Top Domain"
      case "Fedwiki"
         atopia_AddFedwikiForks wikiDomain
         break
      case "Clean and useful"
         atopia_AddUsefulForks wikiDomain
         break
      default
         -- its a forkDomain to add
         atopia_AddHomeForks wikiDomain, forkDomain
   end switch
   --
   fedwiki_Launch wikiDomain
   --
   return the result
end atopia_AddHomeForkHow

command atopia_AddFedwikiForks wikiDomain
   url_DeconstructTopDomain wikiDomain, topDomainName, subDomainBit
   --
   if topDomainName = "fedwiki.org" then
      put "fedwiki.org" into forkDomains
   else
      put topDomainName & comma & "fedwiki.org" into forkDomains
   end if
   --
   atopia_AddHomeForks wikiDomain, forkDomains
   --
   return the result
end atopia_AddFedwikiForks

command atopia_AddUsefulForks wikiDomain
   url_DeconstructTopDomain wikiDomain, topDomainName, subDomainBit
   --
   if subDomain = topDomainName then
      put fedwiki_StandardHomeForks() into forkDomains
      put atopia_FetchSubDomainFolders (topDomainName) into subDomains
      put CR & subDomains after forkDomains
      replace CR with comma in forkDomains
   else
      put topDomainName & comma & "fedwiki.org" into forkDomains
   end if
   --
   atopia_AddHomeForks wikiDomain, forkDomains
   --
   return the result
end atopia_AddUsefulForks

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

