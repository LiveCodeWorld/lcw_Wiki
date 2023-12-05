script "lib_WikiJavascript"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_WikiJavascript
type: library
version: 0.1

/*Some help*/


--> Working on
-


--> Wiki | Javascript
-
function wikijs_GhostPage pageJSON
   put merge ("wiki.showResult(wiki.newPage([[pageJSON]]))") into someJavascript
   return someJavascript
end wikijs_GhostPage

function wikijs_Override
   -- put scaffold_Get ("override_externallink.js") into externalJS
   -- put scaffold_Get ("override_Hamburger.js") into hamburgerJS
   -- set the browser_Javascript of me to externalJS
   -- set the browser_AddJavascriptHandlers of me to "bevent_ExternalLink"
   put scaffold_Get ("override.js") into overrideJS
   return overrideJS
end wikijs_Override

function wiki_FlagLinkJavascript jsFunction
   -- $('.header H1 > a').click(function(){alert("The paragraph was clicked.")});
   --
   put wiki_LiveJavascript (hName) into jsFunction
   --
   -- put merge ("$('.header H1 > a').click(function() { [[jsFunction]] });") into someJavascript
   -- This disables links and clicks but not flag click
   put merge ("$('.header H1 > a').click(function( event ) {event.preventDefault(); [[jsFunction]];return false;});") into someJavascript
   return someJavascript
end wiki_FlagLinkJavascript

function wiki_LiveJavascript hName
   -- put merge ("liveCode.[[jsHandler]]('[[jsMessage]]', [[sjParam]])") into jsFunction
   -- put "alert('The paragraph was clicked.')" into jsFunction
   
   put "alert ('Hello world')" into jsFunction
   return jsFunction
end wiki_LiveJavascript

function wiki_SearchLinkJavascript jsFunction
   -- <a href="#" class="search">search</a>
   put merge ("$('.footer a.search').click(function( event ) {event.preventDefault(); [[jsFunction]];return false;});") into someJavascript
   return someJavascript
end wiki_SearchLinkJavascript

function wiki_JsonLinkJavascript jsFunction
   -- <a class="show-page-source" href="/welcome-visitors.json" title="source">JSON</a>
   put merge ("$('.footer a.show-page-source').click(function( event ) {event.preventDefault(); [[jsFunction]];return false;});") into someJavascript
   return someJavascript
end wiki_JsonLinkJavascript

function wiki_LicenseHtmlJavascript jsFunction
   -- <a class="show-page-license" href="https://creativecommons.org/licenses/by-sa/4.0/" target="_blank">CC BY-SA 4.0</a>
   put merge ("$('.footer a.show-page-license').click(function( event ) {event.preventDefault(); [[jsFunction]];return false;});") into someJavascript
   return someJavascript
end wiki_LicenseHtmlJavascript

function wiki_SoloLinkJavascript jsFunction
   -- no class (should be class="show-page-html")
   -- <a href="/welcome-visitors.html" date-slug="welcome-visitors" target="fedwiki.org">fedwiki.org </a>
   breakpoint
end wiki_SoloLinkJavascript

function wiki_InternalLinkJavascript pageTitle
   put merge ("wiki.doInternalLink('[[pageTitle]]')") into someJavascript
   return someJavascript
end wiki_InternalLinkJavascript

function wiki_RemoteLinkJavascript pageTitle, remoteDomain, pPort
   -- wiki.doInternalLink('apparatus', null, 'wiki.dbbs.co')
   if pPort is a number then put ":" & pPort after remoteDomain
   put merge ("wiki.doInternalLink('[[pageTitle]]', null, '[[remoteDomain]]')") into someJavascript
   return someJavascript
end wiki_RemoteLinkJavascript

function wiki_FooterHeightJavascript pSomeHeight
   -- if pSomeHeight is empty then put 18 into pSomeHeight
   if pSomeHeight is empty then put 60 into pSomeHeight
   put merge ("document.querySelector('section.main').style.bottom='[[pSomeHeight]]px'") into someJavascript
   return someJavascript
end wiki_FooterHeightJavascript

function wiki_HideSiteOwnerJavascript
   put "document.getElementById('site-owner').style.visibility = 'hidden'" into someJavascript
   return someJavascript
end wiki_HideSiteOwnerJavascript

function wiki_FooterVisibleJavascript someBoolean
   -- put "document.getElementById('site-owner').style.visibility = 'hidden'" into someJavascript
   -- put "var myElement = document.querySelector('footer');myElement.style.visibility = 'hidden'" into someJavascript
   -- put "var myElement = document.querySelector('footer');myElement.style.visibility = 'visible'" into someJavascript
   
   if someBoolean is true then
      put "document.querySelector('footer').style.visibility = 'hidden'" into someJavascript
   else
      put "document.querySelector('footer').style.visibility = 'visible'" into someJavascript
   end if
   return someJavascript
end wiki_FooterVisibleJavascript


