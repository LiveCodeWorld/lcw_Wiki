script "Global | Wiki | Local | Index | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Local | Index | Menu
type: controller
version: 0.1

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

private function _SelectedDomains dView
   put the selected_Index of dView into sDomains
   if sDomains is empty then
      put the displayed_Index of dView into sDomains
   end if
   return sDomains
end _SelectedDomains


--> Global | Wiki | Local | Index | Menu
-
on menu_ConstructRoster dView
   put _SelectedDomains(dView) into sDomains
   --
   put sDomains
end menu_ConstructRoster

private on ____
end ____

on menu_FilterLocalWikis dView
   put the wiki_Filter of dView into wikiFilter
   put lcw_Ask ("Filter domains...", wikiFilter, "Wiki Filter", dView) into wikiFilter
   display_LocalWikis dView, "All Filtered", wikiFilter
end menu_FilterLocalWikis

on menu_ListLocalWikis dView
   set the wiki_Filter of dView to empty
   display_LocalWikis dView
end menu_ListLocalWikis

on menu_ListEmptyLocalWikis dView
   display_EmptyLocalWikis dView
end menu_ListEmptyLocalWikis

private on _
end _

on menu_TrashEmptyLocalWikis dView
   display_EmptyLocalWikis dView
   lcw_Answer "Trash displayed folders without pages?", dView
   --
   put the displayed_Index of dView into emptyLocalWikiDomains
   --
   wiki_TrashEmpty emptyLocalWikiDomains, dView
end menu_TrashEmptyLocalWikis

on menu_AddTools dView
   breakpoint
   put the displayed_Index of dView into emptyLocalWikiDomains
   repeat for each line wikiDomain in emptyLocalWikiDomains
      display_Spin wikiDomain, dView, "red"
      put the result into lineNum
      --
      put wiki_GetFolder (wikiDomain) into wikiFolder
      if there is a folder wikiFolder then
         
      else
         breakpoint
      end if
   end repeat
end menu_AddTools

private on __
end __

on menu_LaunchEtcHosts
   launch_EtcHosts
   if the shiftKey is "Down" then
      display_EtcHosts
   end if
end menu_LaunchEtcHosts

on menu_CreateLocalWiki dView
   put the selected_Line of dView into wikiDomain
   put lcw_Ask ("Add new wiki domain to /etchosts?", wikiDomain, "Local Wiki Domain", dView) into wikiDomain
   --
   wikiServer_Create wikiDomain
   display_LocalWikis dView
   --
   put wiki_Browser() into browserView
   display_Wiki wikiDomain, browserView
end menu_CreateLocalWiki

on menu_RecreateEtcHosts dView
   lcw_Answer "Recreate /etc/hosts from local wiki folders?", dView
   --
   set the wiki_Filter of dView to empty
   display_LocalWikis dView
   put wiki_ListLocalShortAll() into wikiFolders
   --
   put hosts_NewText (wikiFolders) into hostsText
   hosts_Set hostsText
   --
   launch_EtcHosts
end menu_RecreateEtcHosts

on menu_InitialiseGit dView
   put wiki_RootFolder() into gitRootFolder
   git_InitFolder gitRootFolder
end menu_InitialiseGit

private on ___
end ___

on submenu_Astral
   return menu_CreateTitle ("Global | Wiki | Astral | Menu")
end submenu_Astral

on menu_ListDynadotWikis displayView
   put lcw_Ask ("Which domain...", "outlandish.academy", "Dynadot Domain", displayView) into domainName
   display_DynadotWikis domainName, displayView, ""
end menu_ListDynadotWikis

-- on menu_DisplayLostWikis
   display_GitWikiFolders empty, "*platform.earth"
end menu_DisplayLostWikis

on submenu_Tunnel
   return menu_CreateTitle ("Global | Tunnel | Menu")
   return "Global | Tunnel | Install | Menu"
end submenu_Tunnel

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Local | Index | Menu")
end submenu_Dev
