script "Global | Menubar | Data | Line | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Menubar | Data | Line | Menu
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

getprop menu_CheckTarget [dView]
   return exists (dView)
end menu_CheckTarget

private function _buttonObject dView
   put the top_Data [1] of dView into itemArray
   put itemArray ["m mButton"] into btnObject
   return btnObject
end _buttonObject


--> Global | Menubar | Data | Line | Menu
-
on menu_MenubarDataLine dView
   put the top_Data [1] of dView into itemArray
   put itemArray ["mTitle"]
end menu_MenubarDataLine

on menu_MenuButtonTitle dView
   put the top_Data [1] of dView into itemArray
   put itemArray ["m mTitle"] into mTitle
   put itemArray ["m mName"] into mName
   put lcw_Ask ("Set the menuButton_Title of menu '[[var]]'?", mTitle, dView, mName) into mTitle
   --
   put _buttonObject (dView) into btnObject
   breakpoint
   set the menuButton_Title [mName] of btnObject to mTitle
end menu_MenuButtonTitle

private on _
end _

on menu_UpdateStyle dView, updateStyle
   put _buttonObject (dView) into btnObject
   set the menuButton_UpdateStyle of btnObject to updateStyle
   --
   put the stack_Name of btnObject into sName 
   display_MenuBarData sName, dView
end menu_UpdateStyle

getprop updateStyle_Param [dView]
   put _buttonObject (dView) into btnObject
   put the menuButton_UpdateStyle of btnObject into updatestyle
   return updatestyle
end updateStyle_Param

getprop updateStyle_Params [dView]
   put _buttonObject (dView) into btnObject
   return the menuButton_UpdateStyles of btnObject
end updateStyle_Params

on menu_ObjectInspector dView
   put _buttonObject (dView) into btnObject
   --
   display_ObjectProperties btnObject
end menu_ObjectInspector

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Menubar | Data | Line | Menu")
end submenu_Dev
