script "Global | Guide | Right | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Guide | Right | Menu
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


--> Global | Guide | Right | Menu
-
on menu_ShowRight guideView
   put the right_Visible of guideView into isRight
   --
   set the right_Visible of guideView to (isRight is false)
end menu_ShowRight

getprop checked_ShowRight [guideView]
   put the right_Visible of guideView into isRight
   return isRight
end checked_ShowRight

getprop disabled_ShowRight [guideView]
   put the left_Visible of guideView into isLeft
   return (isLeft is false)
end disabled_ShowRight

private on _
end _

on menu_OpenReadme guideView, rName
   put the right_View of guideView into rightView
   --
   -- put env_ReadmeNameArray() into nameArray
   put LocalArray ["nameArray"] into nameArray
   put nameArray [rName] into readMeFile
   --
   display_TiddlyFile readMeFile, rightView, false
end menu_OpenReadme

getprop openReadme_Params
   put env_ReadmeNameArray() into nameArray
   put nameArray into LocalArray ["nameArray"]
   put keys (nameArray) into rNames
   sort rNames
   return rNames
end openReadme_Params

on submenu_TiddlyPlugins
   return "Global | TiddlyWiki | Plugins | Menu"
end submenu_TiddlyPlugins

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Guide | Right | Menu")
end submenu_Dev
