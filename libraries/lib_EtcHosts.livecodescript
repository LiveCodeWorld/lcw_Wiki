script "lib_EtcHosts"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_EtcHosts
type: library
version: 0.1

/*Some help*/


--> Working on
-
command hosts_Add localDomainsToAdd, pSystemPassword, pLaunch
   if pSystemPassword is empty then
      put lcw_Ask ("Enter system password...") into pSystemPassword
   end if
   --
   put hosts_ConstructText (pSystemPassword, localDomainsToAdd) into hostsText
   if item 1 of hostsText = "Error" then return hostsText
   --
   if pLaunch is true then
      set the clipboardData to hostsText
      launch_EtcHosts
   else
      hosts_Set pSystemPassword, hostsText
   end if
   return hostsText
end hosts_Add

function hosts_ConstructText yourPassword, pLocalDomainsToAdd
   replace comma with CR in pLocalDomainsToAdd
   --
   put hosts_Get (yourPassword) into hostsText
   if hostsText contains "Password:Sorry, try again." then
      return "Error, wrong passowd"
   end if
   --
   put hosts_GetArray (hostsText) into hostsArray
   put _MaxExistingDomains (hostsArray) into dNum
   --
   put hostsArray ["domains"] into domainArray
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
end hosts_ConstructText

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
command hosts_Backup yourPassword, pSomeHow, pBrowserView   
   put "/etc/hosts" into hostsFile
   put "/etc/hosts_backup" into hostsBackupFile
   --
   get "echo '[[yourPassword]]' | sudo -S mv" && kwote (hostsFile, "'") && kwote (hostsBackupFile, "'")
   put merge (it) into someShell
   --
   shell_Do someShell, pSomeHow, pBrowserView
   return the result 
end hosts_Backup

function hosts_Get yourPassword
   put merge ("echo '[[yourPassword]]' | sudo -S cat /etc/hosts") into someShell
   put shell (someShell) into hostsText
   
   # Tweak
   set the itemdelimiter to ":"
   if item 1 of hostsText = "Password" then
      -- Password:
      delete item 1 of hostsText
   end if
   
   return hostsText
end hosts_Get

command hosts_Set yourPassword, hostsText, pSomeHow, pBrowserView
   hosts_Backup yourPassword
   --
   put the tempname into tTempPath
   put hostsText into url ("binfile:" & tTempPath)
   --
   get "echo '[[yourPassword]]' | sudo -S mv" && kwote (tTempPath, "'") && "'/etc/hosts'"
   put merge (it) into someShell
   --
   shell_Do someShell, pSomeHow, pBrowserView
   return the result
end hosts_Set


--> Private
-
private function _MaxExistingDomains hostsArray
   put hostsArray ["domains"]into domainsArray
   repeat for each key localDomainName in domainsArray
      put domainsArray [localDomainName]["lineNum"] into lineNum
      put lineNum & comma after lineNums
   end repeat
   delete char -1 of lineNums
   return max (lineNums)
end _MaxExistingDomains
