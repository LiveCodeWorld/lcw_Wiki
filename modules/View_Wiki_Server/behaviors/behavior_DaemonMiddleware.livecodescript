﻿script "behavior_DaemonMiddleware" with behavior "behavior_WikiRouter"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_DaemonMiddleware
type: behavior
version: 0.1


/*You dont have to use separate middleware. 
You can put these "before" and "after" handlers anywhere in the behavior_Hirarchy
They work as middleware wherever they are.
They only get called once ( though it should work to be called twice if you try passing them - not tested).

This script is designed to be a behavior for a Live Daemon server.
By default it should be a behavior of the Daemon Server stack.
So the hiierarchy goes: server stack => lib_DaemonMiddleware => lib_DaemonRouter => lib_DaemonServer => lib_DaemonLog => lib_Log

However this hiierarchy can be altered using "server_SetBehaviorHierarchy" in the server stack,
which will override the handler of the same name in the lib_DaemonServer stack.*/

local MiddlewareArray


--> Working on
-
command post_ToController someRoute, socketID, requestArray
   set the itemdelimiter to slash
   put item 2 of someRoute & ".lc" into controllerStackName
   --
   if exists (stack controllerStackName) then
      # Should set all 
      put item 3 of someRoute into hName
      if hName is empty then put "index" into hName
      --
      daemon_SetSocketID socketID
      put the long id of me into serverView
      daemon_SetServer serverView
      --
      put daemon_GetRequestText (requestArray) into postData
      put postData into $_POST_RAW
      --
      dispatch hName to stack controllerStackName with requestArray
      --
      return "Forwarded POST to controller and returned page-json:" controllerStackName
   else
      return "Error, cannot locate controlle stack:" controllerStackName
   end if
end post_ToController

command form_SetFirstMultipart rPostData, sBoundary, @someImage, @shortFileName, @mimeType
   -- "/plugin/image/upload/39e2e88aeea0aa7739a599333f5bb38d.jpg"
   /*
   -----------------------------57324694142348375092642508047
   Content-Disposition: form-data; name="image"; filename="39e2e88aeea0aa7739a599333f5bb38d.jpg"
   Content-Type: image/jpeg
   */
   
   put "--" before sBoundary
   
   # Get header section
   put lineOffset (sBoundary, rPostData) into lineNum
   put lineOffset (sBoundary, rPostData, lineNum) into nextNum
   if nextNum = 0 then return "Error, multipart has no header."
   put lineNum + nextNum into nextLineNum
   put line (lineNum+1) to (nextLineNum-1) of rPostData into headerPart
   put nextLineNum into lineNum
   
   repeat
      put lineOffset (sBoundary, rPostData, lineNum) into nextNum
      if nextNum = 0 then exit repeat
      
      put lineNum + nextNum into nextLineNum
      put line (lineNum+1) to (nextLineNum-1) of rPostData into multiPart
      put multiPart after sData
      put nextLineNum into lineNum
   end repeat
   return sData
end form_SetFirstMultipart

command post_AssetUpload someRoute, socketID, requestArray
   -- someRoute = "/plugin/assets/upload"
   /*
   Content-Length: 896
   Content-Type: multipart/form-data; boundary=---------------------------203997199227640630043106494643
   Host: code.platform.earth
   Origin: http://code.platform.earth
   Referer: http://code.platform.earth/view/welcome-visitors/view/lit
   */
   
   put daemon_ReceivedHeader ("Host", requestArray) into wikiDomain
   put daemon_GetRequestText (requestArray) into rPostData
   
   -- Content-Type: multipart/form-data; boundary=---------------------------113936995760771391925585958
   put daemon_ReceivedHeader ("Content-Type", requestArray) into contentType
   set the itemDelimiter to ";"
   put item 1 of contentType into sType
   put word 1 to -1 of item 2 to -1 of contentType into boundaryInfo
   split boundaryInfo with CR and "="
   put boundaryInfo ["boundary"] into sBoundary
   
   form_SetFirstMultipart rPostData, sBoundary, someData, shortAssetFile, mimeType
   
   put wiki_ConstructAssetFile (shortAssetFile, wikiDomain) into sFile
   
   if there is a file sFile then
      -- seems to be called twice?
      breakpoint
      return "Error, image file exists:" && imageFile
   end if
end post_AssetUpload


--> POST
-
command post_LCW someRoute, socketID, requestArray
   switch someRoute
      case "/openverse"
         put daemon_RequestJsonArray (requestArray) into postArray
         put postArray ["search_Term"] into searchTerm
         --
         put openverse_Search (searchTerm) into sData
         put wikiPage_OpenVerseThumbNails (sData) into pageArray
         --
         daemon_SendArray socketID, pageArray
         return "Sent JSON. Socket still open."
      default
         post_ToController someRoute, socketID, requestArray
   end switch
end post_LCW


--> GET
=
command get_WikiServerToolPage someRoute, requestArray, socketID
   -- "/view/welcome-visitors/view/(.+)"
   
   # Assume wikiDomain is one of our local origin-servers as we are serving it
   put daemon_ReceivedHeader ("Host", requestArray) into wikiDomain
   put daemon_ReceivedHeader ("Referer", requestArray) into sReferer
   
   # Get last page-slug
   set the itemdelimiter to slash
   put item -1 of someRoute into lastPageSlug
   
   # Does the wiki-page already exist
   put pageJson_ConstructFile (wikiDomain, lastPageSlug) into pageJsonFile
   if there is a file pageJsonFile then
      get_EditPage someRoute, socketID, requestArray
   else
      get_CreatePage someRoute, socketID, requestArray
   end if
   return the result
end get_WikiServerToolPage

command get_EditPage someRoute, socketID, requestArray
   put "edit-page" into editPageSlug
   put daemon_ReceivedHeader ("Host", requestArray) into wikiDomain
   --
   set the itemdelimiter to slash
   put item -1 of someRoute into lastPageSlug
   put "/view/" & editPageSlug after of someRoute
   --
   put wikiPage_EditPage (lastPageSlug, wikiDomain, "Edit Page") into editPageArray
   pageArray_Set wikiDomain, editPageSlug, editPageArray, true
   wikiSiteMap_Create wikiDomain
   --
   get_WikiLineUp someRoute, socketID, requestArray
   return the result
end get_EditPage

command get_CreatePage someRoute, socketID, requestArray
   set the itemdelimiter to slash
   put item -1 of someRoute into pageSlugToCreate
   put "view/create-page/" before item -2 of someRoute
   --
   put daemon_ReceivedHeader ("Host", requestArray) into wikiDomain
   create_PageCreator pageSlugToCreate, wikiDomain
   --
   get_WikiLineUp someRoute, socketID, requestArray
   return the result
end get_CreatePage

command create_PageCreator pageSlugToCreate, wikiDomain
   put wikiPage_CreatePage (pageSlugToCreate, wikiDomain, "Create Page") into createPageArray
   pageArray_Set wikiDomain, "create-page", createPageArray, true
   wikiSiteMap_Create wikiDomain
   return createPageArray
end create_PageCreator

command get_FlagClick someRoute, socketID, requestArray, pPageTitle
   -- overrides router
   if someRoute = "/view/welcome-visitors" then
      put daemon_ReceivedHeader ("Referer", requestArray) into sReferer
      set the itemdelimiter to slash
      put item 4 to -1 of sReferer into rPath
      if rPath = "view/welcome-visitors" then
         get_WikiLineUp "/view/welcome-visitors/view/site-tools", socketID, requestArray
      else
         get_WikiDomain someRoute, socketID, requestArray -- the default behavior
      end if
   else
      put wikiServer_GuessLastSlug (someRoute) into lastPageSlug
      put daemon_ReceivedHeader ("Host", requestArray) into wikiDomain
      put wikiPage_Tools (lastPageSlug, wikiDomain) into pageArray
      daemon_SendArray socketID, pageArray
      return "Sent JSON. Socket still open."
   end if
end get_FlagClick

before route_POST someRoute, socketID, requestArray
   put daemon_ReceivedHeader ("Host", requestArray) into wikiDomain
   switch
      case someRoute = "/plugin/assets/upload"
         post_AssetUpload someRoute, socketID, requestArray
         
         /*
         Content-Length: 896
         Content-Type: multipart/form-data; boundary=---------------------------203997199227640630043106494643
         Host: code.platform.earth
         Origin: http://code.platform.earth
         Referer: http://code.platform.earth/view/welcome-visitors/view/lit
         */
         break
      case wikiDomain = "rest.livecode.world"
         -- someRoute = /podcast/rss
         post_LCW someRoute, socketID, requestArray
         exit to top
      default
         -- pass on to behavior
   end switch
end route_POST

before route_GET someRoute, socketID, requestArray
   switch
      case someRoute = "/plugin/assets/upload"
         breakpoint
         break
      case someRoute = "/lcw_BrowserUrl"
         get_LcwBookmarklet someRoute, socketID, requestArray
         --
         return "Sent JSON. Socket still open."
         exit to top
      case someRoute = "/system/sitemap.json"
      case someRoute = "/system/site-index.json"
         -- pass on as it is called regularly
         break
      case matchText (someRoute, "/view/welcome-visitors/view/([^/]+)$", pageSLug)
         -- get_WikiLineUp someRoute, socketID, requestArray
         get_WikiServerToolPage someRoute, requestArray, socketID
         break
      default
         --
         return empty
   end switch
end route_Get

before get_WikiDomain someRoute, socketID, requestArray, pPageTitle, pOwnedBy
   --
end get_WikiDomain

before get_WikiPageJson someRoute, socketID, requestArray, pageSLug, wikiDomain
   switch
      case pageSlug = "tools"
         put daemon_ReceivedHeader ("Referer", requestArray) into sReferer
         put wikiServer_GuessLastSlug (sReferer) into lastPageSlug
         --
         put wikiPage_Tools (lastPageSlug, wikiDomain) into pageArray
         --
         _ReturnAndExit pageArray, socketID
         break
      case wikiDomain = "sites.fedwiki.org"
         put pageSlug into filterWord
         put wikiPage_FilteredDomainList (filterWord) into pageArray
         --
         _ReturnAndExit pageArray, socketID
      case pageSlug = "federation-activity"
         put wikiPage_FederationActivity ("Federation Activity") into pageArray
         --
         _ReturnAndExit pageArray, socketID
      case pageSlug = "since-monday"
         put wikiPage_FederationActivity ("Since Monday", "Monday") into pageArray
         --
         _ReturnAndExit pageArray, socketID
      case pageSlug = "today"
         put wikiPage_TodaysActivity() into pageArray
         --
         _ReturnAndExit pageArray, socketID
      default
         -- pass on to behavior
   end switch
end get_WikiPageJson


--> Deps
-
command get_LcwBookmarklet someRoute, socketID, requestArray
   put daemon_ReceivedHeader ("Host", requestArray) into wikiDomain
   put requestArray ["queryArray"]["url"] into someUrl
   --
   if someUrl begins with "https://www.one-tab.com/page/" then
      put oneTab_FetchPageArray (someUrl, "markdown") into pageArray
      --
      put pageArray ["title"] into pageTitle
      put fedwiki_ConstructSlug (pageTitle) into pSlug
      put pageJson_ConstructFile (wikiDomain, pSlug) into pageJsonFile
      -- 
      if there is a file pageJsonFile then
         display_Wiki wikiDomain
         put the result into browserView
         --
         set the ghost_PageArray of browserView to pageArray
      else
         -- set the page_Array of browserView to pageArray
         put json_FromArray (pageArray) into pageJSON
         text_Set pageJsonFile, pageJson
      end if
      --
      get_WikiDomain someRoute, socketID, requestArray, pageTitle
      
      # Update sitemap
      wikiSiteMap_Create wikiDomain -- could "wikiSiteMap_AddPage"
   else
      undefined_Get socketID, someRoute, requestArray
   end if
   return the result
end get_LcwBookmarklet

function wikiPage_TodaysActivity pFirstPara
   return wikiPage_FederationActivity ("Today", "today", pFirstPara)
end wikiPage_TodaysActivity

function wikiPage_FederationActivity pPageTitle, pDayName, pFirstPara
   if pPageTitle is empty then put "Todays Activity" into pPageTitle
   if pFirstPara is empty then
      put "Here is the activity across [[the federation]] today:" into pFirstPara
   end if
   
   switch pDayName
      case "today"
         put "today" into pDayName
         put "1 day" into sinceWhen
         break
      case "Monday"
         put "Mon" into pDayName
         put date_DaysSinceMonday() into dayNum
         -- put round (dayNum) into dayNum
         put trunc (dayNum) into dayNum
         put dayNum && "day" into sinceWhen
         break
      default
         put empty into pDayName
         put "14 days" into sinceWhen
   end switch
   --
   put ward_ListRecentDomains (pDayName) into wikiDomains
   --
   put pageArray_Construct (pPageTitle, pFirstPara) into pageArray
   
   # Construct Roster from pPageTitle
   pageArray_AddMarkdown pageArray, "# Roster"
   put pPageTitle & CR&CR & wikiDomains into rosterText
   pageArray_AddRoster pageArray, rosterText
   
   # Add matched Activity plugin
   pageArray_AddMarkdown pageArray, "# Activity"
   pageArray_AddActivity pageArray, pPageTitle, sinceWhen, "CONVERSATION"
   
   # Strip Journal
   pageArray_StripJournal pageArray
   return pageArray
end wikiPage_FederationActivity

function ward_ListRecentDomains pDayName, pCheckWikiExists
   put ward_FetchRecentDomainArray (pDayName) into wardsFedray
   put the keys of wardsFedray into domainNames
   --
   url_SortDomainIndex domainNames
   if pCheckWikiExists then
      federation_CheckDomainExists domainNames
   end if
   return domainNames
end ward_ListRecentDomains

function ward_FetchRecentDomainArray pDayName
   put ward_FetchRecentRoster() into wardsRosterText
   put ward_RecentDomainArray (wardsRosterText, pDayName) into wardsFedray
   return wardsFedray
end ward_FetchRecentDomainArray

function ward_RecentDomainArray wardsRosterText, pDayName
   local domainArray
   if pDayName = "today" then
      put item 1 of the internet date into pDayName
   end if
   --
   set the itemdelimiter to "-"
   repeat for each line someLine in wardsRosterText      
      switch
         case word 1 to -1 of someLine is empty
            next repeat
         case someLine contains "." AND pDayName is empty
         case someLine contains "." AND pDayName = thisDay
            -- it's a domain 
            put empty into domainArray [someLine]
            break
         case someLine contains "."
            -- next repeat -- first and last days repeated a week apart
            if domainArray is an array then
               return domainArray
            else
               -- not found first day yet keep going
               next repeat
            end if
         default
            -- it's a date
            put item 1 of someLine into thisDay
      end switch
   end repeat
   return domainArray
end ward_RecentDomainArray

function ward_FetchRecentRoster
   put pageArray_Fetch ("search.fed.wiki.org:3030", "recent-activity", true) into pageArray
   put pageArray_FindItemType ("roster", pageArray) into itemNum
   put pageArray ["story"][itemNum]["text"] into domainNames
   return domainNames
end ward_FetchRecentRoster


--> Private
-
private command _ReturnAndExit pageArray, socketID
   daemon_SendArray socketID, pageArray
   return "Sent JSON. Socket still open."
   exit to top
end _ReturnAndExit
