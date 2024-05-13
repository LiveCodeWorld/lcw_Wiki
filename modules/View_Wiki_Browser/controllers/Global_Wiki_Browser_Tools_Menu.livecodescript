script "Global | Wiki | Browser | Tools | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Browser | Tools | Menu
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
   put the browser_View of tObject into browserView
   --
   put the card_Object of tObject into arrayObject
   put the displayed_RectDataNum [true] of arrayObject into LocalArray ["dRectDataNum"]
   put the displayed_ObjectNames of arrayObject into LocalArray ["objectNames"]
   --
   return browserView
end menu_Target

private function _MenuButtonNames wikiView
   put the menubar_View of wikiView into mBar
   if exists (mBar) then
      return the menuButton_Names of mBar
   else
      breakpoint
      return empty
   end if
end _MenuButtonNames

getprop disabled_EditMode
   if LocalArray ["footer_IsVisible"] is true then
      return false
   else
      return true
   end if
end disabled_EditMode

getprop checked_Footer [wikiView]
   -- return LocalArray ["footer_IsVisible"]
   return the footer_IsVisible of wikiView
end checked_Footer

getprop checked_BrowserVisible [wikiView]
   put the visible of wikiView into isVisible
   return isVisible
end checked_BrowserVisible

getprop checked_SetMenuBar [wikiView]
   put the show_Menu of wikiView into sBoolean
   return sBoolean
end checked_SetMenuBar

getprop setMenuTitle_Params [wikiView]
   return _MenuButtonNames (wikiView)
end setMenuTitle_Params

getprop menuButtonInspector_Params [wikiView]
   return _MenuButtonNames (wikiView)
end menuButtonInspector_Params

getprop scale_Params
   return "0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,-,1,-,1.5"
end scale_Params

getprop shrinkPage_Params [wikiView]
   return the lineup_Titles of wikiView
end shrinkPage_Params

getprop updateToolsMenu_Params [wikiView]
   return _MenuButtonNames (wikiView)
end updateToolsMenu_Params

getprop checked_FlagEvent [wikiView]
   get the flag_Handler of wikiView
   if it = "default" then
      return true
   else
      return true
   end if
end checked_FlagEvent

getprop checked_AnimationEngine [wikiView]
   return "animationEngine" is among the lines of the stacksinuse
end checked_AnimationEngine


--> Global | Wiki | Browser | Tools | Menu
-
on menu_SearchOpenverse wikiView
   put lcw_Ask ("Enter search terms...", "cat|dog", "Openverse", dView) into searchBit
   --
   put openverse_Search (searchBit) into sData
   put wikiPage_OpenVerseThumbNails (sData) into pageArray
   --
   set the ghost_PageArray of wikiView to pageArray
end menu_SearchOpenverse

on menu_SaveStack browserView
   put the stack_Name of browserView into stackName
   save stack stackName
end menu_SaveStack

private on _
end _

on menu_FlagEvent wikiView
   set the flag_Handler of wikiView to "default"
end menu_FlagEvent

on menu_Footer wikiView
   put the footer_IsVisible of wikiView into sBoolean
   set the footer_IsVisible of wikiView to (sBoolean is false)
end menu_Footer

on menu_BrowserVisible wikiView
   put the visible of wikiView into isVisible
   set the visible of wikiView to (isVisible is false)
end menu_BrowserVisible

private on ___
end ___

on menu_Scale wikiView, sSale
   -- put wikijs_SetPageScale (sSale) into sJavascript
   -- set the browser_Javascript of wikiView to sJavascript
   set the wiki_Scale of wikiView to sSale
   -- set the page_Scale of wikiView to sScale
end menu_Scale

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

private on ____
end ____

on submenu_Menu
   return "Global | Menu | Group | Menu"
end submenu_Menu

on submenu_Tools
   get menu_DevTitle ("Global | Wiki | Browser | Tools | Menu")
   return it
end submenu_Tools
