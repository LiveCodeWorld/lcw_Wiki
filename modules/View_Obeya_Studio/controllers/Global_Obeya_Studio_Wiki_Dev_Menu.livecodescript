script "Global | Obeya | Studio | Wiki | Dev | Menu"
--> MetaData
-
license: GPLv3
name: Global | Obeya | Studio | Wiki | Dev | Menu
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


--> Global | Obeya | Studio | Wiki | Dev | Menu
-
on menu_ListLocalWikis
   display_LocalWikis
end menu_ListLocalWikis

on menu_ListDynadotDomains
   display_Dynadot
end menu_ListDynadotDomains

on menu_ListDynadotWikis displayView
   put lcw_Ask ("Which domain...", "outlandish.academy", "Dynadot Domain", displayView) into domainName
   display_DynadotWikis domainName, displayView, ""
end menu_ListDynadotWikis

on menu_Today browserView
   put wikiPage_TodaysActivity() into pageArray
   set the ghost_PageArray of browserView to pageArray
end menu_Today

on menu_EmptyFolders browserView
   put wikiPage_EmptyLocalFolders() into pageArray
   set the ghost_PageArray of browserView to pageArray
end menu_EmptyFolders

