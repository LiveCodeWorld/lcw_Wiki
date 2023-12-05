script "Global | Wiki | Git | Line | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Git | Line | Menu
type: controller
version: 0.2

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_Target [tObject]
   -- return display_MenuTarget(tObject)
   return the display_View of tObject
end menu_Target

getprop menu_CheckTarget [cameraView]
   return exists (cameraView)
end menu_CheckTarget

getprop disabled_MakeSymLink [displayView]
   put the selected_Line of displayView into wDomain
   put wiki_GetFolder (wDomain) into symWikiFolder
   return there is a folder symWikiFolder
end disabled_MakeSymLink

getprop disabled_RegisterLocalXpose [displayView]
   put _SelectedCnameValue (displayView) into cNameValue
   return cNameValue is not empty
end disabled_RegisterLocalXpose

private function _SelectedCnameValue displayView
   set the itemdelimiter to "."
   put the selected_Line of displayView into gitWikiDomain
   put item -2 to -1 of gitWikiDomain into tlDomain
   --
   put tunnel_GetRegisteredCName(tlDomain) into cNameValue
   return cNameValue
end _SelectedCnameValue

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

private function _GitWikiFolder dView
   put the selected_Line of dView into shortWikiFolder
   put gitwiki_GetFolder (shortWikiFolder) into gitWikiFolder
   return gitWikiFolder
end _GitWikiFolder

getprop disabled_TrashFolder [dView]
   if the shiftKey is "down" then return false
   put _GitWikiFolder (dView) into gitWikiFolder
   --
   return wiki_FolderHasNoPages (gitWikiFolder) is false
end disabled_TrashFolder


--> Global | Wiki | Git | Line | Menu
-
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

on menu_MakeSymLink displayView
   put the selected_Line of displayView into gitWikiDomain
   put lcw_Ask ("What domain do you want for the symlink?", gitWikiDomain) into symLinkDomain
   --
   gitwiki_CreateSymLink gitWikiDomain, symLinkDomain
   --
   lcw_Answer "Created symlink!", displayView
   finder_Reveal symWikiFolder
end menu_MakeSymLink

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

on menu_MoveToDead dView
   put the selected_Line of dView into shortWikiFolder
   put gitwiki_GetFolder (shortWikiFolder) into gitWikiFolder
   put gitwiki_GetFolder ("dead.anarchive.earth") into toFolder
   --
   revMoveFolder gitWikiFolder, toFolder
end menu_MoveToDead

private on __
end __

on menu_RevealFolder dView
   put the selected_Line of dView into shortWikiFolder
   put gitwiki_GetFolder (shortWikiFolder) into gitWikiFolder
   --
   finder_Reveal gitWikiFolder
end menu_RevealFolder

on menu_TrashFolder dView
   put the selected_Line of dView into shortWikiFolder
   put gitwiki_GetFolder (shortWikiFolder) into gitWikiFolder
   --
   revDeleteFolder gitWikiFolder
   --
   set the deleted_Line of dView to shortWikiFolder
   if the displayed_Index of dView is empty then
      diplay_GitWikiFolders
   end if
end menu_TrashFolder

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Git | Line | Menu")
end submenu_Dev

