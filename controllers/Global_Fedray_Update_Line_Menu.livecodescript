script "Global | Fedray | Update | Line | Menu"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: Global | Fedray | Update | Line | Menu
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
   -- called first
   pass menu_Target
end menu_Target



--> Global | Fedray | Update | Line | Menu
-
on insert_Menu
   return "Global | Atopia | Build | Line | Menu"
end insert_Menu

on _
end _

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Dev | Menu
-
on menu_Test displayView
   put the atopia_DomainArray of displayView into atopiaFedray
   put the federation_DomainArray of displayView into fedray
   --
   put the selected_Line of displayView into wikiDomain
   put fedray [wikiDomain] into wikiDomainArray
   --
   display_Data wikiDomainArray, wikiDomain, "wikiDomainArray"
   --
   if fedray_IsAtopia (wikiDomain, fedray) then
      put atopiaFedray [wikiDomain] into testWikiDomainArray
      if testWikiDomainArray = wikiDomainArray then
      else
         display_Data wikiDomainArray, wikiDomain, "Atopia Error"
      end if
   end if
end menu_Test

on menu_TrashWiki displayView
   put the selected_Line of displayView into wikiDomain
   lcw_Answer "Are you sure you want to trash the wiki '[[wikiDomain]]'?", displayView, wikiDomain
   --
   atopia_MoveToTrash wikiDomain
   --
   put the atopia_DomainArray of displayView into atopiaFedray
   put the federation_DomainArray of displayView into fedray
   --
   delete variable atopiaFedray [wikiDomain]
   delete variable fedray [wikiDomain]
   --
   set the atopia_DomainArray of displayView to atopiaFedray
   set the federation_DomainArray of displayView to fedray
   --
   set the deleted_Line of displayView to wikiDomain
end menu_TrashWiki


--> Deps
-
