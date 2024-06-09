script "Global | View | Outline | Line | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | View | Outline | Line | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray


--> Display | Events
-
command mDoubleUp_ViewOutline dView, viewName
   if the optionKey is "Down" then breakpoint
   --
   -- put word 2 of the clickline into lineNum -- for a field
   put the selected_LineNum of dView into lineNum
   --
   put the displayed_NestedViewArray of dView into nestedViewArray
   put nestedViewArray ["dictionary"] into viewDictionary
   --
   put the top_Data [1] of dView into viewArray
   put viewArray ["metadata"] into metaDataArray
   
   put metaDataArray ["rObject"] into viewObject
   put the view_Name of viewObject into viewName
   -- put metaDataArray ["view"] into viewName
   
   put merge ("What would you like to do with the view '[[viewName]]'?") into sComment
   answer sComment with "Cancel" or "Placeholder" or "Update"
   switch it
      case "Placeholder"
         set the control_Type of viewObject to "placeholder"
         put the result into createdObject
         --
         set the replaced_ViewName of createdObject to viewName
         set the displayed_NestedViewArray of createdObject to nestedViewArray
         break
      case "Update"
         view_Update viewObject
         break
      default
         exit to top
   end switch
end mDoubleUp_ViewOutline


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


--> Global | View | Outline | Line | Menu
-
on menu_ReplaceView dView
   get the selected_Path of dView
   put item 1 of it into vName
   put the top_Data [1] of dView into viewArray
   put viewArray ["metadata"] into mArray
   --
   put mArray ["rObject"] into rObject
end menu_ReplaceView

private on _
end _

on menu_EditViewBehavior dView
   put the behavior of dView into bObject
   edit the script of bObject
end menu_EditViewBehavior

on menu_ModuleTools dView
   put the view_Name of dView into viewName
   display_ModuleTools viewName
end menu_ModuleTools

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | View | Outline | Line | Menu")
end submenu_Dev
