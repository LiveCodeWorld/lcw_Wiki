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


--> Global | Wiki | Git | Menu
-
on menu_AllGitWikis dView
   display_GitWikiFolders dView
end menu_AllGitWikis

on menu_FilterGitWikis displayView
   put the wiki_Filter of displayView into wikiFilter
   put lcw_Ask ("Filter domains...", wikiFilter, "Wiki Filter", displayView) into wikiFilter
   --
   display_GitWikiFolders displayView, wikiFilter
end menu_FilterGitWikis

private on _
end _

on menu_CheckDisplayed dView   
   wiki_LoadTunnel
   --
   set the itemdelimiter to "."
   put the displayed_Index of dView into gitWikiDomains
   repeat for each line gitWikiDomain in gitWikiDomains
      put gitwiki_Check (gitWikiDomain, gitWikiDomain, true, false) into someColour
      --
      display_Spin gitWikiDomain, dView, someColour
   end repeat
end menu_CheckDisplayed
   
on menu_SymlinkDisplayed dView
   wiki_LoadTunnel
   --
   set the itemdelimiter to "."
   put the displayed_Index of dView into gitWikiDomains
   repeat for each line gitWikiDomain in gitWikiDomains
      gitwiki_SymlinkAndRegister gitWikiDomain, false, gitWikiDomain, false
      display_Spin gitWikiDomain, dView, "green"
   end repeat
   
   hosts_Add gitWikiDomains
end menu_SymlinkDisplayed

on menu_AddToEtcHosts dView
   put the displayed_Index of dView into gitWikiDomains
   hosts_Add gitWikiDomains
end menu_AddToEtcHosts

on menu_EmptyGitWikis dView
   put gitwiki_ListEmptyFolders (true) into emptyFolders
   display_GitWikis emptyFolders, dView, "none", "Empty Git Folders"
end menu_EmptyGitWikis

private on __
end __

on menu_DisplayNumbers dView
   put the displayed_Index of dView into gitWikiDomains
   put gitwiki_RootFolder() into gitwikiRootFolder
   --
   repeat for each line gitWikiDomain in gitWikiDomains
      display_Spin gitWikiDomain, dView, "green"
      --
      put gitwikiRootFolder & gitWikiDomain into gitWikiFolder
      --
      put symlink_Destination (gitWikiFolder) into destFolder
      switch destFolder
         case empty
            -- Not a symlink
            put wiki_NumberOfpages (gitWikiFolder) into numOfPages
            switch
               case numOfPages is empty
               case numOfPages < 1
                  breakpoint
                  revDeleteFolder gitWikiFolder
                  break
               default
                  -- lots of pages
                  put numOfPages && gitWikiDomain & CR after numberIndex
            end switch
            break
         case wikiRootFolder
            put wiki_NumberOfpages (gitWikiFolder) into numOfPages
            switch
               case numOfPages is empty
                  breakpoint
               case numOfPages < 1
                  breakpoint -- trash?
                  symlink_Delete gitWikiFolder
                  break
               default
                  -- lots of pages
                  put numOfPages && gitWikiDomain & CR after numberIndex
            end switch
            break
         default
            breakpoint
            if there is not a folder destFolder then
               breakpoint
               symlink_Delete gitWikiFolder
            end if
      end switch 
      
   end repeat
   delete char -1 of numberIndex
   --
   sort numeric numberIndex by word 1 of each
   set the displayed_Index of dView to numberIndex
end menu_DisplayNumbers

on menu_LaunchEtcHosts
   launch_EtcHosts
end menu_LaunchEtcHosts

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Git | Menu")
end submenu_Dev

