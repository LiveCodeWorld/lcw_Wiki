script "Global | Wiki | Pages | Line | Menu"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: Global | Wiki | Pages | Line | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray

--> Menu | Props
-
on menu_Init tObject
   -- called only once for top menu
   pass menu_Init
end menu_Init

getprop menu_Target [tObject]
   -- called once for each menu
   return tObject
end menu_Target


--> Global | Wiki | Pages | Line | Menu
-
on menu_DisplayPage displayView
   put the top_Array ["slug"] of displayView into pSlug
   put the title_Text of displayView into wikiDomain
   --
   display_WikiPage wikiDomain, pSlug
   return the result
end menu_DisplayPage

on _
end _

on menu_DeletePage displayView
   set the cursor to watch
   --
   put the top_Array ["slug"] of displayView into pSlug
   put the title_Text of displayView into wikiDomain
   --
   pageArray_Delete wikiDomain, pSlug
   put the result into shellResult
   --
   display_WikiDomain wikiDomain
   --
   return shellResult
end menu_DeletePage

on _
end _

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Dev | Menu
-
on menu_Experiment displayView
   put displayView
end menu_Experiment


--> Deps
-
