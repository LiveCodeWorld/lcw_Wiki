script "lib_WikiFix"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_WikiFix
type: library
version: 0.3

/*
*/

--> Variables
-
local DynadotSubDomains
local TunnelDomainArray


--> Working on
-
function wiki_ReDomain wikiDomain, pReDomain
   if pReDomain is empty then return wikiDomain
   --
   set the itemdelimiter to "."
   put item 1 to -3 of wikiDomain into fistBit
   put fistBit & "." & pReDomain into newDomain
   return newDomain
   
   put the number of items of pReDomain into dNum
   put pReDomain into item -dNum to -1 of wikiDomain
   return wikiDomain
end wiki_ReDomain

command gitwiki_MoveToLocal wikiDomain, pAddTohosts, pNewName
   put gitwiki_GetFolder (wikiDomain) into gitWikiFolder
   if pNewName is empty then
      put wiki_ConstructFolder (wikiDomain) into localFolder
   else
      put wiki_ConstructFolder (pNewName) into localFolder
   end if
   --
   if there is a folder localFolder then
      breakpoint
      return "Error, folder" && localFolder && "already exists."
   else
      rename folder gitWikiFolder to localFolder
      --
      if pAddTohosts is not false then
         if pNewName is empty then put wikiDomain into pNewName
         put system_GetAdminPassword() into systemPassword
         hosts_Add pNewName, systemPassword
      end if
   end if
end gitwiki_MoveToLocal

command gitwiki_CopyToLocal wikiDomain, pAddTohosts, pNewName
   put gitwiki_GetFolder (wikiDomain) into gitWikiFolder
   if pNewName is empty then
      put wiki_ConstructFolder (wikiDomain) into localFolder
   else
      put wiki_ConstructFolder (pNewName) into localFolder
   end if
   --
   if there is a folder localFolder then
      breakpoint
      return "Error, folder" && localFolder && "already exists."
   else
      if pNewName is empty then
         put wiki_RootFolder() into wikiRootFolder
         revCopyFolder gitWikiFolder, wikiRootFolder
      else
         put the tempname & slash into tempFolder
         folder_CreateNested tempFolder
         revCopyFolder gitWikiFolder, tempFolder
         get the result
         --
         put tempFolder & wikiDomain & slash into tempWikiFolder
         if there is a folder tempWikiFolder then
            rename folder tempWikiFolder to localFolder
         else
            breakpoint
            return "Error, copying folder" && gitWikiFolder && "to" && tempFolder
         end if
      end if 
      --
      if pAddTohosts is not fale then
         put system_GetAdminPassword() into systemPassword
         hosts_Add wikiDomain, systemPassword
      end if
   end if
end gitwiki_CopyToLocal

on wiki_DroppedURL sURL
   answer the params
end wiki_DroppedURL

command wiki_LoadTunnel
   -- could load Dynadot as well
   put tunnel_FetchDomainArray() into TunnelDomainArray
end wiki_LoadTunnel

private command _SetNames gitWikiDomain, dynSubDomain, @tldDomain, @dynSubDomainName, @localhostDomain, @cNameValue, @dynadotSubDomains
   put domain_GetTld (gitWikiDomain) into tldDomain
   
   # Fetch Dynadot Subdomains
   put dynadot_ListSubdomains (tldDomain, true) into dynadotSubDomains
   
   # Work out names from gitWikiDomain
   set the itemdelimiter to "."
   put item 1 to -3 of dynSubDomain into dynSubDomainName
   
   put wiki_ConstructLocalHostDomain (dynSubDomain) into localhostDomain
   put gitWikiDomain into starDomain
   put "*" into item 1 of starDomain
   
   # Fetch CNAME Value from LocalXpose
   put TunnelDomainArray [gitWikiDomain]["cname"] into cNameValue
   if cNameValue is empty then
      put TunnelDomainArray [starDomain]["cname"] into cNameValue
   end if
end _SetNames


--> Wiki | Fix
-
function gitwiki_CheckCnameValue gitWikiDomain, pDynSubDomain, pColour, pLoad
   if pDynSubDomain is empty then put gitWikiDomain into pDynSubDomain
   if pLoad is not false then wiki_LoadTunnel
   
   # Work out all the names
   _SetNames gitWikiDomain, pDynSubDomain, tldDomain, dynSubDomainName, localhostDomain, cNameValue, dynadotSubDomains
   
   if tldDomain = gitWikiDomain then
      return gitwiki_CheckDomain (tldDomain, pColour)
   else
      return gitwiki_CheckSubdomain (gitWikiDomain, pDynSubDomain, cNameValue, subdomain, pColour)
   end if
end gitwiki_CheckCnameValue

function gitwiki_CheckDomain tldDomain, pColour
   put dynadot_MainDomainCname (tldDomain) into cNameValue
   if cNameValue is empty then
      if pColour is true then return "red"
      return merge ("Toplevel Domain '[[tldDomain]]' has no CNAME value with Dynadot")
   else
      return empty
   end if
end gitwiki_CheckDomain

function gitwiki_CheckSubdomain gitWikiDomain, dynSubDomain, cNameValue, subdomain, pColour
   # Check dynSubDomainName and register if needed
   switch
      case cNameValue is empty
         if pColour is true then return "red"
         return merge ("Subdomain '[[gitWikiDomain]]' has no CNAME value with LocalXpose")
      case dynSubDomain = "platform.earth"
      case dynSubDomain = "together.platform.earth"
         if pColour is true then return "orange"
         return "Reserved subdomain"
      case dynSubDomainName is among the lines of dynadotSubDomains
         if pColour is true then return "blue"
         return  merge ("Subdomain '[[subDomainName]]' already registered!")
      default
         return empty
   end switch
end gitwiki_CheckSubdomain

command gitwiki_SymlinksAndAddHost gitWikiDomain, pAddToHosts, pLocalWikiDomain 
   if pLocalWikiDomain is empty then put gitWikiDomain into pLocalWikiDomain
   
   # Create Symlink
   gitwiki_CreateSymLink gitWikiDomain, pLocalWikiDomain
   get the result
   
   # Create Localhost Symlink
   put wiki_ConstructLocalHostDomain (pLocalWikiDomain) into localhostDomain
   gitwiki_CreateSymLink gitWikiDomain, localhostDomain
   get the result
   
   if pAddToHosts is not false then
      # Add to Etc/hosts
      hosts_Add localhostDomain
   end if
   --
   return empty
end gitwiki_SymlinksAndAddHost

command gitwiki_FixLocalDomain localhostDomain, pDisplayView
   put wiki_GetFolder (localhostDomain) into wikiFolder
   put gitwiki_GetFolder (localhostDomain) into gitWikiFolder
   --
   put wiki_NumberOfpages (wikiFolder) into wikiPageNum
   put wiki_NumberOfpages (gitWikiFolder) into gitWikiPageNum
   --
   switch
      case (wikiPageNum = 0) AND (gitWikiPageNum > 0)
         revDeleteFolder wikiFolder
         symlink_CreateFolder gitWikiFolder, wikiFolder
         break
      case wikiPageNum < 1
         if folder_IsSymLink (wikiFolder) then
            breakpoint
         else
            revDeleteFolder wikiFolder
         end if
         break
      default
         breakpoint
   end switch
   
   if exists (pDisplayView) then
      display_EmptyLocalWikis pDisplayView
   end if
end gitwiki_FixLocalDomain
