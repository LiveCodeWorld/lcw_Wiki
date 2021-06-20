script "behavior_ViewBrowser"
--> MetaData
-
license: GPLv3
name: behavior_ViewBrowser
type: behavior
version: 0.1


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
getprop view_Object
   return the long id of me
end view_Object


--> Object
-
getprop browser_View
   return the long id of me
end browser_View
