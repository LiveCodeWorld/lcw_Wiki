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

getprop disabled_HideFooter [wikiView]
   return exists (wikiView) is false
end disabled_HideFooter

getprop checked_HideFooter [wikiView]
   put the footer_IsVisible of wikiView into sBoolean
   return sBoolean is false
end checked_HideFooter


--> Global | Obeya | Studio | Dev | Menu
-
on menu_AddBrowserMenu wikiView
   set the browser_JavascriptHandlers of wikiView to "myJSHandler"
   
   /*
   We need to disable event propogation
   $('.header a')
   .unbind('click')
   .click(function( event ) {
   event.preventDefault();
   alert ('Hello world');return false;})
   */
   
   // Calling the handler from JavaScript within the browser
   put "$('.header H1 > a').click(function() { liveCode.myJSHandler('myMessage', 12345) });" into someJavascript
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
