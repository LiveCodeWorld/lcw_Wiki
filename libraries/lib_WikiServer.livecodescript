script "lib_WikiServer"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_WikiServer
type: library
version: 0.1

/*Some help*/


--> Variables
-
local WikiServer_SecurityType


--> Working on
-
command display_ServerData
   put wikiServer_GetData() into wsData
   display_Array wsData, "WikiServer_Data", "Wiki"
   put the result into dView
   return dView
end display_ServerData


--> WikiServer
-
function wikiServer_GetSecurityType
   if WikiServer_SecurityType is empty then put "legacy" into WikiServer_SecurityType
   --
   return WikiServer_SecurityType
end wikiServer_GetSecurityType

command wikiServer_SetSecurityType securityType
   put securityType into WikiServer_SecurityType
end wikiServer_SetSecurityType


--> WikiServer | Create
-
command wikiServer_Create wikiDomain
   # Create folders in wikiFolder of default farm
   put wikiFolder_ConstructFromFarm (wikiDomain) into wikiFolder
   --
   repeat for each item shortFolder in "pages,recycle,status"
      put wikiFolder & shortFolder & slash into sFolder
      folder_CreateNested sFolder
   end repeat
   
   # Create Image and Assets folders
   put wikiFolder & "assets/plugins/image" & slash into sFolder
   folder_CreateNested sFolder
   
   # Add domain to /etc/hosts
   put system_GetAdminPassword() into systemPassword
   hosts_Add wikiDomain, systemPassword
   
   # Create files
   put "welcome-visitors" into pageSlug
   put wikiServer_GetPageJson (pageSlug) into pageJSON
   pageJson_Set wikiDomain, pageSlug, pageJSON
   
   put wikiServer_GetFavicon() into pngData
   wiki_SetFavicon wikiDomain, pngData
end wikiServer_Create


--> WikiServer | Running
-
function wikiServer_IsRunning
   put wikiServer_ListObjects() into serverObjects
   put serverObjects is not empty into isRunning
   return isRunning
end wikiServer_IsRunning

function wikiServer_NodeIsRunning
   return wikiServer_ListProcessIds() is not empty
   -- return "wiki" is among the lines of the openprocesses
end wikiServer_NodeIsRunning


--> WikiServer | Start
-
command wikiServer_StartWithXterm pXtermBrowser, pLog
   put wikiServer_TerminalCommand() into someShell -- not working with Shell
   --
   display_Xterm pXtermBrowser, someShell, "paste"
   return pXtermBrowser
end wikiServer_StartWithXterm

command wikiServer_Start pPort, pWikiServer
   -- wikiServer_StartNode
   -- tunnel_LaunchFromConfig
   if exists (pWikiServer) is false then put wikiServer_View() into pWikiServer
   
   # Get Port
   if pPort is empty then
      -- put 80 into pPort
      put the daemon_Port of pWikiServer into pPort
   end if
   
   # Stop servers
   if wikiServer_NodeIsRunning() then
      wikiServer_StopNode
   end if
   
   # Set Port and Start
   -- dispatch "daemon_Start" to pWikiServer with pPort
   set the daemon_IsRunning [pPort] of pWikiServer to true
   
   # Load Gardens
   wikiGarden_Init
   
   return pWikiServer
end wikiServer_Start

command wikiServer_Stop pWikiServers, pCloseAll
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
   return pWikiServer
end wikiServer_Stop


--> Wiki | Start | Node
-
command wikiServer_StartNode pSecurityType, pFarm, pPort
   if pSecurityType is empty then put wikiServer_GetSecurityType() into pSecurityType
   --
   put wikiServer_ListProcessIds() into wikiProcessIDs
   if wikiProcessIDs is not empty then return empty -- so we know already started
   --
   wiki_NormailzePort pPort
   if pPort is empty then put 80 into pPort
   --
   put wikiServer_ShellCommand (pSecurityType, pFarm, pPort) into someShell
   put shell (someShell) into shellResult
   put word 2 of shellResult into wikiProcessID
   
   # Indicate wiki starting up
   return wikiProcessID
end wikiServer_StartNode

command wikiServer_StopNode pIDs
   if the platform = "MacOS" then
      if pIDs is not a number then
         put wikiServer_ListProcessIds() into pIDs
      end if
      --
      repeat for each item pID in pIDs
         kill process pID
      end repeat
   else
      close process wiki
   end if
end wikiServer_StopNode

command wikiServer_Restart pNotify, pNotifyText
   if pNotify is not false then
      if pNotifyText is empty then put "Restarted wiki server!" into pNotifyText
      lcw_Notify pNotifyText
   end if
   
   put wikiServer_View() into serverObject
   set the daemon_IsRunning of serverObject to false
   -- wikiServer_Stop serverObject, pCloseAll
   -- put the result into serverObject
   resetAll
   -- wikiServer_Start serverObject
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
function wikiServer_ShellCommand pSecurityType, pFarm, pPort, pLog, pWithNvm
   put wikiServer_StartNodeCommand (pSecurityType, pFarm, pLog, pPort, pWithNvm) into someShell
   put "/usr/bin/nohup" & space before someShell
   
   # Add redirect output bit (log if needed)
   put _RedirectBit (pLog) into reDirectOutput
   put space & reDirectOutput after someShell
   put space & "jobs -l" after someShell
   --
   put "source ~/.zshrc;" before someShell
   --
   return someShell
end wikiServer_ShellCommand

function wikiServer_StartNodeCommand pSecurityType, pFarm, pLog, pPort, pWithNvm
   if pWithNvm is true then
      put nvm_GetBin() into wikiBinFile
   else
      put "wiki" into wikiBinFile
   end if
   put wikiBinFile into someShell
   
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
   
   put space & "--admin" && "david.bovill@gmail.com" after someShell
   --
   if pFarm is not false then put space & "--farm" after someShell
   if pPort is empty then
      put space & "--port 80" after someShell
   else
      put space & "--port" && pPort after someShell
   end if
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


--> Wiki
-
function wikiServer_ListProcessIds
   -- put "wiki --security_legacy" into wikiCommand
   put "wiki" into wikiCommand
   --
   put merge ("ps aux | grep '[[wikiCommand]]'") into someShell
   put shell (someShell) into shellResult
   put lineOffset (wikiCommand, shellResult) into lineNum
   delete line lineNum of shellResult
   --
   repeat for each line sLine in shellResult
      put word 2 of sLine into pid
      put pid & comma after pids
   end repeat
   delete char -1 of pids
   return pids
end wikiServer_ListProcessIds


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

