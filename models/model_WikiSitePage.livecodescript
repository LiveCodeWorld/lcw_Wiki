script "model_WikiSitePage"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_WikiSitePage
type: model
version: 0.2


--> Working on
-

--> Display
-
command display_LaunchAtopiaSitePage wikiDomain
   put _FederationSiteWord (wikiDomain) into siteWord
   fedwiki_Launch "sites.fedwiki.org", siteWord
   return the result
end display_LaunchAtopiaSitePage

private function _FederationSiteWord wikiDomain
   put wikiDomain into pageSlug
   replace "." with empty in pageSlug
   return pageSlug
end _FederationSiteWord


--> Atopia | SitePage | List
-
function atopia_SiteIsIndexed wikiDomain
   put atopia_ListFederationSitePages() into wikiPages
   set the wholematches to true
   return wikiDomain is among the lines of wikiPages
end atopia_SiteIsIndexed

function atopia_ListSitePagesToCreate
   put fedwiki_ListSitemapPages ("sites.fedwiki.org") into federationSites
   line_Delete "Welcome Visitors", federationSites
   --
   put atopia_FetchRosterDomains() into atopiaDomains
   line_DeleteIndex atopiaDomains, federationSites
   url_SortDomainIndex atopiaDomains
   return atopiaDomains
end atopia_ListSitePagesToCreate

function atopia_ListFederationSitePages
   put fedwiki_ListSitemapPages ("sites.fedwiki.org") into fedDomains
   line_Delete "Welcome Visitors", fedDomains
   url_SortDomainIndex fedDomains
   return fedDomains
end atopia_ListFederationSitePages


--> Atopia | SitePage | Model
-
command atopia_CreateFederationSitePages atopiaDomains, pIndexView
   put word 1 to -1 of atopiaDomains into atopiaDomains
   if atopiaDomains is empty then return atopiaDomains
   --
   repeat for each line wikiDomain in atopiaDomains
      if exists (pIndexView) then
         display_Spin wikiDomain, pIndexView
      end if
      atopia_CreateFederationSitePage wikiDomain, true
   end repeat
   atopia_DeleteFederationSitesMap
end atopia_CreateFederationSitePages

command atopia_CreateFederationSitePage wikiDomain, pDontDeleteSiteMap
   local sitesDomain = "sites.fedwiki.org"
   --
   put fedwiki_FetchCitePageJSON (wikiDomain) into pageJSON
   if pageJSON is empty then return false
   --
   put fedwiki_ConstructSlug (wikiDomain) into pageSlug
   pageJson_Store wikiDomain, pageSlug, pageJSON, true
   --
   return true
end atopia_CreateFederationSitePage

command atopia_DeleteFederationSitesMap
   atopia_DeleteWikiSitemap "sites.fedwiki.org"
end atopia_DeleteFederationSitesMap

command atopia_DeleteFederationSitePage wikiDomain, pRecreateSiteMap
   put _FederationSiteWord (wikiDomain) into pageSlug
   pageJson_Delete "sites.fedwiki.org", pageSlug
   put the result into deletionResult
   if pRecreateSiteMap then 
      atopia_DeleteFederationSitesMap
   end if
   return deletionResult
end atopia_DeleteFederationSitePage


--> Deps
-
command url_SortDomainIndex @domainNames
   set the itemdelimiter to "."
   sort domainNames by item -2 of each & item -3 of each & item -4 of each & item -5 of each
   put word 1 to -1 of domainNames into domainNames
   line_DeleteTail domainNames
   return domainNames
end url_SortDomainIndex
