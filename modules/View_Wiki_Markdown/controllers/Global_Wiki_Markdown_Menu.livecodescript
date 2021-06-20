script "Global | Wiki | Markdown | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Markdown | Menu
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


--> Global | Wiki | Markdown | Menu
-
on menu_Transfer rowView
   get the markdown_Text of rowView
   put line 1 of it into clauseTitle
   put line 2 to -1 of it into utf8Clause
   put lexon_CleanClause (utf8Clause) into someClause
   --
   put view_GetTemplateObject ("View|Contract|Clause") into templateObject
   set the clause_Text ["red"] of templateObject to someClause
end menu_Transfer

on menu_TestClause rowView
   get the markdown_Text of rowView
   put line 1 of it into clauseTitle
   put line 2 to -1 of it into utf8Clause
   --
   put lexon_CleanClause (utf8Clause) into someClause
   put lexon_ConstructWikiClause (someClause) into wikiClause
   --
   put wikiClause
   -- set the markdown_Text of rowView to wikiClause
   --  display_Data clauseArray, "Clause Array", "Lexon Contract"
end menu_TestClause

on _
end _

on menu_TestLongMarkdown rowView
   get "This is a reworking of the standard DataView default row so that it works with the view and module tools of LCW. It is not clear that this is tha fastest way to do things, but the tools make constructing and understanding what is happening easier"
   --
   set the markdown_Text of rowView to it
end menu_TestLongMarkdown

on menu_TestShortMarkdown rowView
   get "This is a short piece of text"
   --
   set the markdown_Text of rowView to it
end menu_TestShortMarkdown

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
