script "Global | Wiki | Local | Index | Line | Dev | Menu"
--> MetaData
-
license: GPLv3
name: Global | Wiki | Local | Index | Line | Dev | Menu
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


--> Global | Wiki | Local | Index | Line | Dev | Menu
-
on menu_CreateLocalTunnel displayView
   put the selected_Line of displayView into sDomain
   put _AskAstral (sDomain, "LocalExpose") into sDomain
   --
   put xterm_FindView() into xtermView
   tunnel_Create sDomain, "paste", xtermView
end menu_CreateLocalTunnel

on menu_Reveal displayView
   put ecoData_GetFarmFolder() into wikiFolder
   put the selected_Line of displayView into shortFolder
   put wikiFolder & shortFolder into longFolder
   --
   if there is a folder longFolder then
      finder_Reveal longFolder
   else
      breakpoint
   end if
end menu_Reveal


