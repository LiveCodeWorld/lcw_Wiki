script "Global | Wiki | Local | Line | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Local | Line | Menu
type: controller
version: 0.2

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
   -- put display_MenuTarget (tObject) into browserView
   put the display_View of tObject into dView
   put the selected_Line of dView into wikiDomain
   put wikiDomain into LocalArray ["wikiDomain"]
   --
   put _GetHostsArray() into hostsArray
   put hostsArray ["domains"][wikiDomain] is empty into LocalArray ["NotInHosts"]
   --
   return dView
end menu_Target

-- getprop menu_CheckTarget [cameraView]
return exists (cameraView)
end menu_CheckTarget

private function _GetHostsArray
   -- delete variable LocalArray ["hostsArray"]
   put LocalArray ["hostsArray"] into hostsArray
   if hostsArray is an array then
      return hostsArray
   else
      put system_GetAdminPassword() into systemPassword
      put hosts_Get (systemPassword) into hostsText
      put hosts_GetArray (hostsText) into hostsArray
      --
      put hostsArray into LocalArray ["hostsArray"]
      return hostsArray
   end if
end _GetHostsArray

private function _GitWikiFolder dView
   put the selected_Line of dView into shortWikiFolder
   put gitwiki_GetFolder (shortWikiFolder) into gitWikiFolder
   return gitWikiFolder
end _GitWikiFolder

private function _LocalWikiFolder dView
   put the selected_Line of dView into shortWikiFolder
   --
   put wiki_RootFolder() into rootFolder
   put rootFolder & shortWikiFolder into symLinkedFolder 
   return symLinkedFolder
end _LocalWikiFolder

private command _Refresh dView
   display_LocalSymWikis dView, "*astralship.wiki", "Sym-linked Astral"
end _Refresh

getprop disabled_TrashLocalFolder [dView]
   if the shiftKey is "down" then return false
   put the selected_Line of dView into shortWikiFolder
   put wikiFolder_Get (shortWikiFolder) into wikiFolder
   --
   return wiki_FolderHasNoPages (wikiFolder) is false
end disabled_TrashLocalFolder

getprop disabled_TrashGitWikiFolder [dView]
   if the shiftKey is "down" then return false
   put _GitWikiFolder (dView) into gitWikiFolder
   --
   return wiki_FolderHasNoPages (gitWikiFolder) is false
end disabled_TrashGitWikiFolder

getprop disabled_DeleteSymLink [dView]
   put _LocalWikiFolder(dView) into symLinkedFolder
   put folder_IsSymLink (symLinkedFolder) into isSymLinked
   return isSymLinked is false
end disabled_DeleteSymLink

getprop disabled_AddToHosts [dView]
   put LocalArray ["wikiDomain"] into wikiDomain
   set the itemdelimiter to "."
   if item -1 of wikiDomain = "localhost" then return true
   --
   return LocalArray ["NotInHosts"] is false
end disabled_AddToHosts

getprop disabled_Display [dView]
   return LocalArray ["NotInHosts"] is true
end disabled_Display


--> Global | Wiki | Local | Line | Menu
-
on menu_DeleteSymLink dView
   put _LocalWikiFolder (dView) into symLinkedFolder
   if folder_IsSymLink (symLinkedFolder) then
      symlink_Delete symLinkedFolder
      display_LocalSymWikis dView
   else
      breakpoint
   end if
end menu_DeleteSymLink

on menu_RenameLocalWiki dView
   put the selected_Line of dView into fromDomain
   --
   put lcw_Ask ("Rename localhost...", fromDomain, "Rename", dView) into toDomain
   --
   put wikiFolder_Get (fromDomain) into oFolder
   put wikiFolder_Construct (toDomain) into newFolder
   if there is a folder newFolder then
      return "Error, folder" && newFolder && "already exists."
   end if
   --
   put system_GetAdminPassword() into systemPassword
   hosts_Rename fromDomain, toDomain, systemPassword
   --
   revMoveFolder oFolder, newFolder
   --
   put wiki_Browser() into browserView
   display_Wiki toDomain, browserView
   --
   display_LocalWikis dView
end menu_RenameLocalWiki

-- on menu_AddTools dView
put the selected_Line of dView into wikiDomain
--
put wikiFolder_Get (wikiDomain) into wikiFolder
put wikiFolder & "tools" into toolFile
if there is not a file toolFile then
   put pageArray_Get (wikiDomain, "tools")
else
   breakpoint
end if
end menu_AddTools

on menu_AddToHosts dView
   put the selected_Line of dView into wikiDomain
   put system_GetAdminPassword() into systemPassword
   hosts_Add wikiDomain, systemPassword
   --
   put wiki_Browser() into browserView
   display_Wiki wikiDomain, browserView
end menu_AddToHosts

on menu_RecreateSitemap dView
   put the selected_Line of dView into wikiDomain
   --
   wikiSiteMap_DeleteFile wikiDomain
   wikiSiteMap_Create wikiDomain
end menu_RecreateSitemap

private on __
end __

on menu_LaunchInBrowser dView
   put the selected_Line of dView into wikiDomain
   --
   put "http://" & wikiDomain into wikiURL
   launch url wikiURL
end menu_LaunchInBrowser

on menu_DisplayWikiApp dView
   put the selected_Line of dView into wikiDomain
   --
   put wiki_Browser() into browserView
   display_Wiki wikiDomain, browserView
end menu_DisplayWikiApp

on menu_DisplaySiteMap dView
   put the selected_Line of dView into wikiDomain
   --
   display_WikiSitePageArray wikiDomain
end menu_DisplaySiteMap

private on _____
end _____

on menu_RevealLocalFolder dView
   put the selected_Line of dView into shortWikiFolder
   put wikiFolder_Get (shortWikiFolder) into gitWikiFolder
   --
   finder_Reveal gitWikiFolder
end menu_RevealLocalFolder

on menu_TrashLocalFolder dView
   put the selected_Line of dView into shortWikiFolder
   put wikiFolder_Get (shortWikiFolder) into wikiFolder
   --
   revDeleteFolder wikiFolder
   --
   display_LocalWikis dView
end menu_TrashLocalFolder

private on ___
end ___

on menu_RevealGitwikiFolder dView
   put the selected_Line of dView into shortWikiFolder
   put gitwiki_GetFolder (shortWikiFolder) into gitWikiFolder
   --
   finder_Reveal gitWikiFolder
end menu_RevealGitwikiFolder

on menu_TrashGitwikiFolder dView
   put the selected_Line of dView into shortWikiFolder
   put gitwiki_GetFolder (shortWikiFolder) into gitWikiFolder
   --
   revDeleteFolder gitWikiFolder
   --
   set the deleted_Line of dView to shortWikiFolder
   if the displayed_Index of dView is empty then
      display_GitWikiFolders
   end if
end menu_TrashGitwikiFolder

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Local | Line | Menu")
end submenu_Dev
