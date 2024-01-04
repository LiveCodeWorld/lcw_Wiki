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
