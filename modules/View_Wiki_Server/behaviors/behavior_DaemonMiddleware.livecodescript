script "behavior_DaemonMiddleware" with behavior "behavior_WikiRouter"
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


--> Before and Afters
-
before daemon_SendNotFound socketID
   -- put daemon_GetSocketData() into SocketData
   -- put SocketData [socketID] into socketArray
   -- dameon_AddToMiddlewareArray socketArray, "Not Found"
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

before daemon_SetPort
   daemon_Log ("User changed server port to:" && pNewPort)
   daemon_Log "Stopping server..."
end daemon_SetPort

after daemon_SetPort
   daemon_Log ("Starting server listening on port:" && pNewPort)
end daemon_SetPort

before daemon_Start
   set the log_View of the target to view_GetTemplateObject ("View|Wiki|Server")
end daemon_Start

after daemon_Start
   daemon_Log ("Server started. Using port:" && the daemon_Port of me)
end daemon_Start


--> Utils
-
command dameon_AddToMiddlewareArray requestArray
   put the number of lines of the keys of MiddlewareArray + 1 into newIndexNum
   put the milliseconds into requestArray ["milliseconds"]
   put requestArray into MiddlewareArray [newIndexNum]
   -- daemon_Log ("Got something and added it to: MiddlewareArray [" && someLabel & "]")
end dameon_AddToMiddlewareArray

command middleware_DeleteArray
   -- delete variable MiddlewareArray
end middleware_DeleteArray

function middleware_GetArray
   return MiddlewareArray
end middleware_GetArray
