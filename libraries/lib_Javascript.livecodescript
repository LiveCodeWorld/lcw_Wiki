script "lib_Javascript"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_Javascript
type: library
version: 0.1

/*Some help*/


--> Working on
-
function js_ConstructQuerySelector qSelector
   put merge ("document.querySelector('[[qSelector]]')") into docQuery
   return docQuery 
end js_ConstructQuerySelector

function js_OuterHtml pageSlug
   put js_ConstructQuerySelector (".header h1", pageSlug) into docQuery
   put merge ("liveCode.javascript_Result([[docQuery]].outerHTML);") into sJavascript
   return sJavascript
end js_OuterHtml


--> Javascript
-
function js_ElementIsTranparent domElement
   put "var sBgColor = window.getComputedStyle([[domElement]]).backgroundColor;" into sJavascript   
   put CR & "if (sBgColor === 'transparent' || sBgColor === 'rgba(0, 0, 0, 0)') {" after sJavascript 
   put CR & "  liveCode.javascript_Result('true');" after sJavascript 
   put CR & "} else {" after sJavascript 
   put CR & "  liveCode.javascript_Result('false');" after sJavascript 
   put CR & "}" after sJavascript 
   return merge (sJavascript)
end js_ElementIsTranparent

function js_ElementIsVisible qSelector
   -- put js_ElementIsVisible ("footer span.editEnable")
   put merge ("liveCode.javascript_Result(window.getComputedStyle(document.querySelector('[[qSelector]]')).visibility);") into sJavascript
   return sJavascript
end js_ElementIsVisible

function js_VisibilityScript qSelector
   -- put scaffold_Get ("footer_visible.js") into sJavascript
   -- put "liveCode.javascript_Result(window.getComputedStyle(document.querySelector('footer')).visibility);" into sJavascript
   put merge ("document.querySelector('[[qSelector]]').style.visibility") into sJavascript
   return sJavascript
end js_VisibilityScript

function js_ConstructSetUserNameSelector uName
   -- document.querySelector("input[type='text']").value = "123";
   
   put "input[type='text']" into iField
   put js_ConstructSetSelector (iField, uName) into sJavascript
   return sJavascript
end js_ConstructSetUserNameSelector

function js_ConstructSetPasswordSelector pWord
   -- document.querySelector("input[type='password']").value = "123";
   
   put "input[type='password']" into iField
   put js_ConstructSetSelector (iField, pWord) into sJavascript
   return sJavascript
end js_ConstructSetPasswordSelector

function js_ConstructSetSelector iField, pWord
   -- document.querySelector("input[type='text']").value = "123";
   
   get "document.querySelector('[[iField]]').value = "
   replace "'" with quote in it
   put merge (it) into sJavascript
   put kwote (pWord) after sJavascript
   put ";" after sJavascript
   return sJavascript
end js_ConstructSetSelector
