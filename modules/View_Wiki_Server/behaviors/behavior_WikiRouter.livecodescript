script "behavior_WikiRouter" with behavior "behavior_DaemonLog"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_WikiRouter
type: behavior
version: 0.2

/*
This script is where routing happens.
You can place this script anywhere if you intercept the "getprop daemon_Router" virtual custom property
This is because the "behaviour_Daemon" script dispatches a "daemon_Request" command to the daemon_Router of me
*/


--> Working on
-
command block_SendPageJSONFromHost pageSlug, fromHost, socketID  
   put pageJson_Get (fromHost, pageSlug) into someJSON
   --
   if someJSON is empty then
      daemon_SendNotFound socketID
      return "Returned 404 page not found."
   else
      -- send the json file stored in the pages folder
      daemon_SendJSON socketID, someJSON
      return "Sent JSON. Socket still open."
   end if
end block_SendPageJSONFromHost


--> Route | Logic
-
command daemon_RouteRequest requestArray
   -- this is the core handler that lib_Daemon dispatches  
   request_DeconstructArray requestArray, socketID, someMethod, someRoute, queryString, requestUrl
   switch someMethod
      case "GET"
         process_GET someRoute, socketID, requestArray
         break
      case "POST"
         process_POST someRoute, socketID, requestArray
         break
      case "PUT"
         process_PUT someRoute, socketID, requestArray
         break
      case "DELETE"
         process_DELETE someRoute, socketID, requestArray
         break
   end switch
end daemon_RouteRequest


--> Process | POST
-
command process_GET someRoute, socketID, requestArray   
   set the itemdelimiter to "/"
   switch
      case someRoute = "/favicon.ico"
      case someRoute = "/favicon.png"
         process_Favicon requestArray, socketID
         return the result
      case someRoute = "/client.js"
      case someRoute = "/client.max.js"
      case someRoute = "/client.map"
      case someRoute begins with "/js/"
         -- "/js/jquery-ui/1.13.2/jquery-ui.min.css"
         -- "/js/jquery-3.6.3.min.js"
         -- "/js/jquery-migrate-3.4.0.min.js"
         -- "/js/jquery.ui.touch-punch.min.js"
         -- "/js/underscore-min.js"
         
         put wikiClient_GetClientFile (someRoute) into jsFile
         put text_Get (jsFile) into sJavascript
         daemon_SendText socketID, sJavascript
         return "Sent client js" && someRoute
      case someRoute begins with "/theme/"
         -- "/theme/style.css"
      case someRoute begins with "/style/"
         -- "/style/print.css"
         -- "/style/style.css"
         
         put wikiClient_GetClientFile (someRoute) into sCSS
         daemon_SendCSS socketID, sCSS
         return "Sent client css" && someRoute
      case someRoute begins with "/images/"
         -- "/images/crosses.png"
         put wikiClient_ConstructFile (someRoute) into pngFile
         if there is a file pngFile then
            put url ("binfile:" & pngFile) into sPNG
            daemon_SendPNG socketID, sPNG
         else
            process_UnGot socketID, someRoute, routeData, requestArray
         end if
         return "Sent client png" && someRoute
      case someRoute = "/"
         put wikiClient_GetStaticHtml() into htmlTemplate
         --
         put daemon_HostFromRequest (requestArray) into wikiDomain
         put wiki_RenderHtml (htmlTemplate, wikiDomain) into someHTML
         --
         daemon_SendText socketID, someHTML
         return "Sent welcome-visitors for" && wikiDomain
      case the number of items of someRoute = 2 and char -5 to -1 of someRoute = ".json" -- specific to Fedwiki routing
         put fedwiki_UrlPathToSlug (someRoute) into pageSlug
         put daemon_HostFromRequest (requestArray) into fromHost
         block_SendPageJSONFromHost pageSlug, fromHost, socketID -- block_SendPageJSON
         --
         return the result
      case "/system/factories.json"
         
         break
      case "/security/security.js"
         
         break
      default
         -- here we come across new stuff for the first time
         process_UnGot socketID, someRoute, routeData, requestArray
         return the result
   end switch
end process_GET

command process_Favicon requestArray, socketID
   put daemon_HostFromRequest (requestArray) into wikiDomain
   --
   put wiki_GetFavicon (wikiDomain) into sPNG
   if sPNG is empty then
      put wiki_GetDefaultFavicon() into sPNG
   end if
   daemon_SendPNG socketID, sPNG
   return the result
end process_Favicon

command process_POST someRoute, socketID, requestArray
   switch someRoute
      case "/persona_login"
         break
      default
         put daemon_GetPostData (requestArray) into rPostData
         daemon_Log "process_POST" && the result
         daemon_SendJSON socketID, "{'hello': 'world'}"
   end switch
end process_POST

command process_UnGot socketID, someRoute, routeData, requestArray
   -- here we come across new stuff for the first time
   -- over ride with middleware for parasitic mode
   -- dameon_AddToMiddlewareArray requestArray
   daemon_SendNotFound socketID
end process_UnGot

command process_PUT someRoute, socketID, requestArray
   put daemon_GetPostData (requestArray) into putInput
   set the itemdelimiter to "/"
   -- if char 1 of someRoute is not "/" then put  "/" before someRoute
   switch
      -- /page/hikey-board/action
      case item -1 of someRoute = "action" and item 2 of someRoute = "page"
         put item 3 of someRoute into pageSlug    
         put request_ConstructHeaderArray (requestArray) into receivedHeaderArray
         put receivedHeaderArray ["Referer"] into someReferer
         put receivedHeaderArray ["Accept-Encoding"] into encodingAccepted
         put receivedHeaderArray ["Host"] into someHost
         
         --  action:{"type":"create","item":{"title":"HiKey Board","story":[]},"date":1438036497154}
         split putInput with "&" and "="
         put putInput [action] into encodedAction
         put urldecode (encodedAction) into actionJSON
         put json_ToArray (actionJSON) into actionArray
         
         block_DoAction actionArray, pageSlug
         put the result into someError
         
         -- send "ok" back
         daemon_SendText socketID, "ok"
         break
      default
         put "PUT" & CR & someRoute & CR & CR & putInput
   end switch
end process_PUT

command process_DELETE someRoute, socketID, requestArray
   beep
   breakpoint
end process_DELETE


--> Private
-
private command _ToolJson someRoute, socketID
   put item -1 of someRoute into pageSlug
   delete char -5 to -1 of pageSlug
   
   put "A particular tool goes here:" into someComment
   put pageArray_Construct ("Hello", someComment) into pageArray
   
   put "* [[Test Tool]]" into someMarkdown
   put CR & "* [[Another Tool]]" after someMarkdown
   pageArray_AddMarkdown pageArray, someMarkdown
   
   put library_FetchHandler ("process_Get,c") into someCode
   pageArray_AddCode pageArray, someCode
   
   daemon_SendArray socketID, pageArray
   return the result
end _ToolJson

private command _ToolIndex socketID
   put "An nice tool index goes here:" into someComment
   put pageArray_Construct ("Tools Index", someComment) into pageArray
   --
   put "* [[Test Tool]]" into someMarkdown
   put CR & "* [[Another Tool]]" after someMarkdown
   pageArray_AddMarkdown pageArray, someMarkdown
   --
   daemon_SendArray socketID, pageArray
   return the result
end _ToolIndex

private command _Hello socketID
   put "This is a test of Hello World. At round about" into someComment
   put the time after someComment
   put pageArray_Construct ("Hello", someComment) into pageArray
   --
   daemon_SendArray socketID, pageArray
   return the result
end _Hello

private command _ProcessCustom
   switch
      case someRoute ends with "tool.json"
         _ToolJson someRoute, socketID
         return the result
      case someRoute = "tools-index.json"
         _ToolIndex socketID
         return the result
      case someRoute = "/hello.json"
         _Hello socketID
         return the result
      case someRoute = "/" or someRoute begins with "/view/welcome-visitors"
         put daemon_GetRouteData ("/view/welcome-visitors") into someHTML
         daemon_SendText socketID, someHTML
         return "Sent HTML. Socket still open."
      case someRoute = "/system/sitemap.json" -- specific to Fedwiki routing
         block_SendSiteMap socketID
         return the result
      case someRoute = "/style.css"
         _TransformedCSS someRoute, socketID
         return "Sent modified CSS based on headerArray. Socket still open."
   end switch
end _ProcessCustom

private command _TransformedCSS someRoute, socketID
   -- can use Livecode javascript to effect the same as changing CSS
   -- daemon_SendHeaderArray someRoute, headerArray, socketID
   
   put daemon_GetRouteData (someRoute) into someCSS
   wiki_ConvertCSS someCSS
   
   put "HTTP/1.1 200 OK" into someHeader
   put CRLF & daemon_DeconstructHeaderArray (headerArray) after someHeader
   daemon_Send someHeader, someCSS, socketID
   return the result
end _TransformedCSS


--> Private
-
function daemon_HostFromRequest requestArray
   put requestArray ["receivedHeaders"] into receivedHeaderArray
   split receivedHeaderArray with CR and ":"
   put word 1 to -1 of receivedHeaderArray ["Host"] into fromHost
   set the itemdelimiter to ":"
   return item 1 of fromHost
end daemon_HostFromRequest


--> Daemon | Routing | Utils
-
command request_DeconstructArray requestArray, @socketID, @someMethod, @someRoute, @queryString, @requestUrl
   put requestArray ["socketID"] into socketID
   put requestArray ["Request Method"] into someMethod
   put requestArray ["SCRIPT_NAME"] into someRoute
   put requestArray ["QUERY_STRING"] into queryString
   put requestArray ["Requested URL"] into requestUrl
end request_DeconstructArray

function request_ConstructHeaderArray requestArray
   -- If-None-Match: "686897696a7c876b7e"
   put requestArray ["receivedheaders"] into receivedHeaders
   put daemon_ConstructHeaderArray (receivedHeaders) into headerArray
   return headerArray 
end request_ConstructHeaderArray
