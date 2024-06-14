script "Global | Wiki | Menu"
--> MetaData
-
license: GPLv3
name: Global | Wiki | Menu
type: controller
version: 0.5


--> Menu | Props
-
local LocalArray

getprop menu_Target [tObject]   
   put the browser_View of tObject into browserView
   if exists (browserView) then
      return browserView
   else
      put line 1 of display_List ("View|Obeya|Studio") into browserView
      if exists (browserView) then return browserView
      return empty
   end if
end menu_Target

-- getprop menu_CheckTarget [browserView]
try
   put wiki_NodeServerIsRunning() into LocalArray ["wikiStarted"]
   return exists (browserView)
catch e
   return false
end try
end menu_CheckTarget


--> Global | Wiki | Menu
-
on menu_DisplayCaddyTools
   display_CaddyTools
end menu_DisplayCaddyTools

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Menu")
end submenu_Dev
