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
on menu_RevMenuBarScript wikiView
   edit the script of ide_DefaultMenuBarStack()
end menu_RevMenuBarScript

private on _
end _

on submenu_IdeHelp
   return "Global | Menu | Group | Help | Menu"
end submenu_IdeHelp
