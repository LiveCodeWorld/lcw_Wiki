script "Global | Tunnel | Install | Dev | Menu"
--> MetaData
-
license: GPLv3
name: Global | Tunnel | Install | Dev | Menu
type: controller
author: David Bovill
version: 0.1

/*
Here you can describe this developer menu.
Full help text should be provided on the linked wiki.

Consider improving by creating with same menu_Target as no-developer menu is is based on.
*/

--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_Target [tObject]
   -- return display_MenuTarget(tObject)
   return the display_View of tObject
end menu_Target

getprop menu_CheckTarget [mTarget]
   return exists (mTarget)
end menu_CheckTarget


--> Global | Tunnel | Install | Dev | Menu
-
on menu_CreateCertificate
   put xterm_FindView() into xtermView
   put LocalArray ["sDomain"] into sDomain
   put lcw_Ask ("Domin name to verify...", sDomain, "LocalExpose", xtermView) into sDomain
   --
   put "loclx domain letsencrypt --domain" && sDomain into someShell
   --
   shell_Do someShell, "paste", xtermView
end menu_CreateCertificate

private on _
end _

on menu_Ngrok
   put ngrok_ListProcessIds() into pIDs
   if pIDs is empty then
      ngrok_Redirect "thought.garden"
   else
      ngrok_Kill pIDs
   end if
end menu_Ngrok

