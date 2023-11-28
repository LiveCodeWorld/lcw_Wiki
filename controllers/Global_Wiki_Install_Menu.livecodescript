script "Global | Wiki | Install | Menu"
--> MetaData
-
license: GPLv3
name: Global | Wiki | Install | Menu
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
   -- return display_MenuTarget(tObject)
   return the display_View of tObject
end menu_Target

getprop menu_CheckTarget [cameraView]
   return exists (cameraView)
end menu_CheckTarget


--> Global | Wiki | Install | Menu
-
on menu_InstallWiki xtermView
   -- put shell ("npm install -g wiki")
   display_Xterm xtermView
   put the result into xtermView
   --
   ttyd_Paste "npm install -g wiki", xtermView
end menu_InstallWiki

private on _
end _

on menu_NvmNodeVersion xtermView
   shell_Do "nvm current", "execute", xtermView
end menu_NvmNodeVersion

on menu_RevealWikiSiteFolder
   put wiki_RootFolder() into wikiSiteFolder
   finder_Reveal wikiSiteFolder
end menu_RevealWikiSiteFolder

on menu_ShowHiddenFiles mTarget, someBoolean
   finder_SetShowInvisibleFiles someBoolean
   finder_Restart
end menu_ShowHiddenFiles

on menu_RevealWikiModulesFolder
   put wiki_ModulesFolder() into wikiModulesFolder
   finder_Reveal wikiModulesFolder
end menu_RevealWikiModulesFolder

private on __
end __

on menu_EditWikiConfig
   display_WikiConfig
end menu_EditWikiConfig

-- on submenu_Dev
return menu_DevTitle ("Global | Wiki | Install | Menu")
end submenu_Dev
