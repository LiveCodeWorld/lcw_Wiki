script "Global | Wiki | Local | Index | Dev | Menu"
--> MetaData
-
license: GPLv3
name: Global | Wiki | Local | Index | Dev | Menu
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


--> Global | Wiki | Local | Index | Dev | Menu
-
on menu_ListLocalSymlinkedWikis dView
   display_LocalSymWikis dView
end menu_ListLocalSymlinkedWikis

on menu_ListLocalNonSymWikis dView
   display_LocalWikis dView, "Non Sym-Linked"
end menu_ListLocalNonSymWikis

private on _
end _

on menu_RevealWikiFolder
   put wiki_RootFolder() into wikiFolder
   finder_Reveal wikiFolder
end menu_RevealWikiFolder

on menu_DisplayFederationChanges
   display_WardsRecentDomains
end menu_DisplayFederationChanges
