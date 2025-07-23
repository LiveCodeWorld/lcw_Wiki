script "behavior_View_Mediawiki"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_View_Mediawiki
type: behavior
version: 0.1
deps: mArray_PopUp


--> Deps
-
getprop title_Menu
   return _MenuTitle()
end title_Menu

setprop title_Menu mTitle
   set the uOPN ["title_Menu"] of me to mTitle
end title_Menu

private function _MenuTitle
   constant DefaultTitleMenu = "Global | Poly | Menu"
   if the controlKey is "Down" then return DefaultTitleMenu
   
   put the uOPN ["title_Menu"] of me into mTitle
   if mTitle is empty then
      return DefaultTitleMenu
   else
      return mTitle
   end if
end _MenuTitle

getprop data_Height
   return the dataHeight of _PolyWidget()
end data_Height

setprop data_Height dHeight
   if dHeight is not a number then
      put 0 into dHeight
   end if
   add _headerHeight() to dHeight
   add _footerHeight() to dHeight
   --
   put the rect of me into newRect
   put item 2 of newRect + dHeight into item 4 of newRect
   --
   LayoutControl newRect
end data_Height

command menu_DispatchTextPick mItemPath
   put the long id of the target into tObject
   --
   put the menu_Target of tObject into mTarget
   put the menu_Controller of mTarget into mController
   
   # Construct hName
   set the itemdelimiter to "|"
   put item 1 of mItemPath into hPostFix
   replace space with empty in hPostFix
   put "menu_" & hPostFix into hName
   
   if the optionKey is "down" then
      menu_OptionAnswer hName, mController
   else
      # Construct callCOmmand
      put item 2 of mItemPath into pValue
      put hName && "mTarget,pValue" into callCommand
      --
      call callCommand of mController
      return hkey_GetCaseConditions(hKey, pScriptObject)
   end if
end menu_DispatchTextPick

command mArray_PopUp mTitle, mButton
   put the menu_Text of me into mText
   set the text of mButton to mText
   --
   popup mButton
end mArray_PopUp


--> Working on
-
getprop menu_Target
   return the long id of me
end menu_Target

getprop menu_Controller
   -- put the name of stack "Global | Poly | Menu" into mController
   set the uOPN ["menu_Controller"] of me to empty
   --
   put the uOPN ["menu_Controller"] of me into mController
   if exists (mController) then return mController
   
   ## Default
   put _MenuTitle() into mTitle
   put menu_GetGlobalController (mTitle) into mController
   return mController
end menu_Controller

setprop menu_Controller mController
   set the uOPN ["menu_Controller"] of me to mController
end menu_Controller

function menu_GetGlobalController mTitle, pWithModel
   if there is a stack mTitle then
      return the name of stack mTitle
   else
      return empty
   end if
end menu_GetGlobalController

private command _DoFooter
   put the long id of me into dView
   put the mouse_Target of dView into mTarget
   
   # Get Hilite info
   put _FooterWidget() into fWidget
   put the hilitedItem of fWidget into iNum
   put the hilitedItemName of fWidget into iName
   
   # Dispatch (menu_Controller is default)
   dispatch "footer_HiliteChange" to mTarget with dView,iName,iNum
end _DoFooter

getprop mouse_Target
   put the long id of the target into tObject
   put the uOPN ["mouse_Target"] of me into mTarget
   if exists (mTarget) is false then
      put _DefaultMouseTarget (tObject) into mTarget
   end if
   return mTarget
end mouse_Target

setprop mouse_Target mTarget
   set the uOPN ["mouse_Target"] of me to mTarget
end mouse_Target

private function _DefaultMouseTarget tObject
   put the menu_Controller of me into mController
   if exists (mController) is true then
      return mController
   else
      return the long id of me
   end if
end _DefaultMouseTarget

private command _DoHeaderCog
   put the clickloc into pLocation
   add 2 to item 1of pLocation
   add 4 to item 2 of pLocation
   --
   put _MenuTitle() into mTitle
   put _MenuButton() into mButton
   
   try
      mArray_PopUp mTitle, mButton
   catch sError
      mArray_PopUp "Global | Module | Error | Menu", mButton
   end try
end _DoHeaderCog

private command _DoHeader -- mouseUp in _HeaderWidget()
   local tActionName
   put the mouseAction of the target into tActionName
   switch tActionName
      case "cog"
         _DoHeaderCog
         break
      default
         -- clicked on the header-widget background
   end switch
end _DoHeader

command _DoDrop
   put the long id of me into dView
   put the drop_Command of me into dCommand
   if dCommand is empty then
      return "Error, the drop_Command is empty"
   end if
   
   put _DragData() into dData 
   put the mouse_Target of me into mTarget
   if exists (mTarget) is false then
      dispatch dCommand to me with dView,dData
   else
      dispatch dCommand to mTarget with dView,dData
   end if
   return dCommand
end _DoDrop

private function _headerHeight
   return 55
end _headerHeight

private function _footerHeight
   return 40
end _footerHeight


--> Props | Display
-
getprop body_IsVisible
   return the visible of _polyWidget()
end body_IsVisible

setprop body_IsVisible sBoolean
   put the rect of me into oRect
   --
   lock screen
   set the visible of _polyWidget() to sBoolean
   LayoutControl oRect
   unlock screen
end body_IsVisible

getprop header_IsVisible
   return the visible of _headerWidget()
end header_IsVisible

setprop header_IsVisible sBoolean
   put the rect of me into oRect
   --
   lock screen
   set the visible of _headerWidget() to sBoolean
   LayoutControl oRect
   unlock screen
end header_IsVisible

getprop footer_IsVisible
   return the visible of _footerWidget()
end footer_IsVisible

setprop footer_IsVisible sBoolean
   put the rect of me into oRect
   --
   lock screen
   set the visible of _footerWidget() to sBoolean -- changes rect
   LayoutControl oRect
   unlock screen
end footer_IsVisible


--> Props
-
getprop poly_DataLayout
   return the dataLayout of _PolyWidget()
end poly_DataLayout

getprop poly_DataContent
   return the dataContent of _PolyWidget()
end poly_DataContent

setprop poly_DataContent [sTitle] cData
   lock screen
   set the dataContent of _PolyWidget() to cData
   if sTitle is not empty then
      set the title_Text of me to sTitle
   end if
   unlock screen
end poly_DataContent

getprop drop_Command
   return the uOPN ["drop_Command"] of me
end drop_Command

setprop drop_Command dCommand
   set the uOPN ["drop_Command"] of me to dCommand
end drop_Command

getprop title_Text
   put _HeaderWidget() into headerWidget
   put the label of headerWidget into displayTitle
   return displayTitle
end title_Text

setprop title_Text displayTitle
   put _HeaderWidget() into headerWidget
   set the label of headerWidget to displayTitle
end title_Text


--> Events | Drag Drop
-
on dragDrop
   _DoDrop
   pass dragDrop
end dragDrop

on dragEnter
   get the drop_Command of me
   if it is not empty then
      set the dragAction to "link" -- "none,move,copy"
   end if
   pass dragEnter
end dragEnter

on dragLeave
   if the drop_Command of me is not empty then
      set the dragAction to "none"
   end if
   pass dragLeave
end dragLeave


--> Events
-
on menuPick menuPath
   menu_DispatchTextPick menuPath
end menuPick

on mouseUp
   switch the short name of the target
      case "Array Header"
         _DoHeader
         break
      case "PolyList"
         -- breakpoint
         break
      case "Array Footer"
         breakpoint -- never happens
         break
   end switch
end mouseUp

on hiliteChanged
   _DoFooter
end hiliteChanged

on resizeControl
   local sRect
   put the rect of me into sRect
   LayoutControl sRect
end resizeControl

command LayoutControl sRect
   if the short id of the target is not the short id of me then
      -- resizing polyList seems to trigger / send LayoutControl
      -- put the name of the target
      return "Error" 
   end if
   
   if sRect is empty then 
      put the rect of me into sRect
   end if
   
   # Objects
   put _MenuButton() into myMenuButton
   put the margins of me into myMargins
   
   # Geometry
   put rect_SubtractNum (sRect, myMargins) into iRect
   --
   put _footerRect (iRect) into fRect
   put _fieldRect (iRect) into pRect
   put _headerRect (iRect) into hRect
   
   # Set Rects
   lock screen
   set the rect of _HeaderWidget() to hRect
   set the rect of myMenuButton to hRect
   set the rect of _FooterWidget() to fRect
   set the rect of _PolyWidget() to pRect
   --
   -- set the rect of me to sRect
   unlock screen
end LayoutControl

function rect_SubtractNum sRect, pNum
   put item 1 of pNum into pNum
   if pNum is not a number then return sRect
   
   add pNum to item 1 of sRect
   add pNum to item 2 of sRect
   subtract pNum from item 3 of sRect
   subtract pNum from item 4 of sRect
   return sRect
end rect_SubtractNum


--> Style
-
on toggle_Header
   put the header_IsVisible of me into sBoolean
   set the header_IsVisible of me to (sBoolean is false)
end toggle_Header


--> Objects
-
getprop view_Object
   return the long id of me
end view_Object

getprop menu_Button
   return _MenuButton()
end menu_Button


--> Private
-
private function _headerRect cRect
   put item 2 of cRect + _headerHeight() into item 4 of cRect
   return cRect
end _headerRect

private function _fieldRect cRect
   if the visible of _HeaderWidget() is true then
      add _headerHeight() to item 2 of cRect
   end if
   if the visible of _footerWidget() is true then
      subtract _footerHeight() from item 4 of cRect
   end if
   return cRect
end _fieldRect

private function _footerRect cRect
   put item 4 of cRect - _footerHeight() into item 2 of cRect
   return cRect
end _footerRect

private function _DragData
   -- horrible hack to fix dragData
   -- If you don't specify a dataType, the dragData property reports or sets the dragData["text"].
   local dData
   put the keys of the dragdata into dKeys
   repeat for each line dKey in dKeys
      put the dragData [dKey] into dData [dKey]
   end repeat
   return dData
end _DragData

private function _HeaderWidget
   return the long id of widget "Array Header" of me
end _HeaderWidget

private function _PolyWidget
   return the long id of widget "PolyList" of me
end _PolyWidget

private function _FooterWidget
   return the long id of widget "Array Footer" of me
end _FooterWidget

private function _MenuButton
   return the long id of btn "_Menu Button" of me
end _MenuButton

