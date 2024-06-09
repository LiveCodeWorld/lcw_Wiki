script "Global | Wiki | Background | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Background | Menu
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


--> Global | Wiki | Background | Menu
-
on menu_WikiBackground dView
   put the flag_Objects of dView into flagObject
end menu_WikiBackground

on menu_ViewProperty someView, someProp
   view_DoPropertyMenu someProp, someView
end menu_ViewProperty

getprop viewProperty_Params [mTarget]
   return LocalArray ["view_PropertyMenu"]
end viewProperty_Params

getprop disabled_ViewProperty [mTarget]
   put the view_PropertyMenu of mTarget into viewPropertyMenu
   put viewPropertyMenu into LocalArray ["view_PropertyMenu"]
   --
   if viewPropertyMenu is empty then
      return "delete"
   else
      return false
   end if
end disabled_ViewProperty

private on _
end _

private on __
end __

on menu_CreatePlaceholder dView
   dispatch "create_FlagButton" to dView
end menu_CreatePlaceholder

on menu_DeleteFlags dView
   dispatch "delete_Flags" to dView
end menu_DeleteFlags

-- getprop disabled_DeleteFlags [dView]
put the flag_Objects of dView into flagObjects
return flagObjects is empty
end disabled_DeleteFlags

private on ___
end ___

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Background | Menu")
end submenu_Dev
