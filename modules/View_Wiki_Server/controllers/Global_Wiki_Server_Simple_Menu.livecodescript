script "Global | Wiki | Server | Simple | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Server | Simple | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_Target [tObject]
   put 9090 into LocalArray ["sPort"]
   put "Live Wiki Server" into LocalArray ["sName"]
   
   -- put display_MenuTarget (tObject) into dView
   put the display_View of tObject into dView
   return dView
end menu_Target

getprop menu_CheckTarget [dView]
   return exists (dView)
end menu_CheckTarget

on NewRequest socketID, rArray
   /*
   The array has the following keys:
   
   "method": The HTTP request method
   "resource": The request resource path e.g /images/foo.gif
   "parameters": For GET requests with parameters or application/x-www-form-urlencoded encoded this key will be an array of parameters
   "headers": An array of request headers
   "content": The request body (empty for application/x-www-form-urlencoded)
   */
   switch rArray ["method"]
      case "GET"
         _DoGet rArray, socketID
         break
      case "POST"
         put rArray ["parameters"] into postedArray
         put rArray ["resource"] into someRoute
         --
         -- post_ToController someRoute, socketID, rArray
         -- _TestPost socketID
         _TestPostJson socketID
         --
         break
      case "OPTIONS"
         -- put daemon_ReceivedHeader ("Host", requestArray) into wikiDomain
         -- put daemon_GetRequestText (requestArray) into routeData
         --
         breakpoint
         daemon_SendOptions routeData, socketID
         return "Options:" && wikiDomain
      default
         -- not found
         httpdResponse socketID, 404
   end switch
   
   if the shiftKey is "Down" then
      display_Data rArray
   end if
end NewRequest

command _TestPostJson socketID
   put pageArray_Construct ("Test", "Hello world") into pageArray
   put pageArray_ToJson (pageArray) into sJSON
   -- put "{'hello': 'world'}" into sJSON
   --
   daemon_SendJSON socketID, sJSON
   --
   -- put jsonrpc_Headers() into sHeader
   -- httpdResponse socketID, 200, sData, sHeader
end _TestPostJson

command daemon_SendJSON socketID, someJSON
   put _OkHeaders ("application/json; charset=utf-8") into someHeader
   --
   -- daemon_Send someHeader, someJSON, socketID
   daemon_SendAndCloseSocket someHeader, someJSON, socketID
   --
   return someHeader
end daemon_SendJSON

command daemon_SendAndCloseSocket someHeader, contentToSend, socketID
   _AddContentLengthHeader someHeader, contentToSend
   put someHeader & CRLF & CRLF & contentToSend into headersAndContent
   daemon_RawSendAndClose headersAndContent, socketID
end daemon_SendAndCloseSocket

command daemon_RawSendAndClose headersAndContent, socketID
   write headersAndContent to socket socketID
   close socket socketID
end daemon_RawSendAndClose

private function _OkHeaders pContentType, pCookieName, pCookieValue
   --  Generates the HTTPd Header with a 200 OK response. (200 OK = Yes it succeded!)
   if pContentType is empty then put "text/html" into pContentType
   
   put "HTTP/1.1 200 OK" into someHeader
   _AddContentTypeHeader someHeader, pContentType
   _AddCorsHeader someHeader
   -- _AddCacheHeader someHeader
   _AddConnectionHeader someHeader
   _AddDateHeader someHeader
   if pCookieName is not empty then
      _AddCookieHeader someHeader, pCookieName, pCookieValue
   end if
   return someHeader
end _OkHeaders

private command _AddDateHeader @someHeader
   put "Date:" && the date & the time into headlerLine  
   put CRLF & headlerLine after someHeader 
end _AddDateHeader

private command _AddCookieHeader @someHeader, cookieName, cookieValue
   put cookieName & "=" & cookieValue & ";" into cookieString
   put CRLF & "Set-Cookie:" && cookieString  after someHeader
end _AddCookieHeader

private command _AddConnectionHeader @someHeader
   -- always defaults to close for now
   -- put CRLF & "Connection: Close " after someHeader
   put CRLF & "Connection: keep-alive " after someHeader
end _AddConnectionHeader

private command _AddKeepAliveHeader @someHeader
   put "Connection:keep-alive" into headlerLine  
   put CRLF & headlerLine after someHeader 
end _AddKeepAliveHeader

private command _AddCorsHeader @someHeader
   put CRLF & "Access-Control-Allow-Origin:*" after someHeader
end _AddCorsHeader

private command _AddCacheHeader @someHeader
   put CRLF & "Cache-Control:public, max-age=0" after someHeader
end _AddCacheHeader

private command _AddContentTypeHeader @someHeader, pContentType
   if pContentType is empty then put "text/html" into pContentType
   put "Content-Type:" && pContentType into headlerLine
   put CRLF & headlerLine after someHeader 
end _AddContentTypeHeader

private command _AddContentLengthHeader @someHeader, theContent
   -- maybe we should be careful and check it is not already there?
   put "Content-Length:" && length (theContent)  into headlerLine   
   put CRLF & headlerLine after someHeader 
end _AddContentLengthHeader

private command _AddContentLengthHeader @someHeader, theContent
   -- maybe we should be careful and check it is not already there?
   put "Content-Length:" && length (theContent)  into headlerLine   
   put CRLF & headlerLine after someHeader 
end _AddContentLengthHeader

command _TestPost socketID
   put pageArray_Construct ("Test", "Hello world!") int pageArray
   put pageArray_ToJson (pageArray) into sData
   --
   put "Posted data" into sData
   --
   put jsonrpc_Headers() into sHeader
   httpdResponse socketID, 200, sData, sHeader
end _TestPost

command _DoGet rArray, socketID
   -- "resource": The request resource path e.g /images/foo.gif
   put rArray ["resource"] into someRoute
   
   switch
      case someRoute = "/lcw_BrowserUrl"
         get_LcwBookmarklet someRoute, socketID, requestArray
         break
      case matchText (someRoute, "/view/welcome-visitors/view/([^/]+)$", pageSLug)
         # Flag Click (see get_FlagClick)
         get_WikiServerToolPage someRoute, requestArray, socketID
         break
      default
         put "Hello world" && the opensockets into tData
   end switch
   
   httpdResponse socketID, 200, tData
end _DoGet

command post_ToController someRoute, socketID, rArray  
   switch someRoute
      case "/openverse"
         put pc_OpenversePageArray (rArray) into pageArray
         --
         daemon_SendArray socketID, pageArray
         break
      default
         put pc_StackName (someRoute) into cStackName
         put pc_GetPageArray (cStackName, someRoute, rArray) into pageArray  
         daemon_SendArray socketID, pageArray, pHeaders      
   end switch
end post_ToController

function pc_GetPageArray cStackName, someRoute, rArray
   if exists (stack cStackName) is false then
      put "Error, cannot locate control stack:" && cStackName into sMarkdown
      put pageArray_Construct (pageTitle, sMarkdown) into pageArray
      return pageArray
   end if
   --
   put daemon_GetRequestText (rArray) into postData
   put postData into $_POST_RAW
   
   put pc_GetPropName(someRoute) into getPropName
   put the getPropName of stack cStackName into pageArray
   -- put _GetValue (someRoute, cStackName, rArray) into pageArray
   
   -- dispatch hName to stack controllerStackName with requestArray
   return pageArray
end pc_GetPageArray

function _GetValue someRoute, cStackName, rArray
   put pc_FunctionName (someRoute) into fName
   put the name of stack cStackName into stackObject
   
   -- value ("revMenubarFileMenu(pContext)" , revMbar)
   -- put kwote (fName & "(rArray)") into sExpression
   put fName & "(rArray)" into sExpression
   -- put "_Index(rArray)" into sExpression
   put value (sExpression, stackObject) into pageArray
   return pageArray
end _GetValue

function pc_StackName someRoute
   set the itemdelimiter to slash
   put item 2 of someRoute & ".lc" into cStackName
   return cStackName
end pc_StackName

function pc_FunctionName someRoute
   put item 3 of someRoute into hName
   if hName is empty then put "index" into hName
   --
   put "_" & hName into fName
   return fName
end pc_FunctionName

function pc_GetPropName someRoute
   put item 3 of someRoute into hName
   if hName is empty then put "index" into hName
   put hName & "_Array" into getPropName
   return getPropName
end pc_GetPropName

command pc_Dispatch someRoute, rArray
   --
   put pageArray_ToJson
end pc_Dispatch

function daemon_GetRequestText rArray
   -- either data for an http POST, or PUT is stored in requestArray ["theData"]
   -- "parameters": For GET requests with parameters or application/x-www-form-urlencoded encoded this key will be an array of parameters
   return rArray ["parameters"]
end daemon_GetRequestText

command daemon_SendArray socketID, pageArray, pHeaders
   -- put json_FromArray (pageArray) into pageJSON
   
   put pageArray_ToJson (pageArray) into pageJSON
   httpdResponse socketID, 200, pageJSON, pHeaders
   return the result
end daemon_SendArray

function pc_OpenversePageArray requestArray
   -- put daemon_RequestJsonArray (requestArray) into rPostArray
   put rPostArray ["search_Term"] into searchTerm
   --
   put openverse_Search (searchTerm) into sData
   put wikiPage_OpenVerseThumbNails (sData) into pageArray
   return pageArray
end pc_OpenversePageArray


--> Global | Wiki | Server | Simple | Menu
-
on menu_WikiServerSimple dView
   put LocalArray ["sName"] into sName
   put LocalArray ["sPort"] into sPort
   
   if _ServerIsRunning() then
      httpdStop sPort
   else
      httpdStart "NewRequest", sPort, sName
      if the result is not empty then
         breakpoint
      end if
      put it into pStartedOn
      
      put "http://localhost:" & pStartedOn into localURL
      if the shiftKey is "down" then
         launch url localURL
      else
         put url localURL
      end if
   end if
end menu_WikiServerSimple

private function _ServerIsRunning
   get the opensockets
   put LocalArray ["sPort"] is among the lines of it into isRunning
   return isRunning
end _ServerIsRunning

getprop checked_WikiServerSimple
   return _ServerIsRunning()
end checked_WikiServerSimple

on menu_CloseAllSockets
   socket_CloseOpen
   resetall
end menu_CloseAllSockets

getprop checked_CloseAllSockets
   return the opensockets is empty
end checked_CloseAllSockets

private on _
end _

on menu_TestPost
   post "hello" to url ("http://rest.livecode.world")
   put it
end menu_TestPost

on menu_TestGet
   put url ("http://rest.livecode.world")
end menu_TestGet

on menu_TestJson
   put pageArray_Construct ("Test", "Hello world") into pageArray
   put pageArray_ToJson (pageArray) into sJSON
   put sJSON
end menu_TestJson

private on __
end __

on menu_EditEchoController
   edit the script of stack "echo.lc"
end menu_EditEchoController

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Server | Simple | Menu")
end submenu_Dev
