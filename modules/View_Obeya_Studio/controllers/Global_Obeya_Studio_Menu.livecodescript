script "Global | Obeya | Studio | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Obeya | Studio | Menu
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
   put display_MenuTarget(tObject) into testView
   if exists (testView) then
      put the browser_View of testView into browserView
   else
      put the browser_View of tObject into browserView
   end if
   --
   if exists (browserView) then
      return browserView
   else
      put line 1 of display_List ("View|Obeya|Studio") into browserView
      if exists (browserView) then
         return browserView
      else
         return empty
      end if
   end if
end menu_Target

getprop disabled_DisplayWiki [browserView]
   return exists (browserView) is false
end disabled_DisplayWiki

getprop displayWiki_Param [browserView]
   put the browser_URL of browserView into browserURL
   replace "http://" with empty in browserURL
   return browserURL
end displayWiki_Param

getprop displayWiki_Params
   put dynadot_ListAstralDomains() into astralDomains
   return "ChatGPT,Localhost,-," & astralDomains
end displayWiki_Params

getprop disabled_HideFooter [wikiView]
   return exists (wikiView) is false
end disabled_HideFooter

getprop checked_HideFooter [wikiView]
   put the footer_IsVisible of wikiView into sBoolean
   return sBoolean is false
end checked_HideFooter

function canvas_Rectangle
   put "const myCanvas = document.createElement('canvas'); document.body.appendChild(myCanvas); const ctx = myCanvas.getContext('2d')" into someJS
   -- put "const myCanvas = document.createElement('canvas'); const ctx = myCanvas.getContext('2d')" into someJS
   
   put "; ctx.fillStyle = 'red';" after someJS
   put "; ctx.fillRect(20, 20, 150, 100);" after someJS
   --
   return someJS
end canvas_Rectangle

getprop disabled_ExternalLinks [wikiView]
   return exists (wikiView) is false
end disabled_ExternalLinks

getprop checked_ExternalLinks [wikiView]
   put the wiki_Override of wikiView into sWay
   return sWay = "external"
end checked_ExternalLinks


--> Global | Obeya | Studio | Menu
-
on menu_DisplayWiki browserView, pWhich
   if the shiftKey is "down" then put empty into browserView
   switch pWhich
      case "Localhost"
         display_WikiBrowser "http://localhost:3000", browserView
         break
      case "ChatGPT"
         display_WikiBrowser "https://chat.openai.com/", browserView
         break
      default
         put "http://" & pWhich into astralURL
         display_WikiBrowser astralURL, browserView
   end switch
end menu_DisplayWiki

on submenu_Openverse
   return menu_CreateTitle ("Global | Openverse | Menu")
end submenu_Openverse

on submenu_Canvas
   return menu_CreateTitle ("Global | Canvas | Menu")
end submenu_Canvas

private on _
end _

on menu_DisplayLineupData wikiView
   put the lineup_Data of wikiView into lineupData
   display_Data lineupData, "Lineup Data", "Wiki"
end menu_DisplayLineupData

on menu_ExternalLinks wikiView
   set the wiki_Override of wikiView to "external"
end menu_ExternalLinks

on menu_HideFooter wikiView
   put the footer_IsVisible of wikiView into sBoolean
   set the footer_IsVisible of wikiView to (sBoolean is false)
end menu_HideFooter

private on __
end __

on submenu_Wiki
   return "Global | Wiki | Menu"
end submenu_Wiki

on submenu_MenuGroup
   return "Global | Menu | Group | Menu"
end submenu_MenuGroup

private on ___
end ___

on submenu_Browser
   return "Global | Browser | Menu"
end submenu_Browser

on submenu_Javascript
   return "Global | Wiki | Story | Javascript | Menu"
end submenu_Javascript

on submenu_Dev
   return menu_DevTitle ("Global | Obeya | Studio | Menu")
end submenu_Dev
