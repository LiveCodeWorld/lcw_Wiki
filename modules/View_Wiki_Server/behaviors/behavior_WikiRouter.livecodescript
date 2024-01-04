script "behavior_WikiRouter" with behavior "behavior_DaemonLog"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_WikiRouter
type: behavior
version: 0.3

/* This script is where routing happens.
You can place this script anywhere if you intercept the "getprop daemon_Router" virtual custom property
This is because the "behaviour_Daemon" script dispatches a "daemon_Request" command to the daemon_Router of me

We use commands instead of functions as this allows before and after handlers to do logging if needed.*/


--> Variables
-
local PluginRouteData


--> Working on
-

--> Props
-
getprop plugin_RouteData
   return PluginRouteData
end plugin_RouteData


--> Not implemented
-
command get_SecurityJS socketID, someRoute, requestArray
   daemon_SendNotFound socketID
   return "Security.js not implemented for" && someRoute
end get_SecurityJS


--> Undefined
-
command undefined_Action socketID, someRoute, requestArray, pageSlug, wikiDomain, actionArray
   daemon_SendNotFound socketID
end undefined_Action

command undefined_Put socketID, someRoute, requestArray, pageSlug, wikiDomain, actionArray
   daemon_SendNotFound socketID
end undefined_Put

command undefined_Get socketID, someRoute, requestArray, pageSlug, wikiDomain, actionArray
   daemon_SendNotFound socketID
end undefined_Get


--> Daemon
-
before daemon_Start pPortToListenOn, pDaemonServer
   daemon_ClearPluginRouteData
   daemon_LoadPluginRouteData
end daemon_Start

command daemon_LoadPluginRouteData
   put wikiPlugin_List() into wikiPlugins
   set the itemdelimiter to "-"
   repeat for each line wikiPlugin in wikiPlugins
      put item 3 of wikiPlugin into pluginName
      _LoadPluginRoutes pluginName
   end repeat
end daemon_LoadPluginRouteData

command daemon_ClearPluginRouteData
   delete variable PluginRouteData
end daemon_ClearPluginRouteData

command daemon_RouteRequest requestArray
   # Core handler that lib_Daemon dispatches  
   _DeconstructRequestArray requestArray, socketID, someMethod, someRoute, queryString, requestUrl
   switch someMethod
      case "GET"
         route_GET someRoute, socketID, requestArray
         break
      case "POST"
         route_POST someRoute, socketID, requestArray
         break
      case "PUT"
         route_PUT someRoute, socketID, requestArray
         break
      case "DELETE"
         route_DELETE someRoute, socketID, requestArray
         break
   end switch
end daemon_RouteRequest


--> DELETE
-
command delete_PageJson pageSLug, wikiDomain, socketID
   -- pageJson_Delete wikiDomain, pageSlug
   pageJson_Trash wikiDomain, pageSlug
   --
   daemon_SendOK socketID, "OK"
   return "Deleted page-json:" && pageSLug
end delete_PageJson

command delete_RecycledPage pageSLug, wikiDomain, socketID
   put wiki_ConstructRecycleFolder (wikiDomain) into recycleFolder
   --
   put recycleFolder & pageSLug into recyclePath
   revDeleteFile recyclePath
   --
   daemon_SendOK socketID, "OK"
   return "Deleted recycled page:" && pageSLug
end delete_RecycledPage


--> GET | Exceptions
-
command get_SiteMapJson wikiDomain, socketID
   put wikiSiteMap_GetJson (wikiDomain) into binaryJSON
   daemon_SendSiteMapJSON socketID, binaryJSON
   -- daemon_SendJSON socketID, binaryJSON
   return "Sent Sitemap JSON. Socket still open."
end get_SiteMapJson

command get_SiteIndexJson wikiDomain, socketID
   put wikiSiteIndex_GetJson (wikiDomain) into binaryJSON
   daemon_SendJSON socketID, binaryJSON
   return "Sent Sitemap JSON. Socket still open."
end get_SiteIndexJson


--> GET | Exceptions
-
command get_RecycledPageJson pageSLug, wikiDomain, socketID
   -- GET /recycler/livecode-sites.json HTTP/1.1
   put pageJson_GetRecycled (wikiDomain, pageSlug) into someJSON
   --
   if someJSON is empty then
      daemon_SendNotFound socketID
      return "Returned 404 page not found."
   else
      daemon_SendJSON socketID, someJSON
      return "Sent JSON. Socket still open."
   end if
end get_RecycledPageJson

command get_RecycledSlugsJson wikiDomain, socketID
   -- "/recycler/system/slugs.json"
   put _RecycledSlugsJson (wikiDomain) into sJSON
   put textEncode (sJSON) into binJSON
   --
   daemon_SendJSON socketID, binJSON
   return "Sent recent-changes.json. Socket still open."
end get_RecycledSlugsJson

command get_WikiClientJsMap someRoute, socketID
   -- strange route = "/view/welcome-visitors/view/changes.js.map"
   
   put wikiPlugin_GetJsMap ("changes", "changes.js.map") into binaryJSON
   daemon_SendJSON socketID, binaryJSON
   return "Sent js.map JSON. Socket still open."
end get_WikiClientJsMap


--> GET | Processing
-
command get_FlagClick socketID
   get_WikiDomain socketID
end get_FlagClick

command get_WikiDomain socketID
   # Fetch default server page
   put wikiClient_GetStaticHtml() into htmlTemplate
   
   # Merge htmlTemplate with simple div based on route
   put _ConstructHtml (htmlTemplate) into someHTML
   
   daemon_SendText socketID, someHTML
   return "Sent welcome-visitors for" && wikiDomain
end get_WikiDomain

command get_WikiLineUp someRoute, socketID, requestArray
   # Fetch default server page
   put wikiClient_GetStaticHtml() into htmlTemplate
   
   # Render server page together with json
   put _ConstructLineUpHtml (htmlTemplate, someRoute) into someHTML
   --
   daemon_SendText socketID, someHTML
   return "Sent welcome-visitors for" && wikiDomain
end get_WikiLineUp

command get_WikiPageJson pageSlug, wikiDomain, socketID   
   # First the wiki-client looks for page at origin server
   put pageJson_Get (wikiDomain, pageSlug) into someJSON
   --
   if someJSON is empty then
      # If not found, wiki-client tries pages remote server
      daemon_SendNotFound socketID
      return "Returned 404 page not found."
   else
      daemon_SendJSON socketID, someJSON
      return "Sent JSON. Socket still open."
   end if
end get_WikiPageJson


--> GET | Plugin
-
command get_PluginPageJson pluginName, pageSlug, socketID
   put wikiPlugin_GetPageJson (pluginName, pageSlug) into pageJSON
   daemon_SendJSON socketID, pageJSON
   return "Sent plugin json. Socket still open."
end get_PluginPageJson

command get_PluginJavascriptMap pluginName, shortFile, socketID
   put "client/" before shortFile
   put wikiPlugin_ConstructFile (pluginName, shortFile) into mapFile
   --
   if there is a file mapFile then
      put url ("binfile:" & mapFile) into mapJSON
      daemon_SendJSON socketID, mapJSON
      return "Sent mapJSON. Socket still open."
   else
      breakpoint
      daemon_SendNotFound socketID
      return "Error, cannot locate mapJSON not sent. Socket still open." && mapFile
   end if
end get_PluginJavascriptMap

command get_PluginJavascript pluginName, shortJavascriptFile, socketID
   -- someRoute = "/recycler/recycler.js"
   put wikiPlugin_ConstructClientFolder (pluginName) into pluginClientFolder
   put pluginClientFolder & shortJavascriptFile into pluginJavascriptFile
   --
   if there is a file pluginJavascriptFile then
      put url ("binfile:" & pluginJavascriptFile) into sJavascript
      daemon_SendJS socketID, sJavascript
      return "Sent plugin js" && shortJavascriptFile
   else
      daemon_SendNotFound socketID
      return "Error, cannot find plugin javascript file" && shortJavascriptFile
   end if
end get_PluginJavascript

command get_WikiClientJavascript someRoute, socketID
   -- "/js/jquery-ui/1.13.2/jquery-ui.min.css"
   -- "/js/jquery-3.6.3.min.js"
   -- "/js/jquery-migrate-3.4.0.min.js"
   -- "/js/jquery.ui.touch-punch.min.js"
   -- "/js/underscore-min.js"
   
   put wikiClient_GetClientFile (someRoute) into sJavascript
   daemon_SendJS socketID, sJavascript
   return "Sent client js" && someRoute
end get_WikiClientJavascript

command get_FactoriesJson socketID
   put wikiClient_GetFactoriesJson() into factoriesJSON
   daemon_SendJSON socketID, factoriesJSON
   return "Sent factories.json. Socket still open."
end get_FactoriesJson

command get_CSS someRoute, socketID
   put wikiClient_GetClientFile (someRoute) into sCSS
   daemon_SendCSS socketID, sCSS
   return "Sent client css" && someRoute
end get_CSS

command get_LocalFavicon wikiDomain, socketID
   -- wiki-client only asks server for local favicons on startup
   put wiki_GetFavicon (wikiDomain) into sPNG
   if sPNG is empty then
      put wiki_GetDefaultFavicon() into sPNG
   end if
   daemon_SendPNG socketID, sPNG
   return the result
end get_LocalFavicon

command get_ClientPNG someRoute, socketID
   -- /images/noise.png
   put wikiClient_ConstructFile (someRoute) into pngFile
   if there is a file pngFile then
      put url ("binfile:" & pngFile) into sPNG
      daemon_SendPNG socketID, sPNG
      return "Sent client png" && someRoute
   else
      daemon_SendNotFound socketID
      return "Returned 404 image not found."
   end if
end get_ClientPNG


--> Route
-
command route_POST someRoute, socketID, requestArray
   # Logins and Transporters?
   switch someRoute
      case "/persona_login"
         break
      default
         put daemon_GetPostData (requestArray) into rPostData
         daemon_SendJSON socketID, "{'hello': 'world'}"
   end switch
end route_POST

command route_DELETE someRoute, socketID, requestArray
   put _HostFromRequest (requestArray) into wikiDomain
   --
   switch
      case matchText (someRoute, "/recycler/(.+).json" , pageSLug)
         delete_RecycledPage pageSLug, wikiDomain, socketID
         return the result
      case matchText (someRoute, "/(.+).json" , pageSLug) -- /voyage-methodology.json
         delete_PageJson pageSLug, wikiDomain, socketID
         return the result
      default
         breakpoint
   end switch
end route_DELETE

command route_GET someRoute, socketID, requestArray
   put _HostFromRequest (requestArray) into wikiDomain
   --
   put PluginRouteData [someRoute] into routeArray
   put routeArray ["type"] into routeType
   --
   switch
      case someRoute = "/system/sitemap.json"
         get_SiteMapJson wikiDomain, socketID
         return the result
      case someRoute = "/system/site-index.json"
         get_SiteIndexJson wikiDomain, socketID
         return the result
         
      case someRoute = "/"
         get_WikiDomain socketID
         return the result
      case someRoute = "/view/welcome-visitors"
         get_FlagClick socketID
         return the result
      case routeType = "pluginMap"
         put routeArray ["pluginName"] into pluginName
         put routeArray ["mapFile"] into shortMapFile
         --
         get_PluginJavascriptMap pluginName, shortMapFile, socketID
         return the result
         break
      case routeType = "pluginJavascript"
         put routeArray ["pluginName"] into pluginName
         put routeArray ["jsFile"] into shortJavascriptFile
         --
         get_PluginJavascript pluginName, shortJavascriptFile, socketID
         return the result
      case routeType = "pluginPageSlug"
         put routeArray ["pluginName"] into pluginName
         put routeArray ["pageSlug"] into pageSlug
         --
         get_PluginPageJson pluginName, pageSlug, socketID
         return the result
         
      case matchText (someRoute, "/recycler/([^/]+)\.json", pageSLug) -- /recycler/livecode-sites.json
         get_RecycledPageJson pageSLug, wikiDomain, socketID
         return the result
      case someRoute = "/recycler/system/slugs.json"
         get_RecycledSlugsJson wikiDomain, socketID
         return the result
      case someRoute = "/view/welcome-visitors/view/changes.js.map"
         get_WikiClientJsMap someRoute, socketID
         return the result
      case someRoute begins with "/plugins/"
         route_Plugin someRoute, socketID, requestArray
         return the result
         
      case someRoute = "/security/security.js"
         get_SecurityJS socketID, someRoute, requestArray
         return the result
         
      case someRoute = "/system/factories.json"
         get_FactoriesJson socketID
         return the result
         
      case someRoute = "/favicon.ico"
      case someRoute = "/favicon.png"
         get_LocalFavicon wikiDomain, socketID
         return the result
         
      case someRoute begins with "/images/"
         get_ClientPNG someRoute, socketID -- "/images/crosses.png"
         return the result
         
      case someRoute = "/js/jquery-ui/1.13.2/jquery-ui.min.css"
      case someRoute begins with "/theme/" -- "/theme/style.css"
      case someRoute begins with "/style/" -- "/style/print.css" -- "/style/style.css"
         get_CSS someRoute, socketID
         return the result
         
      case someRoute = "/client.js"
      case someRoute = "/client.max.js"
      case someRoute = "/client.map"
      case someRoute begins with "/js/"
         get_WikiClientJavascript someRoute, socketID
         return the result
         
      case matchText (someRoute, "/(.+).json" , pageSLug)
         get_WikiPageJson pageSLug, wikiDomain, socketID
         return the result
      default
         -- undefined_Get socketID, someRoute, requestArray
         get_WikiLineUp someRoute, socketID, requestArray
         return the result
   end switch
end route_GET

command route_PUT someRoute, socketID, requestArray
   set the itemdelimiter to "/"
   switch
      case item -1 of someRoute = "action" and item 2 of someRoute = "page"
         put_Action someRoute, requestArray, socketID
         return the result
      default
         undefined_Put socketID, someRoute, requestArray
         return the result
   end switch
end route_PUT

command route_Plugin someRoute, socketID, requestArray
   # Supports route_GET
   -- case someRoute begins with "/plugins/"
   set the itemdelimiter to slash
   put item 3 of someRoute into pluginName
   put item 4 to -1 of someRoute into shortFile
   --
   set the itemdelimiter to "."
   switch item -1 of someRoute
      case "js"
         -- _LoadPluginRoutes pluginName -- preloading on server_Start
         --
         put wikiPlugin_GetJavascript (pluginName) into sJavascript
         daemon_SendJS socketID, sJavascript
         return "Sent client js" && someRoute
      case "css"
         -- /plugins/markdown/markdown.css
         put "client/" before shortFile
         put wikiPlugin_ConstructFile (pluginName, shortFile) into cssFile
         put url ("binfile:" & cssFile) into sCSS
         --
         daemon_SendCSS socketID, sCSS
         return "Sent client css" && someRoute
      case "map"
         get_PluginJavascriptMap pluginName, shortFile, socketID
         return the result
      case "png"
         put wikiPlugin_ConstructFile (pluginName, shortFile) into pngFile
         put url ("binfile:" & pngFile) into sPNG
         daemon_SendPNG socketID, sPNG
         return "Sent client png" && someRoute
      default
         undefined_Get socketID, someRoute, requestArray
   end switch
end route_Plugin


--> Action
-
command action_EditItem pageSlug, wikiDomain, actionArray
   put pageArray_Get (wikiDomain, pageSlug) into pageArray
   
   # Find itemID in storyArray
   put actionArray ["id"] into itemID
   put pageArray_FindItemID (itemID, pageArray) into storyItemNum
   if storyItemNum < 1 then
      return "Error: editing item" && itemID && "of page" && pageSlug & ". It does not exist"
   end if
   
   # Update the story item
   put actionArray ["item"] into itemArray
   put itemArray into pageArray [ "story"][storyItemNum]
   
   # Update the journal
   put pageArray ["journal"] into journalArray
   journalArray_Add journalArray, itemArray, "edit"
   put journalArray into pageArray ["journal"]
   
   # Update the JSON file and sitemap
   save_AfterAction wikiDomain, pageSlug, pageArray, actionArray
   
   return pageArray
end action_EditItem

command action_AddItem pageSlug, wikiDomain, actionArray
   put pageArray_Get (wikiDomain, pageSlug) into pageArray
   if pageArray is not an array then return "Error, page-json is faulty for" && pWikiDomain,pageSlug
   --
   put actionArray ["id"] into itemID
   put actionArray ["after"] into afterID
   put actionArray ["item"]["type"] into itemType
   put itemArray_Construct (itemType, itemID) into itemArray
   
   put pageArray_FindItemID (afterID, pageArray) into afterItemNum
   put pageArray ["story"] into storyArray
   storyArray_InsertAfter storyArray, afterItemNum, itemArray
   put storyArray into pageArray ["story"]
   
   # Update the JSON file and sitemap
   save_AfterAction wikiDomain, pageSlug, pageArray, actionArray
   --
   return pageArray
end action_AddItem

command action_RemoveItem pageSlug, wikiDomain, actionArray
   put pageArray_Get (wikiDomain, pageSlug) into pageArray
   if pageArray is not an array then return "Error, page-json is faulty for" && wikiDomain,pageSlug
   --
   put actionArray ["id"] into itemID
   put pageArray_FindItemID (itemID, pageArray) into storyItemNum
   
   -- let's delete the item and renumber
   put pageArray ["story"] into storyArray
   put item 2 of the extents of storyArray into maxNum
   repeat with toMoveNum = (storyItemNum + 1) to maxNum
      put toMoveNum - 1 into previousNum
      put storyArray [toMoveNum] into storyArray [previousNum]
   end repeat
   delete variable storyArray [maxNum]
   put storyArray into pageArray ["story"]
   
   -- add to journal
   put pageArray ["journal"] into journalArray
   journalArray_Add journalArray, actionArray, "remove"
   put journalArray into pageArray ["journal"]
   
   # Update the JSON file and sitemap
   save_AfterAction wikiDomain, pageSlug, pageArray, actionArray
   --
   return pageArray
end action_RemoveItem

command action_Move pageSlug, wikiDomain, actionArray
   put pageArray_Get (wikiDomain, pageSlug) into pageArray
   
   # Re-order storyArray
   put pageArray ["story"] into storyArray
   put actionArray ["order"] into orderArray
   repeat for each key orderNum in orderArray
      put orderArray [orderNum] into itemID
      put pageArray_FindItemID (itemID, pageArray) into oldStoryItemNum
      put storyArray [oldStoryItemNum] into newPageArray [orderNum]
   end repeat
   put newPageArray into pageArray ["story"]
   
   # Add a "move" to the journal
   put pageArray ["journal"] into journalArray
   journalArray_Add journalArray, actionArray, "move"
   put journalArray into pageArray ["journal"]
   
   # Update the JSON file and sitemap
   save_AfterAction wikiDomain, pageSlug, pageArray, actionArray
   --
   return pageArray
end action_Move

command action_ForkPage pageSlug, wikiDomain, actionArray
   -- put pageArray_Get (wikiDomain, pageSlug) into pageArray
   -- if pageArray is not an array then return "Error, page-json is faulty for" && wikiDomain,pageSlug
   
   -- create a blank new page
   put actionArray ["date"] into forkDate
   put actionArray ["item"] into pageArray
   put actionArray ["site"] into forkDomain
   if forkDomain = wikiDomain then
      put empty into forkDomain
   end if
   -- put pageArray ["title"] into pageTitle
   -- put fedwiki_ConstructSlug (pageTitle) into pageSlug
   
   -- put actionArray ["id"] into itemID
   pageArray_SetFork pageArray, forkDomain, forkDate
   
   # Update the JSON file and sitemap
   save_AfterAction wikiDomain, pageSlug, pageArray, actionArray
   --
   return pageArray
end action_ForkPage

command action_CreatePage pageSlug, wikiDomain, actionArray
   -- create a blank new page
   put actionArray ["date"] into pCreateMilliSeconds
   put actionArray ["item"]["title"] into pageTitle
   
   -- put pageArray_Construct (pageTitle) into pageArray 
   put pageTitle into pageArray ["title"]  
   put actionArray into pageArray ["journal"][1]
   
   # Update the JSON file and sitemap
   save_AfterAction wikiDomain, pageSlug, pageArray, actionArray
   --
   return pageArray
end action_CreatePage


--> PUT
-
command put_Action someRoute, requestArray, socketID
   put daemon_GetPostData (requestArray) into sInput
   
   set the itemdelimiter to slash
   put item 3 of someRoute into pageSlug    
   put _HostFromRequest (requestArray) into wikiDomain
   
   --  action:{"type":"create","item":{"title":"HiKey Board","story":[]},"date":1438036497154}
   split sInput with "&" and "="
   put sInput [action] into encodedAction
   put urldecode (encodedAction) into actionJSON
   put json_ToArray (actionJSON) into actionArray
   
   put actionArray ["type"] into actionType
   switch actionType
      case "remove"
         action_RemoveItem pageSlug, wikiDomain, actionArray
         break
      case "edit"
         action_EditItem pageSlug, wikiDomain, actionArray
         break
      case "add"
         action_AddItem pageSlug, wikiDomain, actionArray
         break
      case "fork"
         action_ForkPage pageSlug, wikiDomain, actionArray
         break
      case "move"
         action_Move pageSlug, wikiDomain, actionArray
         break
      case "create"
         action_CreatePage pageSlug, wikiDomain, actionArray
         break
      default
         undefined_Action socketID, someRoute, requestArray, pageSlug, wikiDomain, actionArray
   end switch
   
   daemon_SendText socketID, "ok" -- send "ok" back
   return the result
end put_Action


--> Private
-
command save_AfterAction wikiDomain, pageSlug, pageArray, actionArray
   # Update the JSON file and dont delete site map
   pageArray_Set wikiDomain, pageSlug, pageArray, false
   put the result into saveResult
   if item 1 of saveResult is "Error" then
      return saveResult
   else
      # Update sitemap
      save_UpdatedSiteMap pageSlug, wikiDomain, pageArray, actionArray
      return the result
   end if
end save_AfterAction

command save_UpdatedSiteMap pageSlug, wikiDomain, pageArray, actionArray
   /* Setting pDateInMilliseconds to the value of the time of a fork.
   Allows page forking to be set to the date of the fork event
   Not the date of the original page creation. */
   
   # Get siteMapArray from file
   put wikiSiteMap_GetArray (wikiDomain) into siteMapArray
   if sitemapArray is not an array then
      return "Error, fetching sitemap.json for:" && save_UpdatedSiteMap,pWikiDomain
   end if
   
   # Find page that has been modified
   put actionArray ["id"] into itemID
   put indexArray_Find (sitemapArray, "slug", pageSlug) into indexNum
   if indexNum = 0 then
      put item 2 of the extents of sitemapArray + 1 into indexNum -- add to end
   end if
   
   # Get edit date in milliseconds
   put actionArray ["date"] into editMilliSeconds
   if editMilliSeconds is empty then
      put pageArray ["journal"] into journalArray
      put item 2 of the extents of journalArray into lastItemNum
      put journalArray [lastItemNum]["date"] into editMilliSeconds
   end if
   
   # Update siteMapArray
   wikiSiteMap_SetIndexItemArray siteMapArray, indexNum, pageSlug, pageArray, editMilliSeconds
   
   # Set siteMapArray file
   wikiSiteMap_SetArray sitemapArray, wikiDomain
   put the result into writeResult
   if writeResult is empty then
      return sitemapArray
   else
      return writeResult
   end if
end save_UpdatedSiteMap

private function _ConstructSiteMapItemArray pageTitle, pageSynopsis, pDateInMilliseconds, pPageSlug
   if pPageSlug is empty then put fedwiki_ConstructSlug (pageTitle) into pPageSlug
   if pDateInMilliseconds is empty then put the milliseconds into pDateInMilliseconds
   
   put pDateInMilliseconds into mapItemArray ["date"] 
   put pPageSlug into mapItemArray ["slug"]
   put pageSynopsis into mapItemArray ["synopsis"] 
   put pageTitle into mapItemArray ["title"]
   --   
   return mapArray
end _ConstructSiteMapItemArray

private function _HostFromRequest requestArray
   put requestArray ["receivedHeaders"] into receivedHeaderArray
   split receivedHeaderArray with CR and ":"
   put word 1 to -1 of receivedHeaderArray ["Host"] into fromHost
   set the itemdelimiter to ":"
   return item 1 of fromHost
end _HostFromRequest

private command _DeconstructRequestArray requestArray, @socketID, @someMethod, @someRoute, @queryString, @requestUrl
   put requestArray ["socketID"] into socketID
   put requestArray ["Request Method"] into someMethod
   put requestArray ["SCRIPT_NAME"] into someRoute
   put requestArray ["QUERY_STRING"] into queryString
   put requestArray ["Requested URL"] into requestUrl
end _DeconstructRequestArray

command _LoadPluginRoutes pluginName
   -- put "recycler" into pluginName
   put wikiPlugin_ListPageSlugs (pluginName) into pageSlugs
   repeat for each line pageSlug in pageSlugs
      -- someRoute = "/about-recycler-plugin.json"
      put "/" & pageSlug & ".json" into someRoute
      --
      put "pluginPageSlug" into PluginRouteData [someRoute]["type"]
      put pluginName into PluginRouteData [someRoute]["pluginName"]
      put pageSlug into PluginRouteData [someRoute]["pageSlug"]
   end repeat
   
   put wikiPlugin_ListClientShortFiles (pluginName) into shortFiles
   set the itemdelimiter to "."
   repeat for each line shortFile in shortFiles
      put "/" & pluginName & "/" & shortFile into someRoute
      --
      put item -1 of shortFile into sFileExtension
      switch sFileExtension
         case "js"
            put "pluginJavascript" into PluginRouteData [someRoute]["type"]
            put pluginName into PluginRouteData [someRoute]["pluginName"]
            put shortFile into PluginRouteData [someRoute]["jsFile"]
            break
         case "map"
            put "pluginMap" into PluginRouteData [someRoute]["type"]
            put pluginName into PluginRouteData [someRoute]["pluginName"]
            put shortFile into PluginRouteData [someRoute]["mapFile"]
            break
         default
            next repeat
      end switch
   end repeat
end _LoadPluginRoutes

private function _RecycledSlugsJson wikiDomain
   # Question: is this is normally provided by client-server registration?
   put _RecycledSlugsData (wikiDomain) into slugData
   put json_FromArray (slugData) into slugJSON
   return slugJSON
end _RecycledSlugsJson

private function _RecycledSlugsData wikiDomain
   put wiki_ListRecyclePageSlugs (wikiDomain) into rSlugs
   put 1 into itemNum
   repeat for each line pageSlug in rSlugs
      put pageSlug into slugData [itemNum]["slug"]
      put fedwiki_ConstructTitle (pageSlug) into pTitle
      put pTitle into slugData [itemNum]["title"]
      add 1 to itemNum
   end repeat
   return slugData
end _RecycledSlugsData

private function _ConstructHtml htmlTemplate, pPageTitle, pOwnedBy
   /* Takes the default welcome-visitors server template and merges the params
   It takes the tags and pageDiv section using _ConstructSimplePageDiv() and replaces curly-tags
   The wiki-client does all the dynamic heavy lifting, so no need for server to render anything.*/
   
   if pPageTitle is empty then put "Welcome Visitors" into pPageTitle
   put fedwiki_ConstructSlug (pPageTitle) into pageSlug
   
   # Construct rendered page div
   put _ConstructSimplePageDiv (pageSlug) into pageDiv
   
   # Set end script login and ownership params
   _SetEndScript htmlTemplate, pPageTitle, pOwnedBy
   
   # Set "pages" div
   put pageArray ["story"] into storyArray
   wiki_SetTagOffsets htmlTemplate, "pages", startCharNum, endCharNum
   put the result into innerHTML
   if innerHTML is not empty then
      put pageDiv into char startCharNum to endCharNum of htmlTemplate
   end if
   
   return htmlTemplate
end _ConstructHtml

private function _ConstructSimplePageDiv pageSlug
   put "<div class='page' id='[[pageSlug]]' tabindex='-1'  >" & CR into pageDivTemplate
   put "  <div class='paper'>" & CR&CR after pageDivTemplate
   put "  </div>" & CR after pageDivTemplate
   put "</div>" after pageDivTemplate
   --
   put merge (pageDivTemplate) into pageDiv
   return pageDiv
end _ConstructSimplePageDiv

private function _ConstructLineupDiv someRoute
   -- /view/welcome-visitors/david.ward.dojo.fed.wiki/welsh/view/changes-to-this-site
   
   if char 1 of someRoute = "/" then
      delete char 1 of someRoute
   else
      return "Error, not a route:" && someRoute
   end if
   
   set the itemdelimiter to slash
   put the number of items of someRoute/2 into numOfPages
   if numOfPages is not an integer then return "Error, not a route:" && someRoute
   
   repeat numOfPages
      put item 1 of someRoute into viewOrDomain
      put item 2 of someRoute into pageSlug
      delete item 1 to 2 of someRoute
      --
      if viewOrDomain = "view" then
         put "<div class='page' id='[[pageSlug]]' tabindex='-1'  >" & CR into pageDivTemplate
      else
         put "<div class='page' id='[[pageSlug]]' tabindex='-1' data-site=[[viewOrDomain]] >" & CR into pageDivTemplate
      end if
      put "  <div class='paper'>" & CR&CR after pageDivTemplate
      put "  </div>" & CR after pageDivTemplate
      put "</div>" after pageDivTemplate
      --
      put merge (pageDivTemplate) into pageDiv
      put pageDiv & CR after pageDivContents
   end repeat
   --
   return pageDivContents
end _ConstructLineupDiv

function _ConstructLineUpHtml htmlTemplate, someRoute, pOwnedBy
   if pTabChars is empty then put "  " into pTabChars
   put pageArray ["title"] into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   
   put _ConstructLineupDiv (someRoute) into pageDiv
   
   # Set end script login and ownership params
   _SetEndScript htmlTemplate, pageTitle, pOwnedBy
   
   # Set "pages" div
   put pageArray ["story"] into storyArray
   wiki_SetTagOffsets htmlTemplate, "pages", startCharNum, endCharNum
   put the result into innerHTML
   if innerHTML is not empty then
      put pageDiv into char startCharNum to endCharNum of htmlTemplate
   end if
   
   return htmlTemplate
end _ConstructLineUpHtml
