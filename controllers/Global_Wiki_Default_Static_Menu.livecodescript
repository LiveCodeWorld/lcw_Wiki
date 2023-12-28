script "Global | Wiki | Default | Static | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Default | Static | Menu
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


--> Global | Wiki | Default | Static | Menu
-
on menu_WikiDefaultStatic dView
   put wikiClient_GetStaticHtml() into sHTML
   set the displayed_Lines of dView to sHTML
end menu_WikiDefaultStatic

on menu_WikiTestJson dView
   put pageArray_GetDefaultJson ("welcome-visitors") into pageJSON
   set the displayed_Lines of dView to pageJSON
end menu_WikiTestJson

on menu_TestRender dView
   put _TestDiv() into testDiv
   --
   set the displayed_Lines of dView to testDiv
end menu_TestRender

on menu_TestOffsets dView
   put wikiClient_GetStaticHtml() into htmlTemplate
   put pageArray_GetDefaultJson ("welcome-visitors") into pageJSON
   --
   put wiki_RenderHtml (htmlTemplate, "thought.garden") into newHtml
   --
   set the displayed_Lines of dView to newHtml
end menu_TestOffsets

private function _TestDiv
   put wikiClient_GetStaticHtml() into htmlTemplate
   --
   put wiki_RenderHtml (htmlTemplate, "thought.garden") into newHtml
   return newHtml
end _TestDiv

private on _
end _

on menu_DefaultWelcome dView
   put pageArray_GetDefault ("welcome-visitors") into pageArray
   -- display_PageArray pageArray
   put pageArray ["story"] into storyArray
   --
   put wiki_ConstructStoryDiv (storyArray) into storyDiv
   --
   set the displayed_Lines of dView to storyDiv
end menu_DefaultWelcome

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
   return menu_DevTitle ("Global | Wiki | Default | Static | Menu")
end submenu_Dev
