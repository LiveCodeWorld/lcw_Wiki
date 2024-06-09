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

--> Working on
-
on preOpenCard
   Init_MenuBar
end preOpenCard

command Init_MenuBar
   put the menubar_View of stack "View|Wiki|Future" into mGroup
   if exists (mGroup) is false then return empty
   
   set the behavior_StackNames of mGroup to "behavior_ViewMenuGroup,behavior_MenuGroupCreate"
   --
   return mTable
end Init_MenuBar


--> Objects | Private
-
private function _BackView
   if exists (group "View|Wiki|Background" of me) is false then return empty
   return the long id of group "View|Wiki|Background" of me
end _BackView

private function _BackGraphic
   if exists (graphic "Drop Zone" of me) is false then return empty
   return the long id of graphic "Drop Zone" of me
end _BackGraphic

private function _MenuBarView
   if exists (group "View|Menu|Group" of me) is false then return empty
   return the long id of group "View|Menu|Group" of me
end _MenuBarView

private function _WikiView
   if exists (widget "View|Wiki|Browser" of me) is false then return empty
   return the long id of widget "View|Wiki|Browser" of me
end _WikiView


--> Objects
-
getprop back_View
   return _BackView()
end back_View

getprop menubar_View
   return _MenuBarView()
end menubar_View

getprop wiki_View
   return _WikiView()
end wiki_View

getprop browser_View
   return _WikiView()
end browser_View

getprop view_Object
   return the long id of me
end view_Object


--> Events
-
on resizeStack
   LayoutCard
   pass resizeStack
end resizeStack

command LayoutCard
   put the rect of me into cRect
   --
   put cRect into wRect
   put the card_Margin of me into cMargin
   rect_SubtractMargins wRect, cMargin
   add 20 to item 2 of wRect
   
   put _BackView() into backView
   if exists (backView) then set the rect of backView to wRect
   --
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
   LayoutCard
end card_Margin


--> Deps
-
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
