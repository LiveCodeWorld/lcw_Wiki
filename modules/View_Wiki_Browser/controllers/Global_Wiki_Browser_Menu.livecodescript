script "Global | Wiki | Browser | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Browser | Menu
type: controller
version: 0.2

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_Target [tObject]
   put the browser_View of tObject into wikiView
   if exists (wikiView) is false then
      put the display_View of tObject into dView
      put the displayed_Object of dView into wikiView
      if exists (wikiView) is false then
         return empty
      end if
   end if
   
   put the wiki_Domain of wikiView into wikiDomain
   put wikiDomain into LocalArray ["wikiDomain"]
   return wikiView
end menu_Target

getprop displayDomain_Param [wikiView]
   put the browser_Domain of wikiView into wikiDomain
   return wikiDomain
end displayDomain_Param

getprop displayDomain_Params
   put wikiFolder_ListTopLevel() into wikiDomains
   --
   if wikiDomains is empty then
      return "ChatGPT,Localhost"
   else
      return wikiDomains & ",-,ChatGPT,Localhost"
   end if
end displayDomain_Params

getprop disabled_EditMode
   if LocalArray ["footer_IsVisible"] is true then
      return false
   else
      return true
   end if
end disabled_EditMode

getprop checked_EditWiki [wikiView]
   put the wiki_EditMode of wikiView into sBoolean
   return sBoolean
end checked_EditWiki

getprop checked_Footer [wikiView]
   return LocalArray ["footer_IsVisible"]
end checked_Footer

getprop checked_BrowserVisible [wikiView]
   put the visible of wikiView into isVisible
   return isVisible
end checked_BrowserVisible

getprop shrink_Params [wikiView]
   return the page_Slugs of wikiView
end shrink_Params

getprop scale_Params
   return "0.2,0.4,0.6,0.8,1.0,1.2,1.4"
end scale_Params

getprop checked_Background [wikiView]
   put the wiki_IsTransparent of wikiView into sBoolean
   return sBoolean
end checked_Background

getprop subdomain_Params [wikiView]
   put the wiki_Domain of wikiView into wikiDomain
   put wikiGarden_ListAllDomains (wikiDomain) into thoughtDomain
   return thoughtDomain
end subdomain_Params

getprop checked_ShowMenu [wikiView]
   put the menuBar_View of wikiView into mGroup
   put the show_Menu of mGroup into sBoolean
   return sBoolean
end checked_ShowMenu

getprop disabled_Subdomain [wikiView]
   put LocalArray ["wikiDomain"] into wikiDomain
   if wikiDomain = "localhost" then
      return true
   else
      retrun false
   end if
end disabled_Subdomain


--> Global | Wiki | Browser | Menu
-
on menu_DisplayDomain wikiView, wikiDomain   
   if the shiftKey is "down" then put empty into wikiView
   switch wikiDomain
      case "ChatGPT"
         display_WikiBrowser "https://chat.openai.com/", wikiView
         break
      default
         -- display_LocalWiki wikiDomain, wikiView
         display_Wiki wikiDomain, wikiView
   end switch
end menu_DisplayDomain

on submenu_Server
   return "Global | Wiki | Browser | Server | Menu"
end submenu_Server

on menu_Subdomain wikiView, subDomain
   set the page_Title [subDomain] of wikiView to "Welcome Visitors"
end menu_Subdomain

private on _
end _

on menu_Thought.1 wikiView
   set the page_Title ["thought.garden"] of wikiView to "Welcome Visitors"
end menu_Thought.1

on menu_Livecode.2 wikiView
   set the page_Title ["livecode.world"] of wikiView to "Welcome Visitors"
   set the page_Title ["project.livecode.world"] of wikiView to "Welcome Visitors"
end menu_Livecode.2

on menu_Earth.3 wikiView
   set the page_Title ["platform.earth"] of wikiView to "Welcome Visitors"
end menu_Earth.3

on menu_Localhost.4 wikiView
   set the page_Title ["localhost"] of wikiView to "Welcome Visitors"
end menu_Localhost.4

private on __
end __

on menu_EditWiki wikiView
   put the wiki_EditMode of wikiView into sBoolean
   set the wiki_EditMode of wikiView to (sBoolean is false)
end menu_EditWiki

on menu_BrowserVisible wikiView
   put the visible of wikiView into isVisible
   set the visible of wikiView to (isVisible is false)
end menu_BrowserVisible

on menu_Footer wikiView
   put the footer_IsVisible of wikiView into sBoolean
   set the footer_IsVisible of wikiView to (sBoolean is false)
end menu_Footer

private on ___
end ___

on menu_ShowMenu wikiView
   put the menuBar_View of wikiView into mGroup
   menuBar_ToggleShowMenu mGroup
end menu_ShowMenu

on menu_Background wikiView
   put the wiki_IsTransparent of wikiView into sBoolean
   set the wiki_IsTransparent of wikiView to (sBoolean is false)
end menu_Background

private on ____
end ____

on menu_SaveStack wikiView
   put the stack_Name of wikiView into sName
   save stack sName
end menu_SaveStack

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Browser | Menu")
end submenu_Dev
