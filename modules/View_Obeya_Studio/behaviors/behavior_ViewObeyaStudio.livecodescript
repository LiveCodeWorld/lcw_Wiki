script "behavior_ViewObeyaStudio"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_ViewObeyaStudio
type: behavior
version: 0.1

/*
on getFooterVisibility
   put "function checkVisibility() {
   let footerVisibility = window.getComputedStyle(document.querySelector('footer')).visibility;
   return footerVisibility;}
   checkVisibility();" into tScript
   
   put _BrowserWidget() into browserWidget
   put browserExecuteScript (browserWidget, tScript) into tCallbackID
end getFooterVisibility

on browserCallback pCallbackID, pResult
   if pCallbackID is tCallbackID then
      answer "The footer visibility is:" && pResult
   end if
end browserCallback
*/

local LocalArray

--> Working on
-
getprop footer_IsVisible
   -- get "liveCode.myJSHandler(document.title);"
   put _BrowserWidget() into browserWidget
   set the javascriptHandlers of browserWidget to "footerVisibleHandler"
   --
   -- put scaffold_Get ("footer_visible.js") into jsScript
   put "liveCode.footerVisibleHandler(window.getComputedStyle(document.querySelector('footer')).visibility);" into jsScript
   do jsScript in browserWidget
   put the result into sResult -- sometimes does not work
   put LocalArray ["sResult"] into sResult
   --
   put sResult = "visible" into isVisible
   return isVisible
end footer_IsVisible

on footerVisibleHandler sResult
   put sResult into LocalArray ["sResult"]
   return sResult
end footerVisibleHandler

setprop footer_IsVisible showMe
   put _BrowserWidget() into browserWidget
   put showMe is false into hideMe
   lock screen
   put wiki_FooterVisibleJavascript (hideMe) into someJavascript
   put ";" after someJavascript
   if showMe is false then
      put wiki_FooterHeightJavascript (18) after someJavascript
   else
      put wiki_FooterHeightJavascript (60) after someJavascript
   end if
   do someJavascript in browserWidget
   unlock screen
end footer_IsVisible

getprop browser_Element
   return LocalArray ["elementHtml"]
end browser_Element

setprop browser_Element elementID
   browser_InitResult "svg"
   return the result
end browser_Element

on browser_InitResult elementHtml
   -- put "svg" into elementHtml
   --
   delete variable LocalArray ["elementHtml"]
   put _BrowserWidget() into browserWidget
   set the javascriptHandlers of browserWidget to "browser_JavascriptResult"
   --
   put merge ("var r=document.getElementById('[[elementHtml]]').outerHTML;liveCode.browser_JavascriptResult(r)") into sJavascript
   replace "'" with quote in sJavascript
   do sJavascript in browserWidget
end browser_InitResult

on browser_JavascriptResult elementHtml
   put elementHtml into LocalArray ["elementHtml"]
end browser_JavascriptResult


--> Props
-
setprop display_Page [remoteDomain] pageSlug
   if remoteDomain is empty then
      put wiki_InternalLinkJavascript (pageSlug) into someJavascript
   else
      put wiki_RemoteLinkJavascript (pageSlug, remoteDomain) into someJavascript
   end if
   set the browser_Javascript of me to someJavascript
   put the result into doResult
   return doResult
end display_Page

setprop ghost_PageArray pageArray
   put json_FromArray (pageArray) into pageJSON
   set the browser_Javascript of me to _ConstructJavascript (pageJSON)
   return the result
end ghost_PageArray

setprop ghost_Page pageJSON
   set the browser_Javascript of me to _ConstructJavascript (pageJSON)
   return the result
end ghost_Page

getprop wiki_Domain
   put the browser_URL of me into someURL
   set the itemdelimiter to slash
   put item 3 of someURL into wikiDomain
   set the itemdelimiter to "."
   if item 1 of wikiDomain = "www" then delete item 1 of wikiDomain
   return wikiDomain
end wiki_Domain

setprop displayed_Domain domainOrURL
   put _BrowserWidget() into browserWidget
   set the itemdelimiter to slash
   switch
      case item 1 of domainOrURL = "https:"
      case item 1 of domainOrURL = "http:"
         -- http://arodic.github.io/p/jellyfish/
         put domainOrURL into someURL
         break
      default
         put "http://" & domainOrURL into someURL
   end switch
   set the browser_URL of browserWidget to someURL
end displayed_Domain

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


--> Events
-
on resizeControl
   LayoutControl
end resizeControl

command LayoutControl pRect
   if pRect is empty then put the rect of me into pRect
   get the menubar of the defaultstack
   if it is not empty then
      put the menu_Group of me into mGroup
      if exists(mGroup) then
         put the height of mGroup into sHeight
         subtract sHeight from item 2 of pRect
      end if
   end if
   set the rect of me to pRect
end LayoutControl


--> Browser | Props
-
setprop browser_Javascript someJavascript
   -- put "wiki.doInternalLink('Federateed Wiki')" into someJavascript
   put _BrowserWidget() into browserWidget
   do someJavascript in browserWidget
   put the result into doResult
   return doResult
end browser_Javascript

getprop browser_Snapshot
   export snapshot from _BrowserWidget() to pictVariable as PNG
   return pictVariable
end browser_Snapshot

getprop browser_JavascriptHandlers
   put the javascriptHandlers of _BrowserWidget() into handlerList
   return handlerList
end browser_JavascriptHandlers

setprop browser_JavascriptHandlers handlerList
   put _BrowserWidget() into browserWidget
   set the javascriptHandlers of browserWidget to handlerList
   return the result
end browser_JavascriptHandlers

getprop browser_URL
   put the url of me into someURL
   return someURL
end browser_URL

setprop browser_URL someURL
   set the url of me to someURL
   return the long id of me
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
private function _BrowserWidget
   return the long id of me
end _BrowserWidget

getprop view_Object
   return the long id of me
end view_Object

getprop browser_View
   return the long id of me
end browser_View
