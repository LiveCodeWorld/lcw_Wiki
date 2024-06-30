script "behavior_WikiBrowserCard"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_WikiBrowserCard
type: behavior
version: 0.3

/*Here you make make notes as a basic form of help for this view.
Full help text can be found on the linked wiki for the view.*/


--> Working on
-

--> Events
-
on resumeStack
   -- dispatch "refresh_Menus" to _MenuBarView() -- slows opening of stack
   send "refresh_Menus" to _MenuBarView() in 2 ticks
end resumeStack

on resizeStack
   LayoutCard
end resizeStack

on preOpenCard
   # Set up Menu Bar (requires menu folder stuff to be intiated)
   set the show_Menu of _MenuBarView() to true
   
   -- dispatch "refresh_Menus" to mGroup
   pass preOpenCard
end preOpenCard

on openCard
   send "wikiBrowser_SetProps" to me in 30 ticks
   --
   _FixLayout
   --
   set the wiki_Domain of _WikiView() to "thought.garden"
end openCard

command _FixLayout
   put _WikiView() into wikiView
   
   lock screen
   set the rect of wikiView to the rect of this cd -- tryng to fix menubar position bug
   dispatch "LayoutControl" to wikiView with the view_RectOnCard of me
   unlock screen   
end _FixLayout

on wikiBrowser_SetProps
   put _WikiView() into wikiView
   --
   -- get the behavior_StackNames of wikiView
   -- set the behavior_StackNames of wikiView to "behavior_ViewWikiBrowser,behavior_WikiJavascript"
   set the behavior_Hierarchy of wikiView to "default"
   --
   set the flag_Handler of wikiView to "default"
   set the wiki_EditMode of wikiView to true
   set the external_Links of wikiView to true
   
   lcw_Notify "Added custom events to wiki!"
end wikiBrowser_SetProps

on menu_Init
   put _MenuBarView() into mGroup
   --
   set the behavior_StackNames of mGroup to "behavior_ViewMenuGroup,behavior_MenuGroupCreate"
   set the menubar_DefaultTable of mGroup to "Browser-Default"
end menu_Init


--> Geometry
-
command LayoutCard
   set the topleft of _MenuBarView() to 0,0
   put the view_RectOnCard of me into viewRect
   dispatch "LayoutControl" to _WikiView() with viewRect
end LayoutCard

getprop view_RectOnCard [pMargin]
   if pMargin is empty then
      put the card_Margin of me into pMargin
   end if
   put the rect of me into someRect
   if pMargin is not 0 then
      rect_SubtractMargins someRect, pMargin
   end if
   return someRect
end view_RectOnCard


--> Private | Object | Functions
-
private function _MenuBarView
   if exists (group "View|Menu|Group" of me) is false then return empty
   return the long id of group "View|Menu|Group" of me
end _MenuBarView

private function _WikiView
   repeat for each line cID in the childControlIDs of me
      put the long id of control id cID of me into sObject
      if word 1 of sObject is not "widget" then next repeat
      if the kind of sObject = "com.livecode.widget.browser" then
         return sObject
      end if
   end repeat
   return empty
end _WikiView


--> Object | Props
-
getprop displayed_Object
   return _WikiView()
end displayed_Object

getprop menu_Target
   return _WikiView()
end menu_Target

getprop menubar_View
   return _MenuBarView()
end menubar_View

getprop wiki_View
   return _WikiView()
end wiki_View

getprop browser_View
   return _WikiView()
end browser_View

