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
         return true
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
   return "ChatGPT,-," & astralDomains
end displayWiki_Params


--> Global | Obeya | Studio | Menu
-
on menu_DisplayWiki browserView, pWhich
   if the shiftKey is "down" then put empty into browserView
   switch pWhich
      case "Localhost"
         display_WikiBrowser "http://localhost", browserView
         break
      case "ChatGPT"
         display_WikiBrowser "https://chat.openai.com/", browserView
         break
      default
         put "http://" & pWhich into astralURL
         display_WikiBrowser astralURL, browserView
   end switch
end menu_DisplayWiki

private on _
end _

on submenu_Wiki
   return "Global | Wiki | Menu"
end submenu_Wiki

on submenu_MenuGroup
   return "Global | Menu | Group | Menu"
end submenu_MenuGroup

private on __
end __

on submenu_Browser
   return "Global | Browser | Menu"
end submenu_Browser

on submenu_Javascript
   return "Global | Wiki | Story | Javascript | Menu"
end submenu_Javascript

on submenu_Dev
   return menu_DevTitle ("Global | Obeya | Studio | Menu")
end submenu_Dev
