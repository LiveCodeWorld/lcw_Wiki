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

command atopia_ToggleIsInRoster wikiDomain, someBoolean
   put atopia_FetchRosterDomains() into wikiDomains
   --
   if someBoolean is true then
      put CR & wikiDomain after wikiDomains
   else
      line_Delete wikiDomain, wikiDomains
   end if
   url_SortDomainIndex wikiDomains
   --
   atopia_StoreRosterDomains wikiDomains
end atopia_ToggleIsInRoster

command atopia_ToggleIsInDomainArray subDomain, someBoolean
   put atopia_FetchDomainArray() into fedray
   --
   if someBoolean is true then
      fedray_UpdateLastModified fedray, subDomain
   else
      delete variable fedray [subDomain]
   end if
   --
   atopia_StoreDomainArray fedray
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
function fedwiki_JsonSiteExportUrl wikiDomain
   -- http://david.viral.academy/system/export.json
   put "http://" & wikiDomain & "/system/export.json" into someUrl
   return someUrl
end fedwiki_JsonSiteExportUrl

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

function fedwiki_FaviconURL wikiDomain
   put "http://" & wikiDomain & "/favicon.png" into someUrl
   return someUrl
end fedwiki_FaviconURL

function fedwiki_ConstructAssetUrl shortFile, wikiDomain, pSubFolder
   put "http://" into assetURL -- could be "https"
   put wikiDomain after assetURL
   put "/assets/" after assetURL
   --
   if pSubFolder is not empty then
      text_AddTrailing pSubFolder, slash
      put pSubFolder after assetURL
   end if
   --
   put shortFile after assetURL
   return assetURL
end fedwiki_ConstructAssetUrl

command fedwiki_DeconstructURL wikiURL, @pageSlug, @wikiDomain
   url_Deconstruct wikiURL, someProtocol, wikiDomain, urlPath, pageSlug, fileExtension, uName, pWord
   return someProtocol
end fedwiki_DeconstructURL

function fedwiki_ConstructURL wikiDomain, pTitle, pProtocol
   put fedwiki_ConstructSlug (pTitle) into pSlug
   put fedwiki_ConstructUrlFromSlug (wikiDomain, pSlug, pProtocol) into someURL
   return someURL
end fedwiki_ConstructURL

function fedwiki_ConstructUrlFromSlug wikiDomain, pSlug, pProtocol
   if pProtocol is empty then put "http" into pProtocol
   
   put pProtocol & "://" & wikiDomain & slash into someURL
   if pSlug is empty then
      put "view/welcome-visitors" & pSlug after someURL
   else
      put "view/welcome-visitors/view/" & pSlug after someURL
   end if
   return someURL
end fedwiki_ConstructUrlFromSlug

function fedwiki_ConstructHtmlUrl wikiDomain, pSlug, pProtocol
   if pProtocol is empty then put "http" into pProtocol
   if pSlug is empty then put "welcome-visitors" into pSlug
   --
   put pProtocol & "://" & wikiDomain & slash into someURL
   put pSlug & ".html" after someURL
   --
   return someURL
end fedwiki_ConstructHtmlUrl
