script "behavior_DaemonLog"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_DaemonLog
type: behavior
version: 0.2

/* This stack contains handlers to log LiveDaemon server events.

We can neatly add or remove logging these events by adding or removing this script from the behavior chain.
This keeps the lib_Daemon serve scripts clean and minimal.
You can also speeds up the server by removing all the logging with one command and no ifs

See also stack lib_Log.*/


--> Variables
-

--> Working on
-
-- before processRequest pSocketID, theData
set the log_Line [word 1 of the params] of me to someRoute
end processRequest

before save_AfterAction wikiDomain, pageSlug, pageArray, actionArray
   set the log_Line [word 1 of the params] of me to wikiDomain,pageSlug
end save_AfterAction

--> GET
-
-- before route_GET someRoute, socketID, requestArray
set the log_Line [word 1 of the params] of me to someRoute
route_GET

-- before get_SiteMapJson wikiDomain, socketID
set the log_Line [word 1 of the params] of me to wikiDomain
end get_SiteMapJson

-- before get_SiteIndexJson wikiDomain, socketID
set the log_Line [word 1 of the params] of me to wikiDomain
get_SiteIndexJson

before get_Image shortImageFile, wikiDomain, socketID, requestArray
   put wikiFile_ConstructImageAsset (shortImageFile, wikiDomain) into imageFile
   put daemon_ReceivedHeader ("Referer", requestArray) into sReferer -- can we use this to find the image better
   set the itemdelimiter to slash
   put item -2 to -1 of sReferer into lastBit
   --
   put shortImageFile,wikiDomain,lastBit into logComment
   set the log_Line [word 1 of the params] of me to logComment
end get_Image

-- before daemon_SendImage socketorRequestArray, someImage, pImageType, pSendCompressed
put someImage,pImageType into logComment
set the log_Line [word 1 of the params] of me to logComment
end daemon_SendImage

before get_WikiClientJsMap someRoute, socketID
   set the log_Line [word 1 of the params] of me to someRoute
end get_WikiClientJsMap

before get_RecycledSlugsJson requestArray, socketID
   set the log_Line [word 1 of the params] of me to someRoute
end get_RecycledSlugsJson

before get_PluginJavascriptMap pluginName, shortFile, socketID
   set the log_Line [word 1 of the params] of me to pluginName && shortFile
end get_PluginJavascriptMap

before get_PluginPageJson pluginName, pageSlug, socketID
   set the log_Line [word 1 of the params] of me to pluginName && pageSlug
end get_PluginPageJson

before get_PluginJavascript pluginName, shortJavascriptFile, socketID
   set the log_Line [word 1 of the params] of me to pluginName && shortJavascriptFile
end get_PluginJavascript

before route_PUT someRoute, socketID, requestArray
   set the log_Line [word 1 of the params] of me to someRoute
end route_PUT


--> Action
-
before action_Move pageSlug, wikiDomain, actionArray
   set the log_Line [word 1 of the params] of me to pageSlug,wikiDomain
end action_Move

before action_RemoveItem pageSlug, wikiDomain, actionArray
   -- breakpoint
   set the log_Line [word 1 of the params] of me to pageSlug,wikiDomain
end action_RemoveItem

before action_AddItem pageSlug, wikiDomain, actionArray
   -- breakpoint
   set the log_Line [word 1 of the params] of me to pageSlug,wikiDomain
end action_AddItem


--> Route
-
before route_POST someRoute, socketID, requestArray
   set the log_Line [word 1 of the params] of me to someRoute
end route_POST

before route_DELETE someRoute, socketID, requestArray
   set the log_Line [word 1 of the params] of me to someRoute
end route_DELETE

before route_Plugin someRoute, socketID, requestArray
   set the log_Line [word 1 of the params] of me to someRoute
end route_Plugin

before undefined_Action socketID, someRoute, requestArray, pageSlug, wikiDomain, actionArray
   set the log_Line [word 1 of the params] of me to someRoute
end undefined_Action

before undefined_Put socketID, someRoute, requestArray, pageSlug, wikiDomain, actionArray
   set the log_Line [word 1 of the params] of me to someRoute
end undefined_Put

before undefined_Get socketID, someRoute, requestArray, pageSlug, wikiDomain, actionArray
   set the log_Line [word 1 of the params] of me to someRoute
end undefined_Get


--> Props
-
after daemon_Start
   set the log_Text of me to empty
   set the log_Line ["Server started. Using port"] of me to the daemon_Port of me
   --
   set the log_Hilite of me to true
   --
   put the daemon_Port of me into portToListenOn
   return portToListenOn
end daemon_Start

after daemon_Stop
   set the log_Line ["Server stopped. Closed port"] of me to the daemon_Port of me
   
   get the opensockets
   if it is empty then
      set the log_Line of me to "Great, there are no sockets open!"
   else
      replace CR with ", " in it
      set the log_Line ["There are still some open sockets"] of me to it
   end if
   --
   set the log_Hilite of me to false
end daemon_Stop

before daemon_SetPort
   put the daemon_Port of me into oldPort
   --
   set the log_Line ["User changed server port from:"] of me to oldPort
   if the daemon_IsRunning of me is true then
      set the log_Line of me to "Stopping server..."
   end if
end daemon_SetPort

after daemon_SetPort
   if the daemon_IsRunning of me is true then
      set the log_Line ["Starting server listening on port"] of me to the daemon_Port of me
   end if
end daemon_SetPort


--> Daemon | Before and Afters
-
before daemon_SendNotFound socketID, pLogComment
   put _GetSocketArray (socketID) into sArray
   put sArray ["theSeconds"] into tSeconds
   put sArray ["theData"] into tData
   put sArray ["request"] into tRequest
   put sArray ["headers"] into tRequestHeaders
   put sArray ["theTarget"] into tObject
   
   -- Site-index.json not found for: map.fedwiki.org
   switch word 1 of pLogComment
      case "Site-index.json"
         break
      default
         set the log_Line [word 1 of the params] of me to pLogComment
   end switch
end daemon_SendNotFound

before daemon_SendRedirect redirectURL, socketID, pDescriptiveContent
   set the log_Line [word 1 of the params] of me to redirectURL
end daemon_SendRedirect

before daemon_SetPort
   set the log_Line ["User changed server port to"] of me to the daemon_Port of me 
   set the log_Line of me to "Stopping server..."
end daemon_SetPort


--> Daemon | Log | lib_DaemonRouter
-
/*
These handlers wrap similar handlers in lib_Daemon to add logging to them.
It requires this stack to be set as a behavior of lib_Daemon.
*/


--> Daemon | Log | lib_DaemonRouter
-
/*
These handlers wrap similar handlers in lib_Daemon to add logging to them.
It requires this stack to be set as a behavior of lib_Daemon.
*/


--> Daemon | Logging | lib_Daemon
-
/*
These handlers wrap similar handlers in lib_Daemon to add logging to them.
It requires this stack to be set as a behavior of lib_Daemon.
*/


--> Private
-
private function _GetSocketArray socketID
   put daemon_GetSocketData() into sData
   put sData [socketID] into socketArray
   return socketArray
end _GetSocketArray
