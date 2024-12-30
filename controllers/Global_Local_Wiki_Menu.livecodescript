script "Global | Local | Wiki | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Local | Wiki | Menu
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


--> Global | Local | Wiki | Menu
-
on menu_TopLevelDomains dView
   put the displayed_Index of dView into localDomains
   put the title_Text of dView into sTitle
   if sTitle = "Top Level Domains" then
      -- set the displayed_Index ["Farm"] of dView to topLevelDomains
      display_WikiFarm
   else
      -- put url_ListTopLevelDomains (localDomains) into topLevelDomains
      -- set the displayed_Index ["Top Level Domains"] of dView to topLevelDomains
      display_WikiFarm true, dView
   end if
end menu_TopLevelDomains

getprop checked_TopLevelDomains [dview]
   put the title_Text of dView into sTitle
   return sTitle = "Top Level Domains"
end checked_TopLevelDomains

on menu_FilterLocalDomains dView
   put lcw_Ask ("Filter local dommains using:", "*democracy*", dView) into sFilter
   --
   put the displayed_Index of dView into dNames
   filter dNames with sFilter
   set the displayed_Index [sFilter] of dView to dNames
end menu_FilterLocalDomains

private on _
end _

on menu_DisplayPiholeAdmin
   display_PiholeAdmin
end menu_DisplayPiholeAdmin

on menu_Refresh dView
   put the title_Text of dView = "Top Level Domains" into isTopLevel
   display_WikiFarm dView, isTopLevel
end menu_Refresh

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Local | Wiki | Menu")
end submenu_Dev
