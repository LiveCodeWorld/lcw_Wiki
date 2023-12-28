script "Global | Wiki | Git | Line | Register | Menu"
--> MetaData
-
license: GPLv3
name: Global | Wiki | Git | Line | Register | Menu
type: controller
author: David Bovill
version: 0.1

/*
Here you can describe this menu.
Full help text should be provided on the linked wiki.
*/

--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_Target [tObject]
   -- put display_MenuTarget (tObject) into dView
   put the display_View of tObject into dView
   return dView
end menu_Target

-- getprop menu_CheckTarget [dView]
   return exists (dView)
end menu_CheckTarget

getprop disabled_RegisterLocalXpose [displayView]
   set the itemdelimiter to "."
   put the selected_Line of displayView into gitWikiDomain
   put item -2 to -1 of gitWikiDomain into tlDomain
   --
   put tunnel_GetRegisteredCName(tlDomain) into cNameValue
   return cNameValue is not empty
end disabled_RegisterLocalXpose

getprop disabled_AddToDynadot [displayView]
   set the itemdelimiter to "."
   put the selected_Line of displayView into wikiDomain
   --
   if the number of items of wikiDomain = 2 then
      return false
   else
      return true
   end if 
end disabled_AddToDynadot

getprop disabled_AddSubdomainToDynadot [displayView]
   set the itemdelimiter to "."
   put the selected_Line of displayView into wikiDomain
   --
   if the number of items of wikiDomain = 2 then
      return true
   else
      return false
   end if 
end disabled_AddSubdomainToDynadot


--> Global | Wiki | Git | Line | Register | Menu
-
on menu_SymLinkAndRegister displayView
   put the selected_Line of displayView into gitWikiDomain
   --
   put lcw_Ask ("Create Dynadot CNAME?", gitWikiDomain, "Dynadot", displayView) into dynDomain
   --
   gitwiki_SymlinkAndRegister gitWikiDomain, dynDomain
   --
   display_EarthWikis
   diplay_GitWikiFolders
end menu_SymLinkAndRegister

private on _
end _

on menu_RegisterLocalXpose displayView
   breakpoint
   set the itemdelimiter to "."
   put the selected_Line of displayView into gitWikiDomain
   put domain_GetTld (gitWikiDomain) into tldDomain
   --
   tunnel_ReserveLocalDomain tldDomain, "eu"
   put the result into cNameValue
   --
   dynadot_AddSubdomain tldDomain, "*", cNameValue
   gitwiki_CreateSymLink tldDomain, tlDomain
   --
   display_EarthWikis
   diplay_GitWikiFolders
end menu_RegisterLocalXpose

private on __
end __

on menu_AddTopLevelDomainToDynadot displayView
   breakpoint
   put the selected_Line of displayView into sDomain
   put domain_GetTld (sDomain) into tldDomain
   --
   put tunnel_GetRegisteredCName (tldDomain) into mainTunnel
   if mainTunnel is empty then
      breakpoint
   else
      dynadot_SetMainDomain tldDomain, mainTunnel
   end if
   --
   gitwiki_CreateSymLink tldDomain, tlDomain
   display_DynadotDomain tldDomain
end menu_AddTopLevelDomainToDynadot

on menu_AddSubdomainToDynadot displayView
   set the itemdelimiter to "."
   put the selected_Line of displayView into wikiSubDomain
   --
   put domain_GetTld (wikiSubDomain) into tldDomain
   --
   put "*." & tldDomain into starDomain
   put tunnel_GetRegisteredCName (starDomain) into subTunnel
   --
   if subTunnel is empty then
      breakpoint
   else
      put item 1 to -3 of wikiSubDomain into subDomainName
      dynadot_AddSubdomain tldDomain, subDomainName, subTunnel
   end if
   --
   gitwiki_CreateSymLink wikiSubDomain, wikiSubDomain
   display_DynadotDomain tldDomain
end menu_AddSubdomainToDynadot
