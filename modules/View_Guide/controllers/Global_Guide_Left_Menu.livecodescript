script "Global | Guide | Left | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Guide | Left | Menu
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
   put the guide_View of tObject into guideView
   return guideView
end menu_Target

getprop menu_CheckTarget [guideView]
   return exists (guideView)
end menu_CheckTarget


--> Global | Guide | Left | Menu
-
on menu_ShowLeft guideView
   put the left_Visible of guideView into isLeft
   --
   set the left_Visible of guideView to (isLeft is false)
end menu_ShowLeft

getprop checked_ShowLeft [guideView]
   put the left_Visible of guideView into isLeft
   return isLeft
end checked_ShowLeft

getprop disabled_ShowLeft [guideView]
   put the right_Visible of guideView into isRight
   return (isRight is false)
end disabled_ShowLeft

private on _
end _

on menu_OpenReadme guideView, rName
   put the left_View of guideView into leftView
   --
   put LocalArray ["nameArray"] into nameArray
   put nameArray [rName] into readMeFile
   --
   display_TiddlyFile readMeFile, leftView, false
end menu_OpenReadme

getprop openReadme_Params
   put env_ReadmeNameArray() into nameArray
   put nameArray into LocalArray ["nameArray"]
   put keys (nameArray) into rNames
   sort rNames
   return rNames
end openReadme_Params

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Guide | Left | Menu")
end submenu_Dev

