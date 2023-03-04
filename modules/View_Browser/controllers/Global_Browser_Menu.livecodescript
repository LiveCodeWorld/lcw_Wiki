script "Global | Browser | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Browser | Menu
type: controller
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
   put the browser_View of tObject into browserView
   if exists (browserView) then return browserView
   
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

command _NotWorking
   switch
      /*
      case "map"
         put "http://livecode.world/assets/graph/graphviz.html" into someURL
         _BrowserScrollbars true, browserView
         break
      case "pretty wiki"
         put "http://livecode.world/assets/graph/pretty_wiki.html" into someURL
         _BrowserScrollbars true, browserView
         break
         */
      case "Anaglyph"
         put "https://threejs.org/examples/webgl_effects_anaglyph.html" into someURL
         break
      case "Cartoon"
         put "https://threejs.org/examples/webgl_animation_skinning_ik.html" into someURL
         break
      case "ThreeJS"
         put "https://threejs.org/examples/webgl_animation_keyframes.html" into someURL
         break
      case "Shop"
         put "https://shop.dudemag.it/" into someURL
         break
   end switch
end _NotWorking


--> Global | Browser | Menu
-
on menu_DisplayUrl browserView, which
   switch which
      case "Exodus"
         get "https://cicolab.notion.site/British-Council-Exodus-94adff44064349b898a013d4eebe296e"
         put it into someURL
         break
      case "Spark"
         get "https://lucid.app/lucidspark/f3d00524-40d7-4fe6-a3ae-79acaed33cc9/edit?viewport_loc=-2161%2C-240%2C10593%2C5652%2C0_0&invitationId=inv_845a0744-dbda-4ca6-bd6a-ea787a4b7585"
         put it into someURL
         break
      case "Notion"
         put "https://www.notion.so/cicolab/Exodus-LARPs-d00dd528651a496d83cc710fabb7d44a" into someURL
         break
      case "Nestr"
         put "https://app.nestr.io/" into someURL
         set the url of browserView to someURL
         --
         wait 60 ticks
         put js_ConstructSetUserNameSelector ("david@regovern.org") after sJavascript
         put CR & js_ConstructSetPasswordSelector ("2Bk3uASK&9nJ") after sJavascript
         set the browser_Javascript of browserView to sJavascript 
         return empty
      case "-"
      case "Infinitown"
         put "https://demos.littleworkshop.fr/infinitown" into someURL
         break
      case "Codepen"
         put "https://codepen.io/alphardex/pen/dyOQyPJ" into someURL
         break
      case "Sound"
         put "https://jhugheswebdev.github.io/sound-equalizer-threejs/" into someURL
         break
      case "Grass"
         put "https://webglsamples.org/field/field.html" into someURL
         break
      case "Video Texture"
         put "https://webglsamples.org/video/video.html" into someURL
         break
      case "Mirror Ball"
         put "https://webglsamples.org/dynamic-cubemap/dynamic-cubemap.html" into someURL
         break
      case "-"
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
      case "-"
      case "ChatGPT"
         put "https://chat.openai.com/chat" into someURL
         break
      case "-"
      case "ask"
         put lcw_Ask ("What url would you like to view...", "https://app.nestr.io/", displayedObject) into someURL
         _BrowserScrollbars true, browserView
         break
      case "Empty"
         put empty into someURL
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

on menu_EditUrl browserView
   put the url of browserView into someURL
   put lcw_Ask ("Edit the displayed url...", someURL, "url", browserView) into newURL
   launch url newURL
end menu_EditUrl

on menu_EditHtml browserView
   -- #notion-app > div > div:nth-child(1) > div > div:nth-child(2) > div.notion-frame > div > div.whenContentEditable > div:nth-child(3) > div > div:nth-child(1) > div > div:nth-child(2) > div > div.notion-selectable.notion-page-block > div
   -- document.querySelector("#notion-app > div > div:nth-child(1) > div > div:nth-child(2) > div.notion-frame > div > div.whenContentEditable > div:nth-child(3) > div > div:nth-child(1) > div > div:nth-child(2) > div > div.notion-selectable.notion-page-block > div")
   -- document.querySelector("#notion-app > div > div:nth-child(1) > div > div:nth-child(2) > div:nth-child(1) > div.notion-topbar > div > div.notranslate > div.notion-focusable > div")
   
   put the htmltext of browserView
   -- put the browser_HtmlText of browserView
end menu_EditHtml

private on __
end __

on submenu_Wiki
   return "Global | Wiki | Menu"
end submenu_Wiki

on submenu_Story
   return "Global | Wiki | Story | Menu"
end submenu_Story

on submenu_Rough
   return "Global | Browser | Rough | Menu"
end submenu_Rough

on submenu_Card
   return "Global | Card | Menu"
end submenu_Card

private command ___
end ___

on menu_DisplayBrowserTemplate
   display_ViewTemplate "View|Browser"
   put the result
end menu_DisplayBrowserTemplate

on menu_EditBrowserBehavior browserView
   put the behavior of browserView into bObject
   edit the script of bObject
end menu_EditBrowserBehavior
