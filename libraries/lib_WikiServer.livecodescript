script "lib_WikiServer"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_WikiServer
type: library
version: 0.1

/*
This library is for starting and stoping the wiki-server.
There are currently two versions the node-server and the live-server.
*/


--> Variables
-
local WikiServer_SecurityType
local WikiServer_NodePort


--> Working on
-   
function wikiServer_NodeIsRunning
   return wikiServer_ListProcessIds() is not empty
   -- return "wiki" is among the lines of the openprocesses
end wikiServer_NodeIsRunning

function wikiServer_ListProcessIds
   -- put "wiki --security_legacy" into wikiCommand
   put ps_Grep ("wiki") into pids
   return pids
end wikiServer_ListProcessIds

private function ps_Grep pCommand
   put "grep" && pCommand into grepCommand
   put "ps aux |" && grepCommand into someShell
   put shell (someShell) into shellResult
   --
   repeat for each line sLine in shellResult
      if word -2 to -1 of sLine = grepCommand then next repeat
      --
      put word 2 of sLine into pid
      put pid & comma after pids
   end repeat
   delete char -1 of pids
   return pids
end ps_Grep


--> Wikiserver
-
function wikiServer_DefaultPort
   -- put the daemon_Port of pWikiServer into pPort
   return 9090
end wikiServer_DefaultPort

function wikiServer_View pPort
   if pPort is empty then
      put view_GetTemplateObject ("View|Wiki|Server") into wsView
      return wsView
   else
      put wikiServer_GetData() into wsData
      repeat for each key wsView in wsData
         put wsData [wsView]["port"] into sPort
         if sPort = sPort then
            return wsView
         end if
      end repeat
      return empty
   end if
end wikiServer_View

command wikiServer_CloseServerWithPort pPort
   put wikiServer_View (pPort) into wsView
   if exists (wsView) then
      set the daemon_IsRunning of wsView to false
      return wsView
   else
      return empty
   end if
end wikiServer_CloseServerWithPort

function wikiServer_OnlyIsRunning
   get the opensockets
   if 80 is not among the lines of it then return false
   
   put wikiServer_GetData() into wsData
   if item 2 of the extents of wsData = 1 then
      put wsData [1]["port"] into onlyPort
      return onlyPort = 80
   end if
   
   -- put wikiServer_ListObjects() into serverObjects
   return true
end wikiServer_OnlyIsRunning

function wikiServer_IsRunning
   put wikiServer_ListObjects() into serverObjects
   put serverObjects is not empty into isRunning
   return isRunning
end wikiServer_IsRunning

function wikiServer_ProxyFarmIsRunning
   put caddy_IsRunning() AND wikiServer_NodeIsRunning() AND wikiServer_IsRunning() into sBoolean
   return sBoolean
end wikiServer_ProxyFarmIsRunning

command toggleServer_LiveOnly
   if wikiServer_OnlyIsRunning() then
      wikiServer_StopLive
   else
      wikiServer_StopAll
      wikiServer_StartLive 80
   end if
end toggleServer_LiveOnly

command toggle_ProxyFarm
   if wikiServer_ProxyFarmIsRunning() is not false then
      wikiServer_StopAll
   else
      try
         wikiServer_StartLocalProxy
      catch e
         breakpoint
      end try
   end if
end toggle_ProxyFarm

command toggleServer_BetweenLiveAndNode
   breakpoint -- this toggles between live and node
   switch
      case wikiServer_NodeIsRunning()
         wikiServer_StopNode
         wikiServer_StartLive
         break
      default
         wikiServer_StopLive
         wikiServer_StartNodeFarm
   end switch
end toggleServer_BetweenLiveAndNode

command toggleServer_Node
   if wikiServer_NodeIsRunning() then
      wikiServer_StopNode
   else
      wikiServer_StartNodeFarm
   end if
end toggleServer_Node

command toggleServer_Live
   if wikiServer_IsRunning() then
      wikiServer_StopLive
   else
      wikiServer_StartLive
   end if
end toggleServer_Live


--> WikiServer
-
command wikiServer_StartLocalProxy
   wikiServer_CloseServerWithPort 80
   --
   wikiServer_StartLive 9090
   wikiServer_StartNodeFarm 3000
   --
   caddy_Start
end wikiServer_StartLocalProxy

command wikiServer_StopAll
   if wikiServer_IsRunning() then wikiServer_StopLive
   if wikiServer_NodeIsRunning() then wikiServer_StopNode
   if caddy_IsRunning() then caddy_CloseServerProcesses
end wikiServer_StopAll

command wikiServer_RestartNode pNotify, pNotifyText
   # Stop
   wikiServer_StopNode
   
   # Reset just in case
   resetAll
   
   # Restart
   wikiServer_StartNodeFarm
   
   # Notify
   if pNotify is not false then
      if pNotifyText is empty then put "Restarted node wiki-server!" into pNotifyText
      lcw_Notify pNotifyText
   end if
   
   return serverObject
end wikiServer_RestartNode

command wikiServer_StartNode pDataFolder, pSecurityType, pFarm, pPort
   -- use "wikiServer_StartNodeFarm" instead
   put wikiServer_ListProcessIds() into wikiProcessIDs
   if wikiProcessIDs is not empty then return empty -- so we know already started
   --
   if pSecurityType is empty then put wikiServer_GetSecurityType() into pSecurityType
   --
   wiki_NormailzePort pPort
   if pPort is empty then put 80 into pPort
   --
   put wikiServer_ShellCommand (pSecurityType, pFarm, pPort, pDataFolder) into someShell
   put shell (someShell) into shellResult
   put word 2 of shellResult into wikiProcessID
   
   # Notify
   put "Started node server on port" && pPort  & ". Using socket" && wikiProcessID into sComment
   lcw_Notify sComment, "Node Server"
   
   # Indicate wiki starting up
   return wikiProcessID
end wikiServer_StartNode

function wikiServer_GetNodePort
   put WikiServer_NodePort into sPort
   if sPort is a number then
      return sPort
   else
      return 3000
      -- return 80
   end if
end wikiServer_GetNodePort

command wikiServer_SetNodePort sPort
   if sPort is a number then
      put sPort into WikiServer_NodePort
   else
      return "Error, sPort must be a valid port number:" && sPort
   end if
end wikiServer_SetNodePort

command wikiServer_SwitchIfGarden wikiDomain
   breakpoint
   put wikiGarden_Name (wikiDomain) into gardenName
   if gardenName is empty then return empty
   
   wikiServer_StopNode
   wikiGarden_StartNodeServer gardenName
   put the result into wikiProcessID
   return wikiProcessID
end wikiServer_SwitchIfGarden


--> WikiServer | Node
-
command wikiServer_StartNodeFarm pNodePort
   # Node Port
   if pNodePort is a number then
      wikiServer_SetNodePort pNodePort
   else
      put wikiServer_GetNodePort() into pNodePort
   end if
   
   put wikiServer_ListProcessIds() into wikiProcessIDs
   if wikiProcessIDs is not empty then
      ecoData_ConstructLoadAndStore
      put the result into ecoData
      
      # Notify
      put merge ("Node server already running [[wikiProcessIDs]]. Not starting another one.") into sComment
      lcw_Notify sComment, "Node Server"
      
      return wikiProcessIDs
   end if
   
   # Must have farmFolder properly set
   put wikiFarm_GetDefaultFolder() into farmFolder
   
   # Load ecodata from file
   ecoData_ConstructLoadAndStore farmFolder
   put the result into ecoData
   if item 1 of ecoData = "Error" then return ecoData
   
   # Quick Check
   if ecoData_Get() is not ecoData then
      breakpoint
   end if
   
   put wikiServer_ShellCommand ("friends", true, pNodePort, farmFolder) into someShell
   put shell (someShell) into shellResult
   put word 2 of shellResult into wikiProcessID
   
   if wikiProcessID is not a number then
      breakpoint
   end if
   
   # Notify
   put "Started node server in farm mode using port" && wikiProcessID into sComment
   lcw_Notify sComment, "Node Server"
   
   # Indicate wiki starting up
   return wikiProcessID
end wikiServer_StartNodeFarm

command wikiServer_StopNode pIDs
   if the platform = "MacOS" then
      if pIDs is not a number then
         put wikiServer_ListProcessIds() into pIDs
      end if
      --
      repeat for each item pID in pIDs
         kill process pID
      end repeat
      
      # Notify
      lcw_Notify "Closed node server!", "Node Server"
   else
      breakpoint
      close process wiki
   end if
end wikiServer_StopNode


--> WikiServer | Start
-
command wikiServer_StartLive pPort, pWikiServer
   -- tunnel_LaunchFromConfig
   if exists (pWikiServer) is false then put wikiServer_View() into pWikiServer
   
   if wikiServer_IsRunning() then
      put merge ("Live server already running. Not starting another one.") into sComment
      lcw_Notify sComment, "Live Server"
      return sComment
   end if
   
   # Get Port
   if pPort is empty then
      put wikiServer_DefaultPort() into pPort
   else
      wiki_SetPort pPort 
   end if
   
   # Stop servers
   put wikiServer_ListProcessIds() into nodeIds
   if pPort is among the lines of nodeIds then
      breakpoint
      wikiServer_StopNode
   end if
   
   # Set Port and Start
   -- dispatch "daemon_Start" to pWikiServer with pPort
   set the daemon_IsRunning [pPort] of pWikiServer to true
   
   # Load Gardens
   ecoData_SetFarmAndGardens
   
   # Notify
   put merge ("Started Live Server on port [[pPort]] and loaded farm and gardens!") into sComment
   lcw_Notify sComment, "Node Server"
   
   return pWikiServer
end wikiServer_StartLive

command wikiServer_StopLive pWikiServers, pCloseAll
   switch
      case pWikiServers is empty
      case pWikiServers = "All"
         put wikiServer_ListObjects() into pWikiServers
         break
      case exists (pWikiServers) is false
         put wikiServer_View() into pWikiServers
         break
   end switch
   
   repeat for each line pWikiServer in pWikiServers
      set the daemon_IsRunning of pWikiServer to false
   end repeat
   
   if pCloseAll is true then
      socket_CloseOpen
      resetAll
   end if
   
   # Notify
   lcw_Notify "Closed Live Server!", "Live Server"
   
   return pWikiServer
end wikiServer_StopLive

function wikiServer_GetFavicon wikiDomain
   put wikiFile_Favicon (wikiDomain) into faviconFile
   if there is a file faviconFile then
      put url ("binfile:" & faviconFile) into pngData
      return pngData
   else
      return empty
   end if
end wikiServer_GetFavicon

command wikiServer_SetFavicon wikiDomain, pngData
   put wikiFile_Favicon (wikiDomain) into faviconFile
   put pngData into url ("binfile:" & faviconFile)
   return faviconFile
end wikiServer_SetFavicon


--> WikiServer
-
function wikiServer_GetSecurityType
   if WikiServer_SecurityType is empty then put "friends" into WikiServer_SecurityType
   --
   return WikiServer_SecurityType
end wikiServer_GetSecurityType

command wikiServer_SetSecurityType securityType
   put securityType into WikiServer_SecurityType
end wikiServer_SetSecurityType

function wikiServer_ListSecurityTypes pPrettyMenu
   if pPrettyMenu is true then
      return "legacy,cookie,passport,-,friends"
   else
      return "legacy,cookie,passport,friends"
   end if
end wikiServer_ListSecurityTypes


--> WikiServer | Start
-
command wikiServer_StartWithXterm pXtermBrowser
   put wikiServer_TerminalCommand() into someShell -- not working with Shell
   --
   display_Xterm someShell, pXtermBrowser, "paste"
   return pXtermBrowser
end wikiServer_StartWithXterm

command wikiServer_Restart pNotify, pNotifyText
   if pNotify is not false then
      if pNotifyText is empty then put "Restarted wiki server!" into pNotifyText
      lcw_Notify pNotifyText
   end if
   
   put wikiServer_View() into serverObject
   set the daemon_IsRunning of serverObject to false
   resetAll
   set the daemon_IsRunning of serverObject to true
   return serverObject
end wikiServer_Restart


--> WikiPage | Default
-
command wikiServer_CopyHomeToDefault wikiDomain, pForkDomains
   wikiServer_CopyPageToDefault wikiDomain, "welcome-visitors", pForkDomains
end wikiServer_CopyHomeToDefault

command wikiServer_CopyPageToDefault wikiDomain, pageSlug, pForkDomains
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   pageArray_StripJournal pageArray
   pageArray_AddFork pageArray, pForkDomains
   --
   wikiServer_SetPageArray pageArray
   return the result
end wikiServer_CopyPageToDefault


--> WikiServer | Shell
-
function wikiServer_ShellCommand pSecurityType, pFarm, pPort, pDataFolder, pLog, pWithNvm
   put wikiServer_StartNodeCommand (pSecurityType, pFarm, pLog, pPort, pDataFolder, pWithNvm) into someShell
   
   put "/usr/bin/nohup" & space before someShell
   
   -- shell_WrapNohup someShell, pLog
   
   # Add redirect output bit (log if needed)
   put _RedirectBit (pLog) into reDirectOutput
   put space & reDirectOutput after someShell
   put space & "jobs -l" after someShell
   
   -- shell_AddSource someShell
   put "source ~/.zshrc;" before someShell
   --
   return someShell
end wikiServer_ShellCommand


--> Private | WikiServer | Shell
-
private function _NodeShell pWithNvm
   if pWithNvm is true then
      return nvm_GetBin()
   else
      return "wiki"
   end if
end _NodeShell

private command _AddDataFolder @someShell, pDataFolder
   if pDataFolder is not empty then
      replace "~/" with ($HOME & slash) in pDataFolder
      put space & "--data" && kwote (pDataFolder) after someShell
   end if
end _AddDataFolder

private command _AddSecurityType @someShell, pSecurityType
   # Add authentication
   switch pSecurityType
      case "legacy"
      case empty
         put " --security_legacy" after someShell
         break
      case "friends"
         put " --security_type friends" after someShell
         --
         put "earth" into sCookieSecret
         put space & "--cookieSecret" && sCookieSecret after someShell
         --
         put space & "--session_duration 9999" after someShell
         break
      default
         put " --security_type" && pSecurityType after someShell
   end switch
end _AddSecurityType

private command _AddAdmin @someShell
   put space & "--admin" && "david.bovill@gmail.com" after someShell
end _AddAdmin

private command _AddFarm @someShell, pFarm
   if pFarm is not false then
      put space & "--farm" after someShell
   end if
end _AddFarm

private command _AddPort @someShell, pPort
   if pPort is empty then
      put space & "--port 80" after someShell
   else
      put space & "--port" && pPort after someShell
   end if
end _AddPort

function wikiServer_StartNodeCommand pSecurityType, pFarm, pLog, pPort, pDataFolder, pWithNvm
   put _NodeShell (pWithNvm) into someShell
   
   _AddSecurityType someShell, pSecurityType
   _AddAdmin someShell
   _AddFarm someShell, pFarm
   _AddPort someShell, pPort
   _AddDataFolder someShell, pDataFolder
   --
   return someShell
end wikiServer_StartNodeCommand

function wikiServer_TerminalCommand
   -- Work with Terminal but exits when using shell()
   put "wiki --security_legacy" into someShell
   
   # Redirect output
   put  space & _PipeToNothing() after someShell
   
   # Background and return jobs
   -- put wikiBit && "& sleep 1; jobs -l" into someShell
   put space & _BackgroundSleep() after someShell
   put space & _ReturnJobs() after someShell
   --
   return someShell
end wikiServer_TerminalCommand


--> Private
-
private function _PipeToNothing
   return "> /dev/null 2>&1 < /dev/null"
end _PipeToNothing

function _RedirectBit pLog
   -- put "> /dev/null 2>&1 < /dev/null" into reDirectOutput
   if pLog is true then
      put "> nohup.out 2> error.log &" after reDirectOutput
   else
      put "> /dev/null 2>&1 &" after reDirectOutput
   end if
   return reDirectOutput
end _RedirectBit

private function _BackgroundSleep
   return "& sleep 1"
end _BackgroundSleep

private function _ReturnJobs
   return "; jobs -l"
end _ReturnJobs

private function _ParseWikiShellResult shellResult, pWikiBit
   -- [1]+ 49160 Done(127)               wiki --security_legacy > /dev/null 2>&1 < /dev/null
   
   if pWikiBit is empty then
      put "wiki --security_legacy > /dev/null 2>&1 < /dev/null" into pWikiBit
   end if
   put lineOffset (wikiBit, shellResult) into lineNum
   put word 2 of line lineNum of shellResult into pid
   return pid
end _ParseWikiShellResult
