script "Global | Wiki | Image | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Image | Menu
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


--> Global | Wiki | Image | Menu
-
on menu_TestImage rowView
   put the image_Object of rowView into imageObject
   set the image_Rect of imageObject to the rect of imageObject
end menu_TestImage

on menu_TestReloadRowData rowView
   put the dvClickRow of rowView into rowNum
   put the row_Data of rowView into rowData
   --
   dispatch "FillInData" to rowView with rowData,rowNum
end menu_TestReloadRowData

getprop disabled_SetResizeStyle [rowView]
   put the image_Object of rowView into imageObject
   if exists (imageObject) is false then
      return "delete"
   else
      return false
   end if
end disabled_SetResizeStyle

getprop setResizeStyle_Param [rowView]
   put the image_Object of rowView into imageObject
   put the resize_Style of imageObject into resizeStyle
   return resizeStyle
end setResizeStyle_Param

getprop setResizeStyle_Params [rowView]
   put the image_Object of rowView into imageObject
   put the resize_Styles of imageObject into resizeStyles
   return resizeStyles
end setResizeStyle_Params

on menu_SetResizeStyle rowView, resizeStyle
   put the image_Object of rowView into imageObject
   set the resize_Style of imageObject to resizeStyle
end menu_SetResizeStyle

on _
end _

on menu_DisplayRowData rowView
   put the dvClickRow of rowView into rowNum
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
getprop checked_SetImageBehavior [rowView]
   put _GetImageBehavior (rowView) into bObject
   put the name of stack "behavior_ViewImage" into dObject
   put bObject = dObject into isSet
   return isSet
end checked_SetImageBehavior

private function _GetImageBehavior rowView
   put the image_Object of rowView into imageObject
   -- put the module_Behavior of stack "View|Image" into bObject
   put the name of stack "behavior_ViewImage" into bObject
   return bObject
end _GetImageBehavior

on menu_SetImageBehavior rowView
   put _GetImageBehavior (rowView) into bObject
   set the behavior of imageObject to bObject
end menu_SetImageBehavior
