script "behavior_ViewWikiMarkdown"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_ViewWikiMarkdown
type: behavior
version: 0.2


--> Hilite
-
setProp dvHilite [pHiliteColor] pBoolean
   if pBoolean then
      set the backgroundcolor of graphic "Background" of me to "green"
   else
      set the backgroundcolor of graphic "Background" of me to pHiliteColor
   end if
end dvHilite


--> Events
-
on mouseDown
   put _ViewIcon() into vIcon
   put the short id of vIcon into vID
   --
   if the short id of the target = vID then
      set the highlight of vIcon to true
      menu_PullDown "Global | Wiki | Markdown | Menu", "", vIcon
      set the highlight of vIcon to false
   else
      pass mouseDown
   end if
end mouseDown

/*
on mouseLeave
   set the highlight of _ViewIcon() to false
end mouseLeave

on mouseUp
   set the highlight of _ViewIcon() to false
end mouseUp
*/

on resizeControl
   if the long id of the target = the long id of me then
      LayoutControl
   else
      pass resizeControl
   end if
end resizeControl


--> Props
-
getprop markdown_Text
   put the dv_RowValue ["text"] of me into mdText
   return mdText
end markdown_Text

setprop markdown_Text mdText
   if the dvControl of me is empty then
      lock screen
      _SetMarkdownText mdText
      LayoutControl
      unlock screen
   else
      set the dv_RowValue ["text"] of me to mdText
      put the result into dData
      return dData
   end if
end markdown_Text


--> Form
-
on FillInData pDataA, pRow
   -- set the text of field "RowNo" of me to pDataA ["@style"]
   put pDataA ["@style"] into sLabel
   if sLabel = "markdown" then put "mkd" into sLabel
   --
   put pDataA ["text"] into mdText
   --
   _SetMarkdownText mdText
end FillInData

private command _SetMarkdownText mdText
   put word 1 to -1 of mdText into mdText
   put mergMarkdownToXHTML (mdText,,true) into someHTML
   --
   dv_TidyHTML someHTML
   --
   put word 1 to -1 of someHTML into someHTML
   set the htmltext of _TextField() to someHTML
   return theHTML
end _SetMarkdownText


--> Geometry | Props
-
getprop row_LeftMargin
   put the dv_LeftMargin of me into leftM
   if leftM is empty then
      return 45
   else
      return leftM
   end if
end row_LeftMargin

getprop icon_Height
   return 18
end icon_Height

getprop min_Height
   return 21
end min_Height

getprop view_Margin
   return 0,0,0,8
end view_Margin


--> Geometry
-
on LayoutControl pControlRect
   local tRect
   if pControlRect is empty then put the rect of me into pControlRect
   put the dv_IconsShowing of me is not false into iconsShowing
   --
   put pControlRect into innerRect
   put the view_Margin of me into viewMargin
   rect_SubtractMargins innerRect, viewMargin
   put item 4 of the result into bMargin
   --
   put _TextRect (innerRect, true) into fieldRect
   --
   put pControlRect into graphicRect
   put item 4 of fieldRect + bMargin into item 4 of graphicRect
   --
   put _IconRect (innerRect) into iconRect
   --
   put _ViewIcon() into vIcon
   set the visible of vIcon to iconsShowing
   set the rect of vIcon to iconRect
   set the rect of _GraphicObject() to graphicRect
   set the rect of _TextField() to fieldRect
   --
   set the rect of me to pControlRect
end LayoutControl


--> Private
-
private function _IconRect innerRect
   put the icon_Height of me into iconHeight
   --
   put item 1 of innerRect + iconHeight into item 3 of innerRect
   put item 2 of innerRect + iconHeight into item 4 of innerRect
   --
   add 12 to item 1 of innerRect
   add 12 to item 3 of innerRect
   
   add 8 to item 2 of innerRect
   add 8 to item 4 of innerRect
   --
   return innerRect
end _IconRect

private function _TextRect pControlRect, pUseFormatted
   put _TextField() into fieldObject
   --
   put the view_Margin of me into someMargin
   put the row_LeftMargin of me into labelFieldWidth
   put the min_Height of me into minHeight
   --
   put pControlRect into tRect
   --
   put item 1 of tRect + labelFieldWidth into tLeft
   put tLeft into item 1 of tRect
   --
   put item 2 of tRect into fTop
   if pUseFormatted is true then
      put the formattedheight of fieldObject into fHeight
      -- add 4 to fHeight
   else
      put item 4 of tRect - fTop into fHeight
   end if
   --
   put max (minHeight,fHeight) into fHeight
   put fTop + fHeight into labelBottom
   --
   put labelBottom into item 4 of tRect
   --
   return tRect
end _TextRect


--> Objects | Private
-
private function _TextFieldID
   return the short id of field "Label" of me
end _TextFieldID

private function _TextField
   return the long id of field "Label" of me
end _TextField

private function _ViewIcon
   return the long id of widget 1 of me
end _ViewIcon

private function _GraphicObject
   return the long id of graphic "Background" of me
end _GraphicObject


--> Objects
-
getProp dvRowControl
   return the long id of me
end dvRowControl
