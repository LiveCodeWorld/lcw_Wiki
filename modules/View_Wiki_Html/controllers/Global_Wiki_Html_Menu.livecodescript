script "Global | Wiki | Html | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Html | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_Target [tObject]
   return the dvRowControl of tObject into rowView
   return rowView
end menu_Target

getprop disabled_ReplaceWithImage [rowView]
   put the row_Value ["text"] of rowView into itemHTML
   put pageItem_GetFirstImage (itemHTML) into imageURL
   if imageURL is empty then
      return true
   else
      return false
   end if
end disabled_ReplaceWithImage


--> Global | Wiki | Html | Menu
-
on menu_ReplaceWithImage rowView
   put the row_Value ["text"] of rowView into itemHTML
   put pageItem_GetFirstImage (itemHTML) into imageURL
   put html_ExtractTagContents ("p", itemHTML) into sCaption
   
   -- put imageURL & CR & sCaption
   put the row_Data of rowView into rowData
   put imageURL into rowData ["url"]
   put sCaption into rowData ["caption"] 
   set the row_Data ["image"] of rowView to rowData
end menu_ReplaceWithImage

on _
end _

on menu_TestLongHtml rowView
   get "This is a reworking of the standard [[DataView]] default row so that it <bold>works</bold> with the view and module tools of LCW. It is not clear that this is tha fastest way to do things, but the tools make constructing and understanding what is happening easier"
   --
   set the html_Text of rowView to it
end menu_TestLongHtml

on menu_TestShortHtml rowView
   get "This is a <bold>bold</bold> piece of text, and a [[link]]."
   --
   set the html_Text of rowView to it
end menu_TestShortHtml

on _
end _

on menu_DisplayRowData rowView
   put the dvClickRow of dView into rowNum
   put the row_Data of rowView into rowData
   --
   display_Data rowData, rowNum, "Row Data"
end menu_DisplayRowData

on menu_RowBehavior rowView
   put the behavior of rowView into bObject
   edit the script of bObject 
end menu_RowBehavior

on _
end _

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Dev | Menu
-
