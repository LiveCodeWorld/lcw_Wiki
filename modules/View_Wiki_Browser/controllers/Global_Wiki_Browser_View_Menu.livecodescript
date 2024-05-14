script "Global | Wiki | Browser | View | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Browser | View | Menu
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
   -- put display_MenuTarget (tObject) into dView
   put the display_View of tObject into dView
   return dView
end menu_Target

getprop disabled_EditMode
   if LocalArray ["footer_IsVisible"] is true then
      return false
   else
      return true
   end if
end disabled_EditMode

getprop checked_EditWiki [wikiView]
   put the wiki_EditMode of wikiView into sBoolean
   return sBoolean
end checked_EditWiki

getprop checked_Footer [wikiView]
   -- return LocalArray ["footer_IsVisible"]
   return the footer_IsVisible of wikiView
end checked_Footer

getprop checked_BrowserVisible [wikiView]
   put the visible of wikiView into isVisible
   return isVisible
end checked_BrowserVisible

getprop checked_ShowMenu [wikiView]
   put the menuBar_View of wikiView into mGroup
   put the show_Menu of mGroup into sBoolean
   return sBoolean
end checked_ShowMenu

getprop checked_Background [wikiView]
   put the wiki_IsTransparent of wikiView into sBoolean
   return sBoolean
end checked_Background


--> Global | Wiki | Browser | View | Menu
-
on menu_EditWiki wikiView
   put the wiki_EditMode of wikiView into sBoolean
   set the wiki_EditMode of wikiView to (sBoolean is false)
end menu_EditWiki

on menu_Footer wikiView
   put the footer_IsVisible of wikiView into sBoolean
   set the footer_IsVisible of wikiView to (sBoolean is false)
end menu_Footer

on menu_BrowserVisible wikiView
   put the visible of wikiView into isVisible
   set the visible of wikiView to (isVisible is false)
end menu_BrowserVisible

private on _
end _

on menu_ShowMenu wikiView
   put the menuBar_View of wikiView into mGroup
   menuBar_ToggleShowMenu mGroup
end menu_ShowMenu

on menu_Background wikiView
   put the wiki_IsTransparent of wikiView into sBoolean
   set the wiki_IsTransparent of wikiView to (sBoolean is false)
end menu_Background

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Browser | View | Menu")
end submenu_Dev
