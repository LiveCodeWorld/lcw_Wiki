script "Global_Server_Atopia_Tree_Menu"
--> MetaData
-
license: GPLv3
name: Global_Server_Atopia_Tree_Menu
type: controller
version: 0.1


--> Global | Server | Atopia | Tree | Menu
-
on menu_CheckBad
   put atopia_TestAndConstructServerDomainArray() into goodBadArray
   put goodBadArray ["good"] into goodArray
   put goodBadArray ["bad"] into badArray
   --
   _DisplayDomains goodArray, "atopia_ConstructServerDomainArray()"
   _DisplayDomains badArray, "badArray()"
end menu_CheckBad

on menu_StoreAtopiaDomainArray
   atopia_StoreServerDomainArray
   --
   display_AtopiaFolders "Stored Atopia"
end menu_StoreAtopiaDomainArray

on menu_FetchSaveDisplay
   put atopia_ConstructServerDomainArray() into serverArray
   atopia_StoreServerArray "Atopia Domains", serverArray
   put the result into putError
   --
   _DisplayDomains serverArray, "atopia_ConstructServerDomainArray()"
end menu_FetchSaveDisplay

command _DisplayDomains serverArray, pTitle
   put keys (serverArray) into domainNames
   url_SortDomainIndex domainNames
   --
   put "Global | Server | Atopia | Tree | Menu" into mTitle
   put "Global | Server | Atopia | Tree | Line | Menu" into mLineTitle
   display_Lines domainNames, pTitle, mTitle, mLineTitle
   return the result
end _DisplayDomains

on menu_DisplayIndex arrayView
   put the displayed_Array of arrayView into serverArray
   _DisplayDomains serverArray, "displayed_Array"
end menu_DisplayIndex

on _
end _

on menu_Delete
   put "hello" into someArray ["world"]
   atopia_StoreServerArray "Atopia Domains", someArray
   put the result
end menu_Delete

on menu_FetchAndDisplay
   put atopia_FetchServerArray ("Atopia Domains") into serverArray 
   _DisplayDomains serverArray, "atopia_FetchServerArray"
end menu_FetchAndDisplay

on menu_Save arrayView
   put the displayed_Array of arrayView into serverArray
   atopia_StoreServerArray "Atopia Domains", serverArray
   menu_Display
end menu_Save


--> Global | Server | Atopia | Tree | Menu | Props
-

--> Global | Server | Atopia | Tree | Menu | Disabled
-
