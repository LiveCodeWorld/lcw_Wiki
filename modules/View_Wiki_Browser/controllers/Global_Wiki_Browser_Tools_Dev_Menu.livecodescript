script "Global | Wiki | Browser | Tools | Dev | Menu"
--> MetaData
-
license: GPLv3
name: Global | Wiki | Browser | Tools | Dev | Menu
type: controller
author: David Bovill
version: 0.1

/*
Here you can describe this developer menu.
Full help text should be provided on the linked wiki.

Consider improving by creating with same menu_Target as no-developer menu is is based on.
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

getprop updateToolsMenu_Params [wikiView]
   return _MenuButtonNames (wikiView)
end updateToolsMenu_Params

private function _MenuButtonNames wikiView
   put the menubar_View of wikiView into mBar
   if exists (mBar) then
      return the menuButton_Names of mBar
   else
      breakpoint
      return empty
   end if
end _MenuButtonNames

getprop setMenuTitle_Params [wikiView]
   return _MenuButtonNames (wikiView)
end setMenuTitle_Params

getprop menuButtonInspector_Params [wikiView]
   return _MenuButtonNames (wikiView)
end menuButtonInspector_Params


--> Global | Wiki | Browser | Tools | Dev | Menu
-
on menu_WikiViewBehavior dView
   put the behavior of dView into bObject
   edit the script of bObject
end menu_WikiViewBehavior

on menu_WikiModuleTools dView
   put the view_Name of dView into viewName
   display_ModuleTools viewName
end menu_WikiModuleTools

private on __
end __

on menu_ListLocalWikis
   display_LocalWikis
end menu_ListLocalWikis
