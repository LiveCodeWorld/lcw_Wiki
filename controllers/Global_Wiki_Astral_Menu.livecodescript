script "Global | Wiki | Astral | Menu"
--> MetaData
-
license: GPLv3
name: Global | Wiki | Astral | Menu
type: controller
author: David Bovill
version: 0.1

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
   -- put display_MenuTarget (tObject) into dView
   put the display_View of tObject into dView
   return dView
end menu_Target

getprop menu_CheckTarget [dView]
   return exists (dView)
end menu_CheckTarget


--> Global | Wiki | Astral | Menu
-
on menu_NewAstralWiki dView
   breakpoint
   put lcw_Ask ("Choose a name for your new astral subdomain...", "new", "Create Astral Subdomain", dView) into newSubDomain
   --
   put wikiFarm_GetFolder() into wikiRootFolder
   set the defaultfolder to wikiRootFolder
   put wikiGarden_ListAllDomains ("astralship.wiki") into wikiFolders
   
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
   symlink_CreateFolder newDomain, localDomain
   
   # Launch Localhost wiki
   launch_LocalhostWiki localDomain
end menu_NewAstralWiki

on menu_AstralDynadotSubdomains dView
   display_LocalWikis dView, "Dynadot Astral Doamins"
end menu_AstralDynadotSubdomains

on menu_AstralNotOnDynadot dView
   -- set the displayed_Index ["Astral Missing from Dynadot"] of dView to missingSubdomains
   display_LocalWikis dView, "Astral Missing from Dynadot"
end menu_AstralNotOnDynadot
