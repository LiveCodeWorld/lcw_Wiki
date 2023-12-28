script "Global | Wiki | Git | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Git | Menu
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

command _MoveWikis wikiDomains, dView, pReDomain
   repeat for each line wikiDomain in wikiDomains
      display_Spin wikiDomain, dView, "green"
      --
      put wiki_GetFolder (wikiDomain) into wikiFolder
      if there is a folder wikiFolder then
         breakpoint
         put wikiDomain & CR after existingDomains
      else
         if pReDomain is empty then
            gitwiki_MoveToLocal wikiDomain, false
         else
            put wiki_ReDomain (wikiDomain, pReDomain) into newName
            gitwiki_MoveToLocal wikiDomain, false, newName
         end if
         put wikiDomain & CR after copiedDomains
      end if
   end repeat
   delete char -1 of copiedDomains
   delete char -1 of existingDomains
   
   put system_GetAdminPassword() into systemPassword
   hosts_Add copiedDomains, systemPassword
   
   if existingDomains is not empty then
      display_Data existingDomains, "Existing", "Local Wiki Domains"
   end if
end _MoveWikis


--> Global | Wiki | Git | Menu
-
on menu_AllGitWikis dView
   set the wiki_Filter of dView to empty
   display_GitWikiFolders dView
end menu_AllGitWikis

on menu_FilterGitWikis displayView
   put the wiki_Filter of displayView into wikiFilter
   put lcw_Ask ("Filter domains...", wikiFilter, "Wiki Filter", displayView) into wikiFilter
   set the wiki_Filter of displayView to wikiFilter
   --
   display_GitWikiFolders displayView, wikiFilter
end menu_FilterGitWikis

private on _
end _

on menu_ListEmptyGitWikis dView
   put gitwiki_ListEmptyFolders (true) into emptyFolders
   display_GitWikis emptyFolders, dView, "none", "Empty Git Folders"
end menu_ListEmptyGitWikis

on menu_MoveToLocal dView
   put the displayed_Index of dView into wikiDomains
   --
   _MoveWikis wikiDomains, dView
   --
   menu_Refresh
end menu_MoveToLocal

on menu_MoveSelectedToLocal dView
   put the selected_Index of dView into wikiDomains
   put lcw_Ask ("Rename wiki domain...", "cico.club", "Rename", dView) into pReDomain
   --
   _MoveWikis wikiDomains, dView, pReDomain
   --
   menu_Refresh
end menu_MoveSelectedToLocal

private on ___
end ___

on menu_DisplayLocalWikis
   display_LocalWikis
end menu_DisplayLocalWikis

on menu_LaunchEtcHosts
   launch_EtcHosts
end menu_LaunchEtcHosts

on menu_Refresh
   put display_FindView ("Local Wikis") into dView
   if exists (dView) then
      put the wiki_Filter of dView into pFilter
   end if
   display_LocalWikis dView, pFilter, pFilter
   display_GitWikiFolders
end menu_Refresh

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Git | Menu")
end submenu_Dev
