script "behavior_ViewWikiRoster"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: behavior_ViewWikiRoster
type: behavior
version: 0.1


--> DataView
-
setProp dvHilite [pHiliteColor] pBoolean
   if pBoolean then
      set the backgroundcolor of graphic "Background" of me to "red"
   else
      set the backgroundcolor of graphic "Background" of me to pHiliteColor
   end if
end dvHilite


--> Geometry | Props
-
getprop label_ShiftDown
   return 0
end label_ShiftDown

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
getprop roster_Domains
   put the row_Value ["text"] of me into mdText
   return mdText
end roster_Domains

setprop roster_Domains wikiDomains
   if the dvControl of me is empty then
      lock screen
      _SetRosterDomains wikiDomains
      LayoutControl
      unlock screen
   else
      set the row_Value ["text"] of me to wikiDomains
      put the result into dData
      return dData
   end if
end roster_Domains

setprop label_Text mdText
   _SetLabelText mdText
end label_Text


--> Form
-
on FillInData pDataA, pRow
   -- set the text of field "RowNo" of me to pDataA ["@style"]
   put pDataA ["@style"] into sLabel
   if sLabel = "markdown" then put "mkd" into sLabel
   _SetLabelText sLabel
   --
   put pDataA ["text"] into mdText
   --
   _SetMarkdownText mdText
end FillInData

private command _SetRosterDomains rosterDomains
   -- <img class="remote" src="//dat.fedwiki.org/favicon.png" title="dat.fedwiki.org" data-site="dat.fedwiki.org" data-slug="welcome-visitors">
   repeat for each item wikiDomain in rosterDomains
      put fedwiki_FaviconURL (wikiDomain) into favURL
      put merge ("<img src='[[favURL]]'>") & CR after someHTML 
   end repeat
   delete char -1 of someHTML
   --
   set the htmltext of _TextField() to someHTML
   return someHTML
end _SetRosterDomains

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
   put the label_ShiftDown of me into shiftDown
   add shiftDown to item 2 of labelRect
   add shiftDown to item 4of labelRect
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
