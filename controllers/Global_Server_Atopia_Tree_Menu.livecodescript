script "Global_Server_Atopia_Tree_Menu"
--> MetaData
-
license: GPLv3
name: Global_Server_Atopia_Tree_Menu
type: controller
version: 0.1

--> Deps
-
function atopia_ConstructServerDomainArray pAtopiaDomains
   breakpoint
   -- return in Ward-compatible format
   put atopia_TestAndConstructServerDomainArray (pAtopiaDomains) into goodBadArray
   put goodBadArray ["good"] into newServerDomainArray
   return newServerDomainArray
end atopia_ConstructServerDomainArray

function atopia_TestAndConstructServerDomainArray pAtopiaDomains
   breakpoint
   if pAtopiaDomains is empty then
      set the cursor to watch
      put atopia_FetchFolders() into pAtopiaDomains
   end if
   --
   url_SortDomainIndex pAtopiaDomains
   repeat for each line atopiaDomain in pAtopiaDomains
      set the cursor to busy
      put fedwiki_FetchSitemapArray (atopiaDomain) into sitemapArray
      if sitemapArray is not an array then
         put true into goodBadArray ["bad"][atopiaDomain] 
         next repeat
      end if
      put keys (sitemapArray) into pageSlugs
      put the number of lines of pageSlugs into pageNum
      put pageNum into goodBadArray ["good"][atopiaDomain]["pages"]
   end repeat
   return goodBadArray
end atopia_TestAndConstructServerDomainArray



--> Global | Server | Atopia | Tree | Menu
-
on menu_CheckBad
   put atopia_TestAndConstructServerDomainArray() into goodBadArray
   put goodBadArray ["good"] into goodArray
   put goodBadArray ["bad"] into badArray
   --
   _DisplayDomains goodArray, "goodArray"
   _DisplayDomains badArray, "badArray"
end menu_CheckBad

on menu_StoreAtopiaDomainArray
   put atopia_ConstructServerDomainArray() into domainArray
   if domainArray is not an array then
      breakpoint
      return "Error, domainArray is not an array"
   end if
   --
   atopia_StoreFedray domainArray
   --
   display_AtopiaDomains "Stored Atopia"
end menu_StoreAtopiaDomainArray

on _
end _

on menu_FetchAndDisplay
   put atopia_FetchFedray() into serverArray 
   _DisplayDomains serverArray, "atopia_FetchFedray"
end menu_FetchAndDisplay

on menu_Save arrayView
   put the displayed_Array of arrayView into domainArray
   atopia_StoreFedray domainArray
end menu_Save


--> Global | Server | Atopia | Tree | Menu | Props
-

--> Global | Server | Atopia | Tree | Menu | Disabled
-
command _DisplayDomains serverArray, pTitle
   put keys (serverArray) into domainNames
   url_SortDomainIndex domainNames
   --
   put "Global | Server | Atopia | Tree | Menu" into mTitle
   put "Global | Server | Atopia | Tree | Line | Menu" into mLineTitle
   display_Lines domainNames, pTitle, mTitle, mLineTitle
   return the result
end _DisplayDomains
