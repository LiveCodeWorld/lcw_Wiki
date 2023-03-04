script "Global | Wiki | Story | Menu"
--> MetaData
-
license: GPLv3
name: Global | Wiki | Story | Menu
type: controller
version: 0.2


--> Menu | Props
-
function _WikiView mTarget
   -- "browser_View" is on card script of stack "Fedwiki Editor"
   put the wiki_View of cd 1 of stack "Fedwiki Editor" into wikiView
   return wikiView
end _WikiView


--> Global | Wiki | Story | Menu
-
on submenu_Browser
   return "Global | Browser | Menu"
end submenu_Browser

on menu_Login browserView
   put js_ConstructSetUserNameSelector ("david@regovern.org") after sJavascript
   put CR & js_ConstructSetPasswordSelector ("2Bk3uASK&9nJ") after sJavascript
   --
   set the browser_Javascript of browserView to sJavascript
end menu_Login

-- on menu_Submit browserView
put "document.querySelector('form').submit();" after sJavascript
--
set the browser_Javascript of browserView to sJavascript
end menu_Submit

on menu_GoToLink mTarget
   put _WikiView() into wikiView
   --
   put wiki_InternalLinkJavascript ("Federated Wiki") into someJavascript
   set the browser_Javascript of wikiView to someJavascript
end menu_GoToLink

on menu_CreateFederationRoster
   set the cursor to watch 
   put fedray_FetchTopFederationDomains() into rosterDomainText
   put fedwiki_UpdateRosterPageArray ("sites.fedwiki.org", "visible-federation", "741a0fcdd3ff76b2", rosterDomainText) into pageArray
   --
   set the ghost_PageArray of _WikiView() to pageArray
   put the result into browserWidget
end menu_CreateFederationRoster

private on _
end _

on menu_CytoAnimate mTarget
   /*
   window.cy2.animate({
   pan: { x: 10, y: 10 },
   zoom: 2
   }, {
   duration: 1000
   });
   */
   put _WikiView() into wikiView
   --
   put script_GetCommentAboveMe() into someJavascript
   set the browser_Javascript of wikiView to someJavascript
end menu_CytoAnimate

on menu_CytoZoom mTarget
   /*
   var pos = window.cy2.nodes("#n6").position();
   window.cy2.zoom({
   level: 1.0,
   position: pos
   });
   */
   put _WikiView() into wikiView
   --
   put script_GetCommentAboveMe() into someJavascript
   set the browser_Javascript of wikiView to someJavascript
end menu_CytoZoom

private on __
end __

on menu_AddBrowserMenu mTarget
   put _WikiView() into wikiView
   --  
   -- Set up the browser javascript handler list
   -- This code goes in a suitable setup handler
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

on menu_HideSiteOwner mTarget
   put _WikiView() into wikiView
   --  
   put wiki_HideSiteOwnerJavascript() into someJavascript
   set the browser_Javascript of wikiView to someJavascript
end menu_HideSiteOwner

on menu_HideFooter mTarget, someBoolean
   put _WikiView() into wikiView
   --
   put wiki_FooterVisibleJavascript (someBoolean) into someJavascript
   if someBoolean is true then
      put ";" & wiki_FooterHeightJavascript (18) after someJavascript
   else
      put ";" & wiki_FooterHeightJavascript (60) after someJavascript
   end if
   set the browser_Javascript of wikiView to someJavascript
end menu_HideFooter

on menu_SetFooterHeight mTarget
   put _WikiView() into wikiView
   --
   put wiki_FooterHeightJavascript () into someJavascript
   set the browser_Javascript of wikiView to someJavascript
end menu_SetFooterHeight

private on ___
end ___

on submenu_Javascript
   return "Global | Wiki | Story | Javascript | Menu"
end submenu_Javascript
