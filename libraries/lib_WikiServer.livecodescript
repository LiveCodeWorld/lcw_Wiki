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


--> Working on
-


--> WikiServer | Create
-
command wikiServer_Create wikiDomain
   # Create folders in wikiFolder of default farm
   put wikiFolder_ConstructFromFarm (wikiDomain) into wikiFolder
   if there is a folder wikiFolder then
      return "Error, a folder for this domain already exists:" && wikiFolder
   end if
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
   put wikiPage_WelcomeVisitors (wikiDomain) into pageArray
   pageArray_Set wikiDomain, "welcome-visitors", pageArray
   
   # Set Favicon
   put wikiServer_GetFavicon() into pngData
   wikiServer_SetFavicon wikiDomain, pngData
   
   # Add owner.json
   wikiServer_SetFriendlyData wikiDomain
   --
   return wikiFolder
end wikiServer_Create

command wikiServer_SwitchIfGarden wikiDomain
   put wikiGarden_Name (wikiDomain) into gardenName
   if gardenName is empty then return empty
   
   wikiServer_StopNode
   wikiGarden_StartNodeServer gardenName
   put the result into wikiProcessID
   return wikiProcessID
end wikiServer_SwitchIfGarden

function wikiServer_NodeIsRunning
   return wikiServer_ListProcessIds() is not empty
   -- return "wiki" is among the lines of the openprocesses
end wikiServer_NodeIsRunning


--> WikiServer | Node
-
command wikiServer_RestartNode pNotify, pNotifyText
   if pNotify is not false then
      if pNotifyText is empty then put "Restarted node wiki-server!" into pNotifyText
      lcw_Notify pNotifyText
   end if
   
   put ecoData_GetFarmFolder() into farmFolder
   --
   wikiServer_StopNode
   resetAll
   wikiServer_StartNode farmFolder
   return serverObject
end wikiServer_RestartNode

command wikiServer_StartNodeFarm
   put wikiServer_ListProcessIds() into wikiProcessIDs
   if wikiProcessIDs is not empty then return wikiProcessIDs
   
   # Must have farmFolder properly set
   put wikiFarm_GetDefaultFolder() into farmFolder
   
   # Load ecodata from file
   ecoData_ConstructLoadAndStore farmFolder
   put the result into ecoData
   
   # Quick Check
   if ecoData_Get() is not ecoData then
      breakpoint
   end if
   
   put wikiServer_ShellCommand ("friends", true, 80, farmFolder) into someShell
   put shell (someShell) into shellResult
   put word 2 of shellResult into wikiProcessID
   
   # Notify
   put "Started node server using" && someShell into sComment
   lcw_Notify sComment, "Node Server"
   
   # Indicate wiki starting up
   return wikiProcessID
end wikiServer_StartNodeFarm

command wikiServer_StartNode pDataFolder, pSecurityType, pFarm, pPort
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
   put "Started node server using" && someShell into sComment
   lcw_Notify sComment, "Node Server"
   
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
      
      # Notify
      lcw_Notify "Closed node server!", "Node Server"
   else
      breakpoint
      close process wiki
   end if
end wikiServer_StopNode


--> WikiServer | Files (see lib_AtopiaDomainOwnership)
-
function wikiServer_OwnerExists wikiDomain
   put wikiFile_ConstructOwner (wikiDomain) into ownerFile
   return there is a file ownerFile
end wikiServer_OwnerExists

command wikiServer_SetFriendlyData wikiDomain, pUserName, pSecret
   put wikiServer_FriendlyOwnerData (pUserName, pSecret) into ownerData
   wikiServer_SetOwnerData wikiDomain, ownerData
   put the result into ownerFile
   return ownerFile
end wikiServer_SetFriendlyData

function wikiServer_GetOwnerData wikiDomain
   put wikiFile_ConstructOwner (wikiDomain) into ownerFile
   if there is a file ownerFile then
      put jsonArray_FromFile (ownerFile) into ownerData
      return ownerData
   else
      return empty
   end if
end wikiServer_GetOwnerData

command wikiServer_SetOwnerData wikiDomain, pOwnerData
   if pOwnerData is not an array then
      put wikiServer_FriendlyOwnerData() inot pOwnerData
   end if
   
   put wikiFile_ConstructOwner (wikiDomain) into ownerFile
   jsonArray_ToFile ownerFile, pOwnerData
   return ownerFile
end wikiServer_SetOwnerData

function wikiServer_FriendlyOwnerData pUserName, pSecret
   if pUserName is empty then put lcw_GetAuthor() into pUserName
   if pSecret is empty then put system_GetAdminPassword() into pSecret
   --
   put wikiServer_ConstructOwnerData (pUserName, pSecret, "friendly") into ownerData
   return ownerData
end wikiServer_FriendlyOwnerData

function wikiServer_ConstructOwnerData pUserName, pSecret, pSecurityType
   -- only "friendly" for now
   if pUserName is empty then put lcw_GetAuthor() into pUserName
   if pSecret is empty then put system_GetAdminPassword() into pSecret
   
   switch pSecurityType
      case "friendly"
      default
         put pUserName into ownerData ["name"]
         put pSecret into ownerData ["friend"]["secret"]
   end switch
   return ownerData
end wikiServer_ConstructOwnerData

function wikiServer_ConstructFriendlyJson pUserName, pSecret
   if pUserName is empty then put lcw_GetAuthor() into pUserName
   if pSecret is empty then put system_GetAdminPassword() into pSecret
   --
   replace "'" with quote in ownerJSON
   return ownerJSON
end wikiServer_ConstructFriendlyJson

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


--> WikiServer | Running
-
function wikiServer_IsRunning
   put wikiServer_ListObjects() into serverObjects
   put serverObjects is not empty into isRunning
   return isRunning
end wikiServer_IsRunning


--> WikiServer | Start
-
command wikiServer_Toggle pWikiView
   if wikiServer_IsRunning() is true then
      wikiServer_Stop
      --
      lcw_Notify "Stopped wiki-server!"
   else
      wikiServer_StopNode
      wikiServer_Start
      --
      lcw_Notify "Started wiki-server!"
   end if
end wikiServer_Toggle

command wikiServer_StartWithXterm pXtermBrowser, pLog
   put wikiServer_TerminalCommand() into someShell -- not working with Shell
   --
   display_Xterm pXtermBrowser, someShell, "paste"
   return pXtermBrowser
end wikiServer_StartWithXterm

command wikiServer_Start pPort, pWikiServer
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
   ecoData_SetFarmAndGardens
   
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
function wikiServer_ShellCommand pSecurityType, pFarm, pPort, pDataFolder, pLog, pWithNvm
   put wikiServer_StartNodeCommand (pSecurityType, pFarm, pLog, pPort, pDataFolder, pWithNvm) into someShell
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

