script "behavior_ViewBrowser"
--> MetaData
-
license: GPLv3
name: behavior_ViewBrowser
type: behavior
version: 0.1

local LocalArray

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

getprop footer_Visible
   put _FooterGroup() into footerGroup
   put the visible of footerGroup into someBoolean
   return someBoolean
end footer_Visible

setprop footer_Visible someBoolean
   put _FooterGroup() into footerGroup
   put the rect of me into oRect
   --
   lock screen
   set the browser_WikiFooterVisible of me to (not someBoolean)
   set the visible of footerGroup to someBoolean
   LayoutControl oRect
   unlock screen
end footer_Visible

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


--> Events
-
on mouseUp
   local tActionName
   put the mouseAction of me into tActionName
   switch tActionName
      case "back"
         go back
         break
      case "add"
         set the opaque of me to true
         set the backgroundcolor of me to white
         break
      default
         put tActionName
   end switch
end mouseUp

on resizeControl
   LayoutControl
end resizeControl

command LayoutControl pRect
   if pRect is empty then put the rect of me into pRect
   set the rect of me to pRect
end LayoutControl


--> Browser | Props
-
getprop browser_Element
   return LocalArray ["elementHtml"]
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

setprop browser_Element elementID
   browser_InitResult "svg"
   return the result
end browser_Element

setprop browser_Javascript someJavascript
   -- put "wiki.doInternalLink('Federateed Wiki')" into someJavascript
   put _BrowserWidget() into browserWidget
   do someJavascript in browserWidget
   put the result into doResult
   return doResult
end browser_Javascript

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


--> View
-
private function _BrowserWidget
   return the long id of me
end _BrowserWidget

getprop view_Object
   return the long id of me
end view_Object


--> Object
-
getprop browser_View
   return the long id of me
end browser_View
