script "Global | Wiki | Git | Line | Dev | Menu"
--> MetaData
-
license: GPLv3
name: Global | Wiki | Git | Line | Dev | Menu
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

getprop disabled_MakeSymLink [displayView]
   put the selected_Line of displayView into wDomain
   put wiki_GetFolder (wDomain) into symWikiFolder
   return there is a folder symWikiFolder
end disabled_MakeSymLink


--> Global | Wiki | Git | Line | Dev | Menu
-
on menu_CopyToLocal dView
   put the selected_Line of dView into wikiDomain
   --
   gitwiki_MoveToLocal wikiDomain
   --
   put wiki_Browser() into browserView
   display_LocalWikis
   display_Wiki wikiDomain, browserView
end menu_CopyToLocal

on menu_CopyAndRename dView
   put the selected_Line of dView into wikiDomain
   --
   put lcw_Ask ("Rename domain...", wikiDomain, "Rename", dView) into newName
   gitwiki_MoveToLocal wikiDomain, true, newName
   --
   put wiki_Browser() into browserView
   --
   _DisplayLocalWikis newName, dView
   display_GitWikiFolders
   display_Wiki wikiDomain, browserView
end menu_CopyAndRename

on menu_MakeGitLocalSymlink dView
   put the selected_Line of dView into wikiDomain
   put lcw_Ask ("What domain do you want for the symlink?", wikiDomain) into symLinkDomain
   put wiki_ConstructLocalHostDomain (symLinkDomain) into localhostDomain
   --
   # Create Localhost Symlink
   put gitwiki_GetFolder (wikiDomain) into gitWikiFolder
   put gitwiki_ConstructFolder (localhostDomain) into symLocalhostFolder
   --
   symlink_CreateFolder gitWikiFolder, symLocalhostFolder
   get the result
   if it is empty then
      lcw_Answer "Created symlink!", dView
   else
      lcw_Answer it, dView
   end if
end menu_MakeGitLocalSymlink

on menu_MakeSymlinks dView
   put the selected_Line of dView into gitWikiDomain
   put lcw_Ask ("What domain do you want for the symlink?", gitWikiDomain) into symLinkDomain
   --
   gitwiki_SymlinksAndAddHost symLinkDomain
   --
   lcw_Answer "Created symlink!", dView
end menu_MakeSymlinks

on menu_RemoveSymlinks displayView
   put the selected_Line of displayView into wikiDomain
   put wiki_CheckFolderColour (wikiDomain) into sColour
   set the line_Colour [wikiDomain] of displayView to sColour
   --
   -- if sColour = "green" then
   lcw_Answer "Delete symlink for '[[wikiDomain]]'?", displayView, wikiDomain
   --
   _DeleteSymLinks wikiDomain
   --
   put wiki_CheckFolderColour (wikiDomain) into sColour
   set the line_Colour [wikiDomain] of displayView to sColour
   -- end if
end menu_RemoveSymlinks

private command _DeleteSymLinks wikiDomain
   # Delete symlink folder
   put wiki_ConstructFolder (wikiDomain) into symLinkedFolder 
   symlink_Delete symLinkedFolder
   get the result
   
   # Delete localhost folder
   put wiki_ConstructLocalHostDomain (wikiDomain) into localhostDomain
   put wiki_ConstructFolder (localhostDomain) into localhostFolder
   symlink_Delete localhostFolder
   get the result
   
   # Delete old
   put old_LocalhostFolder (wikiDomain) into oldLocalhostDomain
   put wiki_ConstructFolder (oldLocalhostDomain) into oldSymlinkFolder
   symlink_Delete oldSymlinkFolder
   get the result
end _DeleteSymLinks

on menu_MoveToDead dView
   put the selected_Line of dView into shortWikiFolder
   put gitwiki_GetFolder (shortWikiFolder) into gitWikiFolder
   put gitwiki_GetFolder ("dead.anarchive.earth") into toFolder
   --
   revMoveFolder gitWikiFolder, toFolder
end menu_MoveToDead

getprop checked_Internet
   return LocalArray ["disabled_Register"] is false
end checked_Internet

on menu_Internet
   put LocalArray ["disabled_Register"] is not true into LocalArray ["disabled_Register"]
end menu_Internet


