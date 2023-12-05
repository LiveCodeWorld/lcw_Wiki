script "Global | Wiki | Local | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Local | Menu
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


--> Global | Wiki | Local | Menu
-
on submenu_LocalWiki
   return "Global | Wiki | Local | Index | Menu"
end submenu_LocalWiki

on submenu_GitWiki
   return menu_Create ("Global | Wiki | Git | Menu")
end submenu_GitWiki

private on _
end _

on menu_DisplayThought dView
   display_LocalWikis dView, "Local Thought Domains", "*thought*"
end menu_DisplayThought

on menu_DisplayTwo dView
   display_LocalWikis dView, "Local Twos", "* 2.*"
end menu_DisplayTwo

on menu_DisplayEarth dView
   display_LocalWikis dView, "Local Earth Domains", "*.earth"
   -- display_EarthWikis
end menu_DisplayEarth

private on __
end __

on menu_DisplayNumbers dView
   put the displayed_Index of dView into localhostDomains
   put wiki_RootFolder() into wikiRootFolder
   --
   repeat for each line localhostDomain in localhostDomains
      display_Spin localhostDomain, dView, "red"
      --
      put wikiRootFolder & localhostDomain into localFolder
      --
      put symlink_Destination (localFolder) into destFolder
      switch destFolder
         case empty
            -- Not a symlink
            put wiki_NumberOfpages (localFolder) into numOfPages
            breakpoint
            switch
               case numOfPages is empty
               case numOfPages < 1
                  revDeleteFolder localFolder
                  break
               default
                  -- lots of pages
                  put numOfPages && localhostDomain & CR after numberIndex
            end switch
            break
         case wikiRootFolder
            put wiki_NumberOfpages (localFolder) into numOfPages
            switch
               case numOfPages is empty
                  breakpoint
               case numOfPages < 1
                  breakpoint -- trash?
                  symlink_Delete localFolder
                  break
               default
                  -- lots of pages
                  put numOfPages && localhostDomain & CR after numberIndex
            end switch
            break
         default
            breakpoint
            if there is not a folder destFolder then
               symlink_Delete localFolder
            end if
      end switch 
      
   end repeat
   delete char -1 of numberIndex
   --
   sort numeric localhostDomain by word 1 of each
   set the displayed_Index of dView to numberIndex
end menu_DisplayNumbers

on menu_FixGitFolders dView
   put the displayed_Index of dView into localhostDomains
   put wiki_RootFolder() into rootFolder
   --
   breakpoint
   repeat for each line localhostDomain in localhostDomains
      display_Spin localhostDomain, dView, "red"
      --
      gitwiki_FixLocalDomain localhostDomain, dView
   end repeat
end menu_FixGitFolders

on menu_RemoveSymLinks dView
   put the displayed_Index of dView into wikiDomains
   put wiki_RootFolder() into rootFolder
   --
   repeat for each line wikiDomain in wikiDomains
      display_Spin wikiDomain, dView, "red"
      --
      put rootFolder & wikiDomain into symLinkedFolder 
      symlink_Delete symLinkedFolder
   end repeat
   display_LocalSymWikis dView, "*astralship.wiki", "Sym-linked Astral"
end menu_RemoveSymLinks

private on ___
end ___

on menu_LocalWithoutAstral dView
   put empty into sFilter
   --
   put wiki_RootFolder() into wikiFolder
   put folder_ListShortAll (wikiFolder) into wikiFolders
   --
   put wikiFolders into localhostFolders
   filter localhostFolders with "*localhost"
   --
   repeat for each line localhostDomain in localhostFolders
      put wiki_AstralFromLocalhost (localhostDomain) into astralDomain
      if astralDomain is not among the lines of wikiFolders then
         put localhostDomain & CR after wihtouAstralDomains
      end if
   end repeat
   delete char -1 of wihtouAstralDomains
   --
   url_SortDomainIndex wihtouAstralDomains
   --
   display_WikiFolders wihtouAstralDomains, "Wiki | Local", dView, sFilter, "Local Without Astral", "Local Wikis"
   return the result
end menu_LocalWithoutAstral

on menu_SymAstralWikis dView
   display_LocalSymWikis dView, "*astralship.wiki", "Sym-linked Astral"
end menu_SymAstralWikis

private on ____
end ____

on menu_AllLocalAstralWikis dView
   -- display_LocalWikis dView, "All Astral", "*astralship.wiki"
   display_LocalAstralWikis dView, false
end menu_AllLocalAstralWikis

on menu_LocalhostWikis dView
   display_LocalWikis dView, "All Localhost", "*localhost"
end menu_LocalhostWikis

on menu_NonSymAstralWikis dView
   display_NonSymLinked dView, "*astralship.wiki", "Non-Symlinked Astral"
end menu_NonSymAstralWikis

on menu_Refresh displayView
   display_LocalWikis displayView
end menu_Refresh

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Local | Menu")
end submenu_Dev

