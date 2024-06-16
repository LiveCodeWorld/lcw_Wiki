script "Global | Wiki | Domain | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Domain | Menu
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
   put the display_View of tObject into dView
   put the displayed_Object of dView into wikiView
   --
   put dView into LocalArray ["dView"]
   return wikiView
end menu_Target

getprop menu_CheckTarget [wikiView]
   return exists (wikiView)
end menu_CheckTarget

command _DisplayData sData
   put LocalArray ["dView"] into dView
   set the displayed_Data of dView to sData
end _DisplayData


--> Global | Wiki | Domain | Menu
-
on menu_SitemapArray wikiView
   put the siteMap_Array of wikiView into siteMapArray
   --
   _DisplayData siteMapArray
end menu_SitemapArray

on menu_PerformativeDictionary wikiView
   put the performative_Dictionary of wikiView into pArray
   --
   _DisplayData pArray
end menu_PerformativeDictionary

private on _
end _

on menu_Behavior dView
   put the behavior of dView into bObject
   edit the script of bObject
end menu_Behavior

on menu_ModuleTools dView
   put the view_Name of dView into viewName
   display_ModuleTools viewName
end menu_ModuleTools

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Domain | Menu")
end submenu_Dev
