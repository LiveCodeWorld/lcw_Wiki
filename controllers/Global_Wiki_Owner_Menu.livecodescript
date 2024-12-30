script "Global | Wiki | Owner | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Owner | Menu
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

private command _DeconstructTitle dView, @tldDomian, @tldLocalHostName
   get the title_Text of dView
   set the itemdelimiter to "@"
   put item 1 of it into tldDomian
   put item 2 of it into tldLocalHostName
end _DeconstructTitle


--> Global | Wiki | Owner | Menu
-
on menu_WriteOwnerJson dView
   _DeconstructTitle dView, wikiDomain, piLocalHost
   lcw_Answer "Write displayed owner.json to [[var]] on [[afds]]", dView, wikiDomain, piLocalHost
   --
   put the displayed_Array of dView into ownerData
   wikiPi_StoreOwnerData wikiDomain, ownerData, piLocalHost
   put the result into scpResult
   if scpResult is not empty then
      put scpResult
      lcw_AnswerWarning scpResult, dView
   end if
end menu_WriteOwnerJson

on menu_DisplayFriendlyDefault dView
   put wikiServer_FriendlyOwnerData() into ownerData
   set the displayed_Data of dView to ownerData
end menu_DisplayFriendlyDefault

on menu_SetFriendlyDefault dView
   _DeconstructTitle dView, wikiDomain, piLocalHost
   lcw_Answer "Set owner.json for [[var]]", dView, wikiDomain
   --
   wikiServer_SetFriendlyData wikiDomain
   --
   menu_Refresh dView
   wikiServer_RestartNode
end menu_SetFriendlyDefault

private on _
end _

on menu_PiServer dView
   _DeconstructTitle dView, wikiDomain, piLocalHost
   --
   if piServer_IsRunning (piLocalHost) is true then
      piServer_Stop piLocalHost
   else
      piServer_Start piLocalHost
   end if
   if the result is not empty then
      breakpoint
   end if
end menu_PiServer

getprop checked_PiServer [dView]
   _DeconstructTitle dView, wikiDomain, piLocalHost
   --
   put piServer_IsRunning (piLocalHost) into serverStatus
   return serverStatus
end checked_PiServer

on menu_RestartPiServer dView
   _DeconstructTitle dView, wikiDomain, piLocalHost
   --
   piServer_Restart piLocalHost
   if the result is not empty then
      breakpoint
   end if
end menu_RestartPiServer

on menu_PiServerStatus dView
   _DeconstructTitle dView, wikiDomain, piLocalHost
   --
   put piServer_Status (piLocalHost) into serverStatus
   --
   display_Text serverStatus, "systemctl --user status federated-wiki", piLocalHost
end menu_PiServerStatus

private on __
end __

on menu_ExportDisplayOwnerData dView
   _DeconstructTitle dView, wikiDomain, piLocalHost
   --
   breakpoint
   put the displayed_Data of dView into ownerData
   wikiServer_SetOwnerData wikiDomain, ownerData
end menu_ExportDisplayOwnerData

on menu_Refresh dView
   _DeconstructTitle dView, wikiDomain, piLocalHost
   --
   display_WikiOwner wikiDomain, dView
end menu_Refresh

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Owner | Menu")
end submenu_Dev
