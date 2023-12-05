script "Global | Obeya | Studio | Dev | Menu"
--> MetaData
-
license: GPLv3
name: Global | Obeya | Studio | Dev | Menu
type: controller
author: David Bovill
version: 0.1

/*
Here you can describe this developer menu.
Full help text should be provided on the linked wiki.

Consider improving by creating with same menu_Target as no-developer menu is is based on.
*/

--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_Target [tObject]
   put display_MenuTarget(tObject) into testView
   if exists (testView) then
      put the browser_View of testView into browserView
   else
      put the browser_View of tObject into browserView
   end if
   --
   if exists (browserView) then
      return browserView
   else
      return true
   end if
end menu_Target


--> Global | Obeya | Studio | Dev | Menu
-
on menu_TestOneTab
   put "https://www.one-tab.com/page/xSSyPyCASfymOEwOT634JQ" into oneTabUrl
   put oneTab_FetchPageArray (oneTabUrl, "markdown") into pageArray
   --
   display_PageArray pageArray
end menu_TestOneTab

private on _
end _

on menu_AddBrowserMenu wikiView
   put "myJSHandler" into mHandler
   --
   set the browser_AddJavascriptHandlers of wikiView to mHandler
   get "$('.header H1 > a').click(function() { liveCode.myJSHandler('[[mHandler]]', 12345) });"
   put merge (it) into someJavascript
   set the browser_Javascript of wikiView to someJavascript
end menu_AddBrowserMenu

on menu_HideSiteOwner wikiView
   put wiki_HideSiteOwnerJavascript() into someJavascript
   set the browser_Javascript of wikiView to someJavascript
end menu_HideSiteOwner

on menu_SetFooterHeight wikiView
   put wiki_FooterHeightJavascript () into someJavascript
   set the browser_Javascript of wikiView to someJavascript
end menu_SetFooterHeight
