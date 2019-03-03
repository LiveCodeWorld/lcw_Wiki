script "lib_Wiki"
--> MetaData
-
license: GPLv3
name: lib_Wiki
type: library
version: 0.1

/*
This is a library for working with Fedwiki inside of a Livecode desktop or obile application.
*/



--> Display
-
function fedwiki_ConvertGitHubReadme readmeMarkdown, pageTitle
   put wiki_Merge ("On this page we describe the [[Github]] project {{githubProjectName}}.") into firstPara
   --
   put fedwiki_ConstructNewPageArray (pageTitle, firstPara) into pageArray
   fedwiki_AddMarkdownToPageArray pageArray, readmeMarkdown
   fedwiki_AddMarkdownToPageArray pageArray, "# See also"
   fedwiki_AddMarkdownToPageArray pageArray, "- [[Github]]"
   --
   fedwiki_CleanJournalArray pageArray
   return pageArray
end fedwiki_ConvertGitHubReadme


--> Props
-


--> Wiki
-
command wiki_ConvertCSS @someCSS
   put lineOffset ("width: 430px;", someCSS) into lineNum
   put "  width: 350px;" into line lineNum of someCSS
   
   put lineOffset ("width: 420px;", someCSS) into lineNum
   put "  width: 344px;" into line lineNum of someCSS
   
   put lineOffset ("#persona-logout-btn {", someCSS) into lineNum
   put CR & "visibility: hidden;" after line lineNum of someCSS
   
   put lineOffset ("#persona-login-btn,", someCSS) into lineNum
   put ".searchbox {float: left}" into csssTweak
   put CR & ".menu {float: left}" after csssTweak
   put csssTweak & CR & CR before line lineNum of someCSS
      
   /*
   -- this scales everything
   put 0.91 into hScale
   put 1 into vScale
   
   put "-moz-transform: scale([[hScale]], [[vScale]]);" into extraCSS
   put CR & "-webkit-transform: scale([[hScale]], [[vScale]]);" after extraCSS
   put CR & "-o-transform: scale([[hScale]], [[vScale]]);" after extraCSS
   put CR & "-ms-transform: scale([[hScale]], [[vScale]]);" after extraCSS
   put CR & "transform: scale([[hScale]], [[vScale]]);" after extraCSS
   put CR & "-moz-transform-origin: top left;" after extraCSS
   put CR & "-webkit-transform-origin: top left;" after extraCSS
   put CR & "-o-transform-origin: top left;" after extraCSS
   put CR & "-ms-transform-origin: top left;" after extraCSS
   put CR & "transform-origin: top left;" after extraCSS
   put merge(extraCSS) into extraCSS
   put lineOffset (".main {", someCSS) into lineNum
   put CR & extraCSS after line lineNum of someCSS
   */
   
   /*
   -- this hides the whole footer
   put lineOffset ("footer {", someCSS) into lineNum
   put CR & "visibility: hidden;" after line lineNum of someCSS
   put lineOffset ("bottom: 60px;", someCSS) into lineNum
   put "  bottom: 16px;" into line lineNum of someCSS
   */
   
   /*
   -- this hides the whole footer
   put lineOffset ("footer {", someCSS) into lineNum
   put CR & "visibility: hidden;" after line lineNum of someCSS
   put lineOffset ("bottom: 60px;", someCSS) into lineNum
   put "  bottom: 16px;" into line lineNum of someCSS
   */
end wiki_ConvertCSS

function wiki_Merge someText
   replace "[" with "{{{" in someText
   replace "]" with "}}}" in someText
   put merge (someText) into mergedText
   replace "{{{" with "[" in mergedText
   replace "}}}" with "]" in mergedText
   return mergedText
end wiki_Merge


--> Wiki | Folder
-
function wiki_GetSiteFolder
   put $HOME & "/.wiki/" into wikiSiteFolder
   return wikiSiteFolder
end wiki_GetSiteFolder

function wiki_GetWikiClientFolder
   put wiki_GetModulesFolder() & "wiki-client/" into wikiClientFolder
   return wikiClientFolder
end wiki_GetWikiClientFolder

function wiki_GetModulesFolder
   return "/usr/local/lib/node_modules/wiki"
end wiki_GetModulesFolder


--> Wiki | Javascript
-
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
   -- no class
   -- should be class="show-page-html"
   -- <a href="/welcome-visitors.html" date-slug="welcome-visitors" target="fedwiki.org">fedwiki.org </a>
   breakpoint
end wiki_SoloLinkJavascript

function wiki_InternalLinkJavascript pageTitle
   put merge ("wiki.doInternalLink('[[pageTitle]]')") into someJavascript
   return someJavascript
end wiki_InternalLinkJavascript

function wiki_RemoteLinkJavascript pageTitle, remoteDomain
   -- wiki.doInternalLink('apparatus', null, 'wiki.dbbs.co')
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
