script "behavior_DaemonLog"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_DaemonLog
type: behavior
version: 0.1

/*This stack contains handlers to log LiveDaemon server events.

We can neatly add or remove logging these events by adding or removing this script from the behavior chain.
This keeps the lib_Daemon serve scripts clean and minimal.
You can also speeds up the server by removing all the logging with one command and no ifs.*/


--> Working on
-

--> Props
-
getprop log_Hilite
   return the hilite of _ToggleButton()
end log_Hilite

setprop log_Hilite sBoolean
   set the hilite of _ToggleButton() to sBoolean is true
end log_Hilite

getprop live_Logging
   return LiveLogging is true
end live_Logging

setprop live_Logging someBoolean
   put someBoolean is true into LiveLogging
   return return
end live_Logging


--> Daemon
-
command daemon_LogClear
   put _LogField()into logField
   set the text of logField to empty
end daemon_LogClear

command daemon_Log logLine, pDisplayNow, pLogName
   -- do without if not needed by the scripts below
   if pLogName is empty then put the live_Logging of me into displayLogNow
   
   log_SetTimeStampEntry logLine, pLogName
   --
   put _LogField()into logField
   put the short id of logField into fieldID
   put logLine & CR after field id fieldID of me
   --
   return logLine
end daemon_Log

function daemon_LogArrayFile
   breakpoint
   put the stack_Folder of me into sFolder
   put sFolder & "log.array" into someFile
   return someFile
end daemon_LogArrayFile


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

--> Damon | Log
-
command daemon_LogUnRouted requestArray, pLogLine
   switch
      case requestArray = "delete"
         daemon_DeleteLogArray
         break
      case requestArray = "start"
         daemon_DeleteLogArray
         break
      case requestArray = "stop"
         daemon_DisplayLogArray
         break
      case requestArray is an array
         daemon_AddRequestToLogArray requestArray
         if  pLogLine is not empty then
            daemon_Log "daemon_LogUnRouted" && pLogLine
         end if
         break
   end switch
end daemon_LogUnRouted


--> Daemon | Log | Display
-
command daemon_DisplayLogArray
   put daemon_FetchLogArray() into logArray
   display_Array logArray, "daemon_DisplayLogArray"
   display_SetInteractions the result, "Daemon | Log"
end daemon_DisplayLogArray

command daemon_AddRequestToLogArray requestArray
   put daemon_FetchLogArray() into dataArray
   put item 2 of the extents of dataArray + 1 into indexNum
   put requestArray into dataArray [indexNum]
   daemon_StoreLogArray dataArray
end daemon_AddRequestToLogArray

function daemon_FetchLogArray
   put daemon_LogArrayFile() into someFile
   put array_Fetch (someFile) into dataArray
   return dataArray
end daemon_FetchLogArray

command daemon_StoreLogArray dataArray
   put daemon_LogArrayFile() into someFile
   array_Save someFile, dataArray
   return someFile
end daemon_StoreLogArray

command daemon_DeleteLogArray
   put daemon_LogArrayFile() into someFile
   delete file someFile
   return someFile
end daemon_DeleteLogArray


--> Daemon | Log | Objects
-
private function _ToggleButton
   return the long id of btn 1 of me
end _ToggleButton

private function _LogField
   return the long id of fld 1 of me
end _LogField

getprop log_View
   return _LogField()
end log_View
