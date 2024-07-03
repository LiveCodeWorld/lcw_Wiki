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

on menu_RefreshTitles wikiView
   put the menubar_View of wikiView into mGroup
   --   
   put the menubar_Titles of mGroup into menubarTitles
   put the menuButton_Names of mGroup into mNames
   set the menubar_Titles of mGroup to mNames
end menu_RefreshTitles

on menu_DefaultMenubarTable wikiView
   put the menubar_View of wikiView into mGroup
   --   
   set the menubar_DefaultTable of mGroup to "Browser-Default"
end menu_DefaultMenubarTable

on menu_DefaultTitle wikiView, mTitle
   get the norm_Title [mTitle] of wikiView
   
   put the menubar_View of wikiView into mGroup
   --   
   put the menubar_DefaultTitles of wikiView into mTitles
   put lineOffset (mTitle, mTitles)
end menu_DefaultTitle

getprop defaultTitle_Params [wikiView]
   put the menubar_View of wikiView into mGroup
   put the menuButton_Names of mGroup into mNames
   return mNames
   
   put the menubar_DefaultTitles of wikiView into mTitles
   return mTitles
end defaultTitle_Params

private on _
end _

on submenu_Menu
   return "Global | Menu | Group | Menu"
end submenu_Menu

on submenu_Server
   return "Global | Wiki | Browser | Server | Menu"
end submenu_Server

on menu_ModuleTools dView
   put the view_Name of dView into viewName
   display_ModuleTools viewName
end menu_ModuleTools

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Domain | Menu")
end submenu_Dev
