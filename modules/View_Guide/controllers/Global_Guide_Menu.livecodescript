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
on menu_GuideHelp guideView
   put the right_View of guideView into rightView
end menu_GuideHelp

private on _
end _

on menu_StandardLayout guideView
   put the width of guideView into gWidth
   put round (gWidth / 2) into leftWidth
   set the left_Width of guideView to leftWidth
end menu_StandardLayout

on menu_FixedView guideView, fixedView
   set the fixed_View of guideView to fixedView
end menu_FixedView

getprop fixedView_Param [guideView]
   put the fixed_View of guideView into fixedView
   return fixedView
end fixedView_Param

getprop fixedView_Params [guideView]
   put the fixed_Views of guideView into fixedViews
   return fixedViews
end fixedView_Params

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

on menu_LoadReadmeData
   tiddly_LoadReadmeData
end menu_LoadReadmeData

on submenu_Dev
   return menu_DevTitle ("Global | Guide | Menu")
end submenu_Dev
