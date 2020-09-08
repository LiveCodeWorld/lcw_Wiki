script "model_Fedwiki"
--> MetaData
-
license: GPLv3
name: model_Fedwiki
type: model
version: 0.2


--> Working on
-

--> Atopia | IsIndexed
-
command atopia_ToggleIsIndexed wikiDomain, someBoolean, pLaunchSitePage
   if atopia_CheckDomain (wikiDomain) is not empty then
      return empty
   end if
   --
   atopia_ToggleIsInRoster wikiDomain, someBoolean
   atopia_ToggleIsInDomainArray wikiDomain, someBoolean
   atopia_ToggleIsInSites wikiDomain, someBoolean, pLaunchSitePage
   fedray_ToggleIsIndexed wikiDomain, someBoolean
   put the result into fedray
   --
   return fedray
end atopia_ToggleIsIndexed

command atopia_ToggleIsInRoster subDomain, someBoolean
   put atopia_FetchRoster() into rosterText
   if someBoolean is true then
      put CR & subDomain after rosterText
   else
      line_Delete subDomain, rosterText
   end if
   url_SortDomainIndex rosterText
   --
   atopia_StoreRoster rosterText
end atopia_ToggleIsInRoster

command atopia_ToggleIsInDomainArray subDomain, someBoolean
   put atopia_FetchFedray() into fedray
   --
   if someBoolean is true then
      fedray_UpdateDomain fedray, subDomain
   else
      delete variable fedray [subDomain]
   end if
   --
   atopia_StoreFedray fedray
end atopia_ToggleIsInDomainArray

command atopia_ToggleIsInSites subDomain, someBoolean, pLaunchSitePage
   if someBoolean is true then
      atopia_CreateFederationSitePage subDomain
      if pLaunchSitePage is not false then    
         display_LaunchAtopiaSitePage subDomain
      end if
   else
      atopia_DeleteFederationSitePage subDomain
   end if
end atopia_ToggleIsInSites


--> Federation | Update
-
function fedwiki_FetchPageMarkdown wikiDomain, pSlug
   put pageArray_Fetch (wikiDomain, pSlug) into pageArray
   if pageArray is empty then return empty
   put pageArray ["title"] into pageTitle
   put pageArray ["story"] into storyArray
   put fedwiki_ConstructPageMarkdown (pageTitle, storyArray) into pageMarkdown
   return pageMarkdown
end fedwiki_FetchPageMarkdown

function fedwiki_FetchOwnerName fedwikiDomain
   /*
   get "https://fedwiki.rodwell.me/view/narrative-chart/view/coffeehouse-culture"
   set the itemdelimiter to slash
   put item 3 of it into fedwikiDomain
   */
   put "http://" & fedwikiDomain & "/welcome-visitors.html" into someURL
   put url someURL into someHTML
   --
   put "//*[@id='site-owner']" into someXPath 
   replace "'" with quote in someXPath
   put scrape_WithXPath (someHTML, someXPath, true) into contentSection
   put line 2 to 3 of contentSection into someName
   replace CR with space in someName
   return word 1 to -1 of someName
end fedwiki_FetchOwnerName

function federation_ModelDocUrl modelName
   put fedwiki_ConstructSlug (modelName) into pageSlug
   put "http://roster.fedwiki.org/view/welcome-visitors/view/" & pageSlug into launchURL
   return launchURL
end federation_ModelDocUrl

function federation_ServerDocUrl serverName
   put serverName && "Server" into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put "http://server.fedwiki.org/view/welcome-visitors/view/" & pageSlug into launchURL
   return launchURL
end federation_ServerDocUrl


--> Fedwiki | URL
-
function fedwiki_JsonSiteExportUrl fedwikiDomain
   -- http://david.viral.academy/system/export.json
   put "http://" & fedwikiDomain & "/system/export.json" into someUrl
   return someUrl
end fedwiki_JsonSiteExportUrl

function fedwiki_JsonSiteMapUrl fedwikiDomain   
   -- set the itemDelimiter to slash
   -- put item 1 to 3 of fedwikiUrl into sitemapURL
   put "http://" & fedwikiDomain into sitemapURL
   put "/system/sitemap.json" after sitemapURL
   return sitemapURL
end fedwiki_JsonSiteMapUrl

function fedwiki_UrlPathToSlug urlPath
   set the itemdelimiter to "/"
   get item -1 of urlPath
   set the itemdelimiter to "."
   put item 1 of it into pageSlug
   return pageSlug
end fedwiki_UrlPathToSlug

function fedwiki_ExtractPageSlugsFromPath urlPath
   set the itemdelimiter to "/"
   repeat with itemNum = 2 to the number of items of urlPath step 2
      put item itemNum of urlPath into someSlug
      put someSlug & CR after someSlugs
   end repeat
   return word 1 to -1 of someSlugs
end fedwiki_ExtractPageSlugsFromPath

function fedwiki_FaviconURL fedwikiDomain
   put "http://" & fedwikiDomain & "/favicon.png" into someUrl
   return someUrl
end fedwiki_FaviconURL

command fedwiki_DeconstructURL wikiURL, @pageSlug, @fedwikiDomain
   url_Deconstruct wikiURL, someProtocol, fedwikiDomain, urlPath, pageSlug, fileExtension, uName, pWord
   return someProtocol
end fedwiki_DeconstructURL

function fedwiki_ConstructURL pageTitle, fedwikiDomain, pSolo, pProtocol
   put fedwiki_ConstructSlug (pageTitle) into pSlug
   put fedwiki_PageUrl (fedwikiDomain, pSlug, pSolo, pProtocol) into someURL
   return someURL
end fedwiki_ConstructURL

function fedwiki_PageUrl fedwikiDomain, pSlug, pSolo, pProtocol
   if pProtocol is empty then put "http" into pProtocol
   
   put pProtocol & "://" & fedwikiDomain & slash into someURL
   if pSolo is true then
      if pSlug is empty then put "welcome-visitors" into pSlug
      put pSlug & ".html" after someURL
      return someURL
   end if
   
   if pSlug is empty then
      put "view/welcome-visitors" & pSlug after someURL
   else
      put "view/welcome-visitors/view/" & pSlug after someURL
   end if
   return someURL
end fedwiki_PageUrl
