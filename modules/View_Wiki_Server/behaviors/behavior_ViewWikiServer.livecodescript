script "behavior_ViewWikiServer" with behavior "behavior_Daemon"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_ViewWikiServer
type: behavior
version: 0.1

/*
You dont have to use separate middleware. 
You can put these "before" and "after" handlers anywhere in the behavior_Hirarchy

This script is designed to be a behavior for a Live Daemon server.
By default it should be a behavior of the Daemon Server stack.
So the hiierarchy goes: server stack => lib_DaemonMiddleware => lib_DaemonRouter => lib_DaemonServer => lib_DaemonLog => lib_Log

However this hiierarchy can be altered using "server_SetBehaviorHierarchy" in the server stack,
which will override the handler of the same name in the lib_DaemonServer stack.
*/


--> Working on
-
-- after process_GET someRoute, socketID, requestArray
switch someRoute
   case "/"
      put daemon_HostFromRequest (requestArray) into fromHost
      daemon_Log "process_GET" && someRoute && fromHost
      break
   case "/favicon.ico"
      put daemon_HostFromRequest (requestArray) into fromHost
      daemon_Log "process_GET" && someRoute && fromHost
      break
   default
      daemon_Log "process_GET" && someRoute
end switch
end process_GET

before daemon_SetPort
   put the daemon_Port of me into oldPort
   --
   daemon_Log ("User changed server port from:" && oldPort)
   if the daemon_IsRunning of me is true then
      daemon_Log "Stopping server..."
   end if
end daemon_SetPort

after daemon_SetPort
   put the daemon_Port of me into newPort
   --
   if the daemon_IsRunning of me is true then
      daemon_Log "Starting server..."
      daemon_Log ("Listening on port:" && newPort)
   end if
end daemon_SetPort


--> Events
-
on preOpenControl
   set the behavior_StackNames of me to "behavior_ViewWikiServer,behavior_Daemon,behavior_DaemonMiddleware,behavior_WikiRouter,behavior_DaemonLog"
   dispatch "daemon_LogClear" to me
end preOpenControl

on mouseUp
   switch word 1 of the target
      case "button"
         if the hilite of the target is true then
            daemon_Start
         else
            daemon_Stop the shiftkey is "Down"
         end if
         break
      default
   end switch
end mouseUp

on resizeControl
   put the rect of me into viewRect
   LayoutControl viewRect
end resizeControl

command LayoutControl pRect
   lock screen
   if pRect is empty then put the rect of me into pRect
   
   # Get button topleft
   put the inner_Rect [pRect] of me into innerRect
   put item 1 to 2 of innerRect into btnTopLeft
   
   # Get fieldRect
   put innerRect into fieldRect
   add 30 to item 2 of fieldRect
   
   set the topleft of _ToggleButton() to btnTopLeft
   set the rect of _LogField() to fieldRect
   unlock screen
end LayoutControl


-- Variables
-
local MiddlewareArray


--> Start and Stop
-
before daemon_Start
   -- set the log_View of the target to view_GetTemplateObject ("View|Wiki|Server")
   daemon_LogClear
end daemon_Start

after daemon_Start
   daemon_Log ("Server started. Using port:" && the daemon_Port of me)
   --
   set the log_Hilite of me to true
end daemon_Start

after daemon_Stop
   daemon_Log ("Server stopped. Closed port:" && the daemon_Port of me)
   get the opensockets
   if it is empty then
      daemon_Log ("Great, there are no sockets open!")
   else
      replace CR with ", " in it
      daemon_Log ("There are still some open sockets:" && it)
   end if
   --
   set the log_Hilite of me to false
end daemon_Stop


--> Before and Afters
-
before processRequest pSocketID, theData
   -- daemon_Log ("Processing:" && theData)
end processRequest

before daemon_SendNotFound socketID
   put daemon_GetSocketData() into SocketData
   put SocketData [socketID] into socketArray
   -- dameon_AddToMiddlewareArray socketArray, "Not Found"
   ---
   daemon_Log ("daemon_SendNotFound:" && theData)
end daemon_SendNotFound

before process_UnGot socketID, someRoute, routeData, requestArray
   dameon_AddToMiddlewareArray requestArray, "UnGot"
end process_UnGot

before process_GET someRoute, socketID, requestArray
   daemon_Log ("Getting:" && someRoute)
   -- dameon_AddToMiddlewareArray requestArray, "process_GET"
end process_GET

before daemon_SendRedirect redirectURL, socketID, pDescriptiveContent
   daemon_Log ("daemon_SendRedirect:" && socketID)
end daemon_SendRedirect


--> Utils
-
command dameon_AddToMiddlewareArray requestArray
   put the number of lines of the keys of MiddlewareArray + 1 into newIndexNum
   put the milliseconds into requestArray ["milliseconds"]
   put requestArray into MiddlewareArray [newIndexNum]
   -- daemon_Log ("Got something and added it to: MiddlewareArray [" && someLabel & "]")
end dameon_AddToMiddlewareArray

command middleware_DeleteArray
   delete variable MiddlewareArray
end middleware_DeleteArray

function middleware_GetArray
   return MiddlewareArray
end middleware_GetArray


--> Private
-
private function _ToggleButton
   return the long id of btn 1 of me
end _ToggleButton

private function _LogField
   return the long id of fld 1 of me
end _LogField


--> Objects
-
getprop daemon_Server
   /*
   This is the control (often a stack) that is an instance of a particular server.
   Attached to this object is a chain of behaviors that implement the generic daemon server functionality.
   
   You customise the server by:
   
   1) Adding scripts to the daemon_Server
   2) Dropping in on wrting your own custom daemon_RouterLibrary
   3) Messing with the behavior_Hierarchy of the daemon_Server
   */
   return the long id of me
end daemon_Server

getprop view_Object
   return the long id of me
end view_Object
