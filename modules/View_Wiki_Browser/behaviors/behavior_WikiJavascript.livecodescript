script "behavior_WikiJavascript"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_WikiJavascript
type: behavior
version: 0.2

/*Here you make make notes as a basic form of help for this view.
Full help text can be found on the linked wiki for the view.*/

--> Variables
-
local LocalArray


--> Working on
-
function pageArray_FromJson pageJSON
   put json_ToArray (pageJSON) into pageArray
   return pageArray
end pageArray_FromJson

function pageArray_ToJson pageArray
   put pageArray ["title"] into pageTitle
   --
   put pageArray ["story"] into storyArray
   put pageArray ["journal"] into journalArray
   --
   put indexArray_ToJson (storyArray) into storyJSON
   put indexArray_ToJson (journalArray) into journalJSON
   
   # Start JSON
   put "{" into pageJSON
   
   # Title
   put kwote ("title") & ":" && kwote (pageTitle) & comma after pageJSON
   
   # Story
   put kwote ("story") & ":" && "[" & storyJSON & "]" & comma after pageJSON
   
   # Journal 
   put kwote ("journal") & ":" && "[" & journalJSON & "]" after pageJSON
   
   # End JSON
   put "}" after pageJSON
   --
   return pageJSON
end pageArray_ToJson

getprop footer_IsVisible
set the javascript_AddHandlers of me to "javascript_Result"
--
put js_ElementIsVisible ("footer") into sJavascript
do sJavascript in me
put LocalArray ["sResult"] into sResult
--
put sResult = "visible" into isVisible
return isVisible
end footer_IsVisible

setprop footer_IsVisible showMe
   put showMe is false into hideMe
   put wikijs_HideFooter (hideMe) into sJavascript
   do sJavascript in me
end footer_IsVisible


--> Props | PageArray
-
setprop ghost_PageArray pageArray
   -- put json_FromArray (pageArray) into pageJSON
   -- put textEncode (pageJSON, "UTF-8") into pageJSON
   
   put pageArray_ToJson (pageArray) into pageJSON
   if pageJSON is empty then put _ErrorJson() into pageJSON
   
   put merge ("wiki.showResult(wiki.newPage([[pageJSON]]))") into sJavascript
   
   set the browser_Javascript of me to sJavascript
   return the result
end ghost_PageArray

function _ErrorJson
   -- simplify without dpes
   put "Error decoding array." into someMarkdown
   put pageArray_Construct ("Error", someMarkdown, "markdown") into pageArray
   put json_FromArray (pageArray) into pageJSON
   return pageJSON
end _ErrorJson


--> Props | Javascript
-
getprop external_Links
   get the javascriptHandlers of me
   return "bevent_ExternalLink" is among the lines of it
end external_Links

setprop external_Links sBoolean
   if sBoolean is true then
      put wikijs_Override() into overrideJS
      set the browser_Javascript of me to overrideJS
      set the javascript_AddHandlers of me to "bevent_ExternalLink"
   else
      set the javascript_RemoveHandlers of me to "bevent_ExternalLink"
   end if
end external_Links

getprop wiki_Override
   get the javascriptHandlers of me
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
         set the javascript_AddHandlers of me to "wikiClick_HamburgerMenu,bevent_ExternalLink,flag_Event"
         --
         set the wiki_EditMode of me to true
         set the flag_Handler of me to "default"
   end switch
end wiki_Override


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

on wikiClick_HamburgerMenu
   set the page_Title of me to "tools"
end wikiClick_HamburgerMenu

on toggle_Editable
   -- put "$('footer span.editEnable').click();" into sJavascript
   put wikijs_ToggleEdit() into sJavascript
   set the browser_Javascript of me to sJavascript
end toggle_Editable


--> Page
-
setprop page_Slug [domainAndPort] pageSlug
   put fedwiki_ConstructTitle (pageSlug) into pageTitle
   _DisplayPage pageTitle, domainAndPort
   return the result
end page_Slug

setprop page_Title [domainAndPort] pTitle
   _DisplayPage pTitle, domainAndPort
   return the result
end page_Title

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

setprop page_Colour [pSlug] sColour
   if pSlug is empty then
      put merge ("var elements = document.querySelectorAll('.page'); elements.forEach(function(el) {el.style.backgroundColor = '[[sColour]]';});") into sJavascript
   else
      put merge ("var element = document.getElementById('[[pSlug]]');element.style.backgroundColor = '[[sColour]]';") into sJavascript
   end if
   set the browser_Javascript of me to sJavascript
   return sJavascript
end page_Colour


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


--> LineUp
-
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

getprop lineUp_PageArray [slugOrNum]
   put the lineUp_URL [slugOrNum] of me into lineupUrl
   put url lineupUrl into pageJson
   put pageArray_FromJson (pageJson) into pageArray
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

getprop lineup_Data
   put the browser_URL of me into browserURL
   --
   put _LineUpUrls (browserURL) into lineUpURLs
   repeat with indexNum = 1 to the number of lines of lineupUrls
      set the cursor to busy
      put line indexNum of lineupUrls into jsonUrl
      --
      put url jsonUrl into pageJson
      put pageArray_FromJson (pageJson) into pageArray
      put pageArray into lineupData [indexNum]
   end repeat
   return lineupData
end lineup_Data


--> Browser | Javascript
-
setprop browser_Javascript sJavascript
   do sJavascript in me
   return the result -- usually not intereting
end browser_Javascript

setprop javascript_AddHandlers newHandlers
   replace comma with CR in newHandlers
   --
   put the javascriptHandlers of me into handlerIndex
   line_Add newHandlers, handlerIndex
   set the javascriptHandlers of me to handlerIndex
   return handlerIndex
end javascript_AddHandlers

setprop javascript_RemoveHandlers jsHandlers
   replace comma with CR in jHandlers
   --
   put the javascriptHandlers of me into handlerIndex
   line_Delete jsHandlers, handlerIndex
   set the javascriptHandlers of me to handlerIndex
   return handlerIndex
end javascript_RemoveHandlers

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


--> Wiki | Scale
-
setprop wiki_Scale sFactor
   put wikijs_ScaleViewport (sFactor) into sJavascript
   set the browser_Javascript of me to sJavascript
   return sJavascript
end wiki_Scale

getprop flag_Event [pageSlug]
   put wikijs_ConstructSelector(".header h1", pageSlug, "outerHTML") into sJavascript
   put _GetJavascriptResult (sJavascript) into sResult
   return sResult
end flag_Event

setprop flag_Handler flagHandler
   if flagHandler is "default" then put "flag_Event" into flagHandler
   set the javascript_AddHandlers of me to flagHandler
   
   # Set javascript
   put wikijs_SetFlagHandler (flagHandler) into sJavascript
   set the browser_Javascript of me to sJavascript -- causes error
   return sJavascript
end flag_Handler

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


--> Private
-
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
   set the javascript_AddHandlers of me to "javascript_Result"
   --
   do sJavascript in me
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
   set the javascript_AddHandlers of me to "javascript_Result"
   --
   do sJavascript in me
   --
   put LocalArray ["sResult"] into sResult
   return sResult
end _GetJavascriptResult

function wikijs_GetLinupUrls
   put "var links = document.querySelectorAll('a.show-page-source');" into sJavascript
   put CR & "var hrefs = Array.from(links).map(function(link) {return link.getAttribute('href');});" after sJavascript
   put CR & "liveCode.javascript_Result(JSON.stringify(hrefs));" after sJavascript
   return sJavascript
end wikijs_GetLinupUrls

