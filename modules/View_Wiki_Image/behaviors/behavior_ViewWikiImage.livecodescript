script "behavior_ViewWikiImage"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_ViewWikiImage
type: behavior
version: 0.1

--> DataView
-
setProp dvHilite [pHiliteColor] pBoolean
   if pBoolean then
      set the backgroundcolor of graphic "Background" of me to "purple"
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
getprop image_File
   put the text of _TextField() into imagefile
   return imagefile
end image_File

setprop image_File imagefile
   _SetImage imagefile
end image_File

setprop label_Text imageCaption
   _SetLabelText imageCaption
end label_Text


--> Form
-
on FillInData pDataA, pRow
   -- set the text of field "RowNo" of me to pDataA ["@style"]
   put pDataA ["@style"] into sLabel
   _SetLabelText sLabel
   --
   -- put pDataA ["text"] into imageText -- wiki editable
   put pDataA ["caption"] into imageCaption
   put pDataA ["url"] into imageURL
   --
   _SetImage imageURL, imageCaption
end FillInData

private command _SetImage dataImageURL, imageCaption
   put word 1 to -1 of imageCaption into imageText
   set the text of _TextField() to imageText
   --
   set the itemdelimiter to slash
   if item 1 of dataImageURL = "data:image" then
      put image_FromDataImageUrl (dataImageURL) into someImage
      set the text of _ImageObject() to someImage
   else
      -- set the text of _ImageObject() to dataImageURL
      set the filename of _ImageObject() to dataImageURL
   end if
   return imageCaption
end _SetImage

private command _SetLabelText sLabel
   set the text of _LabelField() to sLabel
end _SetLabelText


--> Geometry
-
on LayoutControl pControlRect
   local tRect
   put false into pUseFormatted
   
   if pControlRect is empty then put the rect of me into pControlRect
   --
   put pControlRect into innerRect
   put the view_Margin of me into viewMargin
   rect_SubtractMargins innerRect, viewMargin
   put item 4 of the result into bMargin
   --
   _SetLabelRect innerRect
   --
   put _ImageRect (innerRect, pUseFormatted) into imageRect
   set the image_Rect of _ImageObject() to imageRect
   put the result into resizedImageRect
   --
   put _CaptionRect (innerRect, resizedImageRect, pUseFormatted) into captionRect
   set the rect of _TextField() to captionRect
   --
   put pControlRect into graphicRect
   put item 4 of captionRect + bMargin into item 4 of graphicRect
   _SetGraphicRect graphicRect
end LayoutControl

private function _ImageRect innerRect, pUseFormatted
   put the view_Margin of me into someMargin
   put the label_Width of me into labelFieldWidth
   put 8 into imageMargin
   --
   put innerRect into imageRect
   rect_SubtractMargins imageRect, imageMargin
   --
   put item 1 of imageRect + labelFieldWidth into tLeft
   put tLeft into item 1 of imageRect
   --
   put item 2 of imageRect into fTop
   put _GetImageHeight (pUseFormatted) into fHeight
   put fTop + fHeight into labelBottom
   --
   put labelBottom into item 4 of imageRect
   --
   return imageRect
end _ImageRect

private function _GetImageHeight pUseFormatted
   if pUseFormatted is true then
      put _ImageObject() into imageObject
      put the formattedheight of imageObject into fHeight
   else
      put 156 into fHeight
   end if
   --
   put the label_Height of me into labelFieldHeight
   put max (labelFieldHeight, fHeight) into imageHeight
   --
   return imageHeight
end _GetImageHeight

private function _CaptionRect innerRect, imageRect, pUseFormatted
   put _TextField() into fieldObject
   --
   put 8 into captionSpacer
   put the view_Margin of me into someMargin
   put the label_Width of me into labelFieldWidth
   put the label_Height of me into labelFieldHeight
   --
   put innerRect into tRect
   --
   put item 4 of imageRect into imageBottom
   put imageBottom + captionSpacer into captionTop
   put captionTop into item 2 of tRect
   
   put item 1 of tRect + labelFieldWidth into tLeft
   put tLeft into item 1 of tRect
   --
   if pUseFormatted is true then
      put the formattedheight of fieldObject into fHeight
   else
      put item 4 of tRect - captionTop into fHeight
   end if
   --
   put max (labelFieldHeight,fHeight) into fHeight
   put captionTop + fHeight into labelBottom
   --
   put labelBottom into item 4 of tRect
   --
   return tRect
end _CaptionRect

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


--> Objects
-
getProp dvRowControl
   return the long id of me
end dvRowControl

getprop image_Object
   return _ImageObject()
end image_Object


--> Objects | Private
-
private function _ImageObject
   return the long id of image 1 of me
end _ImageObject

private function _TextField
   return the long id of field "Label" of me
end _TextField

private function _LabelField
   return the long id of field "RowNo" of me
end _LabelField

private function _GraphicObject
   return the long id of graphic "Background" of me
end _GraphicObject
