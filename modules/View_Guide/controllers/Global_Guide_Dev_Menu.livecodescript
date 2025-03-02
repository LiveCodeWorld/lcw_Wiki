script "Global | Guide | Dev | Menu"
--> MetaData
-
license: GPLv3
name: Global | Guide | Dev | Menu
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
   -- return display_MenuTarget(tObject)
   return the display_View of tObject
end menu_Target

getprop menu_CheckTarget [mTarget]
   return exists (mTarget)
end menu_CheckTarget


--> Global | Guide | Dev | Menu
-
on menu_Offset dView
   put the displayed_Object of dView into viewObject
   put the readMe_Html of viewObject into rHTML
   --
   put tiddly_DataFromHtml (rHTML) into oTiddlyData
   put tiddlyArray_GetText (oTiddlyData, "White Paper")
   --
   -- display_Data tiddlerArray
end menu_Offset

function tiddlyArray_GetText oTiddlyData, tTitle
   put tiddlyArray_Get (oTiddlyData, tTitle) into tiddlyArray
   return tiddlyArray ["text"]
end tiddlyArray_GetText

function tiddlyArray_Get oTiddlyData, tTitle
   put indexArray_FindArray (oTiddlyData, "title", tTitle) into tiddlerArray
   return tiddlerArray
end tiddlyArray_Get

function tiddly_DataFromHtml rHTML
   -- <!--~~ Ordinary tiddlers ~~-->
   put html_CommentTitle ("~~ Ordinary tiddlers ~~") into sTitle
   put lineOffset (sTitle, rHTML) into startLine
   put html_CommentTitle ("~~ Library modules ~~") into eTitle
   put lineOffset (eTitle, rHTML) into endLine
   --
   put line startLine to endLine of rHTML into oTiddlers
   put html_StripEnclosingScriptTag (oTiddlers) into sJSON
   --
   put json_ToArray (sJSON) into oTiddlyData
   return oTiddlyData
end tiddly_DataFromHtml

function html_StripEnclosingScriptTag sText
   -- rough and ready
   put offset ("</script>", sText) into endChar
   if endChar = 0 then return sText
   
   get char 1 to (endChar-1) of sText
   put offset ("<script", it) into startTagChar
   if startTagChar = 0 then return sText
   
   put offset (">", sText, startTagChar) into endTagChar
   if endTagChar = 0 then return sText
   
   delete char 1 to (endTagChar + startTagChar) of it
   return it
end html_StripEnclosingScriptTag

function html_CommentTitle sTitle
   return "<!--" & sTitle & "-->"
end html_CommentTitle

on menu_ModuleProperties dView
   put the view_Name of dView into viewName
   display_Template viewName
   --
   put the result into moduleObject
   display_ObjectProperties moduleObject
end menu_ModuleProperties

on menu_DisplayModuleTools dView
   -- put the menu_Name of me into mName
   put the view_Name of dView into viewName
   --
   display_ModuleTools viewName
end menu_DisplayModuleTools

on menu_Behavior dView
   put the behavior of dView into bObject
   edit the script of bObject
end menu_Behavior

private on _
end _

on menu_MenuEdit displayView
   menu_Edit "Global | Guide | Dev | Menu"
end menu_MenuEdit
