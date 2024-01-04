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
getprop log_Text
   put _LogField() into logField
   put the text of logField into logText
   return logText
end log_Text

setprop log_Text logText
   put _LogField() into logField
   set the text of logField to logText
end log_Text

setprop log_Line [pLogName] logLine 
   put the short id of _LogField() into fieldID
   -- put log_ConstructEntry (logLine, pLogName, true) into logLine
   if pLogName is not empty then
      put pLogName & ": " before logLine
   end if
   --
   get word 1 to -1 of line 1 of logLine
   put it & CR after field id fieldID of me
   --
   return logLine
end log_Line

getprop log_Hilite
   return the hilite of _ToggleButton()
end log_Hilite

setprop log_Hilite sBoolean
   set the hilite of _ToggleButton() to sBoolean is true
end log_Hilite


--> Events
-
on preOpenControl
   set the behavior_StackNames of me to "behavior_ViewWikiServer,behavior_Daemon,behavior_DaemonMiddleware,behavior_WikiRouter,behavior_DaemonLog"
   set the log_Text of me to empty
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
getprop log_View
   return _LogField()
end log_View

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
