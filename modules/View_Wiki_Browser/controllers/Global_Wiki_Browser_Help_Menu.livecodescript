script "Global | Wiki | Browser | Help | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Browser | Help | Menu
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
   put the browser_View of tObject into browserView
   if exists (browserView) then
      put the footer_IsVisible of browserView into LocalArray ["footer_IsVisible"]
      return browserView
   else
      put line 1 of display_List ("View|Wiki|Browser") into browserView
      if exists (browserView) then return browserView
      return empty
   end if
end menu_Target


--> Global | Wiki | Browser | Help | Menu
-
on menu_WorkingOn wikiView
   put the behavior of dView into bObject
   edit the script of bObject
end menu_WorkingOn

on menu_SecondHelp wikiView
   set the page_Title of wikiView to "About"
end menu_SecondHelp

on menu_Bout wikiView
   set the page_Title of wikiView to "About"
end menu_Bout

on menu_LastHelp wikiView
   set the page_Title of wikiView to "About"
end menu_LastHelp
