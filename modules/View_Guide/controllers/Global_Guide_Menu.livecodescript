script "Global | Guide | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Guide | Menu
type: controller
version: 0.2


--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_Target [tObject]
   put _ReadeNames() into LocalArray ["ReadeNames"]
   --
   put the displayed_Object of tObject into guideView
   if exists (guideView) then
      put the guide_View of guideView into guideView
   else
      put the guide_View of tObject into guideView
   end if
   return guideView
end menu_Target

private function _ReadeNames
   put env_ReadmeNameArray() into nameArray
   put keys (nameArray) into rNames
   sort rNames
   return rNames
end _ReadeNames

private function _dView
   return LocalArray ["dView"]
end _dView

getprop menu_CheckTarget [guideView]
   return exists (guideView)
end menu_CheckTarget


--> Global | Guide | Menu
-
on menu_LeftWiki guideView, rName
   put env_ReadmeNameArray() into nameArray
   put nameArray [rName] into tiddlyFile
   --
   put the left_View of guideView into leftView
   display_TiddlyFile tiddlyFile, leftView, false
end menu_LeftWiki

getprop leftWiki_Params
   return LocalArray ["ReadeNames"]
end leftWiki_Params

on submenu_RightPlugin
   return "Global | TiddlyWiki | Plugins | Menu"
end submenu_RightPlugin

on menu_RightWiki guideView, rName
   put env_ReadmeNameArray() into nameArray
   put nameArray [rName] into tiddlyFile
   --
   put the right_View of guideView into rightView
   display_TiddlyFile tiddlyFile, rightView, false
end menu_RightWiki

getprop rightWiki_Params
   return LocalArray ["ReadeNames"]
end rightWiki_Params

private on _
end _

on menu_GuideProperty guideView, someProp
   view_DoPropertyMenu someProp, guideView
end menu_GuideProperty

getprop guideProperty_Params [mTarget]
   return LocalArray ["view_PropertyMenu"]
end guideProperty_Params

getprop disabled_GuideProperty [guideView]
   put the view_PropertyMenu of guideView into viewPropertyMenu
   put viewPropertyMenu into LocalArray ["view_PropertyMenu"]
   --
   if viewPropertyMenu is empty then
      return "delete"
   else
      return false
   end if
end disabled_GuideProperty

on menu_SetViews guideView, viewName
   set the view_Type of guideView to viewName
end menu_SetViews

getprop setViews_Param [guideView]
   put the view_Type of guideView into shortViewNames
   return shortViewNames
end setViews_Param

getprop setViews_Params
   return "Tiddlywiki,-,Placeholder"
end setViews_Params

private on __
end __

on menu_Camera guideView
   put the stack_Name of guideView into sName
   put screen_BottomRight() into cRect
   --
   set the camera_Video [cRect] of guideView to "Facetime"
end menu_Camera

getprop checked_Camera [guideView]
   put the camera_IsOpen of guideView into isOpen
   return isOpen
end checked_Camera

on menu_ShowCamera guideView
   put the camera_IsVisible of guideView into isVisible
   if item 1 of isVisible = "Error" then
      breakpoint
   end if
   -- if isVisible is true then set the camera_Video of guideView to ""
   --
   set the camera_IsVisible of guideView to (isVisible is false)
end menu_ShowCamera

getprop disabled_ShowCamera [guideView]
   return _CameraMissing (guideView)
end disabled_ShowCamera

getprop checked_ShowCamera [guideView]
   put the camera_IsVisible of guideView into isVisible
   return isVisible
end checked_ShowCamera

on menu_CloseCamera guideView
   put the camera_Name of guideView into cameraName
   cameraControlDelete cameraName
end menu_CloseCamera

getprop disabled_CloseCamera [guideView]
   return _CameraMissing (guideView)
end disabled_CloseCamera

private function _CameraMissing guideView
   put the camera_Name of guideView into cameraName
   return cameraName is empty
end _CameraMissing

private on ___
end ___

on menu_ShowMenu guideView
   put the menubar_View of guideView into mGroup
   menuBar_ToggleShowMenu mGroup
end menu_ShowMenu

getprop checked_ShowMenu [guideView]
   put the menubar_View of guideView into mGroup
   if exists (mGroup) is false then return false
   --
   put the show_Menu of mGroup into sBoolean
   return sBoolean
end checked_ShowMenu

on menu_SetMargins guideView
   put the view_Name of guideView into viewName
   put the card_Margin of guideView into cMargin
   --
   put lcw_Ask ("Set the card_Margin of [[viewName]]", cMargin, guideView, viewName) into cMargin
   --
   lock screen
   set the card_Margin of guideView to cMargin
   set the horizontal_Spacing of guideView to cMargin
   unlock screen
end menu_SetMargins

on menu_LayoutBehavior guideView
   put the view_Childen of guideView
end menu_LayoutBehavior

on submenu_Dev
   return menu_DevTitle ("Global | Guide | Menu")
end submenu_Dev
