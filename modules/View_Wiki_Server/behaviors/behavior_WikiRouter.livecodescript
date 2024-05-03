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
command get_FlagClick someRoute, socketID, requestArray, pPageTitle
   get_WikiDomain someRoute, socketID, requestArray, pPageTitle
end get_FlagClick

command get_WikiDomain someRoute, socketID, requestArray, pPageTitle, pOwnedBy
   /* Site reload
   Takes the default welcome-visitors server template and merges the params
   It takes the tags and pageDiv section using _ConstructSimplePageDiv() and replaces curly-tags
   The wiki-client does all the dynamic heavy lifting, so no need for server to render anything.*/
   
   if pPageTitle is empty then put "Welcome Visitors" into pPageTitle
   put fedwiki_ConstructSlug (pPageTitle) into pageSlug
   
   # Fetch default server page
   put wikiClient_GetStaticHtml() into someHTML
   
   # Construct rendered page div
   put _ConstructSimplePageDiv (pageSlug) into pageDiv
   
   # Set end script login and ownership params
   _SetEndScript someHTML, pPageTitle, pOwnedBy
   
   # Set "pages" div
   wiki_SetTagOffsets someHTML, "pages", startCharNum, endCharNum
   put the result into innerHTML
   if innerHTML is not empty then
      put pageDiv into char startCharNum to endCharNum of someHTML
   end if
   
   # Send HTML   
   daemon_SendText socketID, someHTML
   return merge ("Sent [[pageSlug]] for [[wikiDomain]]")
end get_WikiDomain

command get_WikiPageJsonNotFound someRoute, socketID, requestArray
   -- /jacob-soll.json
   set the itemdelimiter to slash
   put item -1 of someRoute into pageSlugToCreate
   if char -5 to -1 of pageSlugToCreate = ".json" then
      delete char -5 to -1 of pageSlugToCreate
   end if
   
   # If not found, wiki-client tries pages remote server and then present a ghost-create page]
   put daemon_ReceivedHeader ("Host", requestArray) into wikiDomain
   put daemon_ReceivedHeader ("Referer", requestArray) into sReferer
   --
   if the optionKey is "Down" then
      switch wikiDomain
         -- quick hack to provide custom tools per domain
         -- could look for a charmed wiki page
         case "transcript.thought.garden"
            set the itemdelimiter to slash
            put item -1 of sReferer into fromPageSlug
            put wikiPage_Transcript (wikiDomain, pageSlugToCreate, fromPageSlug) into pageArray
            --
            put wikiFile_Construct (wikiDomain, pageSlugToCreate) into wikiFile
            if there is not a file wikiFile then
               pageArray_Set wikiDomain, pageSlugToCreate, pageArray, true
               put fedwiki_ConstructTitle (pageSlugToCreate) into pageTitle
               put "Created page [[" & pageTitle & "]]" into someMarkdown
               put pageArray_Construct ("Success", someMarkdown, "markdown") into pageArray
            end if
            --
            daemon_SendArray socketID, pageArray
            return "Sent JSON. Socket still open."
         default
            if the shiftKey is "Down" then
               mediawiki_NormaliseTitle pageSlugToCreate, pageTitle, pageID
               if pageID is a number then
                  put mediawiki_FetchSummaryPageArray (pageTitle) into pageArray
                  put "markdown" into pageArray ["plugin"]
               else
                  put wikiPage_CreatePage (pageSlugToCreate, wikiDomain, "Create Page") into pageArray
               end if
            else
               put wikiPage_CreatePage (pageSlugToCreate, wikiDomain, "Create Page") into pageArray
            end if
            --
            daemon_SendArray socketID, pageArray
            return "Sent JSON. Socket still open."
      end switch
   else
      put wikiServer_GetPageArray (pageSlugToCreate) into pageArray
      if pageArray is an array then
         put json_FromArray (pageArray) into someJSON
         daemon_SendJSON socketID, someJSON
         return "Sent default page JSON. Socket still open."
      else
         put word 1 of the params && someRoute into logComment
         daemon_SendNotFound socketID, logComment
         return "Returned 404 page not found."
      end if
   end if
end get_WikiPageJsonNotFound

command _SetFirstMultipart rPostData, @someImage, @shortFileName, @mimeType
   -- "/plugin/image/upload/39e2e88aeea0aa7739a599333f5bb38d.jpg"
   /*
   -----------------------------57324694142348375092642508047
   Content-Disposition: form-data; name="image"; filename="39e2e88aeea0aa7739a599333f5bb38d.jpg"
   Content-Type: image/jpeg
   */
   
   # Quick parsing hack assuming its an image in a single part
   set the itemdelimiter to ":"
   put line 1 of rPostData into boundaryLine
   put token -1 of item 2 line 2 of rPostData into shortFileName
   put word -1 of line 3 of rPostData into mimeType
   --
   delete line 1 to 3 of rPostData
   put word 1 to -1 of rPostData into someImage
   delete line -1 of someImage
   --
   return "Finished"
end _SetFirstMultipart


--> Not implemented
-
command get_SecurityJS socketID, someRoute, requestArray
   daemon_SendNotFound socketID, word 1 of the params
   return "Security.js not implemented for" && someRoute
end get_SecurityJS


--> Props
-
getprop plugin_RouteData
   return PluginRouteData
end plugin_RouteData


--> Plugin
-
command route_Plugin someRoute, socketID, requestArray
   -- now that we properly use PluginRouteData this should not be needed
   put "route_Plugin undefined" && someRoute into logComment
   daemon_SendNotFound socketID, logComment
   return "Error, plugin not found"
   
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


--> GET | Assets
-
command action_ForkPage pageSlug, wikiDomain, actionArray
   -- put pageArray_Get (wikiDomain, pageSlug) into pageArray
   -- if pageArray is not an array then return "Error, page-json is faulty for" && wikiDomain,pageSlug
   
   -- create a blank new page
   put actionArray ["date"] into forkDate
   -- put actionArray ["item"] into pageArray
   put actionArray ["forkpage"] into pageArray
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

command get_WikiLineUp someRoute, socketID, requestArra, pOwnedBy
   # Fetch default server page
   put wikiClient_GetStaticHtml() into someHTML
   
   # Render server page together with json
   put pageArray ["title"] into pPageTitle
   put _ConstructLineupDiv (someRoute) into pageDiv
   
   # Set end script login and ownership params
   _SetEndScript someHTML, pPageTitle, pOwnedBy
   
   # Set "pages" div
   put pageArray ["story"] into storyArray
   wiki_SetTagOffsets someHTML, "pages", startCharNum, endCharNum
   put the result into innerHTML
   if innerHTML is not empty then
      put pageDiv into char startCharNum to endCharNum of someHTML
   end if
   --
   daemon_SendText socketID, someHTML
   return "Sent welcome-visitors for" && wikiDomain
end get_WikiLineUp

command get_Asset assetPath, wikiDomain, socketID, requestArray, pSendCompressed
   put wikiFile_ConstructAsset (assetPath, wikiDomain) into assetFile
   if there is a file assetFile then
      daemon_SendAsset requestArray, assetFile, pSendCompressed
      return the result
   else
      put "get_Asset" && wikiDomain & "," && assetFile into logComment
      daemon_SendNotFound socketID, logComment
      return "Returned 404 image not found."
   end if
end get_Asset

command get_Image shortImageFile, wikiDomain, socketID, requestArray
   put wikiFile_ConstructImageAsset (shortImageFile, wikiDomain) into imageFile
   -- put daemon_ReceivedHeader ("Referer", requestArray) into sReferer -- can we use this to find the image better
   --
   if there is a file imageFile then
      put url ("binfile:" & imageFile) into someImage
      set the itemdelimiter to "."
      put item -1 of shortImageFile into fileExt
      switch fileExt
         case "gif"
            daemon_SendImage socketID, someImage, "gif"
            break
         case "jpeg"
         case "jpg"
            daemon_SendImage socketID, someImage, "jpeg"
            break
         case "png"
            daemon_SendImage socketID, someImage, "png"
            break
         default
            daemon_SendImage socketID, someImage
      end switch
      return "Sent image" && someRoute
   else
      -- /assets/plugins/image/f9189e09ad44c357a66cea9550a721d3.jpg
      put "_SendImage" && imageFile & "," && wikiDomain into logComment
      daemon_SendNotFound socketID, logComment
      return "Returned 404 image not found."
   end if
end get_Image


--> Undefined
-
command undefined_Action socketID, someRoute, requestArray, pageSlug, wikiDomain, actionArray
   put "undefined_Action" && someRoute into logComment
   daemon_SendNotFound socketID, logComment
end undefined_Action

command undefined_Post socketID, someRoute, requestArray, pageSlug, wikiDomain, actionArray
   put "undefined_Post" && someRoute into logComment
   daemon_SendNotFound socketID, logComment
end undefined_Post

command undefined_Put socketID, someRoute, requestArray, pageSlug, wikiDomain, actionArray
   put "undefined_Put" && someRoute into logComment
   daemon_SendNotFound socketID, logComment
end undefined_Put

command undefined_Get socketID, someRoute, requestArray, pageSlug, wikiDomain, actionArray
   put "undefined_Get" && someRoute into logComment
   daemon_SendNotFound socketID, logComment
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
      case "OPTIONS"
         -- seems to iterate through each elemtn of neighbourhood
         -- but domain is not shown in "daemon_ReceivedHeader"
         put daemon_ReceivedHeader ("Host", requestArray) into wikiDomain
         if wikiDomain = "rest.livecode.world" then
            put daemon_GetRequestText (requestArray) into routeData
            put daemon_ReceivedHeader ("Referer", requestArray) into sReferer
         end if
         --
         daemon_SendOptions routeData, socketID
         return "Options:" && wikiDomain
         break
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

command daemon_SendOptions routeData, socketID
   /*
   Accept-Encoding: gzip, deflate
   Access-Control-Request-Method: POST
   Access-Control-Request-Headers: content-type
   Referer: http://thought.garden/
   Origin: http://thought.garden
   Connection: keep-alive
   
   HTTP/1.1 200 OK
   Allow: GET,HEAD
   Content-Type: text/html; charset=utf-8
   Content-Length: 8
   ETag: W/"8-ZRAf8oNBS3Bjb/SU2GYZCmbtmXg"
   Date: Wed, 10 Jan 2024 13:00:26 GMT
   Connection: keep-alive
   Keep-Alive: timeout=5 
   */
   -- put "GET,HEAD" into headerArray ["Allow"]
   -- put "text/html; charset=utf-8" into headerArray ["Content-Type"]
   put "*" into headerArray ["Access-Control-Allow-Origin"]
   put "POST, GET, OPTIONS" into headerArray ["Access-Control-Allow-Methods"]
   put "Content-Type" into headerArray ["Access-Control-Allow-Headers"]
   --
   put "HTTP/1.1 200 OK" into someHeader
   put CRLF & daemon_DeconstructHeaderArray (headerArray) after someHeader
   
   -- daemon_SendRaw someHeader, routeData, socketID
   daemon_Send someHeader, routeData, socketID
   --
   return "Options:" && wikiDomain
end daemon_SendOptions


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
   put wikiFolder_ConstructRecycled (wikiDomain) into recycleFolder
   --
   put recycleFolder & pageSLug into recyclePath
   revDeleteFile recyclePath
   --
   daemon_SendOK socketID, "OK"
   return "Deleted recycled page:" && pageSLug
end delete_RecycledPage


--> POST
-
command post_Favicon requestArray, socketID
   put daemon_GetRequestText (requestArray) into rPostData
   get URLDecode (rPostData)
   put item 1 of it into imageTypeBit -- image=data:image/png;base64
   put item 2 to -1 of it into encodedData
   --
   put base64Decode (encodedData) into someImage
   set the itemdelimiter to ":"
   put item 2 of imageTypeBit into mimeType  
   set the itemdelimiter to slash
   put item 2 of mimeType into fileExt
   --
   put daemon_ReceivedHeader ("Host", requestArray) into wikiDomain
   put wikiFile_ConstructFavicon (wikiDomain) into faviconFile
   put someImage into url ("binfile:" & faviconFile)
   --
   daemon_SendOK socketID, "OK"
   return "Saved favicon:" && wikiDomain && shortImageFile
end post_Favicon

command post_Image shortImageFile, requestArray, socketID
   put daemon_ReceivedHeader ("Host", requestArray) into wikiDomain
   put wikiFile_ConstructImageAsset (shortImageFile, wikiDomain) into imageFile
   if there is a file imageFile then
      -- seems to be called twice?
      return "Error, image file exists:" && imageFile
   end if
   
   put daemon_GetRequestText (requestArray) into rPostData
   _SetFirstMultipart rPostData, someImage, shortFileName, mimeType
   
   if shortFileName = shortImageFile then
      set the itemdelimiter to slash
      put item -1 of mimeType into imageType
      --
      put someImage into url ("binfile:" & imageFile)
      --
      -- display_Text someImage, shortImageFile
      daemon_SendOK socketID, "OK"
      return "Saved image to asset folder:" && wikiDomain && shortImageFile
   else
      beep
      breakpoint
      return "Error, pasing image using post_Image"
   end if
end post_Image


--> GET | Exceptions
-
command get_ListAssets wikiDomain, requestArray, socketID
   -- "/plugin/assets/list?assets=pages/model-furniture"
   
   # Get text of assets plugin from querystring
   get requestArray ["QUERY_STRING"] -- assets=pages/model-furniture
   put urldecode (it) into queryString
   split it with "&" and "="
   put it ["assets"] into relAssetPath
   
   -- set the itemdelimiter to ":"
   -- put word 1 to -1 of item 1 of queryString into sKey -- "assets"
   -- put word 1 to -1 of item 2 of queryString into relAssetPath -- "pages/model-furniture" as text of assets plugin
   
   # Construct json from files on server
   -- put "{'error':null,'files':['living-room.scad','living-room.stl','seating.scad','seating.stl']}" into sJSON
   -- replace "'" with quote in sJSON
   put wikiFile_ListAssets (wikiDomain, relAssetPath, true) into shortFiles
   put "null" into jsonArray ["error"]
   put 1 into itemNum
   repeat for each line shortFile in shortFiles
      put shortFile into jsonArray ["files"][itemNum]
      add 1 to itemNum
   end repeat
   put json_FromArray (jsonArray) into sJSON
   --
   daemon_SendJSON socketID, sJSON
   return "Sent assets file JSON. Socket still open."
end get_ListAssets

command get_SiteMapJson wikiDomain, socketID
   put wikiSiteMap_GetJson (wikiDomain) into binaryJSON
   daemon_SendSiteMapJSON socketID, binaryJSON
   -- daemon_SendJSON socketID, binaryJSON
   return "Sent Sitemap JSON. Socket still open."
end get_SiteMapJson

command get_SiteIndexJson wikiDomain, socketID
   put wikiSiteIndex_GetJson (wikiDomain) into binaryJSON
   if binaryJSON is empty then
      put "Site-index.json not found for:" && wikiDomain into logComment
      daemon_SendNotFound socketID, logComment
      return logComment
   else
      daemon_SendJSON socketID, binaryJSON
      return "Sent site-index.json. Socket still open."
   end if
end get_SiteIndexJson

command get_RecycledPageJson pageSLug, wikiDomain, socketID
   -- GET /recycler/livecode-sites.json HTTP/1.1
   put pageJson_GetRecycled (wikiDomain, pageSlug) into someJSON
   --
   if someJSON is empty then
      daemon_SendNotFound socketID, word 1 of the params
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
command get_WikiPageJson someRoute, socketID, requestArray, pageSLug, wikiDomain
   # First the wiki-client looks for page at origin server
   put pageJson_Get (wikiDomain, pageSlug) into someJSON
   --
   if someJSON is empty then
      get_WikiPageJsonNotFound someRoute, socketID, requestArray
      return the result
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
      put word 1 of the params && pageSlug,pluginName into logComment
      daemon_SendNotFound socketID, logComment
      return "Error, cannot locate mapJSON not sent. Socket still open." && mapFile
   end if
end get_PluginJavascriptMap

command get_PluginCss pluginName, shortCssFile, socketID
   put wikiPlugin_ConstructClientFolder (pluginName) into pluginClientFolder
   put pluginClientFolder & shortCssFile into pluginCssFile
   --
   if there is a file pluginCssFile then
      put url ("binfile:" & pluginCssFile) into sCSS
      daemon_SendCSS socketID, sCSS
      return "Sent plugin css" && pluginName
   else
      put word 1 of the params && shortCssFile,pluginName into logComment
      daemon_SendNotFound socketID, logComment
      return "Error, cannot find plugin css file" && shortCssFile
   end if
end get_PluginCss

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
      put word 1 of the params && shortJavascriptFile,pluginName into logComment
      daemon_SendNotFound socketID, logComment
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
      put wikiServer_GetFavicon() into sPNG
   end if
   daemon_SendPNG socketID, sPNG
   return the result
end get_LocalFavicon

command get_ClientPNG someRoute, socketID
   -- /images/noise.png
   put wikiClient_ConstructFile (someRoute) into pngFile
   --
   if there is a file pngFile then
      put url ("binfile:" & pngFile) into sImage
      daemon_SendPNG socketID, sImage
      return "Sent client png" && someRoute
   else
      put "get_ClientPNG" && pngFile & "," && someRoute into logComment
      daemon_SendNotFound socketID, logComment
      return "Returned 404 image not found."
   end if
end get_ClientPNG


--> Route
-
command get_FromPlugineRouteData routeArray, socketID, wikiDomain, requestArray
   put routeArray ["type"] into routeType
   put routeArray ["pluginName"] into pluginName
   put routeArray ["relPath"] into relPath
   --
   put routeArray ["fileExt"] into fileExt
   
   switch
      case routeType = "pluginPageSlug"
         put routeArray ["pageSlug"] into pageSlug
         get_PluginPageJson pluginName, pageSlug, socketID
         break
      case routeType = "pluginCss"
         get_PluginCss pluginName, relPath, socketID
         break
      case routeType = "pluginMap"
         get_PluginJavascriptMap pluginName, relPath, socketID
         break
      case routeType = "pluginJavascript"
         get_PluginJavascript pluginName, relPath, socketID
         break
      case routeType = "pluginMedia"
      case fileExt is among the items of "jpg,jpeg,png,gif,svg"
         get_Image relPath, wikiDomain, socketID, requestArray
         break
      case routeType = "pluginHtml"
         put routeArray ["relPath"] into relPath
         get_PluginHtml pluginName, relPath, socketID
         break
      default
         -- video or audio?
         breakpoint
   end switch
   return the result
end get_FromPlugineRouteData

command get_PluginHtml pluginName, relPath, socketID
   -- ie for Frame Plugin
   put wikiPlugin_ConstructClientFolder (pluginName) into clientFolder
   put clientFolder & relPath into frameHtmlFile
   --
   if there is a file frameHtmlFile then
      put url ("binfile:" & frameHtmlFile) into binaryHtml
      daemon_SendJSON socketID, binaryHtml
      return "Sent plugin html. Socket still open."
   else
      daemon_SendNotFound socketID, word 1 of the params
      return the result
   end if
end get_PluginHtml

command route_GET someRoute, socketID, requestArray
   put daemon_ReceivedHeader ("Host", requestArray) into wikiDomain
   --
   put PluginRouteData [someRoute] into routeArray
   --
   switch
      case routeArray is an array
         get_FromPlugineRouteData routeArray, socketID, wikiDomain, requestArray
         return the result
      case someRoute = "/plugins/activity.js"
         -- investigate why this route is popping up
         put PluginRouteData ["/plugins/activity/activity.js"] into routeArray
         put routeArray ["pluginName"] into pluginName
         put routeArray ["relPath"] into shortJavascriptFile
         get_PluginJavascript pluginName, shortJavascriptFile, socketID
         return the result
         
      case someRoute = "/plugins/search.js"
         -- why is this different?
         breakpoint
         put PluginRouteData ["/plugins/search/search.js"] into routeArray
         
         put routeArray ["pluginName"] into pluginName
         put routeArray ["relPath"] into shortJavascriptFile
         get_PluginJavascript pluginName, shortJavascriptFile, socketID
         return the result
      case someRoute = "/plugins/search.js.map"
         -- why is this different?
         breakpoint
         return the result
         
      case someRoute = "/plugins/image/import.svg"
         breakpoint
         return the result
         
      case someRoute begins with "/plugins/"
         -- breakpoint -- should have been trapped by PluginRouteData
         route_Plugin someRoute, socketID, requestArray
         return the result
         
      case matchText (someRoute, "/assets/plugins/image/(.+)" , shortImageFile)
         get_Image shortImageFile, wikiDomain, socketID, requestArray         
         break
      case someRoute = "/plugin/assets/list"
         get_ListAssets wikiDomain, requestArray, socketID
         return the result
      case matchText (someRoute, "/assets/(.+)" , encodedPath)
         put URLDecode (encodedPath) into assetPath
         get_Asset assetPath, wikiDomain, socketID, requestArray 
         return the result
         
      case someRoute = "/system/sitemap.json"
         get_SiteMapJson wikiDomain, socketID
         return the result
      case someRoute = "/system/site-index.json"
         get_SiteIndexJson wikiDomain, socketID
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
         get_WikiPageJson someRoute, socketID, requestArray, pageSLug, wikiDomain
         return the result
         
      case someRoute = "/"
         get_WikiDomain someRoute, socketID, requestArray
         return the result
      case someRoute = "/view/welcome-visitors"
         -- case matchText (someRoute, "/view/welcome-visitors/view/(.+)" , pageSLug)
         -- http://server.livecode.world/view/welcome-visitors
         get_FlagClick someRoute, socketID, requestArray
         return the result
         
      default
         if _LinupTest (someRoute) is true then
            get_WikiLineUp someRoute, socketID, requestArray
            return the result
         else
            -- /plugin/assets/list
            undefined_Get socketID, someRoute, requestArray
            return the result
         end if
   end switch
end route_GET

command route_POST someRoute, socketID, requestArray
   # Logins and Transporters?
   switch
      case matchText (someRoute, "/plugin/image/upload/(.+)", shortImageFile)
         post_Image shortImageFile, requestArray, socketID
         return the result
      case someRoute = "/favicon.png"
         post_Favicon requestArray, socketID
         return the result
      default
         put daemon_GetRequestText (requestArray) into rPostData
         daemon_SendJSON socketID, "{'hello': 'world'}"
         return the result
   end switch
end route_POST

command route_DELETE someRoute, socketID, requestArray
   put daemon_ReceivedHeader ("Host", requestArray) into wikiDomain
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


--> Action
-
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
   put actionArray ["item"] into itemArray
   -- put itemArray ["type"] into itemType
   -- put itemArray_Construct (itemType, itemID) into itemArray
   
   put pageArray_FindItemID (afterID, pageArray) into afterItemNum
   put pageArray ["story"] into storyArray
   storyArray_InsertAfter storyArray, afterItemNum, itemArray
   put storyArray into pageArray ["story"]
   
   # Add to journal
   put pageArray ["journal"] into journalArray
   journalArray_Add journalArray, itemArray, "add"
   put journalArray into pageArray ["journal"]
   
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
   
   # Delete the item and renumber
   put pageArray ["story"] into storyArray
   put item 2 of the extents of storyArray into maxNum
   repeat with toMoveNum = (storyItemNum + 1) to maxNum
      put toMoveNum - 1 into previousNum
      put storyArray [toMoveNum] into storyArray [previousNum]
   end repeat
   delete variable storyArray [maxNum]
   put storyArray into pageArray ["story"]
   
   # Add to journal
   put pageArray ["journal"] into journalArray
   journalArray_Add journalArray, actionArray, "remove"
   put journalArray into pageArray ["journal"]
   
   # Update the JSON file and sitemap
   save_AfterAction wikiDomain, pageSlug, pageArray, actionArray
   --
   return pageArray
end action_RemoveItem

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
   put daemon_GetRequestText (requestArray) into sInput
   split sInput with "&" and "="
   put sInput [action] into encodedAction
   put urldecode (encodedAction) into actionJSON
   put json_ToArray (actionJSON) into actionArray
   
   set the itemdelimiter to slash
   put item 3 of someRoute into pageSlug    
   put daemon_ReceivedHeader ("Host", requestArray) into wikiDomain
   
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
   
   put wikiPlugin_ListClientRelativePaths (pluginName) into relPaths
   set the itemdelimiter to "."
   repeat for each line relPath in relPaths
      put "/plugins/" & pluginName & "/" & relPath into someRoute
      --
      put item -1 of relPath into sFileExtension
      switch sFileExtension
         case "js"
            _SetRoutes "pluginJavascript", pluginName, relPath, someRoute
            break
         case "map"
            _SetRoutes "pluginMap", pluginName, relPath, someRoute
            break
         case "css"
            _SetRoutes "pluginCss", pluginName, relPath, someRoute
            break
         case "html"
         case "htm"
            _SetRoutes "pluginHtml", pluginName, relPath, someRoute
            break
         default
            -- some sort of media
            _SetRoutes "pluginMedia", pluginName, relPath, someRoute
            put sFileExtension into PluginRouteData [someRoute]["fileExt"]
      end switch
   end repeat
end _LoadPluginRoutes

private command _SetRoutes pType, pluginName, relPath, someRoute
   put pType into PluginRouteData [someRoute]["type"]
   put pluginName into PluginRouteData [someRoute]["pluginName"]
   put relPath into PluginRouteData [someRoute]["relPath"]
end _SetRoutes

command _SimpleLoadPluginRoutes pluginName
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
            put shortFile into PluginRouteData [someRoute]["relPath"]
            break
         case "map"
            put "pluginMap" into PluginRouteData [someRoute]["type"]
            put pluginName into PluginRouteData [someRoute]["pluginName"]
            put shortFile into PluginRouteData [someRoute]["relPath"]
            break
         default
            next repeat
      end switch
   end repeat
end _SimpleLoadPluginRoutes

private function _RecycledSlugsJson wikiDomain
   # Question: is this is normally provided by client-server registration?
   put _RecycledSlugsData (wikiDomain) into slugData
   put json_FromArray (slugData) into slugJSON
   return slugJSON
end _RecycledSlugsJson

private function _RecycledSlugsData wikiDomain
   put wikiFile_ListRecycled (wikiDomain) into rSlugs
   put 1 into itemNum
   repeat for each line pageSlug in rSlugs
      put pageSlug into slugData [itemNum]["slug"]
      put fedwiki_ConstructTitle (pageSlug) into pTitle
      put pTitle into slugData [itemNum]["title"]
      add 1 to itemNum
   end repeat
   return slugData
end _RecycledSlugsData

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

private function _LinupTest someRoute
   -- fast but crude
   set the itemdelimiter to slash
   get item 2 of someRoute
   if it = "view" or "." is among the chars of it then
      return true
   else
      return false
   end if
end _LinupTest
