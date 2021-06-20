script "Global | Wiki | Code | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Code | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray

--> Menu | Props
-
on menu_Init tObject
   -- called only once for top menu
   pass menu_Init
end menu_Init

getprop menu_Target [tObject]
   return the dvRowControl of tObject into rowView
   return rowView
end menu_Target


--> Global | Wiki | Code | Menu
-
on menu_TestLongCode rowView
   get "This is a reworking of the standard DataView default row so that it works with the view and module tools of LCW. It is not clear that this is tha fastest way to do things, but the tools make constructing and understanding what is happening easier"
   --
   set the markdown_Text of rowView to it
end menu_TestLongCode

on menu_TestShortCode rowView
   get "This is a short piece of text"
   --
   set the markdown_Text of rowView to it
end menu_TestShortCode

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
on menu_TestLongText rowView
   get "This is a reworking of the standard DataView default row so that it works with the view and module tools of LCW. It is not clear that this is tha fastest way to do things, but the tools make constructing and understanding what is happening easier"
   --
   set the code_Text ["code"] of rowView to it
end menu_TestLongText

on menu_TestShortText rowView
   get "This is a short ppeice of text"
   --
   set the code_Text ["code"] of rowView to it
end menu_TestShortText
