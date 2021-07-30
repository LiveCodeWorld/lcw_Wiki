script "Global | Browser | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Browser | Menu
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

getprop displayUrl_Params
   return the hkey_CaseConditions ["M menu_DisplayUrl"] of me
end displayUrl_Params

private command _BrowserScrollbars sBoolean, browserView
   set the vScrollbar of browserView to sBoolean
   set the hScrollbar of browserView to sBoolean
end _BrowserScrollbars


--> Global | Browser | Menu
-
-- getprop disabled_TestSvg [browserView]
dispatch "browser_InitResult" to browserView
return false
end disabled_TestSvg

on menu_SetRough browserView
   put scaffold_GetTemplate ("Rough Blue") into roughHTML
   set the browser_HtmlText of browserView to roughHTML
   --
   set the browser_Element of browserView to "svg"
end menu_SetRough

on menu_TestSvg browserView
   put the browser_Element of browserView
end menu_TestSvg

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

on _
end _

on menu_DisplayUrl browserView, which
   switch which
      case "Rough"
         put "https://fskpf.github.io/" into someURL
         break
      case "cyto cats"
         put "https://js.cytoscape.org/demos/images-breadthfirst-layout/" into someURL
         -- put "http://livecode.world/assets/graph/graph.html" into someURL
         _BrowserScrollbars false, browserView
         break
      case "cose-bilkent"
         put "https://cytoscape.org/cytoscape.js-cose-bilkent/demo-compound.html" into someURL
         _BrowserScrollbars false, browserView
         break
      case "complex cytoscape"
         put "https://pathwaycommons.github.io/cytoscape-sbgn-stylesheet/" into someURL
         _BrowserScrollbars false, browserView
         break
      case "map"
         put "http://livecode.world/assets/graph/graphviz.html" into someURL
         _BrowserScrollbars true, browserView
         break
      case "pretty wiki"
         put "http://livecode.world/assets/graph/pretty_wiki.html" into someURL
         _BrowserScrollbars true, browserView
         break
      case "-"
      case "ask"
         put lcw_Ask ("What url would you like to view...", "http://thought.garden", displayedObject) into someURL
         _BrowserScrollbars true, browserView
         break
   end switch
   --
   if the shiftKey is "Down" then
      launch url someURL
   else
      set the url of browserView to someURL
      -- set the browser_URL of browserView to someURL
   end if
end menu_DisplayUrl

on submenu_Wiki
   return "Global | Wiki | Menu"
end submenu_Wiki

on submenu_Story
   return "Global | Wiki | Story | Menu"
end submenu_Story

on _
end _

on submenu_Frame
   return "Global | Frame | Menu"
end submenu_Frame

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Dev | Menu
-
on menu_EditBehavior browserView
   put the behavior of browserView into bObject
   edit the script of bObject
end menu_EditBehavior
