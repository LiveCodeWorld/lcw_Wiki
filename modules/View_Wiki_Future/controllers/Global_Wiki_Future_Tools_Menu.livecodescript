script "Global | Wiki | Future | Tools | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Future | Tools | Menu
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
   put display_MenuTarget (tObject) into cardObject
   return cardObject
end menu_Target

getprop menu_CheckTarget [cardObject]
   return exists (cardObject)
end menu_CheckTarget


--> Global | Wiki | Future | Tools | Menu
-
on menu_WikiFutureTools cardObject
   put the params
end menu_WikiFutureTools

private on _
end _

on menu_EditFutureBehavior cardObject
   put the behavior of cardObject into bObject
   edit the script of bObject
end menu_EditFutureBehavior

on menu_EditBackBehavior cardObject
   put the behavior of the back_View of cardObject into bObject
   edit the script of bObject
end menu_EditBackBehavior

on menu_EditMenuBehavior cardObject
   put the behavior of the menubar_View of cardObject into bObject
   edit the script of bObject
end menu_EditMenuBehavior

private on __
end __

on menu_ShowMenu cardObject
   put the menubar_View of cardObject into mGroup
   menuBar_ToggleShowMenu mGroup
end menu_ShowMenu

getprop checked_ShowMenu [cardObject]
   put the menubar_View of cardObject into mGroup
   if exists (mGroup) is false then return false -- bug should not be needed
   --
   put the show_Menu of mGroup into sBoolean
   return sBoolean
end checked_ShowMenu

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Future | Tools | Menu")
end submenu_Dev
