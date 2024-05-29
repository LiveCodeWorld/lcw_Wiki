script "behavior_ViewWikiBrowser"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_ViewWikiBrowser
type: behavior
version: 0.3

/*
This view is for a single wiki-browser view
*/


--> Variables
-
local LocalArray


--> Working on
-
setprop ghost_PageArray pageArray
   put json_FromArray (pageArray) into pageJSON
   put textEncode (pageJSON, "UTF-8") into pageJSON
   -- put _JsonFromArray (pageArray) into pageJSON
   --
   if pageJSON is empty then
      put "Error decoding array." into someMarkdown
      put pageArray_Construct ("Error", someMarkdown, "markdown") into pageArray
      put json_FromArray (pageArray) into pageJSON
   end if
   
   put _ConstructJavascript (pageJSON) into sJavascript
   set the browser_Javascript of me to sJavascript
   return the result
end ghost_PageArray

function json_FromArray pArray, pForceRootType, pPretty
   repeat for each key tKey in pArray
      if pArray[tKey] is an array then
         put "}"&json_FromArray(pArray[tKey]) into pArray[tKey]
      end if
   end repeat
   
   try
      -- put ArrayToJSON (pArray) into sJSON -- does not work reliably
      put mergJSONEncode("pArray",pForceRootType,pPretty) into sJSON
      return sJSON
   catch e
      -- lcw_Notify "Error encoding array"
      put ArrayToJSON (pArray) into sJSON
      return sJSON
      
      put pArray ["text"] into itemText
      -- breakpoint
      return empty
   end try
end json_FromArray

function json_ToArray pJSON
   local tArray,tKeys
   if pJSON is empty then return false
   -- put jsonImport (pJSON) into tArray -- not the same
   
   try -- as otherwise an error with non-json causes script to exit
      if pJSON is empty then return empty
      repeat for each line tKey in mergJSONDecode(pJSON,"tArray")
         put json_ToArray(tArray[tKey]) into tArray[tKey]
      end repeat
      return tArray
   catch e
      return empty
   end try
end json_ToArray


--> Props
-
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

private function _WikiDomain
   set the itemdelimiter to slash
   --
   put the browser_URL of me into someURL
   put item 3 of someURL into wikiDomain
   --
   set the itemdelimiter to "."
   if item 1 of wikiDomain = "www" then delete item 1 of wikiDomain
   return wikiDomain
end _WikiDomain

getprop page_Text [titleOrNum]
   put the page_Array [titleOrNum] of me into pageArray
   put pageArray_Text (pageArray) into pageText
   return pageText
end page_Text

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


--> Props
-
getprop last_PageSlug
   put the browser_URL of me into browserURL
   get _LineUpInfo (browserURL)
   return item -1 of line -1 of it
end last_PageSlug

getprop last_PageInfo
   put the browser_URL of me into browserURL
   get _LineUpInfo (browserURL)
   return line -1 of it
end last_PageInfo

setprop page_Slug [domainAndPort] pageSlug
   put fedwiki_ConstructTitle (pageSlug) into pageTitle
   _DisplayPage pageTitle, domainAndPort
   return the result
end page_Slug

setprop page_Title [domainAndPort] pTitle
   _DisplayPage pTitle, domainAndPort
   return the result
end page_Title

private command _DisplayPage pTitle, pDomainAndPort
   -- put fedwiki_ConstructSlug (pTitle) into pageSlug
   --
   if pDomainAndPort is empty then
      put wiki_InternalLinkJavascript (pTitle) into sJavascript
   else
      put wiki_RemoteLinkJavascript (pTitle, pDomainAndPort) into sJavascript
   end if
   set the browser_Javascript of me to sJavascript
   put the result into doResult
   return doResult
end _DisplayPage


--> Wiki | Scale
-
setprop wiki_Scale sFactor
   put wikijs_ScaleViewport (sFactor) into sJavascript
   set the browser_Javascript of me to sJavascript
   return sJavascript
end wiki_Scale

setprop page_Scale [pageSlug] scaleItems
   if scaleItems is empty then
      put wikijs_ResetPageTransform (pageSlug) into sJavascript
   else
      put item 1 of scaleItems into sSale
      put item 2 of scaleItems into sX
      put item 3 of scaleItems into sY
      put item 4 of scaleItems into sTime
      --
      -- put wikijs_SetPageScale (sSale, pageSlug) into sJavascript
      put wikijs_TransformPage (pageSlug, sSale, sX, sY, sTime) into sJavascript
   end if
   --
   set the browser_Javascript of me to sJavascript
   return sJavascript
end page_Scale


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

on flag_Event flagYaml
   -- called by wiki-client Livecode javascript
   split flagYaml using comma and ":"
   --
   put flagYaml ["target"] into wikiDomain
   put flagYaml ["href"] into urlPath
   put flagYaml ["pageTitle"] into pageTitle
   
   # Store Yaml
   set the clicked_FlagArray of me to flagYaml
   
   if char 1 to 2 of urlPath = "//" then
      # Open nwiki in new tab
      display_Wiki wikiDomain, "New"
      put the result into wikiView
   else
      _DisplayToolsPage pageTitle, wikiDomain, urlPath
   end if
end flag_Event


--> Custom | Events | Flag
-
on wikiBrowser_Init
   set the flag_Handler of me to "default"
   set the wiki_EditMode of me to true
   --
   -- set the show_Menu of _MenubarView() to true
end wikiBrowser_Init

getprop flag_Event [pageSlug]
   put wikijs_ConstructSelector(".header h1", pageSlug, "outerHTML") into sJavascript
   put _GetJavascriptResult (sJavascript) into sResult
   return sResult
end flag_Event

setprop flag_Handler flagHandler
   if flagHandler is "default" then put "flag_Event" into flagHandler
   set the browser_AddJavascriptHandlers of me to flagHandler
   
   # Set javascript
   put wikijs_SetFlagHandler (flagHandler) into sJavascript
   set the browser_Javascript of me to sJavascript -- causes error
   return sJavascript
end flag_Handler


--> Events
-
on preOpenControl
   -- LayoutCard
   
   send "wikiBrowser_Init" to me in 30 ticks
   pass preOpenControl
end preOpenControl

on resizeControl
   put the rect of me into viewRect
   LayoutControl viewRect
end resizeControl

command LayoutControl pRect
   if pRect is empty then put the rect of this cd into pRect
   get the menubar of the defaultstack
   if it is not empty then
      put the menubar_View of me into mView
      if exists (mView) then
         put 20 into sHeight
         -- subtract sHeight from item 2 of pRect
         add sHeight to item 2 of pRect
      end if
   end if
   set the rect of me to pRect
end LayoutControl


--> Custom | Events
-
on wikiClick_HamburgerMenu
   set the page_Title of me to "tools"
end wikiClick_HamburgerMenu

on toggle_Editable
   -- put "$('footer span.editEnable').click();" into sJavascript
   put wikijs_ToggleEdit() into sJavascript
   set the browser_Javascript of me to sJavascript
end toggle_Editable


--> Javascript | Events
-
on javascript_Result sResult
   -- Generic handler to return result to "getprop"
   -- Not called when js fails to return text
   put sResult into LocalArray ["sResult"]
   return sResult
end javascript_Result

on bevent_ExternalLink externalURL
   platform_DeconstructURL externalURL, toolItems, urlExt, hName
   switch
      case toolItems is empty
         display_WikiBrowser externalURL
         break
      default
         --
         put the long id of me into browserView
         put item 2 to -1 of toolItems into otherItems
         dispatch hName with browserView,otherItems
         switch it
            case "unhandled"
               put hName
               break
            default
               
         end switch
   end switch
end bevent_ExternalLink


--> Override
-
getprop wiki_Override
   get the browser_JavascriptHandlers of me
   switch it
      case "bevent_ExternalLink"
         return "external"
      default
         return empty
   end switch 
end wiki_Override

setprop wiki_Override sWay
   switch sWay
      case "flag"
         set the flag_Handler of me to "default"
         break
      case "Hamburger"
         break
      case "external"
         break
      default
         set the browser_AddJavascriptHandlers of me to "wikiClick_HamburgerMenu,bevent_ExternalLink,flag_Event"
         --
         put wikijs_Override() into overrideJS
         set the browser_Javascript of me to overrideJS
         --
         set the wiki_EditMode of me to true
         set the flag_Handler of me to "default"
   end switch
end wiki_Override


--> LineUp
-
getprop lineUp_PageArray [slugOrNum]
   put the lineUp_URL [slugOrNum] of me into lineupUrl
   put _PageArray (lineupUrl) into pageArray
   return pageArray
end lineUp_PageArray

getprop lineUp_Domain [slugOrNum]
   put the lineUp_URL [slugOrNum] of me into lineupURL
   --
   put url_GetDomain (lineupURL) into lineUpDomain
   return lineUpDomain
end lineUp_Domain

getprop lineUp_Info
   put the browser_URL of me into browserURL
   return _LineUpInfo (browserURL)
end lineUp_Info

getprop lineUp_URL [slugOrNum]
   put the browser_URL of me into browserURL
   put _LineUpUrls (browserURL) into lineUpURLs
   
   switch
      case slugOrNum is empty
         put the wiki_Domain of me into wikiDomain
         
         set the itemdelimiter to slash
         replace ".json" with empty in lineUpURLs
         put line 1 of lineUpURLs & slash into lineUpURL
         put "view/" before item 4 of lineUpURL
         
         replace (slash & wikiDomain & slash) with (slash & "view" & slash)  in lineUpURLs
         --
         delete line 1 of lineUpURLs
         replace "http://" with empty in lineUpURLs
         repeat for each line newBit in lineupUrls 
            put newBit & slash after lineUpURL
         end repeat
         return lineUpURL
      case slugOrNum is a number
         put line slugOrNum of lineUpURLs into lineUpURL
         return lineUpURL
      default
         # Find Slug
         repeat for each line lineUpURL in lineupUrls      
            # Extract Test Slug
            set the itemdelimiter to slash
            get item -1 of lineupUrl
            set the itemdelimiter to "."
            put item 1 of it into testSlug
            
            if testSlug = slugOrNum then
               return lineupUrl
            end if
         end repeat
         return empty
   end switch
end lineUp_URL

getprop lineup_Data
   put the browser_URL of me into browserURL
   --
   put _LineUpUrls (browserURL) into lineUpURLs
   repeat with indexNum = 1 to the number of lines of lineupUrls
      set the cursor to busy
      put line indexNum of lineupUrls into lineupUrl
      --
      put _PageArray (lineupUrl) into pageArray
      put pageArray into lineupData [indexNum]
   end repeat
   return lineupData
end lineup_Data


--> Props
-
setprop wikipedia_Page pageTitle
   put mediawiki_GetPageArrayFromSlug (pageTitle) into pageArray
   set the ghost_PageArray of me to pageArray
   return pageArray
end wikipedia_Page

getprop page_Html [pSlug]
   put merge ("liveCode.javascript_Result(document.querySelector('#[[pSlug]]').outerHTML);") into sJavascript
   put _GetJavascriptResult (sJavascript) into sResult
   return sResult
end page_Html

getprop json_Html [qAndSlug]
   put item 1 of qAndSlug into pageSlug
   put item 2 of qAndSlug into pJsFunction
   --
   -- put wiki_PageJsonJavascript (pageSlug, pJsFunction) into sJavascript
   put wikijs_ConstructSelector(".footer a.show-page-source", pageSlug, pJsFunction) into sJavascript
   put _GetJavascriptResult (sJavascript) into sResult
   return sResult
end json_Html

getprop outer_Html [qAndSlug]
   put item 1 of qAndSlug into qSelector
   if qSelector is empty then put ".header h1" into qSelector
   put item 2 of qAndSlug into pageSlug
   --
   put wikijs_ConstructSelector (qSelector, pageSlug, "outerHTML") into sJavascript
   put _GetJavascriptResult (sJavascript) into sResult
   return sResult
end outer_Html

setprop page_Width [pSlug] sWidth
   if pSlug is empty then
      -- put merge ("var elements = document.querySelectorAll('.page'); elements.forEach(function(el) {el.style.sWidth = '[[sWidth]]';});") into sJavascript
      put merge ("var element = document.getElementById('[[pSlug]]');element.style.width = '[[sWidth]]';") into sJavascript
   else
      put merge ("var element = document.getElementById('[[pSlug]]');element.style.width = '[[sWidth]]';") into sJavascript
   end if
   --
   put sJavascript
   set the browser_Javascript of me to sJavascript
   --
   return sJavascript
end page_Width

getprop page_Class [pageSlug]
   put wikijs_GetPageClass (pageSlug) into sJavascript
   put _GetJavascriptResult (sJavascript) into sResult
   return sResult
end page_Class


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


--> Working on
-
getprop browser_Snapshot
   -- export snapshot from _BrowserWidget() to somePNG as PNG -- bug: returns half the data
   put the object_Snapshot of _BrowserWidget() into somePNG
   return somePNG
end browser_Snapshot


--> Lineup
-
getprop lineup_Titles
   return the page_Titles of me
end lineup_Titles

getprop lineup_Slugs
   return the page_Slugs of me
end lineup_Slugs

getprop lineup_Urls
   put the browser_URL of me into browserURL
   put _LineUpUrls (browserURL) into lineUpURLs
   return lineUpURLs
end lineup_Urls

getprop footer_WikiEditTag
   put "liveCode.javascript_Result(document.querySelector('footer span.editEnable').outerHTML);" into sJavascript
   put _GetJavascriptResult (sJavascript) into sResult
   return sResult
end footer_WikiEditTag

getprop wiki_EditMode
   return _IsTicked()
end wiki_EditMode

setprop wiki_EditMode sBoolean
   put _IsTicked() into isTicked
   if isTicked is not sBoolean then
      toggle_Editable
   end if
end wiki_EditMode


--> Props
-
getprop license_Handler [slugAndFunc]
   put item 1 of slugAndFunc into pageSlug
   put item 2 of slugAndFunc into pJsFunction
   --
   put wikijs_ConstructSelector(".footer a.show-page-license", pageSlug, pJsFunction) into sJavascript
   put _GetJavascriptResult (sJavascript) into sResult
   return sResult
end license_Handler

getprop search_Html [slugAndFunc]
   put item 1 of slugAndFunc into pageSlug
   put item 2 of slugAndFunc into pJsFunction
   --
   put wikijs_ConstructSelector(".footer a.search", pageSlug, pJsFunction) into sJavascript
   put _GetJavascriptResult (sJavascript) into sResult
   return sResult
end search_Html

getprop flag_Html [pageSlug]
   if pageSlug is empty then put "welcome-visitors" into pageSlug
   --
   put wiki_PageFlagJavascript (pageSlug) into sJavascript
   put _GetJavascriptResult (sJavascript) into sResult
   return sResult
end flag_Html


--> Javascript | Handlers
-
setprop license_Handler hName
   put wiki_LiveJavascript (hName) into jsFunction
   put wiki_LicenseHtmlJavascript (jsFunction) into sJavascript
   set the browser_Javascript of me to sJavascript
   put the result into doResult
   return doResult
end license_Handler

setprop json_Handler hName
   put wiki_LiveJavascript (hName) into jsFunction
   put wiki_JsonLinkJavascript (jsFunction) into sJavascript
   set the browser_Javascript of me to sJavascript
   put the result into doResult
   return doResult
end json_Handler

setprop search_Handler hName
   put wiki_LiveJavascript (hName) into jsFunction
   put wiki_SearchLinkJavascript (jsFunction) into sJavascript
   set the browser_Javascript of me to sJavascript
   put the result into doResult
   return doResult
end search_Handler

getprop element_IsTransparent [domElement]
   if domElement is empty then put "document.body" into domElement
   
   put js_ElementIsTranparent (domElement) into sJavascript
   put _GetJavascriptResult (sJavascript) into sResult
   return sResult
end element_IsTransparent


--> Wiki
-
getprop wiki_IsTransparent
   put the element_IsTransparent ["document.body"] of me into sBoolean
   return sBoolean
end wiki_IsTransparent

setprop wiki_IsTransparent sBoolean
   if sBoolean is true then
      put "document.body.style.background = 'transparent';" into sJavascript
   else
      put "document.body.style.background = '#eeeeee url("  into sJavascript
      put kwote ("/images/crosses.png") & ")';" after sJavascript
   end if
   set the browser_Javascript of me to sJavascript
   return sJavascript
end wiki_IsTransparent

getprop wiki_Garden
   put _WikiDomain() into wikiDomain
   put wikiGarden_Name (wikiDomain) into gardenName
   return gardenName
end wiki_Garden

setprop wiki_Domain domainOrURL
   put _BrowserWidget() into browserWidget
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
   set the browser_URL of browserWidget to someURL
   set the stack_Label of me to wikiDomain
end wiki_Domain


--> Ghost
-
setprop ghost_JSON pageJSON
   put _ConstructJavascript (pageJSON) into sJavascript
   set the browser_Javascript of me to sJavascript
   return the result
end ghost_JSON

setprop ghost_PageJson pageJSON
   set the browser_Javascript of me to _ConstructJavascript (pageJSON)
   return the result
end ghost_PageJson


--> Page
-
getprop page_Rect [pageSlug]
   if pageSlug is empty then put "welcome-visitors" into pageSlug
   get scaffold_Get ("page_Rect.js")
   put merge (it) into sJavascript
   put _GetJavascriptResult (sJavascript) into pageRect
   rect_Normalise pageRect
   return pageRect
end page_Rect

setprop page_Rect [pageSlug] sRect
   put _SetPageRectJavascript (sRect, pageSlug) into sJavascript
   put _GetJavascriptResult (sJavascript) into sResult
   return sResult
end page_Rect

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


--> Pretty
-
setprop pretty_Journal sBoolean
   if sBoolean is true then
      put wikijs_SetJournalCss ("none") into sJavascript
   else
      put wikijs_SetJournalCss ("block") into sJavascript
   end if
   set the browser_Javascript of me to sJavascript
   return sJavascript
end pretty_Journal

setprop page_Colour [pSlug] sColour
   if pSlug is empty then
      put merge ("var elements = document.querySelectorAll('.page'); elements.forEach(function(el) {el.style.backgroundColor = '[[sColour]]';});") into sJavascript
   else
      put merge ("var element = document.getElementById('[[pSlug]]');element.style.backgroundColor = '[[sColour]]';") into sJavascript
   end if
   set the browser_Javascript of me to sJavascript
   return sJavascript
end page_Colour

getprop footer_IsVisible
   put _BrowserWidget() into browserWidget
   set the browser_AddJavascriptHandlers of browserWidget to "javascript_Result"
   --
   -- put js_VisibilityScript (footer) into sJavascript
   put js_ElementIsVisible ("footer") into sJavascript
   do sJavascript in browserWidget
   put LocalArray ["sResult"] into sResult
   --
   put sResult = "visible" into isVisible
   return isVisible
end footer_IsVisible

setprop footer_IsVisible showMe
   put _BrowserWidget() into browserWidget
   put showMe is false into hideMe
   -- lock screen
   put wikijs_HideFooter (hideMe) into sJavascript
   do sJavascript in browserWidget
   -- unlock screen
end footer_IsVisible


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


--> Browser | javascript
-
setprop browser_Javascript sJavascript
   _SetJavascriptResult sJavascript
   return the result -- usually not intereting
end browser_Javascript

setprop browser_AddJavascriptHandlers newHandlers
   replace comma with CR in newHandlers
   put _BrowserWidget() into browserWidget
   --
   put the javascriptHandlers of browserWidget into handlerIndex
   line_Add newHandlers, handlerIndex
   set the javascriptHandlers of browserWidget to handlerIndex
   return handlerIndex
end browser_AddJavascriptHandlers

getprop browser_JavascriptHandlers
   put the javascriptHandlers of _BrowserWidget() into handlerList
   return handlerList
end browser_JavascriptHandlers

setprop browser_JavascriptHandlers handlerList
   put _BrowserWidget() into browserWidget
   set the javascriptHandlers of browserWidget to handlerList
   return the result
end browser_JavascriptHandlers


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

private function _BrowserWidget
   return the long id of me
end _BrowserWidget


--> Private
-
private function _LineUpInfo browserURL
   put _LineUpJson() into lineupJson
   
   set the itemdelimiter to slash
   put item 3 of browserURL into ownerDomain
   
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
      put sDomain,pageSlug & CR after lineUpInfo
   end repeat
   delete char -1 of lineUpInfo
   return lineUpInfo
end _LineUpInfo

private function _LineUpUrls browserURL
   put _LineUpJson() into lineupJson
   
   set the itemdelimiter to slash
   put item 3 of browserURL into urlDomain
   
   set the itemdelimiter to comma
   repeat for each item sLink in lineupJson
      replace quote with empty in sLink
      if char 1 to 2 of sLink = "//" then
         put "http:" & sLink into someURL
      else
         put "http://" & urlDomain & sLink into someURL
      end if
      put someURL & CR after lineUpURLs
   end repeat
   delete char -1 of lineUpURLs
   return lineUpURLs
end _LineUpUrls

private function _LineUpJson
   put wikijs_GetLinupUrls() into sJavascript
   put _GetJavascriptResult (sJavascript) into lineupJson
   
   # Work out urls in Livecode (probably faster in js)
   --
   delete char 1 of lineupJson
   delete char -1 of lineupJson
   
   return lineupJson
end _LineUpJson

private function _IsTicked
   put the footer_WikiEditTag of me into htmlTag
   put (htmlTag contains "display: none") is false into isTicked
   return isTicked
end _IsTicked

private function _SetPageRectJavascript sRect, pageSlug
   if pageSlug is empty then put "welcome-visitors" into pageSlug
   --
   put item 1 of sRect into sLeft
   put item 2 of sRect into sTop
   put item 3 of sRect into sRight
   put item 4 of sRect into sBottom
   --
   put 8 into sMargin
   subtract sMargin from sLeft
   subtract sMargin from sRight
   subtract sMargin from sTop
   subtract sMargin from sBottom
   --
   put sRight - sLeft into sWidth
   put sBottom - sTop into sHeight
   --
   get scaffold_Get ("page_SetRect.js")
   put merge (it) into sJavascript
   --
   return sJavascript
end _SetPageRectJavascript

private function _GetJavascriptResult sJavascript
   put the browser_View of the target into browserWidget
   set the browser_AddJavascriptHandlers of browserWidget to "javascript_Result"
   --
   do sJavascript in browserWidget
   get the result
   put LocalArray ["sResult"] into sResult
   put empty into LocalArray ["sResult"] -- otherwise we can get last result returned when js fails
   return sResult
end _GetJavascriptResult

function _PageJsonConstructFile wikiDomain, pSlug
   -- was "wikiFile_Construct"
   put wikiFolder_FromRouter (wikiDomain) into wikiDomainFolder
   put wikiDomainFolder & pSlug into pageJsonFile
   return pageJsonFile
end _PageJsonConstructFile

private function _GetJavascriptResult sJavascript
   put _BrowserWidget() into browserWidget
   set the browser_AddJavascriptHandlers of browserWidget to "javascript_Result"
   --
   do sJavascript in browserWidget
   --
   put LocalArray ["sResult"] into sResult
   return sResult
end _GetJavascriptResult

private command _SetJavascriptResult sJavascript
   -- put "wiki.doInternalLink('Federateed Wiki')" into sJavascript
   -- replace CR with empty in sJavascript
   --
   put _BrowserWidget() into browserWidget
   do sJavascript in browserWidget
   put the result into doResult -- usually not intereting
   return doResult
end _SetJavascriptResult

private function _ConstructJavascript pageJSON
   if pageJSON is empty then
      put pageArray_Construct ("Test Ghost Page", "Helo world!") into pageArray
      put json_FromArray (pageArray) into pageJSON
   end if
   --
   put merge ("wiki.showResult(wiki.newPage([[pageJSON]]))") into sJavascript
   return sJavascript
end _ConstructJavascript

private function _PageArray lineupUrl
   -- should I use binary and textEncode
   put url lineupUrl into pageJson
   put json_ToArray (pageJson) into pageArray
   return pageArray
end _PageArray

command _DisplayToolsPage pageTitle, wikiDomain, urlPath
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


--> Deps
-
function wikijs_GetLinupUrls
   put "var links = document.querySelectorAll('a.show-page-source');" into sJavascript
   put CR & "var hrefs = Array.from(links).map(function(link) {return link.getAttribute('href');});" after sJavascript
   put CR & "liveCode.javascript_Result(JSON.stringify(hrefs));" after sJavascript
   return sJavascript
end wikijs_GetLinupUrls

function url_GetDomain someURL
   -- url_Deconstruct wikiURL, someProtocol, wikiDomain, urlPath, shortName, fileExtension, uName, pWord
   set the itemdelimiter to slash
   get item 3 of someURL
   
   # Might be no slash and ?
   set the itemdelimiter to "?"
   put item 1 of it into urlDomain
   
   return urlDomain
end url_GetDomain
