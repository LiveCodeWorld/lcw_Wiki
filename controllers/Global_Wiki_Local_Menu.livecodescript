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

on menu_DisplayEarth dView
   display_LocalWikis dView, "Local Earth Domains", "*.earth"
   -- display_EarthWikis
end menu_DisplayEarth

private on __
end __

on menu_DeleteAllSymLinked dView
   display_LocalSymWikis dView
   lcw_Answer "Delete all these  local symlinks?", dView
   
   put the displayed_Index of dView into localSymFolders
   repeat for each line localWikiDomain in localSymFolders
      display_Spin localWikiDomain, dView, "red"
      put the result into lineNum
      --
      put wikiFolder_Construct (localWikiDomain) into symLinkedFolder
      if folder_IsSymLink (symLinkedFolder) then
         symlink_Delete symLinkedFolder
         set the deleted_Line of dView to lineNum
      else
         breakpoint
      end if
   end repeat
end menu_DeleteAllSymLinked

private on ___
end ___

on menu_LocalhostWikis dView
   display_LocalWikis dView, "All Localhost", "*localhost"
end menu_LocalhostWikis

on menu_DynadotDomains
   display_Dynadot
end menu_DynadotDomains

on menu_DisplayLocalWikis displayView
   display_LocalWikis displayView
end menu_DisplayLocalWikis

private on ____
end ____

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Local | Menu")
end submenu_Dev
