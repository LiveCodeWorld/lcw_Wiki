script "Global | Wiki | Git | Dev | Menu"
--> MetaData
-
license: GPLv3
name: Global | Wiki | Git | Dev | Menu
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


--> Global | Wiki | Git | Dev | Menu
-
on menu_CheckCnames dView   
   wiki_LoadTunnel
   --
   set the itemdelimiter to "."
   put the displayed_Index of dView into gitWikiDomains
   repeat for each line gitWikiDomain in gitWikiDomains
      put gitwiki_CheckCnameValue (gitWikiDomain, gitWikiDomain, true, false) into someColour
      --
      display_Spin gitWikiDomain, dView, someColour
   end repeat
end menu_CheckCnames

on menu_CheckDisplayed dView
   set the itemdelimiter to "."
   put the displayed_Index of dView into gitWikiDomains
   repeat for each line wikiDomain in gitWikiDomains
      put wiki_CheckFolderColour (wikiDomain) into sColour
      --
      display_Spin wikiDomain, dView, sColour
   end repeat
end menu_CheckDisplayed

private on _
end _

on menu_DisplayNumbers dView
   put the displayed_Index of dView into gitWikiDomains
   put gitwiki_RootFolder() into gitwikiRootFolder
   --
   repeat for each line gitWikiDomain in gitWikiDomains
      display_Spin gitWikiDomain, dView, "green"
      --
      put gitwikiRootFolder & gitWikiDomain into gitWikiFolder
      --
      put symlink_Destination (gitWikiFolder) into destFolder
      switch destFolder
         case empty
            -- Not a symlink
            put wiki_NumberOfpages (gitWikiFolder) into numOfPages
            switch
               case numOfPages is empty
               case numOfPages < 1
                  breakpoint
                  revDeleteFolder gitWikiFolder
                  break
               default
                  -- lots of pages
                  put numOfPages && gitWikiDomain & CR after numberIndex
            end switch
            break
         case wikiRootFolder
            put wiki_NumberOfpages (gitWikiFolder) into numOfPages
            switch
               case numOfPages is empty
                  breakpoint
               case numOfPages < 1
                  breakpoint -- trash?
                  symlink_Delete gitWikiFolder
                  break
               default
                  -- lots of pages
                  put numOfPages && gitWikiDomain & CR after numberIndex
            end switch
            break
         default
            breakpoint
            if there is not a folder destFolder then
               breakpoint
               symlink_Delete gitWikiFolder
            end if
      end switch 
      
   end repeat
   delete char -1 of numberIndex
   --
   sort numeric numberIndex by word 1 of each
   set the displayed_Index of dView to numberIndex
end menu_DisplayNumbers

on menu_SymlinkAndAddHost dView
   wiki_LoadTunnel
   --
   set the itemdelimiter to "."
   put the displayed_Index of dView into gitWikiDomains
   repeat for each line gitWikiDomain in gitWikiDomains
      -- put gitwiki_CheckCnameValue (gitWikiDomain, pDynSubDomain, pColour, pLoad)
      gitwiki_SymlinksAndAddHost gitWikiDomain, false
      display_Spin gitWikiDomain, dView, "green"
   end repeat
   --
   hosts_Add gitWikiDomains
end menu_SymlinkAndAddHost

on menu_AddToEtcHosts dView
   put the displayed_Index of dView into gitWikiDomains
   hosts_Add gitWikiDomains
end menu_AddToEtcHosts
