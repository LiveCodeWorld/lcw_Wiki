script "Global | Browser | Rough | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Browser | Rough | Menu
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
   put the display_View of tObject into displayView
   if exists (displayView) is false then return empty
   --
   put the displayed_Object of displayView into displayedObject
   return displayedObject
end menu_Target


--> Global | Browser | Rough | Menu
-
on menu_SetRough browserView
   put scaffold_GetTemplate ("Rough Blue") into roughHTML
   set the browser_HtmlText of browserView to roughHTML
   --
   set the browser_Element of browserView to "svg"
end menu_SetRough

on menu_TestRoughen browserView
   put "http://livecode.world/assets/graph/hierarchical.svg" into svgURL
   --
   put env_GetRepoFolder() & "sketchviz-docker/sketchviz/" into someDir
   put the defaultfolder into oDir
   --
   set the defaultfolder to someDir
   put url svgURL into url "file:downloaded.svg"
   put "node roughen.js 'downloaded.svg' 'roughened.svg'" into someShell
   get shell (someShell) -- (node:34706) ExperimentalWarning: The fs.promises API is experimental
   --
   set the defaultfolder to oDir
   --
   put someDir & "roughened.svg" into svgFile
   display_SVG svgFile, "roughened.svg"
end menu_TestRoughen
