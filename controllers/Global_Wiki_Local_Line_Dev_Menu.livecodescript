script "Global | Wiki | Local | Line | Dev | Menu"
--> MetaData
-
license: GPLv3
name: Global | Wiki | Local | Line | Dev | Menu
type: controller
author: David Bovill
version: 0.1

/*
Here you can describe this developer menu.
Full help text should be provided on the linked wiki.

Consider improving by creating with same menu_Target as no-developer menu is is based on.
*/

--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_Target [tObject]
   -- return display_MenuTarget(tObject)
   return the display_View of tObject
end menu_Target

getprop menu_CheckTarget [mTarget]
   return exists (mTarget)
end menu_CheckTarget


--> Global | Wiki | Local | Line | Dev | Menu
-
on menu_TestSymLink dView
   put _SymlinkedFolder(dView) into symLinkedFolder
   ---
   put "ls -la"&& kwote (symLinkedFolder) into someShell
   put shell (someShell) -- lrw-------  1 david  staff  36 Jan  1  1970 /Users/david/Documents/git-repos/Earth/project.astralship.wiki -> /Users/david/.wiki/project.localhost
   -- put files (someShell)
end menu_TestSymLink

on menu_SymLinkAndRegister displayView
   set the itemdelimiter to "."
   put the selected_Line of displayView into gitWikiDomain
   put item -2 to -1 of gitWikiDomain into tlDomain
   --
   put dynadot_ListSubdomains (gitWikiDomain, true) into subDomainNames
   put item 1 to -3 of dynSubDomain into dynSubDomainName
   --
   -- put "yhdhcbundskxzwc.eu.loclx.io" into cNameValue
   put tunnel_FetchDomainArray() into domainArray
   put domainArray [gitWikiDomain]["cname"] into cNameValue
   --
   put lcw_Ask ("Create Dynadot CNAME?", gitWikiDomain, "Dynadot", displayView) into dynSubDomain
   
   switch
      case dynSubDomainName is among the lines of subDomainNames
         lcw_AnswerWarning  "Subdomain '[[subDomainName]]' already registered!", displayView, dynSubDomainName
         break 
      case dynSubDomain = "platform.earth"
      case dynSubDomain = "together.platform.earth"
         lcw_AnswerWarning "Reserved subdomain", displayView
         break
      case cNameValue is empty
         breakpoint
         break
      case item -2 to -1 of dynSubDomain is "platform.earth"
         breakpoint
         dynadot_AddSubdomain gitWikiDomain, dynSubDomainName, cNameValue
         --
         gitwiki_CreateSymLink gitWikiDomain, dynSubDomain
         --
         display_EarthWikis
         diplay_GitWikiFolders
         break
   end switch
end menu_SymLinkAndRegister

private on _
end _

on menu_AddToDynadot displayView
   set the itemdelimiter to "."
   put the selected_Line of displayView into tlDomain
   if the number of items of tlDomain is not 2 then
      breakpoint
      exit to top
   end if
   --
   put tunnel_GetRegisteredCName (tlDomain) into mainTunnel
   if mainTunnel is empty then
      breakpoint
   else
      dynadot_SetMainDomain tlDomain, mainTunnel
   end if
   --
   gitwiki_CreateSymLink tlDomain, tlDomain
   display_DynadotDomain tlDomain
end menu_AddToDynadot

on menu_AddSubdomainToDynadot displayView
   set the itemdelimiter to "."
   put the selected_Line of displayView into wikiSubDomain
   --
   put item -2 to -1 of wikiSubDomain into tlDomain
   put "*." & tlDomain into starDomain
   put tunnel_GetRegisteredCName (starDomain) into subTunnel
   --
   if subTunnel is empty then
      breakpoint
   else
      put item 1 to -3 of wikiSubDomain into subDomainName
      dynadot_AddSubdomain tlDomain, subDomainName, subTunnel
   end if
   --
   gitwiki_CreateSymLink wikiSubDomain, wikiSubDomain
   display_DynadotDomain tlDomain
end menu_AddSubdomainToDynadot

on menu_MoveToDead dView
   put the selected_Line of dView into shortWikiFolder
   put gitwiki_GetFolder (shortWikiFolder) into gitWikiFolder
   put gitwiki_GetFolder ("dead.anarchive.earth") into toFolder
   --
   revMoveFolder gitWikiFolder, toFolder
end menu_MoveToDead


