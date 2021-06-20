script "Global | Fedray | Update | Menu"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: Global | Fedray | Update | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray


--> Menu | Props
-
on mDoubleUp_WikiDomain fieldObject, wikiDomain
   put the display_View of fieldObject into displayView
   put the federation_DomainArray of displayView into fedray
   put fedray [wikiDomain] into wikiDomainArray
   --
   display_Data wikiDomainArray, wikiDomain, "Fedray WikiDomainArray"
   --
   fedwiki_Launch wikiDomain
end mDoubleUp_WikiDomain

getprop menu_Target [tObject]
   -- called first
   put the display_View of tObject into displayView
   put the atopia_DomainArray of displayView into LocalArray ["atopiaFedray"]
   put the federation_DomainArray of displayView into LocalArray ["fedray"]
   --
   pass menu_Target
end menu_Target


--> Global | Fedray | Update | Menu
-
on menu_AddNewFederationDomains displayView
   put the atopia_DomainArray of displayView into atopiaFedray
   put the federation_DomainArray of displayView into fedray
   put the fedray_LoadResultArray of displayView into loadResultArray
   --
   put loadResultArray ["new"] into newDomainArray
   put digitalocean_FetchDropletIP ("Atopia") into atopiaIP
   put atopia_FetchTreeWelcomeInfoArray() into treeFileArray
   --
   repeat for each key wikiDomain in newDomainArray
      display_Spin wikiDomain, displayView, "dark green"
      --
      put newDomainArray [wikiDomain]["sitemapArray"] into sitemapArray -- all have sitemapArray
      --
      put fedray_FetchNewWikiDomainArray (wikiDomain, sitemapArray, atopiaIP, treeFileArray) into wikiDomainArray
      --
      put wikiDomainArray into fedray [wikiDomain]
      --
      put wikiDomainArray ["ipAddress"] into testIP
      if testIP = atopiaIP then
         put wikiDomainArray into atopiaFedray [wikiDomain]
      end if
   end repeat
   --
   set the federation_DomainArray of displayView to fedray
   set the atopia_DomainArray of displayView to atopiaFedray
end menu_AddNewFederationDomains

on menu_UpdateFedraysAndRoster displayView
   lcw_Answer "Store the Atopia domain array, roster and federation fedray?", displayView
   --
   put the atopia_DomainArray of displayView into atopiaFedray
   put the federation_DomainArray of displayView into fedray
   --
   atopia_UpdateDomainArrayAndRoster atopiaFedray
   fedray_StoreModel fedray
end menu_UpdateFedraysAndRoster

on _
end _

on menu_UpdateCreationInfo displayView
   menu_UpdateOwnerNames displayView
   menu_UpdateOwnerNames displayView
end menu_UpdateCreationInfo

on menu_UpdateOwnerNames displayView
   put the displayed_Index of displayView into wikiDomains
   --
   repeat for each line wikiDomain in wikiDomains
      display_Spin wikiDomain, displayView, "orange"
      --
      put fedwiki_FetchOwnerName (wikiDomain) into ownerName
      --
      put ownerName into LocalArray ["atopiaFedray"][wikiDomain]["owner"]
      put ownerName into LocalArray ["fedray"][wikiDomain]["owner"]
   end repeat
end menu_UpdateOwnerNames

on menu_UpdateOwnerNames displayView
   put the displayed_Index of displayView into wikiDomains
   --
   repeat for each line wikiDomain in wikiDomains
      display_Spin wikiDomain, displayView, "blue"
      --
      put fedwiki_FetchSiteCreationDate (wikiDomain) into wikiCreationDate
      --
      put wikiCreationDate into LocalArray ["atopiaFedray"][wikiDomain]["created"]
      put wikiCreationDate into LocalArray ["fedray"][wikiDomain]["created"]
   end repeat
end menu_UpdateOwnerNames

on _
end _

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Dev | Menu
-
on menu_DisplayAtopiaDomainArray displayView
   put LocalArray ["atopiaFedray"] into atopiaFedray
   --
   display_Data atopiaFedray, "atopiaFedray"
end menu_DisplayAtopiaDomainArray

on menu_DisplayFedray
   put LocalArray ["fedray"] into fedray
   --
   display_Data fedray, "fedray"
end menu_DisplayFedray

on menu_DisplayLoadResult displayView
   -- put fedray_GetLoadResultArray() into loadResultArray
   put the fedray_LoadResultArray of displayView into loadResultArray
   --
   display_Data loadResultArray, "loadResultArray"
end menu_DisplayLoadResult


--> Deps
-
