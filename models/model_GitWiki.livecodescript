script "model_GitWiki"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_GitWiki
type: model
version: 0.1

--> Variables
-
local DynadotSubDomains


--> GitWiki | Fix
-
command gitwiki_MoveToLocal wikiDomain, pAddTohosts, pNewName
   put gitwiki_GetFolder (wikiDomain) into gitWikiFolder
   if pNewName is empty then
      put wikiFolder_Get (wikiDomain) into localFolder
   else
      put wikiFolder_Get (pNewName) into localFolder
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
      put wikiFolder_Get (wikiDomain) into localFolder
   else
      put wikiFolder_Get (pNewName) into localFolder
   end if
   --
   if there is a folder localFolder then
      breakpoint
      return "Error, folder" && localFolder && "already exists."
   else
      if pNewName is empty then
         put wikiFarm_GetFolder() into wikiRootFolder
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
   put wikiFolder_Get (localhostDomain) into wikiFolder
   put gitwiki_GetFolder (localhostDomain) into gitWikiFolder
   --
   put wikiFolder_NumberOfPages (wikiFolder) into wikiPageNum
   put wikiFolder_NumberOfPages (gitWikiFolder) into gitWikiPageNum
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


--> GitWiki
-
command gitwiki_CreateSymLink gitWikiDomain, pSymLinkDomain
   if pSymLinkDomain is empty then
      put gitWikiDomain into pSymLinkDomain
   end if
   --
   put gitwiki_GetFolder (gitWikiDomain) into gitWikiFolder
   put wikiFolder_Get (pSymLinkDomain) into symWikiFolder
   --
   symlink_CreateFolder gitWikiFolder, symWikiFolder
   --
   if the result is empty then
      return pSymLinkDomain
   else
      breakpoint
      return "Error," && the result
   end if
end gitwiki_CreateSymLink


--> Gitwiki | Folders
-
function gitwiki_ConstructFolder sDomain
   put gitwiki_RootFolder() into gitWikiFolder
   put gitWikiFolder & sDomain into folderPath 
   return folderPath
end gitwiki_ConstructFolder

function gitwiki_GetFolder sDomain
   put gitwiki_ConstructFolder(sDomain) into folderPath
   if there is a folder folderPath then
      return folderPath
   else
      return empty
   end if
end gitwiki_GetFolder

function gitwiki_ListAllLocalFolders pFilter
   put gitwiki_RootFolder() into rootFolder
   --
   put folder_ListShortAll (rootFolder) into shortWikiFolders
   put _NotTheseWikiFolders() into notThese
   put wikiFolder_StripNotThese (shortWikiFolders, notThese) into goodShortFolders
   --
   if pFilter is not empty then filter wikiFolders with pFilter
   url_SortDomainIndex goodShortFolders
   --
   return goodShortFolders
end gitwiki_ListAllLocalFolders

function gitwiki_ListFolders pListshort
   put gitwiki_RootFolder() into rootFolder
   put _NotTheseWikiFolders() into notThese
   --
   if pListshort is true then
      put wiki_ListShortFolders (rootFolder, notThese) into gitWikiFolders
   else
      put wiki_ListFolders (rootFolder, notThese) into gitWikiFolders
   end if
   return gitWikiFolders
end gitwiki_ListFolders

function gitwiki_ListEmptyFolders pListShort
   put gitwiki_RootFolder() into rootFolder
   put wikiFolder_ListEmpty (rootFolder, pListShort, ".git,fedwiki_owners,dead.anarchive.earth") into emptyFolders
   return emptyFolders
end gitwiki_ListEmptyFolders

function gitwiki_RootFolder
   put env_GetRepoFolder() into repoFolder
   put repoFolder & "wiki/" into gitWikiFolder
   return gitWikiFolder
end gitwiki_RootFolder


--> Private
-
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

private function _NotTheseWikiFolders
   put ".git,fedwiki_owners,dead.anarchive.earth" into notThese
   return notThese
end _NotTheseWikiFolders


