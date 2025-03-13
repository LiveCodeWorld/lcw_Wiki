script "Global | Guide | Camera | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Guide | Camera | Menu
type: controller
version: 0.1


--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_Target [tObject]
   put the display_View of tObject into LocalArray ["dView"]
   put the displayed_Object of tObject into sObject
   return sObject
end menu_Target

private function _dView
   return LocalArray ["dView"]
end _dView

getprop menu_CheckTarget [dView]
   return exists (dView)
end menu_CheckTarget

private function _CameraMissing guideView
   put the right_View of guideView into rightView
   put the camera_Name of rightView into cameraName
   return cameraName is empty
end _CameraMissing


--> Global | Guide | Camera | Menu
-
on menu_GuideCamera dView
   put the params
end menu_GuideCamera

private on _
end _

on menu_RightCamera guideView
   put the right_View of guideView into rightView
   --
   put the rect of rightView into cameraRect
   set the camera_Video [cameraRect] of rightView to "Facetime"
   set the visible of rightView to false
end menu_RightCamera

getprop checked_RightCamera [guideView]
   put the camera_IsOpen of guideView into isOpen
   
   put the right_View of guideView into rightView
   return the visible of rightView
end checked_RightCamera

on menu_Camera guideView
   put the right_View of guideView into rightView
   --
   put the camera_Rect of guideView into cameraRect
   put the camera_GuideRect of guideView into guideRect
   --
   set the rect of rightView to guideRect
   -- 
   set the camera_Video [cameraRect] of rightView to "Facetime"
end menu_Camera

getprop checked_Camera [guideView]
   put the camera_IsOpen of guideView into isOpen
   return isOpen
end checked_Camera

on menu_ShowCamera guideView
   put the right_View of guideView into rightView
   --
   put the camera_IsVisible of rightView into isVisible
   if item 1 of isVisible = "Error" then
      breakpoint
   end if
   -- if isVisible is true then set the camera_Video of guideView to ""
   --
   set the camera_IsVisible of rightView to (isVisible is false)
end menu_ShowCamera

getprop disabled_ShowCamera [guideView]
   return _CameraMissing (guideView)
end disabled_ShowCamera

getprop checked_ShowCamera [guideView]
   put the right_View of guideView into rightView
   --
   put the camera_IsVisible of rightView into isVisible
   return isVisible
end checked_ShowCamera

on menu_CloseCamera guideView
   put the right_View of guideView into rightView
   --
   put the camera_Name of rightView into cameraName
   cameraControlDelete cameraName
end menu_CloseCamera

getprop disabled_CloseCamera [guideView]
   return _CameraMissing (guideView)
end disabled_CloseCamera

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Guide | Camera | Menu")
end submenu_Dev
