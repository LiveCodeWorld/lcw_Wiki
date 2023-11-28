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
      shell_DeleteSymLink symLinkedFolder
   end repeat
   display_LocalWikis dView, "Sym-linked Astral", "*astralship.wiki"
end menu_RemoveSymLinks

private on _
end _

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
   display_LocalWikis dView, "Sym-linked Astral", "*astralship.wiki"
end menu_SymAstralWikis

private on __
end __

on menu_AllLocalAstralWikis dView
   display_LocalWikis dView, "All Astral", "*astralship.wiki"
end menu_AllLocalAstralWikis

on menu_LocalhostWikis dView
   display_LocalWikis dView, "All Localhost", "*localhost"
end menu_LocalhostWikis

on menu_NonSymAstralWikis dView
   display_LocalWikis dView, "Non-Symlinked Astral", "*astralship.wiki"
end menu_NonSymAstralWikis

on submenu_LocalWiki
   return "Global | Wiki | Local | Index | Menu"
end submenu_LocalWiki

on menu_Refresh displayView
   display_LocalWikis displayView
end menu_Refresh

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Local | Menu")
end submenu_Dev

