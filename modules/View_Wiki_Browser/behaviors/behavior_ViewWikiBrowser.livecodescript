script "behavior_ViewWikiBrowser" with behavior "behavior_WikiJavascript"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_ViewWikiBrowser
type: behavior
version: 0.4

/*
This view is for a single wiki-browser view
*/


--> Variables
-
local LocalArray


--> Working on
-


--> Props
-
getprop performative_Dictionary
   put _WikiDomain() into wikiDomain
   --
   put pageArray_Get (wikiDomain, "performative-dictionary") into pageArray
   put handlerWiki_Array() into wikiArray
   put pageArray_ReferenceDictionary (pageArray, wikiArray) into pDict
   return pDict
end performative_Dictionary

getprop siteMap_Array
   put _WikiDomain() into wikiDomain
   put wikiSiteMap_Construct (wikiDomain) into wsmArray
   return wsmArray
end siteMap_Array

getprop wiki_Domain [pageTitle]
   if pageTitle is empty then
      return _WikiDomain()
   else
      put fedwiki_ConstructSlug (pageTitle) into pageSlug
      put _SlugArray() into slugArray
      put slugArray [pageSlug]["wikiDomain"] into wikiDomain
      return wikiDomain
   end if
end wiki_Domain

setprop wiki_Domain wikiDomain
   put "http://" & wikiDomain into wikiURL
   set the browser_URL of me to wikiURL
   set the stack_Label of me to wikiDomain
end wiki_Domain

private function _WikiDomain
   set the itemdelimiter to slash
   --
   put the browser_URL of me into someURL
   get item 3 of someURL
   --
   set the itemdelimiter to ":"
   put item 1 of it into wikiDomain
   put item 2 of wikiDomain into sPort
   --
   set the itemdelimiter to "."
   if item 1 of wikiDomain = "www" then
      delete item 1 of wikiDomain
   end if
   return wikiDomain
end _WikiDomain

setprop wiki_URL lineupURL
   set the itemdelimiter to slash
   switch
      case item 1 of domainOrURL = "https:"
      case item 1 of domainOrURL = "http:"
         -- http://arodic.github.io/p/jellyfish/
         put domainOrURL into someURL
         set the itemdelimiter to slash
         put item 3 of domainOrURL into wikiDomain
         break
      default
         put domainOrURL into wikiDomain
         put wiki_ConstructUrl (wikiDomain) into someURL
   end switch
   --
   set the browser_URL of me to someURL
   set the stack_Label of me to wikiDomain
end wiki_URL


--> Working on | Init
-
on wikiBrowser_Init
   set the flag_Handler of me to "default"
   set the wiki_EditMode of me to true
   --
   -- set the show_Menu of _MenubarView() to true
end wikiBrowser_Init

private command _RectIfMenuBar @sRect
   put the menubar of the defaultstack into gName
   if (gName is not empty) then
      put 20 into mHeight
      --
      put the menubar_View of me into mGroup
      if exists (mGroup) is false then return false
      add mHeight to item 2 of sRect
      -- subtract mHeight from item 4 of sRect
      return true
   else
      return false
   end if
end _RectIfMenuBar


--> Events
-
on resizeControl
   put the rect of me into viewRect
   LayoutControl viewRect
end resizeControl

command LayoutControl pRect
   if pRect is empty then put the rect of this cd into pRect
   _RectIfMenuBar pRect
   --
   set the rect of me to pRect
end LayoutControl


--> Init
-
on preOpenControl
   -- LayoutCard
   
   send "wikiBrowser_Init" to me in 30 ticks
   pass preOpenControl
end preOpenControl


--> Props
-
getprop browser_Snapshot [newW]
   -- if pNewW is empty then put 420 into pNewW
   local sMargin = 12
   
   # WindowID
   put the windowID of the defaultstack into wID
   
   # Work out local rect
   put the rect of me into localRect
   put rect_SimpleSubtract (localRect, sMargin) into innerRect
   --
   if newW is empty then
      export snapshot from rect innerRect of window wID to somePNG as PNG
   else
      put scale_Height (localRect, newW) into newH
      put newW,newH into exportDimensions
      --
      export snapshot from rect innerRect of window wID at size exportDimensions to somePNG as PNG
   end if
   return somePNG
end browser_Snapshot

getprop page_Text [titleOrNum]
   put the page_Array [titleOrNum] of me into pageArray
   put pageArray_Text (pageArray) into pageText
   return pageText
end page_Text

getprop menu_Target [tObject]
   -- used but menus of "View|Wiki|Browser"
   if exists (tObject) is false then
      put the long id of the target into tObject
   end if
   --
   put the wikiBrowser_View of tObject into wikiView
   if exists (wikiView) is false then
      put the display_View of tObject into dView
      put the displayed_Object of dView into wikiView
      if exists (wikiView) is false then
         return empty
      end if
   end if
   
   return wikiView
end menu_Target


--> Objects
-
getprop wikiBrowser_View
   return the long id of me
end wikiBrowser_View

getprop browser_View
   return the long id of me
end browser_View

getprop view_Object
   return the long id of me
end view_Object


--> Wiki | URL
-
getprop browser_URL
   put the url of me into someURL
   return someURL
end browser_URL

setprop browser_URL someURL
   put the previous_Url of me into previousURL
   set the url of me to someURL
   
   set the previous_Url of me to someURL
   
   # Init
   send "wikiBrowser_Init" to me in 30 ticks
   return previousURL
end browser_URL

setprop wikipedia_Page pageTitle
   put mediawiki_GetPageArrayFromSlug (pageTitle) into pageArray
   set the ghost_PageArray of me to pageArray
   return pageArray
end wikipedia_Page


--> Page | Model
-
getprop page_Array [titleOrNum]
   put the lineup_Data of me into lineupData
   switch
      case titleOrNum is empty
         return lineupData
      case titleOrNum is a number
         return lineupData [titleOrNum]
      default
         -- find
         get indexArray_FindArray (lineupData, "title", titleOrNum)
         return it
   end switch
end page_Array

setprop page_Array [overWrite] pageArray
   put pageArray ["Title"] into pTitle
   put fedwiki_ConstructSlug (pTitle) into pSlug
   put the page_JsonFile [pSlug] of me into pageJsonFile
   --
   switch
      case overWrite is true
      case there is not a file pageJsonFile
         breakpoint
         put json_FromArray (pageArray) into pageJSON
         text_Set pageJsonFile, pageJson
         set the page_Title of me to pageSlug
         break
      default
         return empty
   end switch
end page_Array

getprop page_Json [pSlug]
   put the page_JsonFile [pSlug] of me into pageJsonFile
   put text_Get (pageJsonFile) into pageJson
   return pageJson
end page_Json

setprop page_Json [pSlug] pageJSON
   put the page_JsonFile [pSlug] of me into pageJsonFile
   text_Set pageJsonFile, pageJson
   return pageJsonFile
end page_Json

getprop page_JsonFile [pSlug]
   put the wiki_Domain of me into wikiDomain
   put _PageJsonConstructFile (wikiDomain, pSlug) into pageJsonFile
   return pageJsonFile
end page_JsonFile

getprop wiki_Garden
   put _WikiDomain() into wikiDomain
   put wikiGarden_Name (wikiDomain) into gardenName
   return gardenName
end wiki_Garden

getprop page_Slugs
   put the lineup_Urls of me into lineupUrls
   repeat for each line wikiURL in lineupUrls
      set the itemdelimiter to slash
      put item -1 of wikiURL into shortFile
      set the itemdelimiter to "."
      put item 1 of shortFile into pSlug
      --
      put pSlug & CR after pSlugs
   end repeat
   delete char -1 of pSlugs
   return pSlugs
end page_Slugs

getprop page_Titles
   put the lineup_Data of me into lineupData
   put indexArray_List (lineupData, "title") into pageTitles
   return pageTitles
end page_Titles


--> Displayed
-
getprop displayed_Data
   put the browser_URL of me into someURL
   if someURL is empty then
      return the browser_HtmlText of me
   else
      return someURL
   end if
end displayed_Data

setprop displayed_Data urlOrHtml
   set the itemdelimiter to ":"
   put item 1 of urlOrHtml is among the items of "http:https" into isUrl
   --
   if isUrl then
      set the browser_URL of me to urlOrHtml
   else
      set the browser_HtmlText of me to urlOrHtml
   end if
   return isUrl
end displayed_Data


--> URL
-
getprop previous_Url
   put the previous_Url of me into someURL
   return someURL
end previous_Url

setprop previous_Url someURL
   set the previous_Url of me to someURL
   return the long id of me
end previous_Url

getprop browser_Domain
   get the browser_URL of me
   set the itemdelimiter to slash
   put item 3 of it into sDomain
   return sDomain
end browser_Domain

setprop browser_Domain sDomain
   put url_Construct (sDomain) into someURL
   set the browser_URL of me to someURL
   return the result
end browser_Domain

getprop browser_HtmlText
   put the htmltext of me into someHTML
   return someHTML
end browser_HtmlText

setprop browser_HtmlText someHTML
   set the htmltext of me to someHTML
   return the long id of me
end browser_HtmlText


--> Private | Objects
-
private function _MenubarView
   put the menu_Group of me
   if exists (group 1 of the owner of me) is false then return empty
   put the long id of group 1 of the owner of me into mGroup
   return mGroup
end _MenubarView

private function _PageArray lineupUrl
   -- should I use binary and textEncode
   put url lineupUrl into pageJson
   put json_ToArray (pageJson) into pageArray
   return pageArray
end _PageArray

private command _DisplayToolsPage pageTitle, wikiDomain, urlPath
   # Open tools
   set the itemdelimiter to slash
   put item -1 of urlPath into pageSlug
   --
   put the page_Class [pageSlug] of me into pageClass
   switch
      /*
      case the optionkey is "Down"
         set the page_Title of me to "Tools"
         break
      case the shiftkey is "Down"
         */
      case pageClass contains "ghost"
         set the wikipedia_Page of me to pageSlug
         break
      default 
         put wikiFile_Construct (wikiDomain, pageSlug) into jsonFile
         if there is a file jsonFile then
            put wikiPage_EditPage (pageSlug, wikiDomain) into pageArray
         else
            put wikiDialogue_Get (pageSlug, wikiDomain, "create-page-dialogue", "Create Page") into pageArray
         end if
         set the ghost_PageArray of me to pageArray
         --
         -- _CheckPageArray pageArray, pageSlug, wikiDomain
   end switch
end _DisplayToolsPage

private function _GuessLastSlug sReferer
   set the itemdelimiter to slash
   put item -1 of sReferer into lastPageSlug
   if lastPageSlug = "tools" then
      put item -3 of sReferer into lastPageSlug
   end if
   return lastPageSlug
end _GuessLastSlug

private command _CheckPageArray pageArray, pageSlug, wikiDomain
   put _GuessLastSlug (urlPath) into lastPageSlug
   --
   put pageArray ["story"] into storyArray
   put item 2 of the extents of storyArray into maxItemNum
   --
   if the shiftKey is "down" then
      display_PageArray pageArray
   end if
   --
   if maxItemNum < 3 then
      breakpoint
      put wikiDialogue_Get (pageSlug, wikiDomain, "create-page-dialogue", "Create Page") into pageArray
   end if
end _CheckPageArray

private function _SlugArray
   put the browser_URL of me into browserURL
   --
   set the itemdelimiter to slash
   put item 3 of browserURL into ownerDomain
   
   put _LineUpJson() into lineupJson
   replace comma with CR in lineupJson
   replace quote with empty in lineupJson
   
   repeat for each line sLink in lineupJson
      set the itemdelimiter to slash
      if char 1 to 2 of sLink = "//" then
         put item 3 of sLink into sDomain
         put item 4 of sLink into pageSlug
      else
         put ownerDomain into sDomain
         put item -1 of sLink into pageSlug
      end if
      
      set the itemdelimiter to "."
      delete item -1 of pageSlug
      
      put sDomain into slugArray [pageSlug]["wikiDomain"]
   end repeat
   return slugArray
end _SlugArray


--> Deps
-
function pageArray_Text pageArray, pIncludeNotes, pBreak
   if pBreak is empty then put CR&CR into pBreak
   --
   put pageArray ["story"] into storyArray
   repeat with itemNum = 1 to item 2 of the extents of storyArray
      put storyArray [itemNum] into itemArray
      put itemArray ["text"] into itemText
      switch itemArray ["type"]
         case "pageFold"
            if pIncludeNotes is not false then
               exit repeat
            end if
         case "paragraph"
         case "markdown"
            if itemText = "# See also" and pIncludeNotes is not false then
               exit repeat
            end if
            
            -- pageArray_CleanText itemText
            put markdown_ToText (itemText) into sText
            put sText & pBreak after pageText
         case "html"
            break
         default
            next repeat
      end switch
   end repeat
   return word 1 to -1 of pageText
end pageArray_Text

function url_GetDomain someURL
   -- url_Deconstruct wikiURL, someProtocol, wikiDomain, urlPath, shortName, fileExtension, uName, pWord
   set the itemdelimiter to slash
   get item 3 of someURL
   
   # Might be no slash and ?
   set the itemdelimiter to "?"
   put item 1 of it into urlDomain
   
   return urlDomain
end url_GetDomain

function rect_SimpleSubtract someRect, sNum
   add sNum to item 1 of someRect
   add sNum to item 2 of someRect
   subtract sNum from item 3 of someRect
   subtract sNum from item 4 of someRect
   --
   return someRect
end rect_SimpleSubtract

function scale_Height originalRect, newW
   rect_ExtractDimensions originalRect, originalW , originalH
   put newW / originalW into sFactor
   put originalH * sFactor into newH
   return newH
end scale_Height

command rect_ExtractDimensions someRect, @someW, @someH, pScale
   if pScale is not a number then put 1 into pScale
   --
   put pScale * (item 3 of someRect - item 1 of someRect) into someW
   put pScale * (item 4 of someRect - item 2 of someRect) into someH
end rect_ExtractDimensions
