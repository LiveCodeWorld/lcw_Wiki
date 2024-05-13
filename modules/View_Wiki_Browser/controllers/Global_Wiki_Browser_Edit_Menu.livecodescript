script "Global | Wiki | Browser | Edit | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Browser | Edit | Menu
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


--> Global | Wiki | Browser | Edit | Menu
-
on menu_WikiBehavior wikiView
   put the behavior of wikiView into bObject
   edit the script of bObject
end menu_WikiBehavior

on menu_MenuGroupBehavior wikiView
   put the menuBar_View of wikiView into mGroup
   put the behavior of mGroup into bObject
   edit the script of bObject
end menu_MenuGroupBehavior

private on _
end _

on insert_Edit
   return "Global | Menu | Group | Edit | Menu"
end insert_Edit

-- on subMenu_Create
return "Global | Wiki | Browser | Create | Menu"
end subMenu_Create

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Browser | Edit | Menu")
end submenu_Dev
