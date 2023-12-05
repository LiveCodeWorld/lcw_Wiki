script "Global | Wiki | Local | Line | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Local | Line | Menu
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

-- getprop menu_CheckTarget [cameraView]
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

private function _SymlinkedFolder dView
   put the selected_Line of dView into shortWikiFolder
   --
   put wiki_RootFolder() into rootFolder
   put rootFolder & shortWikiFolder into symLinkedFolder 
   return symLinkedFolder
end _SymlinkedFolder

private command _Refresh dView
   display_LocalSymWikis dView, "*astralship.wiki", "Sym-linked Astral"
end _Refresh

command symlink_FolderInfo wikiFolder, @twoExists, @twoDestFolder, @numOfPages
   put there is a folder wikiFolder into twoExists
   if twoExists then      
      if folder_IsSymLink (wikiFolder) then
         put symlink_Destination (twoFolder) into twoDestFolder
         put wiki_NumberOfpages (twoDestFolder) into numOfPages
      else
         put wiki_NumberOfpages (wikiFolder) into numOfPages
      end if
   end if
end symlink_FolderInfo

-- on menu_MakeSymLink dView
put the selected_Line of dView into shortWikiFolder
put wiki_RootFolder() into rootFolder
put rootFolder & shortWikiFolder into symLinkedFolder 
--
put lcw_Ask ("Create Astral symlink?", shortWikiFolder) into symLinkDomain
--
gitwiki_CreateSymLink shortWikiFolder, symLinkDomain
--
lcw_Answer "Created symlink!", dView
finder_Reveal symWikiFolder
end menu_MakeSymLink


--> Global | Wiki | Local | Line | Menu
-
on menu_FixTwo dView
   put the selected_Line of dView into localhostDomain
   --
   if localhostDomain contains " 2." then
      put localhostDomain into fixedName
      replace " 2." with "." in fixedName
      --
      put wiki_GetFolder (localhostDomain) into twoFolder
      put wiki_ConstructFolder (fixedName) into fixedFolder 
      --
      
      --
      put there is a folder fixedFolder into fixedExists
      if fixedExists then
         if folder_IsSymLink (fixedFolder) then
            put true into fixedIsSymLinked
         else if wiki_FolderHasNoPages (fixedFolder) is true then
            put true into fixedIsEmpty
         else
            put false into fixedIsEmpty
         end if
      end if
      
      breakpoint
      
      if there is a folder fixedFolder then
         if wiki_FolderHasNoPages (fixedFolder) is true then
            if folder_IsSymLink (fixedFolder) is true then
               breakpoint
               return "Error, fixed symlink folder alreaady exists."
            else
               revDeleteFolder fixedFolder
            end if
         else
            breakpoint
            if folder_IsSymLink (twoFolder) then
               put symlink_Destination (twoFolder) into twoDestFolder
               symlink_Delete twoFolder
               symlink_CreateFolder twoDestFolder, fixedFolder
            else
               if wiki_FolderHasNoPages (twoFolder) is true then
                  put symlink_Destination (twoFolder) into twoDestFolder
                  revDeleteFolder twoFolder
                  symlink_CreateFolder twoDestFolder, twoFolder
               else if wiki_FolderHasNoPages (fixedFolder) is true then
                  put symlink_Destination (twoFolder) into twoDestFolder
                  if twoDestFolder is empty then
                     breakpoint
                     return "Error, twoFolder is not a symlink"
                  end if
                  --
                  revDeleteFolder fixedFolder
                  symlink_CreateFolder twoDestFolder, fixedFolder
               else
                  return "Error, fixed folder alreaady exists."
               end if
            end if
         end if
      end if
      --
      if folder_IsSymLink (twoFolder) then
         put wiki_RootFolder() into rootFolder
         set the defaultfolder to rootFolder
         -- put merge ("mv '[[twoFolder]]' '[[fixedFolder]]'") into someShell
         put merge ("mv '[[localhostDomain]]' '[[fixedName]]'") into someShell
         replace "'" with quote in someShell
         --
         put shell (someShell) into mvResult
         put "ls -l" && kwote (fixedName) into someShell
         put shell (someShell) into lsResult
         --
         set the itemdelimiter to comma
         -- lrwxr-xr-x@ 1 david  staff  73 Jan  1  1970 events.thought.garden -> /Users/david/Documents/git-repos/LiveCodeWorld/wiki/events.thought.garden
         put lsResult contains (fixedName & " -> ") into fixedLink
         --
         display_LocalWikis dView, "Local Twos", "* 2.*"
      end if
      --
   end if
end menu_FixTwo

on menu_FixGitSymlink dView
   put the selected_Line of dView into localhostDomain
   --
   gitwiki_FixLocalDomain localhostDomain
end menu_FixGitSymlink

on menu_MakeAstralSymLink dView
   put the selected_Line of dView into localhostDomain
   put wiki_RootFolder() into rootFolder
   put rootFolder & localhostDomain into symLinkedFolder 
   --
   put wiki_AstralFromLocalhost (localhostDomain) into astralDomain
   put lcw_Ask ("Create Astral symlink?", astralDomain) into symLinkDomain
   --
   wiki_CreateSymLink localhostDomain, symLinkDomain
   --
   display_LocalWithoutAstral dView
end menu_MakeAstralSymLink

on menu_DeleteSymLink dView
   put _SymlinkedFolder(dView) into symLinkedFolder
   symlink_Delete symLinkedFolder
   _Refresh dView
end menu_DeleteSymLink

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
      display_GitWikiFolders
   end if
end menu_TrashFolder

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Local | Line | Menu")
end submenu_Dev

