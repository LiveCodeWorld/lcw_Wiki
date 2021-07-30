script "behavior_ViewWikiHtml"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_ViewWikiHtml
type: behavior
version: 0.1


--> Props
-

--> DataView
-
setProp dvHilite [pHiliteColor] pBoolean
   if pBoolean then
      set the backgroundcolor of graphic "Background" of me to "orange"
   else
      set the backgroundcolor of graphic "Background" of me to pHiliteColor
   end if
end dvHilite


--> Geometry | Props
-
getprop label_Height
   return 21
end label_Height

getprop label_Width
   return 45
end label_Width

getprop view_Margin
   return 0,0,0,8
end view_Margin


--> Events
-
on resizeControl
   LayoutControl
end resizeControl


--> Props
-
getprop html_Text
   put the dv_RowValue ["text"] of me into someHTML
   return someHTML
end html_Text

setprop html_Text someHTML
   if the dvControl of me is empty then
      lock screen
      _SetHtmlText someHTML
      LayoutControl
      unlock screen
   else
      set the dv_RowValue ["text"] of me to someHTML
      put the result into dData
      return dData
   end if
end html_Text

setprop label_Text mdText
   _SetLabelText mdText
end label_Text


--> Form
-
on FillInData pDataA, pRow
   _SetLabelText pDataA ["@style"]
   _SetHtmlText pDataA ["text"]
end FillInData

private command _SetHtmlText someHTML
   put word 1 to -1 of someHTML into someHTML
   set the htmltext of _TextField() to someHTML
   return someHTML
end _SetHtmlText

private command _SetLabelText sLabel
   set the text of _LabelField() to sLabel
end _SetLabelText


--> Geometry
-
on LayoutControl pControlRect
   local tRect
   if pControlRect is empty then put the rect of me into pControlRect
   --
   put pControlRect into innerRect
   put the view_Margin of me into viewMargin
   rect_SubtractMargins innerRect, viewMargin
   put item 4 of the result into bMargin
   --
   _SetTextRect innerRect
   put item 4 of the result + bMargin into item 4 of pControlRect
   --
   _SetGraphicRect pControlRect
   _SetLabelRect innerRect
end LayoutControl

command _SetTextRect pControlRect   
   put _TextRect (pControlRect, true) into tRect
   set the rect of _TextField() to tRect
   return tRect
end _SetTextRect

command _SetLabelRect pControlRect   
   put _LabelRect (pControlRect) into labelRect
   set the rect of _LabelField() to labelRect
   return labelRect
end _SetLabelRect

command _SetGraphicRect pControlRect
   set the rect of _GraphicObject() to pControlRect
end _SetGraphicRect


--> Private
-
private function _LabelRect pControlRect
   put the label_Width of me into labelFieldWidth
   put the label_Height of me into labelFieldHeight
   --
   put rect_FromWidthAndHeight (pControlRect, labelFieldWidth, labelFieldHeight) into labelRect
   --
   return labelRect
end _LabelRect

private function _TextRect pControlRect, pUseFormatted
   put _TextField() into fieldObject
   --
   put the view_Margin of me into someMargin
   put the label_Width of me into labelFieldWidth
   put the label_Height of me into labelFieldHeight
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
   put max (labelFieldHeight,fHeight) into fHeight
   put fTop + fHeight into labelBottom
   --
   put labelBottom into item 4 of tRect
   --
   return tRect
end _TextRect


--> Objects
-
getProp dvRowControl
   return the long id of me
end dvRowControl


--> Objects | Private
-
private function _TextField
   return the long id of field "Label" of me
end _TextField

private function _LabelField
   return the long id of field "RowNo" of me
end _LabelField

private function _GraphicObject
   return the long id of graphic "Background" of me
end _GraphicObject

