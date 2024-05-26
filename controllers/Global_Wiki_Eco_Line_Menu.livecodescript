script "Global | Wiki | Eco | Line | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Eco | Line | Menu
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
   -- put display_MenuTarget (tObject) into dView
   put the display_View of tObject into dView
   return dView
end menu_Target

getprop menu_CheckTarget [dView]
   return exists (dView)
end menu_CheckTarget

on mDoubleUp_WikiEco dView, sValue
   put the selected_Path of dView into sPath
   switch 
      case item -1 of sPath = "folder"
         put sValue into wikiFolder
         file_AddHome wikiFolder
         if there is a folder wikiFolder then
            finder_Reveal wikiFolder
         else
            wikiGarden_Update
            put the result into ecoData
            --
            breakpoint
            finder_Reveal wikiFolder
         end if
         break
      default
         breakpoint
   end switch
end mDoubleUp_WikiEco


--> Global | Wiki | Eco | Line | Menu
-
on menu_RevealGarden dView
   -- Eco,Thought Gardens,Gardens,Legal,legalcommons.org
   put the selected_Path of dView into sPath
   if sPath begins with "Eco,Thought Gardens,Gardens," then
      put item 4 of sPath into gardenName
      put wikiGarden_Folder (gardenName)
   end if
end menu_RevealGarden

private on _
end _

on menu_DisplayWikiPreferences dView
  display_WikiPage "localhost", "local-preference"
end menu_DisplayWikiPreferences

on menu_ModuleTools dView
   put the view_Name of dView into viewName
   display_ModuleTools viewName
end menu_ModuleTools

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Eco | Line | Menu")
end submenu_Dev
