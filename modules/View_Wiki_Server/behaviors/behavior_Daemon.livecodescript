script "behavior_Daemon" with behavior "behavior_DaemonMiddleware"
--> MetaData
-
name: behavior_Daemon
type: behavior
version: 0.9
copyright: David Bovill
licence:  GPLv3

/*
A minimal library for creating simple HTTP and Restful servers using Livecode.
It should contain only code that is absolutle necessary - and is optimised for speed.

Another aim of this library is that it should be able to run a server, without any additional code
using only custom properties of an object that it is attached to as a behavior.

All othere messages (if any are needed) would be dispatched and optional)
Logging and similar functions are added using before/after middleware handlers.
*/

--> Variables
-
local SocketData   -- Array used to gather socket data from potentially multiple connections as they come in

local DropDelay = 60
local SessionArray

local DefaultPort = 3000


--> Working on
-
private command _AddSessionCookie @someHeader
   return empty
   
   -- for now a quick hack
   if SessionArray is empty then return "Cookie not set"
   get "qvHx_T04gEAtKXxlGHG0Cw.j9Kd9ZUK-wSPFr12Ml4jtqhQsvXve3AnwUbVOYu081QD3Xe65TuV5s0Ts8IQWSYi.1438080455096.86400000.7Q_SkgQfc7nrHgjZoLfL-xSOKtNUKNounvxyD-oIjtI"
   _AddCookieHeader someHeader, "session", it
end _AddSessionCookie

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

private command _AddLastModifiedHeader @someHeader, pInternetDate
   -- this seems essential to functioning of changes / activity plugins.
   put CRLF & "Last-Modified:" && date_Construct7232 (pInternetDate) after someHeader -- Last-Modified: Tue, 02 Jan 2024 08:54:39 GMT
end _AddLastModifiedHeader

function date_Construct7232 pInternetDate
   if pInternetDate is empty then
      put the internet date into pInternetDate
   end if
   
   put word -1 of pInternetDate into utcOffset
   convert pInternetDate to dateItems
   -- 
   put char 2 to 3 of utcOffset into extraHours
   put char 4 to 5 of utcOffset into extraMin
   if char 1 of utcOffset is "+" then
      add extraHours to item 4 of pInternetDate
      add extraMin to item 5 of pInternetDate
   else
      subtract extraHours from item 4 of pInternetDate
      subtract extraMin from item 5 of pInternetDate
   end if
   --
   convert pInternetDate to internet date
   
   put "GMT" into word -1 of pInternetDate
   return pInternetDate
end date_Construct7232

command daemon_SendSiteMapJSON socketOrRequestArray, someJSON, pSendCompressed, wikiURL
   put _NormalizeSocket (socketorRequestArray) into socketID
   --
   put "http://code.astralship.wiki" into wikiURL
   --
   /*
   HTTP/1.1 304 Not Modified
   Access-Control-Allow-Origin: http://code.astralship.wiki
   Accept-Ranges: bytes
   Cache-Control: public, max-age=0
   Last-Modified: Tue, 02 Jan 2024 08:54:39 GMT
   ETag: W/"2bc98-18cc961ce1c"
   Date: Wed, 03 Jan 2024 19:32:44 GMT
   Connection: keep-alive
   Keep-Alive: timeout=5
   */
   
   put "HTTP/1.1 200 OK" into someHeader -- HTTP/1.1 304 Not Modified
   put CRLF & "Accept-Ranges: bytes" after someHeader
   _AddContentTypeHeader someHeader, "application/json; charset=utf-8"
   -- put CRLF & "Access-Control-Allow-Origin:" && wikiURL after someHeader
   _AddCorsHeader someHeader, wikiURL
   put CRLF & "Cache-Control: public, max-age=0" after someHeader
   put CRLF & "Connection: keep-alive" after someHeader
   -- _AddConnectionHeader someHeader
   _AddDateHeader someHeader -- Date: Wed, 03 Jan 2024 19:32:44 GMT
   -- put CRLF & "ETag: W/" & kwote ("2bc98-18cc961ce1c") after someHeader
   put CRLF & "Keep-Alive: timeout=5" after someHeader
   _AddLastModifiedHeader someHeader -- this seems essential to functioning of changes / activity plugins.
   --
   daemon_Send someHeader, someJSON, socketID, pSendCompressed
   return someHeader
end daemon_SendSiteMapJSON


--> Daemon | Sessions
-
command daemon_SetSession socketID, someReply, pContentType
   -- Set-Cookie: sessionToken=abc123; Expires=Wed, 09 Jun 2021 10:18:14 GM
   -- put true into SessionArray
   
   get "IHqOSrK5HDQ7rFiarE1KcQ.EqHAy6x1nZ4z80ClyyMVivHNqfs4zhkNRoFqMbe6DlBkBAI3aRAtseJGHO7qcaqE.1438105299038.86400000.UzvAUVkRttrGikzPDllFJG4iNgURB4cVMqkr_rBR4EU"
   put it into theSessionID
   put _OkHeaders (pContentType, "session", theSessionID) into someHeader
   daemon_Send someHeader, someReply, socketID
   return the result
end daemon_SetSession


--> Objects
-
getprop daemon_Server
   return _DaemonServer()
end daemon_Server


--> Daemon | Objects
-
getprop daemon_IsRunning
   return _DaemonIsRunning()
end daemon_IsRunning

setprop daemon_IsRunning [closeAll] someBoolean
   put _DaemonIsRunning() into daemonIsRunning
   --
   if someBoolean is true then
      if daemonIsRunning is false then
         daemon_Start
      end if
   else
      if closeAll is true then
         socket_CloseOpen
      else
         if daemonIsRunning is true then
            daemon_Stop
         end if
      end if
   end if
   --
   return _DaemonIsRunning()
end daemon_IsRunning

getprop daemon_Port
   return daemon_GetPort()
end daemon_Port

setprop daemon_Port newPort
   daemon_SetPort newPort
end daemon_Port

function daemon_GetPort
   return DefaultPort
end daemon_GetPort

command daemon_SetPort newPort
   -- so we can log with "after daemon_SetPort"
   put the daemon_IsRunning of me into isRunning
   if isRunning is true then daemon_Stop
   --
   put newPort into DefaultPort
   --
   if isRunning is true then daemon_Start
end daemon_SetPort


--> Daemon | Start and Stop
-
command daemon_Start pPortToListenOn, pDaemonServer
   _NormalizeDaemonPort pPortToListenOn
   --
   accept connections on port pPortToListenOn with message "newConnection"
end daemon_Start

command daemon_Stop pCloseAll
   if pCloseAll is true then
      socket_CloseOpen
      daemon_DeleteSocketData
   else
      put the daemon_Port of me into portToListenOn
      close socket portToListenOn
   end if
end daemon_Stop

function daemon_GetSocketData
   return SocketData
end daemon_GetSocketData

command daemon_DeleteSocketData
   delete variable SocketData
end daemon_DeleteSocketData


--> Daemon | Connection
-
on newConnection pSocketID
   /*
   This handler is the first step of a new connection. It will start processing the connections and pipeing the control to the handler called "proccessRequest"
   
   pDropDelay is the number of seconds that a connection that never completed is kept around in SocketData before it is purged. 
   In this case, I assume that if we don't get a fully formed set of data within 10 minutes of the initial connection, it's not going to happen.
   */
   put the long id of target into SocketData [pSocketId]["theTarget"]
   put the seconds + DropDelay into SocketData [pSocketId]["theSeconds"]
   read from socket pSocketID until CRLF with message "readRequest"
end newConnection

on readRequest pSocketId, pSocketData
   /*
   This handler gets the next set of data that comes in a connection. 
   It is possible for this data to come in a separate packet from the initial connection. 
   Under certain conditions Revolution may assume that the first packet was all the data there was and think it is ready to let the code process the data. 
   This causes it to wait for more of the request when the request spans multiple packets.
   */
   
   put pSocketData into SocketData [pSocketId]["request"]
   read from socket pSocketID until CRLF & CRLF with message "readheaders"
end readRequest

on readHeaders pSocketId, pSocketData
   /*
   And this handler gets the final set of data that is coming in the request, 
   again just in case the request is split into multiple packets for some reason by the sender.
   This chain of handlers makes the processing more reliable.
   */
   put pSocketData into SocketData [pSocketId]["headers"]
   read from socket pSocketID until empty with message "processRequest"
end readHeaders

on processRequest pSocketID, theData
   -- This handler is called when we process a new request.
   put theData into SocketData [pSocketId]["theData"]
   put _CacheRequestArray (pSocketID) into requestArray
   
   put _DaemonRouter() into routerObject
   dispatch "daemon_RouteRequest" to routerObject with requestArray
   switch it
      -- could do stuff here
      case "handled"
         break
      case "unhandled" -- no matching handlers were found
         break
      case "passed" -- the message was handled but passed by all handlers
         break
   end switch
   
   -- let's automatically close the socket (so that routers don't need to do that)
   -- 127.0.0.1:51606 -- bug with socket
   put requestArray ["socketID"] into socketID
   if socketID is among the lines of the opensockets then
      close socket socketID
   end if
   _CleanSocketData socketID
end processRequest


--> Dameon | POST
-
function daemon_GetPostData requestArray
   -- put SocketData [socketID]["theData"] into theData
   return requestArray ["theData"]
end daemon_GetPostData


--> Dameon | Send
-
command daemon_SendArray socketOrRequestArray, sArray, pSendCompressed
   put json_FromArray (pageArray) into someJSON
   daemon_SendJSON socketOrRequestArray, someJSON, pSendCompressed
   put the result into someHeader
   return someHeader
end daemon_SendArray

command daemon_SendJSON socketOrRequestArray, someJSON, pSendCompressed
   put _NormalizeSocket (socketorRequestArray) into socketID
   put _OkHeaders ("application/json; charset=utf-8") into someHeader
   daemon_Send someHeader, someJSON, socketID, pSendCompressed
   return someHeader
end daemon_SendJSON

command daemon_SendPNG socketorRequestArray, faviconPNG, pSendCompressed
   put _NormalizeSocket (socketorRequestArray) into socketID
   put _OkHeaders ("image/png") into someHeader
   daemon_Send someHeader, faviconPNG, socketID, pSendCompressed
   return someHeader
end daemon_SendPNG

command daemon_SendJS socketOrRequestArray, sJavascript, pSendCompressed
   put _NormalizeSocket (socketorRequestArray) into socketID
   put _OkHeaders ("application/javascript; charset=UTF-8") into someHeader
   daemon_Send someHeader, sJavascript, socketID, pSendCompressed
   return someHeader
end daemon_SendJS

command daemon_SendCSS socketOrRequestArray, someText, pSendCompressed
   put _NormalizeSocket (socketorRequestArray) into socketID
   put _OkHeaders ("text/css; charset=UTF-8") into someHeader
   daemon_Send someHeader, someText, socketID, pSendCompressed
   return someHeader
end daemon_SendCSS

command daemon_SendText socketOrRequestArray, someText, pETag, pCookieName, pCookieValue, pSendCompressed
   put _NormalizeSocket (socketorRequestArray) into socketID
   put _OkHeaders ("text/html", pCookieName, pCookieValue) into someHeader
   daemon_Send someHeader, someText, socketID, pSendCompressed
   return someHeader
end daemon_SendText

command daemon_SendMovedTemporarily socketID, locationURL
   /*
   •	Date:Tue, 28 Jul 2015 16:27:39 GMT
   •	Location:welcome-visitors.html
   •	Vary:Accept
   */
   put _MovedTemporarilyHeaders (locationURL) into someHeader
   daemon_Send someHeader, "Moved Temporarily", socketID, false
   return the result
end daemon_SendMovedTemporarily

command daemon_SendNotFound socketID
   put _NotFoundHeaders() into someHeader
   daemon_Send someHeader, "Page not found", socketID, false
   return the result
   
   -- put _CustomHeaders (404, "Error: 404", "file not found") into someHeader
   put someHeader & CRLF & CRLF & contentToSend into headersAndContent
   write headersAndContent to socket socketID
   return headersAndContent
end daemon_SendNotFound

command daemon_SendRedirect redirectURL, socketID, pDescriptiveContent
   -- Handler that Forwards the user to another URL. It needs an absolute url as a parameter.
   -- This handler uses a 301 (permanent redirection) to drive the browser to a new location.
   
   if pDescriptiveContent is empty then
      put "Should redirect to <a href=" & quote & redirectURL & quote & ">" & redirectURL & "</a>" into descriptiveContent
   end if
   put _RedirectionHeaders (redirectURL, pDescriptiveContent) into someHeader
   daemon_Send someHeader, descriptiveContent, socketID, false
   return the result
end daemon_SendRedirect

command daemon_SendHeaderArray someRoute, headerArray, socketID, pSendCompressed
   put daemon_GetRouteData (someRoute) into routeData
   
   put daemon_ConstructDefaultHeader() into defaultHeaderArray
   delete variable headerArray ["Content-Length"] -- because it is always added below
   union headerArray with defaultHeaderArray
   put "HTTP/1.1 200 OK" into someHeader
   put CRLF & daemon_DeconstructHeaderArray (headerArray) after someHeader
   
   -- daemon_SendRaw someHeader, routeData, socketID
   daemon_Send someHeader, routeData, socketID, pSendCompressed -- adds "Content-Length"
   return the result
end daemon_SendHeaderArray

command daemon_Send someHeader, contentToSend, socketID, pSendCompressed
   -- always adds "Content-Length:" header
   -- should choose compression based on headers of requestArray
   if pSendCompressed is true then
      put CRLF & "Content-Encoding: gzip" after someHeader
      put compress (contentToSend) into contentToSend
   end if
   
   _AddContentLengthHeader someHeader, contentToSend
   daemon_SendRaw someHeader, contentToSend, socketID
   return the result
end daemon_Send

command daemon_SendCompressed someHeader, contentToSend, socketID
   -- always adds "Content-Length:" header
   put CRLF & "Content-Encoding: gzip" after someHeader
   put compress (contentToSend) into compressedData
   
   _AddContentLengthHeader someHeader, compressedData
   
   daemon_SendRaw someHeader, compressedData, socketID
   return the result
end daemon_SendCompressed

command daemon_SendSimple someHeader, contentToSend, socketID
   -- always adds "Content-Length:" header
   _AddContentLengthHeader someHeader, contentToSend
   
   daemon_SendRaw someHeader, contentToSend, socketID
   return the result
end daemon_SendSimple

command daemon_SendRaw someHeader, contentToSend, socketID
   -- everything should use this to send (so it can be trapped by middleware for logging etc)
   put someHeader & CRLF & CRLF & contentToSend into headersAndContent
   write headersAndContent to socket socketID
   return headersAndContent
end daemon_SendRaw


--> Dameon | Send | And Close
-
command daemon_SendOK socketOrRequestArray, contentToSend, pContentType, pCookieName, pCookieValue
   -- sends output back to the browser
   if socketorRequestArray is an array then
      put socketorRequestArray ["socketID"] into socketID
   else
      put socketorRequestArray into socketID
   end if
   put _OkHeaders (pContentType, pCookieName, pCookieValue) into someHeader
   daemon_SendAndCloseSocket someHeader, contentToSend, socketID
end daemon_SendOK

command daemon_SendAndCloseSocket someHeader, contentToSend, socketID
   -- always adds "Content-Length:" header
   _AddContentLengthHeader someHeader, contentToSend
   put someHeader & CRLF & CRLF & contentToSend into headersAndContent
   daemon_RawSendAndClose headersAndContent, socketID
end daemon_SendAndCloseSocket

command daemon_RawSendAndClose headersAndContent, socketID
   write headersAndContent to socket socketID
   close socket socketID
end daemon_RawSendAndClose


--> Dameon | Headers
-
command daemon_StripDefaultHeadersFromArray @headerArray
   put daemon_ConstructDefaultHeader() into defaultHeaderArray
   delete variable defaultHeaderArray ["Content-Type"]
   repeat for each key someKey in defaultHeaderArray
      delete variable headerArray [someKey]
   end repeat
   
   set the itemdelimiter to "/"
   repeat for each key someKey in headerArray
      if item 1 of someKey = "HTTP" then
         delete variable headerArray [someKey]
      end if
   end repeat
   put "Block Daemon" into  headerArray ["X-Powered-By"]
end daemon_StripDefaultHeadersFromArray

function daemon_ConstructDefaultHeader
   put "text/html" into headerArray ["Content-Type"] 
   put "*" into headerArray ["Access-Control-Allow-Origin"]
   put "Close" into headerArray ["Connection"]
   -- put the date & the time into headerArray ["Date"]
   put the internet date into headerArray ["Date"]
   -- _AddCacheHeader someHeader
   -- put "public, max-age=0" into headerArray ["Cache-Control"] after someHeader
   return headerArray
end daemon_ConstructDefaultHeader

function daemon_DeconstructHeaderArray headerArray
   combine headerArray with CRLF and ":"
   return headerArray
end daemon_DeconstructHeaderArray

function daemon_ConstructHeaderArray someHeaders, pFast
   if pFast is true then
      split someHeaders with CR and ":"
      return someHeaders
   end if
   
   set the itemdelimiter to ":"
   put quote & "'" into someQuotes
   repeat for each line headerLine in someHeaders
      put word 1 to -1 of item 1 of headerLine into headerKey
      put word 1 to -1 of item 2 of headerLine into headerValue
      if char 1 of headerValue is among the chars of someQuotes and char -1 of headerValue is among the chars of someQuotes then
         delete char 1 of headerValue
         delete char -1 of headerValue
      end if
      put headerValue into headerArray [headerKey]
   end repeat
   return headerArray
end daemon_ConstructHeaderArray


--> Private
-
private function _CacheRequestArray pSocketID
   -- doing this in advance of need for every request is slower than necessary
   put the itemdel into oDelim
   -- 
   put pSocketID into requestArray ["SocketID"] -- Store the socket id, we'll use that later for responding back to the browser
   put _DaemonServer() into requestArray ["daemonServer"] -- store as it is the only way to reference the daemon_Server instance
   
   put SocketData [pSocketId]["request"] into someRequest
   put word 1 to -1 of SocketData [pSocketId]["headers"] into requestArray ["receivedHeaders"]
   
   put word 1 of someRequest into someMethod
   put someMethod into requestArray ["Request Method"]
   put SocketData [pSocketId]["theData"] into requestArray ["theData"]
   
   put word 2 of someRequest into requestUrl
   put requestUrl into requestArray ["Requested URL"]
   
   set the itemdel to "?"
   put item 1 of requestUrl into requestArray ["SCRIPT_NAME"]
   put item 2 of requestUrl into queryString
   put queryString into requestArray ["QUERY_STRING"]
   
   put "&" & queryString into tVarsA
   split tVarsA by "&" and "="
   repeat for each line tKey in the keys of tVarsA
      if tKey is empty then next repeat
      put tVarsA [tKey] into varValue
      put urldecode (varValue) into requestArray ["queryArray"][tKey]
   end repeat
   set the itemdel to oDelim
   
   _SetEnvironmentalVariables requestArray
   return requestArray
end _CacheRequestArray

private function _RedirectionHeaders redirectURL
   if pContentType is empty then put "text/html" into pContentType
   
   put "HTTP/1.1 307 redirect" into someHeader
   _AddContentTypeHeader someHeader, "text/html"
   put CRLF & "Location:" && redirectURL after someHeader
   _AddConnectionHeader someHeader
   _AddCorsHeader someHeader
   _AddDateHeader someHeader
   return someHeader
end _RedirectionHeaders

private function _NotFoundHeaders
   put "HTTP/1.1 404 Error: 404" into someHeader
   _AddContentTypeHeader someHeader, "text/html"
   _AddCorsHeader someHeader
   _AddKeepAliveHeader someHeader
   return someHeader
end _NotFoundHeaders

private function _MovedTemporarilyHeaders locationURL
   put "HTTP/1.1 302 Moved Temporarily" into someHeader
   _AddContentTypeHeader someHeader, "text/html"
   put CRLF & "Location:" && locationURL after someHeader
   put CRLF & "Vary: Accept" after someHeader
   _AddConnectionHeader someHeader
   _AddCorsHeader someHeader
   _AddDateHeader someHeader
   return someHeader
end _MovedTemporarilyHeaders


--> Dameon | HTTP | Header | Utitlities
-
/*
These handlers help construct http headers.
Handlers that begin with _Add assume a header is not empty
ie there is is at least one line in an existing header, then they add to it
*/

private function _CustomHeaders httpStatusCode, contentToSend, httpStatusMessage
   -- Function that generates custom headers, like redirections and errors. Helper function to generate custom httpd headers.
   -- see https://en.wikipedia.org/wiki/List_of_HTTP_status_codes
   put "HTTP/1.1" && httpStatusCode && httpStatusMessage into someHeader
   _AddContentTypeHeader someHeader, "text/html"
   _AddCorsHeader someHeader
   _AddContentLengthHeader someHeader, contentToSend
   return someHeader
end _CustomHeaders

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


--> Dameon | Utilis
-
private function _NormalizeSocket socketorRequestArray
   -- sends output back to the browser
   if socketorRequestArray is an array then
      put socketorRequestArray ["socketID"] into socketID
   else
      put socketorRequestArray into socketID
   end if
   return socketID
end _NormalizeSocket

private command _SetEnvironmentalVariables requestArray
   -- not vital (check them???)
   -- must happen after "_CacheRequestArray"
   put "LiveDaemon" into $SERVER_SOFTWARE
   put the daemon_Port of me into $SERVER_PORT
   put requestArray ["SCRIPT_NAME"] into $SCRIPT_NAME
   put requestArray ["QUERY_STRING"] into $QUERY_STRING
end _SetEnvironmentalVariables

command _CleanSocketData pSocketId
   /*
   Clean out SocketData of any partial connection data that is older than the 'on newConnection' dropDelay number of seconds.
   If the connection to RevHTTPd does not complete but there has been some data stored in this array, this routine finds it and deletes it when it is too old.
   Otherwise SocketData could fill up and use up all available memory until Revolution dies.
   */
   -- and remove this connection data from local variable SocketData (otherwise it will look like a memory leak)
   delete variable SocketData [pSocketId]
   
   repeat for each key someSocketID in SocketData
      put SocketData [someSocketID]["theSeconds"] into timeToKill
      put the seconds into theSeconds
      if timeToKill < theSeconds then
         delete variable SocketData [someSocketID]
      end if
   end repeat
end _CleanSocketData

private command _NormalizeDaemonPort @pPortToListenOn
   if pPortToListenOn is a number then
      set the daemon_Port of me to pPortToListenOn
   else
      put the daemon_Port of me into pPortToListenOn
   end if
end _NormalizeDaemonPort

private function _DaemonServer
   return the long id of me
end _DaemonServer

private function _DaemonRouter
   -- this allows dispatching to any control in the Livecode environment and does not bug out
   -- check if dispatching is significantly slower than using the message hierarchy
   
   put the daemon_Router of me into routerObject
   if exists (routerObject) is false then put the long id of me into routerObject
   return routerObject
end _DaemonRouter

private function _DaemonIsRunning
   put daemon_GetPort() into portToListenOn
   get the opensockets
   put portToListenOn is among the lines of it into daemonIsRunning
   return daemonIsRunning
end _DaemonIsRunning


--> Deps
-
function json_FromArray pArray, pForceRootType, pPretty
   -- put jsonExport (pArray) into someJSON -- not the same
   
   repeat for each key tKey in pArray
      if pArray[tKey] is an array then
         put "}"&json_FromArray(pArray[tKey]) into pArray[tKey]
      end if
   end repeat
   return (mergJSONEncode("pArray",pForceRootType,pPretty))
end json_FromArray

function json_ToArray pJSON
   local tArray,tKeys
   if pJSON is empty then return false
   -- put jsonImport (pJSON) into tArray -- not the same
   
   try -- as otherwise an error with non-json causes script to exit
      if pJSON is empty then return empty
      repeat for each line tKey in mergJSONDecode(pJSON,"tArray")
         put json_ToArray(tArray[tKey]) into tArray[tKey]
      end repeat
      return tArray
   catch e
      return empty
   end try
end json_ToArray
