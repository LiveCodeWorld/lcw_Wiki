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
   get the name of tObject
   if word 1 of tObject = "card" then
      breakpoint
   end if
   put the guide_View of tObject into guideView
   if exists (guideView) is false then
      breakpoint
      return empty
   end if
   --
   put guideView into LocalArray ["guideView"]
   put the left_View of guideView into leftView
   put leftView into LocalArray ["leftView"]
   
   if exists (the menubutton) then
      put the long id of the menubutton into mButton
      get the name of mButton
      breakpoint
      set the uOPN ["menu_Target"] of mButton to guideView
   end if
   
   return guideView
end menu_Target

getprop menu_CheckTarget [guideView]
   return exists (guideView)
end menu_CheckTarget

getprop submenu_Target [hName]
   return LocalArray ["leftView"]
end submenu_Target


--> Global | Guide | Left | Menu
-
on menu_ShowLeft.L guideView
   put the left_Visible of guideView into isLeft
   --
   set the left_Visible of guideView to (isLeft is false)
end menu_ShowLeft.L

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

on submenu_Ipfs
   return "Global | IPFS | Menu"
end submenu_Ipfs

-- on menu_LeftWiki guideView, rName
put env_ReadmeNameArray() into nameArray
put nameArray [rName] into tiddlyFile
--
put the left_View of guideView into leftView
display_TiddlyFile tiddlyFile, leftView, false
end menu_LeftWiki

getprop leftWiki_Params
   return LocalArray ["ReadeNames"]
end leftWiki_Params

-- on menu_RightWiki guideView, rName
put env_ReadmeNameArray() into nameArray
put nameArray [rName] into tiddlyFile
--
put the right_View of guideView into rightView
display_TiddlyFile tiddlyFile, rightView, false
end menu_RightWiki

getprop rightWiki_Params
   return LocalArray ["ReadeNames"]
end rightWiki_Params

on submenu_Dev
   return menu_DevTitle ("Global | Guide | Left | Menu")
end submenu_Dev
