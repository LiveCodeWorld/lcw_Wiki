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

--> Javascript
-
