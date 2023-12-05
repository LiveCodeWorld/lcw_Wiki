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
   
   put dynadot_ConstructLocalhostDomain (dynSubDomain) into localhostDomain
   put gitWikiDomain into starDomain
   put "*" into item 1 of starDomain
   
   # Fetch CNAME Value from LocalXpose
   put TunnelDomainArray [gitWikiDomain]["cname"] into cNameValue
   if cNameValue is empty then
      put TunnelDomainArray [starDomain]["cname"] into cNameValue
   end if
end _SetNames

function dynadot_ConstructLocalhostDomain wikidomain
   set the itemdelimiter to "."
   if the number of items of wikidomain = 2 then
      put "wiki." & item 1 of wikidomain & ".localhost" into wikidomain
   else
      put "localhost" into item -2 to -1 of wikidomain
   end if
   return wikidomain
end dynadot_ConstructLocalhostDomain


--> Wiki | Fix
-
function gitwiki_Check gitWikiDomain, pDynSubDomain, pColour, pLoad
   if pDynSubDomain is empty then put gitWikiDomain into pDynSubDomain
   if pLoad is not false then wiki_LoadTunnel
   
   # Work out all the names
   _SetNames gitWikiDomain, pDynSubDomain, tldDomain, dynSubDomainName, localhostDomain, cNameValue, dynadotSubDomains
   
   if tldDomain = gitWikiDomain then
      return gitwiki_CheckDomain (tldDomain, pColour)
   else
      return gitwiki_CheckSubdomain (gitWikiDomain, pDynSubDomain, cNameValue, subdomain, pColour)
   end if
end gitwiki_Check

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

command gitwiki_SymlinkAndRegister gitWikiDomain, pLoad, pDynSubDomain, pAddToHosts
   if pDynSubDomain is empty then put gitWikiDomain into pDynSubDomain
   --
   get gitwiki_Check (gitWikiDomain, pDynSubDomain, false, pLoad)
   if it is not empty then
      return it
   end if
   
   # Construct localhostDomain
   put dynadot_ConstructLocalhostDomain (pDynSubDomain) into localhostDomain
   breakpoint
   
   # Create Symlinks
   gitwiki_CreateSymLink gitWikiDomain, pDynSubDomain
   gitwiki_CreateSymLink gitWikiDomain, localhostDomain
   
   if pAddToHosts is not false then
      # Add to Etc/hosts
      hosts_Add localhostDomain
   end if
   --
   return empty
end gitwiki_SymlinkAndRegister

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

