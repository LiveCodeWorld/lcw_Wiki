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


--> Global | Wiki | Local | Index | Menu
-
on menu_NewAstralWiki dView
   put lcw_Ask ("Choose a name for your new astral subdomain...", "new", "Create Astral Subdomain", dView) into newSubDomain
   --
   put wiki_RootFolder() into wikiRootFolder
   set the defaultfolder to wikiRootFolder
   put wiki_ListAllLocalFolders ("*astralship.wiki") into wikiFolders
   
   # Check newDomain does not exists
   put newSubDomain & ".astralship.wiki" into newDomain
   if newDomain is among the lines of wikiFolders then
      lcw_AnswerWarning "Folder for subdomain '[[newSubDomain]]' already exists!", dView, newSubDomain
   end if
   
   # Check localDomain does not exists
   put newSubDomain & ".localhost" into localDomain
   if localDomain is among the lines of wikiFolders then
      lcw_AnswerWarning "Folder for local-subdomain '[[newSubDomain]]' already exists!", dView, newSubDomain
   end if
   
   # Register Subdomain DNS
   breakpoint
   astral_AddSubdomain "astralship.wiki", subDomainName
   put the result into dnsData
   
   # Create localDomain 
   create folder localDomain
   
   # Symlink newDomain
   folder_CreateSymLink newDomain, localDomain
   
   # Launch Localhost wiki
   launch_LocalhostWiki localDomain
end menu_NewAstralWiki

on menu_EmptyLocalWikis dView
   display_EmptyLocalWikis dView
end menu_EmptyLocalWikis

on menu_EmptyGitWikis dView
   put gitwiki_ListEmptyFolders (true) into emptyFolders
   display_GitWikis emptyFolders, dView, "none", "Empty Local Wikis"
end menu_EmptyGitWikis

private on ____
end ____

on menu_ListDynadotWikis displayView
   put lcw_Ask ("Which domain...", "outlandish.academy", "Dynadot Domain", displayView) into domainName
   display_DynadotWikis domainName, displayView, ""
end menu_ListDynadotWikis

on menu_DiplayLostWikis
   diplay_GitWikiFolders empty, "*platform.earth"
end menu_DiplayLostWikis

private on _
end _

on menu_AstralDynadotSubdomains dView
   display_LocalWikis dView, "Dynadot Astral Doamins"
end menu_AstralDynadotSubdomains

on menu_AstralNotOnDynadot dView
   -- set the displayed_Index ["Astral Missing from Dynadot"] of dView to missingSubdomains
   display_LocalWikis dView, "Astral Missing from Dynadot"
end menu_AstralNotOnDynadot

private on __
end __

on menu_DisplayLocalWikis dView
   display_LocalWikis dView
end menu_DisplayLocalWikis

on menu_DisplaySymWikis dView
   display_LocalWikis dView, "Sym-Linked"
end menu_DisplaySymWikis

on menu_DisplayNonSymWikis dView
   display_LocalWikis dView, "Non Sym-Linked"
end menu_DisplayNonSymWikis

private on ___
end ___

on menu_Filter displayView
   put lcw_Ask ("Filter domains...", "*platform.earth", "Wiki Filter", displayView) into wikiFilter
   display_LocalWikis displayView, "All Filtered", wikiFilter
end menu_Filter

on submenu_Tunnel
   return menu_CreateTitle ("Global | Tunnel | Menu")
   return "Global | Tunnel | Install | Menu"
end submenu_Tunnel

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Local | Index | Menu")
end submenu_Dev

