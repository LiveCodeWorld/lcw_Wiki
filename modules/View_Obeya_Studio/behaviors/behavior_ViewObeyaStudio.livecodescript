script "behavior_ViewObeyaStudio"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_ViewObeyaStudio
type: behavior
version: 0.3

/*
*/

--> Variables
-
local LocalArray


--> Working on
-
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
         put pageJson_ConstructFile (wikiDomain, pageSlug) into jsonFile
         if there is a file jsonFile then
            put wikiPage_EditPage (pageSlug, wikiDomain) into pageArray
         else
            put wikiPage_CreatePage (pageSlug, wikiDomain) into pageArray
         end if
         set the ghost_PageArray of me to pageArray
         --
         -- _CheckPageArray pageArray, pageSlug, wikiDomain
   end switch
end _DisplayToolsPage

private command _CheckPageArray pageArray, pageSlug, wikiDomain
   put wikiServer_GuessLastSlug (urlPath) into lastPageSlug
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
      put wikiPage_CreatePage (pageSlug, wikiDomain) into pageArray
   end if
end _CheckPageArray


--> Props | Flag
-
getprop flag_Event [pageSlug]
   put wikijs_ConstructSelector(".header h1", pageSlug, "outerHTML") into sJavascript
   put _GetJavascriptResult (sJavascript) into sResult
   return sResult
end flag_Event

setprop flag_Handler flagHandler
   if flagHandler is "default" then put "flag_Event" into flagHandler
   --
   set the browser_AddJavascriptHandlers of me to flagHandler
   put wikijs_SetFlagHandler (flagHandler) into sJavascript
   set the browser_Javascript of me to sJavascript
   return sJavascript
end flag_Handler


--> Custom | Events
-
on flag_Event flagYaml
   -- called by wiki-client Livecode javascript
   split flagYaml using comma and ":"
   --
   set the clicked_FlagArray of me to flagYaml
   --
   put flagYaml ["target"] into wikiDomain
   put flagYaml ["href"] into urlPath
   put flagYaml ["pageTitle"] into pageTitle
   --
   if char 1 to 2 of urlPath = "//" then
      # Open nwiki in new tab
      display_Wiki wikiDomain, "New"
   else
      _DisplayToolsPage pageTitle, wikiDomain, urlPath
   end if
end flag_Event

on wikiClick_HamburgerMenu
   set the page_Title of me to "tools"
end wikiClick_HamburgerMenu

on toggle_Editable
   -- put "$('footer span.editEnable').click();" into sJavascript
   put wikijs_ToggleEdit() into sJavascript
   set the browser_Javascript of me to sJavascript
end toggle_Editable

setprop wikipedia_Page pageTitle
   put mediawiki_GetPageArrayFromSlug (pageTitle) into pageArray
   set the ghost_PageArray of me to pageArray
   return pageArray
end wikipedia_Page


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


--> Page | Model
-
setprop page_Title [domainAndPort] pTitle
   put fedwiki_ConstructSlug (pTitle) into pageSlug
   _DisplayPage pageSlug, domainAndPort
   return the result
end page_Title

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


--> Events
-
on resizeControl
   LayoutControl
end resizeControl

command LayoutControl pRect
   if pRect is empty then put the rect of this cd into pRect
   get the menubar of the defaultstack
   if it is not empty then
      put the menubar_View of me into mView
      if exists (mView) then
         -- put the height of mView into sHeight
         put 20 into sHeight
         -- subtract sHeight from item 2 of pRect
         add sHeight to item 2 of pRect
      end if
   end if
   set the rect of me to pRect
end LayoutControl


--> Working on
-
getprop browser_Snapshot
   -- export snapshot from _BrowserWidget() to somePNG as PNG -- bug: returns half the data
   put the object_Snapshot of _BrowserWidget() into somePNG
   return somePNG
end browser_Snapshot


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

function wikijs_GetLinupUrls
   put "var links = document.querySelectorAll('a.show-page-source');" into sJavascript
   put CR & "var hrefs = Array.from(links).map(function(link) {return link.getAttribute('href');});" after sJavascript
   put CR & "liveCode.javascript_Result(JSON.stringify(hrefs));" after sJavascript
   return sJavascript
end wikijs_GetLinupUrls


--> Lineup
-
getprop lineup_Titles
   return the page_Titles of me
end lineup_Titles

getprop lineup_Slugs
   return the page_Slugs of me
end lineup_Slugs

getprop lineup_Data
   put the browser_URL of me into browserURL
   --
   put _LineUpUrls (browserURL) into lineUpURLs
   repeat with indexNum = 1 to the number of lines of lineupUrls
      set the cursor to busy
      put line indexNum of lineupUrls into lineupUrl
      --
      put url lineupUrl into pageJson
      put json_ToArray (pageJson) into pageArray
      put pageArray into lineupData [indexNum]
   end repeat
   return lineupData
end lineup_Data

getprop lineup_Urls
   put the browser_URL of me into browserURL
   put _LineUpUrls (browserURL) into lineUpURLs
   return lineUpURLs
end lineup_Urls

private function _LineUpUrls browserURL
   put wikijs_GetLinupUrls() into sJavascript
   put _GetJavascriptResult (sJavascript) into lineupJson
   
   # Work out urls in Livecode (probably faster in js)
   set the itemdelimiter to slash
   put item 3 of browserURL into urlDomain
   --
   delete char 1 of lineupJson
   delete char -1 of lineupJson
   
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

getprop footer_WikiEditTag
   put "liveCode.javascript_Result(document.querySelector('footer span.editEnable').outerHTML);" into sJavascript
   put _GetJavascriptResult (sJavascript) into sResult
   return sResult
end footer_WikiEditTag

getprop wiki_EditMode
   return _IsTicked()
end wiki_EditMode

private function _IsTicked
   put the footer_WikiEditTag of me into htmlTag
   put (htmlTag contains "display: none") is false into isTicked
   return isTicked
end _IsTicked

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
setprop wiki_Scale sFactor
   put wikijs_ScaleViewport (sFactor) into sJavascript
   set the browser_Javascript of me to sJavascript
   return sJavascript
end wiki_Scale

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

getprop wiki_Domain
   put the browser_URL of me into someURL
   set the itemdelimiter to slash
   put item 3 of someURL into wikiDomain
   set the itemdelimiter to "."
   if item 1 of wikiDomain = "www" then delete item 1 of wikiDomain
   return wikiDomain
end wiki_Domain

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
setprop ghost_PageArray pageArray
   put json_FromArray (pageArray) into pageJSON
   set the browser_Javascript of me to _ConstructJavascript (pageJSON)
   return the result
end ghost_PageArray

setprop ghost_PageJson pageJSON
   set the browser_Javascript of me to _ConstructJavascript (pageJSON)
   return the result
end ghost_PageJson


--> Page
-
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

setprop page_Slug [domainAndPort] pageSlug
   _DisplayPage pageSlug, domainAndPort
   return the result
end page_Slug

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

getprop browser_URL
   put the url of me into someURL
   return someURL
end browser_URL

setprop browser_URL someURL
   put the previous_Url of me into previousURL
   set the url of me to someURL
   set the previous_Url of me to someURL
   return previousURL
end browser_URL

getprop browser_HtmlText
   put the htmltext of me into someHTML
   return someHTML
end browser_HtmlText

setprop browser_HtmlText someHTML
   set the htmltext of me to someHTML
   return the long id of me
end browser_HtmlText


--> Objects
-
getprop view_Object
   return the long id of me
end view_Object

getprop browser_View
   return the long id of me
end browser_View

private function _BrowserWidget
   return the long id of me
end _BrowserWidget


--> Private
-
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
   -- was "pageJson_ConstructFile"
   put wiki_GetFolder (wikiDomain) into wikiDomainFolder
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

private command _DisplayPage pageSlug, pDomainAndPort
   if pDomainAndPort is empty then
      put wiki_InternalLinkJavascript (pageSlug) into sJavascript
   else
      put wiki_RemoteLinkJavascript (pageSlug, pDomainAndPort) into sJavascript
   end if
   set the browser_Javascript of me to sJavascript
   put the result into doResult
   return doResult
end _DisplayPage

private function _ConstructJavascript pageJSON
   if pageJSON is empty then
      put pageArray_Construct ("Test Ghost Page", "Helo world!") into pageArray
      put json_FromArray (pageArray) into pageJSON
   end if
   --
   put merge ("wiki.showResult(wiki.newPage([[pageJSON]]))") into sJavascript
   return sJavascript
end _ConstructJavascript
