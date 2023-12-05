script "Global | Canvas | Menu"
--> MetaData
-
license: GPLv3
name: Global | Canvas | Menu
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


--> Global | Canvas | Menu
-
on menu_TestCanvas wikiView
   -- put scaffold_Get ("HTML5 Canvas") into canvasHtml
   put scaffold_Get ("HTML5 Click Canvas") into canvasHtml
   set the browser_HtmlText of wikiView to canvasHtml
end menu_TestCanvas

on menu_ColourCanvas wikiView
   put canvas_Rectangle() into someJS
   put someJS
   set the browser_Javascript of wikiView to someJS
end menu_ColourCanvas

on menu_AddClickAlert
   put "canvas.addEventListener('click', function() {alert('clicked an element')}, false);" into someJS
   set the browser_Javascript of wikiView to someJS
end menu_AddClickAlert

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Canvas | Menu")
end submenu_Dev
