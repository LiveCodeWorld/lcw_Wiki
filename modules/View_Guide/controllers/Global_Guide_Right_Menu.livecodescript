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
   if exists (guideView) is false then
      breakpoint
      return empty
   end if
   --
   put guideView into LocalArray ["guideView"]
   put the right_View of guideView into LocalArray ["rightView"]
   return guideView
end menu_Target

getprop menu_CheckTarget [guideView]
   return exists (guideView)
end menu_CheckTarget

getprop submenu_Target [hName]
   return LocalArray ["rightView"]
end submenu_Target


--> Global | Guide | Right | Menu
-
on menu_ShowRight.R guideView
   put the right_Visible of guideView into isRight
   --
   set the right_Visible of guideView to (isRight is false)
end menu_ShowRight.R

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

on menu_TiddlyTemplate guideView, shortFile
   put tiddly_TemplateFile (shortFile) into tFile
   --
   put the right_View of guideView into rightView
   display_TiddlyFile tFile, rightView, false
end menu_TiddlyTemplate

getprop tiddlyTemplate_Params
   put tiddly_ListShortTemplates() into shortFiles
   filter shortFiles with "*.html"
   return shortFiles
end tiddlyTemplate_Params

private on __
end __

on menu_Fedwiki guideView
   put the right_View of guideView into rightView
   tiddly_SetBehavior rightView, "wiki"
   --
   set the browser_URL of rightView to "http://code.astralship.wiki"
end menu_Fedwiki

on menu_IpfsAdmin guideView
   put the right_View of guideView into rightView
   set the browser_URL of rightView to "http://localhost:5001/webui"
end menu_IpfsAdmin

on menu_DisplayIpfsCatPicture guideView, rName
   put the right_View of guideView into rightView
   
   put "http://127.0.0.1:8080/ipfs/QmW2WQi7j6c7UgJTarActp7tDNikE4B2qXtFCfLPdsgaTQ/cat.jpg" into ipfsURL
   set the browser_URL of rightView to ipfsURL
end menu_DisplayIpfsCatPicture

on submenu_Ipfs
   return "Global | IPFS | Menu"
end submenu_Ipfs

on submenu_Dev
   return menu_DevTitle ("Global | Guide | Right | Menu")
end submenu_Dev
