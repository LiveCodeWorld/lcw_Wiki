script "behavior_ViewWikiFuture"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_ViewWikiFuture
type: behavior
version: 0.1

/*Here you make make notes as a basic form of help for this view.
Full help text can be found on the linked wiki for the view.*/

--> Variables
-
constant kViewName = "View|Wiki|Browser"


--> Working on
-
-- on preOpenCard
   Init_MenuBar
end preOpenCard

command Init_MenuBar
   put the menubar_View of stack "View|Wiki|Future" into mGroup
   -- put _MenuBarView() into mGroup
   if exists (mGroup) is false then return empty
   
   put "File-Rev,Edit-Rev,Future-Default,Menu-Global|Menu|Group|Exists|Menu,Help-Rev" into mTable
   set the menubar_Table of mGroup to mTable
   --
   return mTable
end Init_MenuBar


--> Objects
-
getprop view_Object
   return the long id of me
end view_Object

getprop module_View
   return _WikiView()
end module_View

getprop menubar_View
   return _MenuBarView()
end menubar_View

private function _MenuBarView
   if exists (group "View|Menu|Group" of me) is false then return empty
   put the long id of group "View|Menu|Group" of me into mGroup
   return mGroup
end _MenuBarView

private function _WikiView
   return the long id of widget kViewName of me
end _WikiView

private function _BackGraphic
   return the long id of graphic "Drop Zone" of me
end _BackGraphic


--> Events
-
on resizeStack
   LayoutCard
   pass resizeStack
end resizeStack

command LayoutCard cRect
   if cRect is empty then put the rect of me into cRect
   --
   put cRect into wRect
   put the card_Margin of me into cMargin
   rect_SubtractMargins wRect, cMargin
   --
   put _WikiView() into wikiView
   put _BackGraphic() into backGraphic
   --
   -- if exists (wikiView) then set the rect of wikiView to wRect
   if exists (backGraphic) then set the rect of backGraphic to cRect
   return wRect
end LayoutCard


--> Margins
-
getprop card_Margin
   put the card_Margin of me into cardMargin
   if cardMargin is empty then put 24 into cardMargin
   return cardMargin
end card_Margin

setprop card_Margin cardMargin
   set the card_Margin of me to cardMargin
   LayoutControl
end card_Margin


--> Deps
-
getprop module_Controller [menuBit]
   put the module_Folder of the target into moduleFolder
   put moduleFolder & "controllers/" into cFolder
   --
   put the module_MenuTitle [menuBit] of the target into mTitle
   put lcw_PipesToUnderscore (mTitle) & ".livecodescript" into shortFile
   --
   put cFolder & shortFile into cPath
   return cPath
end module_Controller

getprop module_MenuTitle [menuBit]
   put the view_Name of the target into moduleName
   if viewName is empty then return empty
   --
   if menuBit is not empty then
      put space & "|" && menuBit after moduleName
   end if
   put menu_GlobalTitleFromViewName (moduleName) into globalMenuTitle
   put module_ConstructGlobalMenuTitle (moduleName, true) into globalMenuTitle
   return globalMenuTitle
end module_MenuTitle

command rect_SubtractMargins @someRect, pMargin
   margin_Normalize pMargin, leftM, topM, rightM, bottomM
   put the result into nMargins
   --
   add leftM to item 1 of someRect
   add topM to item 2 of someRect
   subtract rightM from item 3 of someRect
   subtract bottomM from item 4 of someRect
   --
   return nMargins
end rect_SubtractMargins

command margin_Normalize someMargin, @leftM, @topM, @rightM, @bottomM
   if the number of items of someMargin < 4 then
      put item 1 of someMargin into defaultMargin
      put defaultMargin into leftM
      
      put item 2 of someMargin into actualMargin
      if actualMargin is empty then
         put leftM into topM
      else
         put actualMargin into topM
      end if
      
      put item 3 of someMargin into actualMargin
      if actualMargin is empty then
         put leftM into rightM
      else
         put actualMargin into rightM
      end if
      
      put item 4 of someMargin into actualMargin
      if actualMargin is empty then
         put topM into bottomM
      else
         put actualMargin into bottomM
      end if
   else
      put item 1 of someMargin into leftM
      put item 2 of someMargin into topM
      put item 3 of someMargin into rightM
      put item 4 of someMargin into bottomM
   end if
   return leftM,topM,rightM,bottomM
end margin_Normalize


--> Objects
-
getprop view_Object
   return the long id of me
end view_Object
