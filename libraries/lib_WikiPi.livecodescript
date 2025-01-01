script "lib_WikiPi"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_WikiPi
type: library
version: 0.2

/*
This library is for handlers that manipulate the structure of federated wiki files 
on a standard RasperryPi based wiki-farm.
*/


--> Working on
-
command wikiPi_StoreOwnerData wikiDomain, ownerData, pPiLocalHost
   if pPiLocalHost is empty then
      put pihole_DomainToPiName (wikiDomain) into pPiLocalHost
   end if
   
   put wikiFile_ConstructOwner (wikiDomain, "~/.wiki/") into remoteFile
   put the tempname & ".json" into localFile
   jsonArray_ToFile localFile, ownerData
   
   scp_StoreFile pPiLocalHost, remoteFile, localFile
   put the result into shellResult
   return shellResult
end wikiPi_StoreOwnerData


--> WikiPi
-
function wikiPi_FetchOwnerData wikiDomain, piLocalHost
   if piLocalHost is empty then
      put pihole_DomainToPiName (wikiDomain) into piLocalHost
   end if
   
   put wikiFile_ConstructOwner (wikiDomain, "~/.wiki/") into ownerFile
   put ssh_FetchFile (piLocalHost, ownerFile) into ownerJSON 
   --
   set the itemdelimiter to ":"
   if (item 1 of ownerJSON = "cat" and item -1 of ownerJSON = " No such file or directory") then return empty
   
   put json_ToArray (ownerJSON) into ownerData
   return ownerData
end wikiPi_FetchOwnerData

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


--> PiServer
-
function piServer_Status piLocalHost
   ssh_DoRemoteShell piLocalHost, "systemctl --user status federated-wiki"
   put the result into sResult
   return sResult   
end piServer_Status

command piServer_Restart piLocalHost
   piServer_Systemctl piLocalHost, "restart"
   return the result
end piServer_Restart

command piServer_Start piLocalHost
   piServer_Systemctl piLocalHost, "start"
   return the result
end piServer_Start

command piServer_Stop piLocalHost
   piServer_Systemctl piLocalHost, "stop"
   return the result
end piServer_Stop

command piServer_Systemctl piLocalHost, sCommand
   put merge ("systemctl --user [[sCommand]] federated-wiki") into remoteShell
   ssh_DoRemoteShell piLocalHost, remoteShell
   put the result into sResult
   return sResult
end piServer_Systemctl

function piServer_ProcessID piLocalHost
   put piServer_Status(piLocalHost) into sStatus
   put "(?ms)^\s*Main PID:\s*([0-9]+)\s+\(node\)" into rExp
   --
   if matchText(sStatus, rExp, pID) is true then
      return pID
   else
      return empty
   end if
end piServer_ProcessID

function piServer_IsRunning piLocalHost
   put piServer_ProcessID (piLocalHost) into pID
   return pID is not empty
end piServer_IsRunning


--> WikiPi
-
command wikipi_AddDomains tldDomian, piHost, subDomains
   # Add TLD domain to Pihole
   put the hostNameToAddress of piHost into ipAddress
   if ipAddress is empty then
      breakpoint
   else
      pihole_AddCustomDomain tldDomian, ipAddress
      put the result into successMessage
   end if
   
   # Add Subdomains to Pihole
   line_Delete tldDomian, subDomains
   pihole_AddSubDomains piHost, subDomains
   
   return subDomains
end wikipi_AddDomains

function wikiPi_LocalDomainData tldDomain
   put pihole_LocalHostArray() into domainNameArray
   put wikiPi_ConstructLocalDomainData (tldDomain, domainNameArray) into localDomainData
   put wikiDomain_List (tldDomain, true) into localDomainData ["laptop"]
   return localDomainData   
end wikiPi_LocalDomainData

function wikiPi_ConstructLocalDomainData tldDomain, domainNameArray
   repeat for each key localHostName in domainNameArray
      put wikiPi_ListShortFolders (localHostName, tldDomain) into wikiDomains
      put wikiDomains into localDomainData [localHostName]
   end repeat
   
   put wikiDomain_List (tldDomain, true) into localDomainData ["laptop"]
   return localDomainData   
end wikiPi_ConstructLocalDomainData


--> WikiPi
-
command wikiPi_Renamefolder oldName, newName, piHostName, pSshUser, pFarmDir
   if pFarmDir is empty then put "~/.wiki/" into pFarmDir
   put pFarmDir & oldName into oldDir
   put pFarmDir & newName into newDir
   -- 
   shell_BashParamEscape oldDir
   shell_BashParamEscape newDir
   --
   put "mv" && oldDir && newDir into remoteCommand
   --
   ssh_DoRemoteShell piHostName, remoteCommand, pSshUser
   put the result into someData
   return someData
end wikiPi_Renamefolder

function wikiPi_ListPageSlugs localHostName, wikiDomain
   put "~/.wiki/" & wikiDomain & "/pages/" into serverPath
   put server_ListShortFiles (localHostName, serverPath) into pageSlugs
   return pageSlugs
end wikiPi_ListPageSlugs

function wikiPi_ListShortFolders localHostName, pTldDomain
   # Check localhostname is reachable (hangs otherwise)
   put hostNameToAddress (localHostName) into localHostAddress -- ideally just ping
   if localHostAddress is empty then
      breakpoint
      return "Error, cannot reach localHostName:" && localHostName
   end if
   
   # Remote LS
   put server_ListShortFolders (localHostName, "~/.wiki") into wikiPiNames
   
   # Tidy
   line_Delete "commons", wikiPiNames
   
   # Construct TLD and do a smart filter
   if pTldDomain is not empty then
      put url_GetTLD (pTldDomain) into tldDomain
      filter wikiPiNames with ("*." & tldDomain) into domainNames
      
      set the wholematches to true
      if lineOffset (tldDomain, wikiPiNames) > 0 then
         put word 1 to -1 of (tldDomain & CR & domainNames) into domainNames
      end if
      return domainNames
   else
      return wikiPiNames
   end if
end wikiPi_ListShortFolders


--> Deps
-
