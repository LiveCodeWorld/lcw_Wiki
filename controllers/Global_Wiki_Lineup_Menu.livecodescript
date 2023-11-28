script "Global | Wiki | Lineup | Menu"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: Global | Wiki | Lineup | Menu
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
   put the display_View of tObject into displayView
   put the displayed_Data of displayView into LocalArray ["dataArray"]
   --
   return displayView
end menu_Target

getprop launchPage_Params [displayView]
   -- put the title_Text of displayView into wikiDomain
   put LocalArray ["dataArray"] into lineUpArray
   put fedwiki_GetLineupSlugs (lineUpArray) into pageSlugs
   return pageSlugs
end launchPage_Params


--> Global | Wiki | Lineup | Menu
-
on menu_LaunchLineup displayView
   put the title_Text of displayView into wikiDomain
   put the displayed_Array of displayView into lineUpArray
   --
   put fedwiki_ConstructLineUpURL (lineUpArray, wikiDomain) into lineUpURL
   launch url lineUpURL
end menu_LaunchLineup

on menu_LaunchPage displayView, pageSlug
   put the title_Text of displayView into wikiDomain
   put fedwiki_ConstructUrlFromSlug (wikiDomain, pageSlug) into wikiURL
   launch url wikiURL
end menu_LaunchPage

on _
end _

on submenu_WikiDomain
   return "Global | Subdomain | Tools | Menu"
end submenu_WikiDomain

on submenu_Roster
   return "Global | Server | Roster | Menu"
end submenu_Roster

on submenu_Dynadot
   return "Global | Dynadot | Menu"
end submenu_Dynadot

on _
end _

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Dev | Menu
-
on menu_SetDefaultHome displayView, pageTitle
   breakpoint
   -- put atopia_FetchHomePageArray (wikiDomain) into pageArray
   
   put "welcome.fedwiki.org" into wikiDomain
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   --
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   if pageArray is not an array then
      put "Cannot locate stored home page [[pageSlug]]"
      lcw_AnswerWarning someQuestion
   end if
   pageArray_StripJournal pageArray
   pageArray_AddFork pageArray, "proto.institute,fedwiki.org,orientation.fedwiki.org"
   --
   pageArray_Set wikiDomain, "welcome-visitors", pageArray
   -- atopia_StoreDefaultHomePageArray pageArray
   --
   return the result
end menu_SetDefaultHome


--> Deps
-
