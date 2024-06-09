script "Global | Wiki | Future | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Future | Menu
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
   put display_MenuTarget (tObject) into dView
   put the card_Object of dView into cardObject
   return cardObject
end menu_Target

getprop menu_CheckTarget [dView]
   return exists (dView)
end menu_CheckTarget


--> Global | Wiki | Future | Menu
-
on menu_CreateMenuBar cardObject
   lcw_Answer "Sure you want to create a menubar view on this card?", cardObject
   --
   lock screen
   view_InsertFromPath "View|Menu|Group", cardObject
   put the result into mGroup
   set the topleft of mGroup to 0,0
   unlock screen
   --
   set the show_Menu [true] of mGroup to true
   dispatch "Init_MenuBar" to mGroup
end menu_CreateMenuBar

private on _
end _

on menu_InitMenuBar cardObject
   put the menuBar_View of cardObject into mGroup
   --
   dispatch "Init_MenuBar" to mGroup
end menu_InitMenuBar

private on __
end __

on menu_PreOpen cardObject
   put the menubar_View of cardObject into mGroup
   --
   dispatch "preOpenControl" to mGroup
end menu_PreOpen

on menu_Add cardObject
   put the menubar_View of cardObject into mGroup
   --
   set the add_Menu ["Menu"] of mGroup to "Tools"
   set the add_Menu ["Tools"] of mGroup to "Rev"
   set the add_Menu ["Object"] of mGroup to "Rev"
end menu_Add

on menu_SetMenuTable cardObject
   put the menubar_View of cardObject into mGroup
   --
   put "File-Rev,Edit-Rev,Future-Default,Menu-Global|Menu|Group|Exists|Menu,Help-Rev" into mTable
   set the menubar_Table of mGroup to mTable
end menu_SetMenuTable

on menu_TestSetMenu cardObject
   put the menubar_View of cardObject into mGroup
   --
   set the menuButton_Title of btn 3 of mGroup to "Default"
   set the menuButton_Title of btn 4 of mGroup to "Menu"
   --
   set the menuButton_Title ["File"] of btn 1 of mGroup to "Rev"
   set the menuButton_Title ["Edit"] of btn 2 of mGroup to "Rev"
   --
   set the add_Menu of mGroup to "Help"
   put the result into mButton
   set the menuButton_Title ["Help"] of btn 4 of mGroup to "Rev"
end menu_TestSetMenu

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Future | Menu")
end submenu_Dev
