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
   -- return _BrowserView(tObject)
   put the browser_View of tObject into browserView
   if exists (browserView) then
      return browserView
   else
      put line 1 of display_List ("View|Obeya|Studio") into browserView
      if exists (browserView) then return browserView
      return empty
   end if
end menu_Target

private function canvas_Rectangle
   put "const myCanvas = document.createElement('canvas'); document.body.appendChild(myCanvas); const ctx = myCanvas.getContext('2d')" into someJS
   -- put "const myCanvas = document.createElement('canvas'); const ctx = myCanvas.getContext('2d')" into someJS
   
   put "; ctx.fillStyle = 'red';" after someJS
   put "; ctx.fillRect(20, 20, 150, 100);" after someJS
   --
   return someJS
end canvas_Rectangle

private function _BrowserView tObject
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
end _BrowserView

private function internet_IsDisabled
   return LocalArray ["disabled_Register"] is true
end internet_IsDisabled

private command internet_ToggleStatus
   put internet_IsDisabled() into sBoolean
   internet_SetDisabled (sBoolean is false)
end internet_ToggleStatus

private command internet_SetDisabled sBoolean
   -- default is false
   put sBoolean is true into LocalArray ["disabled_Register"]
end internet_SetDisabled

getprop menu_CheckTarget [browserView]
   if exists (browserView) then
      put the footer_IsVisible of browserView into LocalArray ["footer_IsVisible"]
      return true
   else
      return false
   end if
end menu_CheckTarget

getprop disabled_DisplayWiki [browserView]
   return exists (browserView) is false
end disabled_DisplayWiki

getprop displayDomain_Param [browserView]
   put the browser_Domain of browserView into wikiDomain
   return wikiDomain
end displayDomain_Param

getprop displayDomain_Params
   put wiki_ListLocalShortAll ("*.localhost") into wikiDomains
   return "ChatGPT,Localhost,-," & wikiDomains
end displayDomain_Params

getprop disabled_EditMode
   if LocalArray ["footer_IsVisible"] is true then
      return false
   else
      return true
   end if
end disabled_EditMode

getprop checked_EditMode [wikiView]
   put the wiki_EditMode of wikiView into sBoolean
   return sBoolean
end checked_EditMode

getprop checked_Footer [wikiView]
   return LocalArray ["footer_IsVisible"]
   -- return the footer_IsVisible of wikiView
end checked_Footer

getprop checked_BrowserVisible [wikiView]
   put the visible of wikiView into isVisible
   return isVisible
end checked_BrowserVisible

getprop disabled_ExternalLinks [wikiView]
   return exists (wikiView) is false
end disabled_ExternalLinks

getprop checked_ExternalLinks [wikiView]
   put the wiki_Override of wikiView into sWay
   return sWay = "external"
end checked_ExternalLinks

getprop disabled_Tunnel
   return internet_IsDisabled() is not false
end disabled_Tunnel

getprop disabled_Openverse
   return internet_IsDisabled() is not false
end disabled_Openverse

getprop shrink_Params [wikiView]
   return the page_Slugs of wikiView
end shrink_Params

getprop scale_Params
   return "0.2,0.4,0.6,0.8,1.0,1.2,1.4"
end scale_Params

getprop checked_Internet
   return internet_IsDisabled() is false
end checked_Internet

getprop checked_Background [wikiView]
   put the wiki_IsTransparent of wikiView into sBoolean
   return sBoolean
end checked_Background


--> Global | Obeya | Studio | Menu
-
on menu_DisplayDomain browserView, wikiDomain   
   if the shiftKey is "down" then put empty into browserView
   switch wikiDomain
      case "ChatGPT"
         display_WikiBrowser "https://chat.openai.com/", browserView
         break
      default
         -- display_LocalWiki wikiDomain, browserView
         display_Wiki wikiDomain, browserView
   end switch
end menu_DisplayDomain

on submenu_Wiki
   return "Global | Wiki | Menu"
end submenu_Wiki

on submenu_Menu
   return "Global | Menu | Group | Menu"
end submenu_Menu

private on _
end _

on menu_DisplayThought wikiView
   display_LocalWikis empty, "Local Thought Domains", "*thought*"
end menu_DisplayThought

on menu_DisplayGitWikis wikiView
   display_GitWikiFolders empty, "*fedwiki.org"
end menu_DisplayGitWikis

private on __
end __

on menu_Footer wikiView
   put the footer_IsVisible of wikiView into sBoolean
   set the footer_IsVisible of wikiView to (sBoolean is false)
end menu_Footer

on menu_BrowserVisible wikiView
   put the visible of wikiView into isVisible
   set the visible of wikiView to (isVisible is false)
end menu_BrowserVisible

on menu_Background wikiView
   put the wiki_IsTransparent of wikiView into sBoolean
   set the wiki_IsTransparent of wikiView to (sBoolean is false)
end menu_Background

private on ___
end ___

on menu_SaveStack wikiView
   put the stack_Name of wikiView into sName
   save stack sName
end menu_SaveStack

on menu_EditMode wikiView
   put the wiki_EditMode of wikiView into sBoolean
   set the wiki_EditMode of wikiView to (sBoolean is false)
end menu_EditMode

private on ____
end ____

on menu_Rects wikiView
   put the page_Slugs of wikiView into pageSlugs
   repeat with lineNum = 1 to the number of lines of pageSlugs
      put line lineNum of pageSlugs into pageSlug
      --
      put the page_Rect [pageSlug] of wikiView into pRect
      put pRect into line lineNum of pageRects
   end repeat
   put pageRects
end menu_Rects

on menu_Shrink wikiView, pageSlug
   -- put the page_Rect ["welcome-visitors"] of wikiView into sRect
   -- 204,364,302,542
   
   set the page_Scale [pageSlug] of wikiView to 0.2
   put the page_Rect [pageSlug] of wikiView into sRect
   --
   rect_Translate sRect, 400, 200
   --
   set the page_Rect [pageSlug] of wikiView to sRect
end menu_Shrink

on menu_Scale wikiView, sScale
   set the page_Scale of wikiView to sScale
end menu_Scale

private on _____
end _____

on menu_FlagEvent wikiView
   set the flag_Handler of wikiView to "default"
end menu_FlagEvent

on menu_Internet
   internet_ToggleStatus
end menu_Internet

on submenu_Tunnel
   return "Global | Tunnel | Menu"
end submenu_Tunnel

on submenu_Openverse
   return "Global | Openverse | Menu"
end submenu_Openverse

on submenu_Dev
   return menu_DevTitle ("Global | Obeya | Studio | Menu")
end submenu_Dev
