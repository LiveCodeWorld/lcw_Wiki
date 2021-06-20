script "behavior_ViewTitleWiki"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_ViewTitleWiki
type: view behavior
version: 0.6

/*
This view is designed to look and feel like a fedwiki wiki-page header.

It is also an experiment in the proper development path for views.
We look to:
- Move towards Livecode Builder widget development
- Create a rapid prototyping environment for HTML5 web components
- Integrate with Demo based javascipt develoopment
*/

--> Variables
-
local LocalArray


--> Working on
-

--> Wiki | Props
-
getprop flag_URL
   put _FlagImage() into flagImage
   put the filename of flagImage into fileOrURL
   return fileOrURL
end flag_URL

setprop flag_URL fileOrURL
   put _FlagImage() into flagImage
   set the filename of flagImage to fileOrURL
   return flagImage
end flag_URL


--> Geometry
-
getprop working_Rect
   put the long id of the target into tObject
   --
   put the rect of tObject into tRect
   put the margins of tObject into tMargins
   --
   if the showborder of tObject is true then
      put the borderwidth of tObject into bWidth
      rect_SubtractMargins tRect, bWidth
   end if
   rect_SubtractMargins tRect, tMargins
   return tRect
end working_Rect

command LayoutControl pControlRect, pWorkingRect
   lock screen
   if pControlRect is empty then put the rect of me into pControlRect
   if pWorkingRect is empty then put the working_Rect of me into pWorkingRect
   
   put _TitleFieldRect (pWorkingRect, pControlRect) into tFieldRect
   put _MenuButtonRect (pWorkingRect) into mButtonRect
   --
   set the rect of _TitleField() to tFieldRect
   set the rect of _FlagMenuButton() to mButtonRect
   set the rect of _FlagImage() to mButtonRect
   unlock screen
end LayoutControl

private function _TitleFieldRect wRect, cRect
   put _GetMarginLeft (wRect, cRect) into marginLeft
   put _GetWorkingHeight (wRect) into wHeight
   --
   put wRect into fRect
   put item 1 of wRect + wHeight + marginLeft into item 1 of fRect
   return fRect
end _TitleFieldRect

private function _MenuButtonRect wRect
   put wRect into bRect
   put _GetWorkingHeight (wRect) into wHeight
   put item 1 of wRect + wHeight into item 3 of bRect
   return bRect
end _MenuButtonRect

private function _GetMarginLeft workingRect, controlRect
   put item 1 of workingRect - item 1 of controlRect into marginLeft
   return marginLeft
end _GetMarginLeft

private function _GetWorkingHeight wRect
   put item 4 of wRect - item 2 of wRect into wHeight
   return wHeight
end _GetWorkingHeight


--> Events
-
on resizeControl
   put the rect of me into viewRect
   LayoutControl viewRect
end resizeControl

on menuPick menuPath
   menu_DispatchTextPick menuPath
end menuPick

on mouseDown
   -- customise or remove
   switch word 1 of the name of the target
      case "button"
         break
      case "field"
         break
   end switch
end mouseDown

on preOpenControl
   -- customise or remove
   pass preOpenControl
end preOpenControl

on mouseUp
   -- customise or remove
   switch word 1 of the name of the target
      case "button"
         break
      case "field"
         break
   end switch
   pass mouseUp
end mouseUp

on mouseDoubleUp
   -- customise or remove
   switch word 1 of the name of the target
      case "button"
         break
      case "field"
         break
   end switch
   pass mouseDoubleUp
end mouseDoubleUp


--> Objects
-
getprop menu_Button
   return _FlagMenuButton()
end menu_Button


--> Private
-
private function _TitleField
   put the long id of fld 1 of me into titleField
   return titleField
end _TitleField

private function _FlagMenuButton
   put the long id of btn 1 of me into mButton
   return mButton
end _FlagMenuButton

private function _FlagImage
   put the long id of image 1 of me into flagImage
   return flagImage
end _FlagImage


--> Variables
-
-- local LocalArray


--> Events
-
on dragEnter
   set the dragAction to "link"
end dragEnter

on dragDrop
   put the dragdata ["text"] into droppedURL
   --
   set the wiki_URL of me to droppedURL
end dragDrop

command fedwiki_CheckURL droppedURL, @wikiDomain, @slugOrLineUp
   set the itemdelimiter to slash
   put item 3 of droppedURL into wikiDomain
   if fedwiki_WikiExists (wikiDomain) is false then
      put empty into slugOrLineUp
      return empty
   end if
   
   switch
      case the number of items of droppedURL = 4 AND droppedURL ends with ".html"
         get item 4 of droppedURL
         set the itemdelimiter to "."
         put item 1 of it into slugOrLineUp
         return "html"
      default
         put item 4 to -1 of droppedURL into slugOrLineUp
         return "lineup"
   end switch
end fedwiki_CheckURL


--> Page | Props
-
getprop page_Array
   put _WikiGrid() into wikiGrid
   put the dgData of wikiGrid into storyArray
   put the title_Text of me into pageArray ["title"]
   put storyArray into pageArray ["story"]
   put the journal_Array of me into pageArray ["journal"]
   return pageArray
end page_Array

setprop page_Array pageArray
   put _WikiGrid() into wikiGrid
   put pageArray ["story"] into storyArray
   --
   set the title_Text of me to pageArray ["title"]
   set the dgData of wikiGrid to storyArray
   set the journal_Array of me to pageArray ["journal"]
   return wikiGrid
end page_Array

getprop title_Text
   put the text of _TitleField() into pageTitle
   return pageTitle
end title_Text

setprop title_Text pageTitle
   set the text of _TitleField() to pageTitle
end title_Text

private function _TitleField
   put the long id of fld "Page Title" of me into titleField
   return titleField
end _TitleField
   
getprop page_Slug
   put LocalArray ["pageSlug"] into pageSlug
   return pageSlug
end page_Slug

setprop page_Slug pageSlug
   put pageSlug into LocalArray ["pageSlug"]
end page_Slug

getprop journal_Array
   put LocalArray ["journalArray"] into journalArray
   return journalArray
end journal_Array

setprop journal_Array journalArray
   put journalArray into LocalArray ["journalArray"]
end journal_Array


--> Wiki | Props
-
getprop wiki_Flag
   put _FlagImage() into flagImage
   put the filename of flagImage into fileOrURL
   return fileOrURL
end wiki_Flag

setprop wiki_Flag fileOrURL
   put _FlagImage() into flagImage
   set the filename of flagImage to fileOrURL
   return flagImage
end wiki_Flag

getprop wiki_URL
   put LocalArray ["wikiURL"] into wikiURL
   return wikiURL
end wiki_URL

setprop wiki_URL wikiURL
   put wikiURL into LocalArray ["wikiURL"]
   --
   fedwiki_CheckURL wikiURL, wikiDomain, slugOrLineUp
   switch the result
      case "html"
         _DisplayHtmlUrl wikiDomain, slugOrLineUp
         break
      case "lineUp"
         put wikiDomain & CR & slugOrLineUp
         break
      case empty
         answer "Not a wiki!"
         break
   end switch
end wiki_URL

private command _DisplayHtmlUrl wikiDomain, slugOrLineUp
   put pageArray_Fetch (wikiDomain, slugOrLineUp) into pageArray
   put pageArray ["title"] into pageTitle
   --
   put wikiDomain & CR & slugOrLineUp
   set the title_Text of me to pageTitle
   --
   -- display_Data pageArray, pageTitle, "Wiki HTML", empty, "system"
   -- display_PageArray
   --
   set the page_Array of me to pageArray
end _DisplayHtmlUrl

getprop wiki_Domain
   put LocalArray ["wikiDomain"] into wikiDomain
   return wikiDomain
end wiki_Domain
   
setprop wiki_Domain wikiDomain
   put wikiDomain into LocalArray ["wikiDomain"]
end wiki_Domain

--> Geometry
-
private function _GetLeftIconRect innerRect
   switch the leftIcon_Size of me
      case "square"
         put item 4 of innerRect - item 2 of innerRect into iconWidth
         break
      case "fixed"
         put the left_IconWidth of me into iconWidth
         break
      default -- case "formatted"
         put the left_Icon of me into iconView
         put the formatted_Width of iconView into iconWidth
         if iconWidth is empty then put the formattedWidth of iconView into iconWidth
         if iconWidth is empty then put the width of iconView into iconWidth
   end switch
   
   put item 1 of innerRect + iconWidth into item 3 of innerRect
   return innerRect
end _GetLeftIconRect


--> Private
-
private function _WikiGrid
   put the long id of group "Wiki Grid" of me into wikiGrid
   return wikiGrid
end _WikiGrid

private function _FlagImage
   put the long id of image "Flag Image" of me into flagImage
   return flagImage
end _FlagImage
   

/*
-- This script defines the behavior of your data grid's custom template. This behavior
-- only applies to 'forms' and not 'tables'.

on FillInData itemArray
   -- This message is sent when the Data Grid needs to populate
   -- this template with the data from a record. pDataArray is an
   -- an array containing the records data.
   -- You do not need to resize any of your template's controls in
   -- this message. All resizing should be handled in resizeControl.
   
   put itemArray ["id"] into itemID
   put itemArray ["type"] into itemType
   put itemArray ["text"] into itemText
   --
   set the text of field "Text" of me to word 1 to -1 of itemText
end FillInData


on resizeControl 
   put the rect of me into pControlRect
   LayoutControl pControlRect
   pass resizeControl
end resizeControl


on LayoutControl pControlRect, pWorkingRect
   local theFieldRect
   
   put the long id of field "Text" of me into textField
   --
   put pControlRect into theFieldRect
   /*
   put the formattedheight of field "Text" of me into fHeight
   --
   put item 3 of theFieldRect - 5 into item 3 of theFieldRect
   put item 2 of theFieldRect + fHeight into item 4 of theFieldRect
   */
   set the rect of textField to theFieldRect
   set the rect of graphic "Background" of me to pControlRect
   --
   put colour_GetRandom() into someColour
   set the backgroundcolor of textField to someColour
   set the opaque of textField to true
end LayoutControl


on ResetData
   -- Sent when data is being emptied because the control is no longer being used to display data
   set the text of field "Text" of me to empty
end ResetData


on PreFillInData
   -- Sent right before new data is going to replace existing data in the control
end PreFillInData


setprop dgHilite pBoolean
   -- This custom property is set when the highlight of your custom template has
   -- changed. By default the "Background" graphic will be highlighted for you. 
   -- You only add script here if you want to further customize the highlight.
   
   -- Example:
   if pBoolean then
      set the foregroundColor of me to the dgProp["hilited text color"] of the dgControl of me
   else
      set the foregroundColor of me to empty
   end if
end dgHilite


getprop dgDataControl
   -- Required by library so that it can locate your control.
   return the long ID of me
end dgDataControl


on mouseDoubleUp pMouseBtnNum
   local theKey
   
   -- Example of how to edit the contents of a field.
   -- By passing the index of the record associated with copy of this template being displayed and
   -- a key (array key) the data grid will automatically save the changes the user
   -- makes and refresh the UI by calling FillInData and resizeControl.
   if pMouseBtnNum is 1 then
      if the dgProps["allow editing"] of the dgControl of me then
         switch the short name of the target
            case "Text"
               put "Text" into theKey
               EditFieldText the long ID of the target, the dgIndex of me, theKey
               break                 
         end switch
      end if
   end if
   
   pass mouseDoubleUp
end mouseDoubleUp
*/
