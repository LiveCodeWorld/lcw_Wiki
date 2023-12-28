script "lib_WikiJavascript"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_WikiJavascript
type: library
version: 0.3

/*
This library is for javascript control over federated wiki.

put wiki_FooterVisibleJavascript (hideMe) into someJavascript
put ";" after someJavascript
if showMe is false then
   put wiki_FooterHeightJavascript (18) after someJavascript
else
   put wiki_FooterHeightJavascript (60) after someJavascript
end if
*/


--> Working on
-
function wikijs_GetPageClass pageSlug
   if pageSlug is empty then put "welcome-visitors" into pageSlug 
   --
   put "function getPageClass(pageSlug) {" & CR after sJavascript
   put " var pageElement = document.getElementById(pageSlug);" & CR after sJavascript
   put " if (pageElement && pageElement.classList.contains('page')) {" & CR after sJavascript
   put "  return pageElement.className;" & CR after sJavascript
   put " } else {" & CR after sJavascript
   put "  return '';" & CR after sJavascript
   put "}}" & CR after sJavascript
   put "var pageClass = getPageClass('[[pageSlug]]');" & CR after sJavascript
   put "liveCode.javascript_Result(pageClass);" & CR after sJavascript
   --
   put "getPageClass('[[pageSlug]]')" & CR after sJavascript
   --
   return merge (sJavascript)
end wikijs_GetPageClass

function wikijs_SetFlagHandler flagHandler
   if flagHandler is empty then put "flag_Event" into flagHandler
   --
   put "function flagClick(event) {" & CR after sJavascript
   put " var h1El = event.target.closest('.header > h1');" & CR after sJavascript
   put " if (h1El) {" & CR after sJavascript
   put "  event.preventDefault();" & CR after sJavascript
   put "  event.stopPropagation();" & CR after sJavascript
   put "  var anchor = h1El.querySelector('a');" & CR after sJavascript
   put "  if (anchor) {" & CR after sJavascript
   put "   var href = anchor.getAttribute('href');" & CR after sJavascript
   put "   var targetAttr = anchor.getAttribute('target');" & CR after sJavascript
   put "   var pageTitle = h1El.textContent.trim(); // Get the text content of the h1 element" & CR after sJavascript
   put "   var yString = 'target:' + targetAttr + ',href:' + href + ',pageTitle:' + pageTitle;" & CR after sJavascript
   put "   liveCode.[[flagHandler]](yString);" & CR after sJavascript
   put "}}}" & CR after sJavascript
   put "document.body.addEventListener('click', flagClick, true);" & CR after sJavascript
   --
   put "flagClick('[[event]]')" after sJavascript
   return merge (sJavascript)
end wikijs_SetFlagHandler

function wikijs_ToggleEdit
   put "var span = document.querySelector('footer span.editEnable');" & CR after sJavascript
   put "if (span) {span.click();}" & CR after sJavascript
   --
   delete char -1 of sJavascript
   --
   return merge ( sJavascript)
end wikijs_ToggleEdit

function wikijs_ScaleViewport sFactor
   put "function scaleViewport(sFactor) {" & CR after sJavascript
   put " var container = document.body;" & CR after sJavascript
   put " container.style.transformOrigin = 'top left';" & CR after sJavascript
   put " container.style.transform = 'scale(' + sFactor + ')';" & CR after sJavascript
   put " container.style.width = (100 / sFactor) + '%';" & CR after sJavascript
   put " container.style.height = (100 / sFactor) + '%';" & CR after sJavascript
   put "}" & CR after sJavascript
   --
   put "scaleViewport('[[sFactor]]')" & CR after sJavascript
   --
   return merge ( sJavascript)
end wikijs_ScaleViewport

function wikijs_ResetPageTransform pageSlug, pSeconds
   if pSeconds is empty then put 0.3 into pSeconds
   --
   put "function resetPageTransformation(pageSlug, pSeconds) {" & CR after sJavascript
   put " var pageElement = document.getElementById(pageSlug);" & CR after sJavascript
   put " if (pageElement) {" & CR after sJavascript
   put "  // Apply a transition effect" & CR after sJavascript
   put "  pageElement.style.transition = `transform ${pSeconds}s ease-in-out`;" & CR after sJavascript
   put "  // Reset transformations after applying the transition" & CR after sJavascript
   put "  setTimeout(function() {" & CR after sJavascript
   put "   pageElement.style.transform = '';" & CR after sJavascript
   put "   pageElement.style.transformOrigin = '';" & CR after sJavascript
   put "   pageElement.removeAttribute('data-original-rect');" & CR after sJavascript
   put "  }, 0); // SetTimeout with 0 to ensure the transition style is applied first" & CR after sJavascript
   put " } else {" & CR after sJavascript
   put "  liveCode.javascript_Result('Error, page element with id " & "' + pageSlug + '" & " not found.');" & CR after sJavascript
   put " }" & CR after sJavascript
   put "}" & CR after sJavascript
   --
   put "resetPageTransformation('[[pageSlug]]', '[[pSeconds]]')" & CR after sJavascript
   --
   return merge ( sJavascript)
end wikijs_ResetPageTransform

function wiki_PageFlagJavascript pageSlug
   put wikijs_ConstructSelector(".header h1", pageSlug, "outerHTML") into sJavascript
   return sJavascript
end wiki_PageFlagJavascript

function wikijs_PageSelector pageSlug
   put '.page'
end wikijs_PageSelector

function wikijs_TransformPage pSlug, pScale, pX, pY, pSeconds, pEaseHow
   if pSlug is empty then put "welcome-visitors" into pSlug
   if pScale is empty then put 1 into pScale
   if pX is empty then put 0 into pX
   if pY is empty then put 0 into pY
   if pSeconds is empty then put 0.3 into pSeconds
   --
   put scaffold_Get ("page_Transform.js") into sTemplate
   put merge (sTemplate) into sJavascript
   return sJavascript
   
   if pEaseHow is empty then put "ease-in-out" into pEaseHow
   --
   put "var pageSlug = '[[pSlug]]';" into sTemplate
   put CR & "var pageElement = document.getElementById(pageSlug);" after sTemplate
   --
   put CR & "if (pageElement && pageElement.classList.contains('page')) {" after sTemplate
   put CR & "  pageElement.style.transition = 'transform [[pSeconds]]s [[pEaseHow]]';" after sTemplate
   put CR & "  pageElement.style.transform = 'scale([[pScale]]) translate([[pX]]px, [[pY]]px)';" after sTemplate
   put CR & "} else {" after sTemplate
   put CR & "liveCode.javascript_Result('Error, page ' + pageSlug + ' not found');" after sTemplate
   put CR & "}" after sTemplate
   --
   if pScale is empty then put 1 into pScale
   put merge (sTemplate) into sJavascript
   return sJavascript
end wikijs_TransformPage

function wikijs_SetPageScale pScale, pSlug
   if pPSlug is empty then
      put "var pageElements = document.querySelectorAll('.page');" into sTemplate
      put "pageElements.forEach(function(el) {" after sTemplate
      put "el.style.transform = 'scale([[pScale]])';" after sTemplate
      put "});" after sTemplate
   else
      put "var pageSlug = '[[pSlug]]';" into sTemplate
      put CR & "var pageElement = document.getElementById(pageSlug);" after sTemplate
      put CR & "if (pageElement && pageElement.classList.contains('page')) {" after sTemplate
      put CR & "  pageElement.style.transform = 'scale(0.5)';" after sTemplate
      put CR & "} else {" after sTemplate
      put CR & "  liveCode.javascript_Result('Error, page ' + pageSlug + ' not found');" after sTemplate
      put CR & "}" after sTemplate
   end if
   --
   # None or empty or other value for pDisplayValue
   if pScale is empty then put 1 into pScale
   put merge (sTemplate) into sJavascript
   return sJavascript
end wikijs_SetPageScale

function wiki_SoloLinkJavascript jsFunction
   -- no class (should be class="show-page-html")
   -- <a href="/welcome-visitors.html" date-slug="welcome-visitors" target="fedwiki.org">fedwiki.org </a>
   breakpoint
end wiki_SoloLinkJavascript

function wikijs_Override
   put scaffold_Get ("override.js") into overrideJS
   return overrideJS
end wikijs_Override

function wiki_LiveJavascript hName
   -- put merge ("liveCode.[[jsHandler]]('[[jsMessage]]', [[sjParam]])") into jsFunction
   -- put "alert('The paragraph was clicked.')" into jsFunction
   
   put "alert ('Hello world')" into jsFunction
   return jsFunction
end wiki_LiveJavascript


--> Wiki | Javascript | Selectors
-
function wiki_PageJsonJavascript pageSlug, pJsFunction
   put wikijs_ConstructSelector(".footer a.show-page-source", pageSlug, pJsFunction) into sJavascript
   return sJavascript
end wiki_PageJsonJavascript

function wikijs_ConstructSelector qSelector, pSlug, pJsFunction
   if pSlug is empty then put "welcome-visitors" into pSlug
   if pJsFunction is empty then put "outerHTML" into pJsFunction
   --
   put merge ("#[[pSlug]] [[qSelector]]") into qSelector
   put js_ConstructQuerySelector (qSelector) into docQuery
   put merge ("liveCode.javascript_Result([[docQuery]].[[pJsFunction]]);") into sJavascript
   return sJavascript
end wikijs_ConstructSelector


--> Wiki | Javascript
-
function wikijs_SetJournalCss pDisplayValue
   put "var style = document.createElement('style');style.type = 'text/css';style.innerHTML = `" into sTemplate
   --
   put ".action.add {display: [[pDisplayValue]];}" after sTemplate
   put ".action.edit {display: [[pDisplayValue]];}" after sTemplate
   put ".action.remove {display: [[pDisplayValue]];}" after sTemplate
   put ".action.move {display: [[pDisplayValue]];}" after sTemplate
   put ".action.separator {display: [[pDisplayValue]];}" after sTemplate
   --
   put "`;document.head.appendChild(style);" after sTemplate
   
   # None or empty or other value for pDisplayValue
   if pDisplayValue is empty then put "''" into pDisplayValue
   put merge (sTemplate) into sJavascript
   return sJavascript
end wikijs_SetJournalCss

function wikijs_HideFooter hideMe
   # Hide
   put wiki_FooterVisibleJavascript (hideMe) into sJavascript
   
   # Set Height
   put ";" after sJavascript
   if hideMe is true then
      put wiki_FooterHeightJavascript (18) after sJavascript
   else
      put wiki_FooterHeightJavascript (60) after sJavascript
   end if
   --
   return sJavascript
end wikijs_HideFooter

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

function wiki_FooterHeightJavascript pSomeHeight
   -- if pSomeHeight is empty then put 18 into pSomeHeight
   if pSomeHeight is empty then put 60 into pSomeHeight
   put merge ("document.querySelector('section.main').style.bottom='[[pSomeHeight]]px'") into someJavascript
   return someJavascript
end wiki_FooterHeightJavascript


--> Wiki | Javascript
-
function wikijs_GhostPage pageJSON
   put merge ("wiki.showResult(wiki.newPage([[pageJSON]]))") into someJavascript
   return someJavascript
end wikijs_GhostPage

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

function wiki_HideSiteOwnerJavascript
   put "document.getElementById('site-owner').style.visibility = 'hidden'" into someJavascript
   return someJavascript
end wiki_HideSiteOwnerJavascript
