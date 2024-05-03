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


--> Global | Wiki | Local | Line | Dev | Menu
-
on menu_FixTwo dView
   put the selected_Line of dView into localhostDomain
   --
   if localhostDomain contains " 2." then
      put localhostDomain into fixedName
      replace " 2." with "." in fixedName
      --
      put wikiFolder_Get (localhostDomain) into twoFolder
      put wikiFolder_Construct (fixedName) into fixedFolder 
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
