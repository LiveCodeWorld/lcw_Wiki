script "behavior_ViewWikiBackground"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_ViewWikiBackground
type: behavior
version: 0.1

/*Here you make make notes as a basic form of help for this view.
Full help text can be found on the linked wiki for the view.*/


--> Variables
-
constant kFlagWidth = 30


--> Working on
-
on mouseDoubleUp
   put the wiki_View of me into wikiView
   --
   put the short name of the target into wikiURL
   if char 1 of wikiURL = "_" then pass mouseDoubleUp
   
   wikiUrl_Deconstruct wikiURL, wikiDomain, slugDomain, pageSlug, -1
   --
   set the page_Slug [slugDomain] of wikiView to pageSlug
end mouseDoubleUp

function fedwiki_CheckUrl
   return true
end fedwiki_CheckUrl

on mouseUp
   -- create_FlagButton
   pass mouseUp
end mouseUp


--> Create
-
command delete_Flags
   put the flag_Objects of me into flagObjects
   repeat for each line flagObject in flagObjects
      delete flagObject
   end repeat
   
   put the flag_Images of me into flagImages
   repeat for each line flagImage in flagImages
      delete flagImage
   end repeat
end delete_Flags

command create_FaviconImage faviconURL, pDropLoc
   put _ImageGroup() into imageGroup
   
   # Check flag for wikidomain not already created
   set the itemdelimiter to slash
   put item 3 of faviconURL into wikiDomain
   if exists (image wikiDomain of imageGroup) then
      put the long id of image wikiDomain of imageGroup into imageView
      return imageView
   end if
   
   # dropRect
   if pDropLoc is empty then put the mouseLoc into pDropLoc
   put rect_LocWidthHeight (pDropLoc, kFlagWidth, kFlagWidth) into dropRect
   
   lock screen
   view_InsertFromPath "View|Image", imageGroup, dropRect
   put the result into imageView
   --
   set the name of imageView to wikiDomain
   --
   set the image_URL of imageView to faviconURL
   set the script of imageView to handler_Grabme()
   unlock screen
   --
   return imageView
end create_FaviconImage

function handler_Grabme
   put "on mouseDown,   grab me,end mouseDown" into grabScript
   replace comma with CR in grabScript
   return grabScript
end handler_Grabme

command create_FlagButton flagURL, pIconID, pDropLoc
   put the short id of me into myID
   put colour_GetRandom() into sColour
   
   # dropRect
   if pDropLoc is empty then put the mouseLoc into pDropLoc
   put rect_LocWidthHeight (pDropLoc, kFlagWidth, kFlagWidth) into dropRect
   
   # Create
   lock screen
   create_PlaceHolder flagURL, dropRect, myID, sColour
   put the result into flagButton
   --
   set the drag_Able of flagButton to true
   set the showname of flagButton to false
   set the label of flagButton to empty
   set the tooltip of flagButton to flagURL
   --
   if pIconID is a number then
      set the icon of flagButton to pIconID 
   end if
   unlock screen
   --
   return flagGraphic
end create_FlagButton


--> Drag
-
function drag_Type newArray
   switch
      case newArray ["files"] is not empty
         return "files"
      case newArray ["html"] ends with "/favicon.png</p>"
         return "favicon"
      case newArray ["html"] is not empty
         put newArray ["text"] into sURL
         if fedwiki_CheckUrl (sURL) is true then
            return "flag"
         end if
      default
         return empty
   end switch
end drag_Type

function drag_DropArray
   repeat for each item dKey in "text,html,files,image,rtf,unicode,styles,private"
      put the dragdata [dKey] into dropArray [dKey]
   end repeat
   return dropArray
end drag_DropArray


--> Events | Drag Drop
-
on dragDrop
   put drag_DropArray() into newArray
   set the drop_Data of me to newArray
   --
   switch drag_Type (newArray) 
      case "flag"
         put newArray ["text"] into flagURL
         set the itemdelimiter to slash
         put item 3 of flagURL into wikiDomain
         put fedwiki_FaviconURL (wikiDomain) into faviconURL
         --
         create_FaviconImage faviconURL
         put the result into imageObject
         put the short id of imageObject into imageID
         --
         create_FlagButton flagURL, imageID
         put the result into flagButton
         break
      case "favicon"
         put newArray ["text"] into faviconURL
         create_FaviconImage faviconURL
         break
      case "files"
         
         break
   end switch
   pass dragDrop
end dragDrop

on dragEnter -- show a green outline around the drop target
   set the allowableDragActions to "link"
   set the dragAction to "Link"
   --
   pass dragEnter
end dragEnter

on dragLeave
   -- set the borderColor of the target to ""
   pass dragLeave
end dragLeave


--> Props
-
getprop drop_Data
   return the arrayData of _DropTree()
end drop_Data

setprop drop_Data dData
   set the arrayData of _DropTree() to dData
end drop_Data

getprop show_Name
   return the showname of _BackGraphic()
end show_Name

setprop show_Name sBoolean
   set the showname of _BackGraphic() to sBoolean
end show_Name


--> Geometry
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

command LayoutControl cRect
   if cRect is empty then put the rect of me into cRect
   --
   put cRect into wRect
   put the card_Margin of me into cMargin
   rect_SubtractMargins wRect, cMargin
   --
   put _BackGraphic() into backGraphic
   if exists (backGraphic) then set the rect of backGraphic to cRect
   return wRect
end LayoutControl


--> Events
-
on resizeControl
   put the rect of me into viewRect
   LayoutControl viewRect
end resizeControl

on mouseDown pButtonNumber
   if pButtonNumber is not 3 then pass mouseDown
   --
   put the module_menuTitle of me into mTitle
   put CR & "-" after mTitle
   put CR & "Global | Wiki | Background | Menu" & tab & "submenu" after mTitle
   put the menu_Button of me into mButton
   --
   mArray_PopUp mTitle, mButton
end mouseDown


--> Objects
-
getprop flag_Images
   put _ImageGroup() into imageGroup
   repeat for each line imageID in the childControlIDs of imageGroup
      put the long id of control id imageID of imageGroup into imageObject
      put imageObject & CR after imageObjects
   end repeat
   delete char -1 of imageObjects
   return imageObjects
end flag_Images

getprop flag_Objects
   return the top_Views ["placeHolder_Button"] of me
end flag_Objects

getprop view_Object
   return the long id of me
end view_Object

private function _ImageGroup
   return the long id of group "_Favicon Images" of me
end _ImageGroup

private function _DropTree
   return the long id of widget "_DropTree" of me
end _DropTree

private function _BackGraphic
   return the long id of graphic "_DropZone" of me
end _BackGraphic


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
