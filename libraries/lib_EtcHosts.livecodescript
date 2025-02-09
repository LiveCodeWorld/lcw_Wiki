script "lib_EtcHosts"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_EtcHosts
type: library
version: 0.2

/*
This library is for manipulating the /etc/hosts file.

This is useful for setting up federated wiki farms on your laptop.
*/


--> Working on
-

--> Hosts
-
function hosts_ListFiles
   -- return shell ("ls /etc/host*")
   put files ("/etc/") into hostFiles
   filter hostFiles with "hosts*"
   return hostFiles
end hosts_ListFiles

command hosts_Delete sDomain, pSystemPassword
   _NormalizeSystemPassword pSystemPassword
   --
   put hosts_Get (pSystemPassword) into hostsText
   if item 1 of hostsText = "Error" then return hostsText
   put hosts_GetArray (hostsText) into hostsArray
   --
   delete variable hostsArray ["domains"][sDomain]
   --
   put hosts_TextFromArray (hostsArray) into hostText
   hosts_Set hostsText, pSystemPassword
   return hostsText
end hosts_Delete

command hosts_Rename fromDomain, toDomain, pSystemPassword
   _NormalizeSystemPassword pSystemPassword
   --
   put hosts_Get (pSystemPassword) into hostsText
   if item 1 of hostsText = "Error" then return hostsText
   put hosts_GetArray (hostsText) into hostsArray
   --
   delete variable hostsArray ["domains"][fromDomain]
   --
   put "127.0.0.1" into hostsArray ["domains"][toDomain]["ip"]
   put "127.0.0.1" && toDomain into hostsArray ["domains"][toDomain]["line"]
   --
   put hosts_TextFromArray (hostsArray) into newText
   hosts_Set newText, pSystemPassword
   return newText
end hosts_Rename

command hosts_Add localDomainsToAdd, pSystemPassword, pLaunch
   _NormalizeSystemPassword pSystemPassword
   put hosts_AddLocalDomainsToText (localDomainsToAdd, pSystemPassword) into hostsText
   if item 1 of hostsText = "Error" then return hostsText
   --
   if pLaunch is true then
      set the clipboardData to hostsText
      launch_EtcHosts
   else
      hosts_Set hostsText, pSystemPassword
   end if
   return hostsText
end hosts_Add

function hosts_NewText localDomains
   local domainArray
   url_SortDomainIndex localDomains
   
   put "##,# Host Database,#,# localhost is used to configure the loopback interface" into hostText
   put ",# when the system is booting.  Do not change this entry.,##" after hostText
   replace comma with CR in hostText
   --
   put CR & "127.0.0.1	localhost" after hostText
   put CR & "255.255.255.255	broadcasthost" after hostText
   --
   put "127.0.0.1" into localIP
   repeat for each line localDomain in localDomains
      switch
         case localDomain is "localhost"
            next repeat
         default
            put CR & localIP && localDomain after hostText
      end switch
   end repeat
   --
   put CR & "::1             localhost" after hostText
   --
   return hostText
end hosts_NewText

function hosts_AddLocalDomainsToText pLocalDomainsToAdd, pSystemPassword
   _NormalizeSystemPassword pSystemPassword
   --
   replace comma with CR in pLocalDomainsToAdd
   --
   if there is a file "/etc/hosts" then
      put hosts_Get (pSystemPassword) into hostsText
      switch hostsText
         case hostsText contains "Password:Sorry, try again."
            return "Error, wrong passowd"
         default
            put hosts_GetArray (hostsText) into hostsArray
            put _MaxExistingDomains (hostsArray) into dNum
            --
            put hostsArray ["domains"] into domainArray
      end switch
      --
   end if
   
   repeat for each line localDomain in pLocalDomainsToAdd
      switch
         case localDomain is "localhost"
         case localDomain is among the keys of hostsArray
            next repeat
         default
            put "127.0.0.1" into localIP
            add 1 to dNum
            put dNum into hostsArray ["domains"][localDomain]["lineNum"]
            put localIP && localDomain into hostsArray ["domains"][localDomain]["line"]
            put localIP into hostsArray ["domains"][localDomain]["ip"]
      end switch
   end repeat
   --
   put hosts_TextFromArray (hostsArray) into hostText
   return hostText
end hosts_AddLocalDomainsToText

function hosts_TextFromArray hostsArray
   put LF into lineDelimChar
   --
   put hostsArray ["hostsHeader"] into hostText
   put lineDelimChar & hostsArray ["localhost"]["line"] after hostText
   put hostsArray ["domains"]["broadcasthost"]["line"] into bLine
   if bLine is not empty then
      delete variable hostsArray ["domains"]["broadcasthost"]
      put lineDelimChar & bLine after hostText
   end if
   --
   put hostsArray ["domains"]into domainsArray
   repeat for each key localDomainName in domainsArray
      put domainsArray [localDomainName]["line"] into sLine
      put lineDelimChar & sLine after hostText
   end repeat
   put lineDelimChar & hostsArray ["IPv6 loopback address"]["line"] after hostText
   return hostText
end hosts_TextFromArray

function hosts_GetArray hostsText
   put line 1 of hostsText into hostsHeader
   put the number of lines of hostsText into maxNum
   repeat with lineNum = 2 to maxNum
      get line lineNum of hostsText
      if char 1 of it = "#" then
         put CR & it after hostsHeader
      else
         exit repeat
      end if
   end repeat
   put lineNum into firstLineNum
   --
   put hostsHeader into hostsArray ["hostsHeader"]
   put firstLineNum into hostsArray ["firstLineNum"]
   --
   repeat with lineNum = firstLineNum to maxNum
      get line lineNum of hostsText
      put word -1 of it into localDomainName
      switch localDomainName
         case empty
            next repeat
            break
         case "localhost"
            put word 1 of it into localIP
            if localIP = "::1" then
               put lineNum into hostsArray ["IPv6 loopback address"]["lineNum"]
               put localIP into hostsArray ["IPv6 loopback address"]["ip"]
               put it into hostsArray ["IPv6 loopback address"]["line"]
            else
               put lineNum into hostsArray [localDomainName]["lineNum"]
               put localIP into hostsArray [localDomainName]["ip"]
               put it into hostsArray [localDomainName]["line"]
            end if
            break
         default
            put word 1 of it into localIP
            put lineNum into hostsArray ["domains"][localDomainName]["lineNum"]
            put it into hostsArray ["domains"][localDomainName]["line"]
            put localIP into hostsArray ["domains"][localDomainName]["ip"]
      end switch
   end repeat
   --
   return hostsArray
end hosts_GetArray


--> Etc | Hosts
-
command hosts_ToggleEmpty pSystemPassword
   if hosts_IsMinimal() then
      hosts_CopyToRecent pSystemPassword
      hosts_RestoreBackup pSystemPassword, true
   else
      hosts_SetMinimal pSystemPassword
   end if
end hosts_ToggleEmpty

command hosts_SetMinimal pSystemPassword
   hosts_CopyToRecent pSystemPassword
   --
   put hosts_NewText() into emptyHosts
   hosts_Set emptyHosts, pSystemPassword
   return the result
end hosts_SetMinimal


--> Hosts | Write
-
command hosts_RestoreBackup pSystemPassword, pOverwrite
   if _BackupMissing() then
      return "Error, cannot use hosts_RestoreBackup as etc/hosts_CopyToBackup file is missing!"
   end if
   if pOverwrite is not true then
      if _HostsExists() then
         return "Error, cannot use hosts_RestoreBackup as etc/hosts file exists!"
      end if
   end if
   
   put hosts_File() into hostsFile
   put hosts_BackUpFile() into hostsBackupFile
   --
   _MoveFromTo hostsBackupFile, hostsFile, pSystemPassword
   return the result
end hosts_RestoreBackup

command hosts_MoveToBackup pSystemPassword
   -- does nothing if no /etc/hosts
   -- otherwise moves it to "/etc/hosts_CopyToBackup"
   -- overwrites old backup if it exists
   
   put hosts_File() into hostsFile
   put hosts_BackUpFile() into hostsBackupFile
   --
   _MoveFromTo hostsFile, hostsBackupFile, pSystemPassword
   return the result
end hosts_MoveToBackup

command hosts_CopyToRecent pSystemPassword
   put hosts_RecentFile() into hostsRecentFile
   --
   _CopyFromHostsTo hostsRecentFile, pSystemPassword
   return the result
end hosts_CopyToRecent

command hosts_CopyToBackup pSystemPassword
   put hosts_BackUpFile() into hostsBackupFile
   --
   _CopyFromHostsTo hostsBackupFile, pSystemPassword
   return the result
end hosts_CopyToBackup

function hosts_IsMinimal pSystemPassword
   put hosts_Get (pSystemPassword) into hostsText
   put hosts_NewText() into emptyHosts
   return word 1 to -1 of hostsText = word 1 to -1 of emptyHosts
end hosts_IsMinimal

function hosts_Get pSystemPassword
   _NormalizeSystemPassword pSystemPassword
   --
   put merge ("echo '[[pSystemPassword]]' | sudo -S cat /etc/hosts") into someShell
   put shell (someShell) into hostsText
   
   # Tweak
   set the itemdelimiter to ":"
   if item 1 of hostsText = "Password" then
      -- Password:
      delete item 1 of hostsText
      return hostsText
   else
      return "Error," && hostsText
   end if
end hosts_Get

command hosts_Set hostsText, pSystemPassword
   _NormalizeSystemPassword pSystemPassword
   --
   hosts_CopyToBackup pSystemPassword
   --
   put the tempname into tTempPath
   put hostsText into url ("binfile:" & tTempPath)
   --
   get "echo '[[pSystemPassword]]' | sudo -S mv" && kwote (tTempPath, "'") && "'/etc/hosts'"
   put merge (it) into someShell
   --
   put shell (someShell) into shellResult
   return shellResult
end hosts_Set


--> Hosts | File
-
function hosts_File
   put "/etc/hosts" into hostsFile
   return hostsFile
end hosts_File

function hosts_RecentFile
   -- a place for temporary storage of hosts file
   put "/etc/hosts.recent" into hostsRecentFile
   return hostsRecentFile
end hosts_RecentFile

function hosts_BackUpFile
   -- a place for backup storage of hosts file
   put "/etc/hosts.backup" into hostsBackupFile
   return hostsBackupFile
end hosts_BackUpFile


--> Private
-
command shell_DoSudo someShell, pSystemPassword
   _NormalizeSystemPassword pSystemPassword
   --
   put "echo '" & pSystemPassword & "' | sudo -S" && someShell into sudoShell
   put shell (sudoShell) into shellResult
   if sResult = "Password:" then
      return empty
   else
      return sResult 
   end if
end shell_DoSudo

private command _NormalizeSystemPassword @pSystemPassword
   if pSystemPassword is empty then
      put system_GetAdminPassword() into pSystemPassword
      if pSystemPassword is empty then
         put lcw_Ask ("Enter system password...") into pSystemPassword
         system_SetAdminPassword pSystemPassword
      end if
   else
      system_SetAdminPassword pSystemPassword
   end if
end _NormalizeSystemPassword

private command _MoveFromTo fromFile, toFile, pSystemPassword
   put _ConstructShell ("mv", fromFile, toFile) into someShell
   shell_DoSudo someShell, pSystemPassword
   --
   return the result
end _MoveFromTo

private command _CopyFromHostsTo sFile, pSystemPassword
   put hosts_File() into hostsFile
   --   
   put _ConstructShell ("cp", hostsFile, sFile) into someShell
   shell_DoSudo someShell, pSystemPassword
   --
   return the result
end _CopyFromHostsTo

private command _CopyToHostsFrom sFile, pSystemPassword
   put hosts_File() into hostsFile
   --   
   put _ConstructShell ("cp", sFile, hostsFile) into someShell
   shell_DoSudo someShell, pSystemPassword
   --
   return the result
end _CopyToHostsFrom

private function _ConstructShell sCommand, fromFile, toFile
   put sCommand && kwote (fromFile, "'") && kwote (toFile, "'") into someShell
   return someShell
end _ConstructShell

private function _HostsExists
   put hosts_File() into hostsFile
   return there is a file hostsFile
end _HostsExists

private function _BackupMissing
   -- if there is not a file "/etc/hosts_CopyToBackup"
   put hosts_BackUpFile() into hostsBackupFile
   put there is not a file hostsBackupFile into isMissing
   return isMissing
end _BackupMissing

private function _MaxExistingDomains hostsArray
   put hostsArray ["domains"]into domainsArray
   repeat for each key localDomainName in domainsArray
      put domainsArray [localDomainName]["lineNum"] into lineNum
      put lineNum & comma after lineNums
   end repeat
   delete char -1 of lineNums
   return max (lineNums)
end _MaxExistingDomains
