script "Global | Wiki | Browser | Create | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Browser | Create | Menu
type: controller
version: 0.2

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray

--> Menu | Props
-  
getprop menu_CheckTarget [wikiView]
   put the wiki_Domain of wikiView into wikiDomain
   put wikiDomain into LocalArray ["wikiDomain"]
   return exists (wikiView)
end menu_CheckTarget

getprop disabled_CreateSitesPage
   return _IsLocalHost()
end disabled_CreateSitesPage

getprop disabled_CreateActivityPage
   return _IsLocalHost()
end disabled_CreateActivityPage

getprop disabled_CreateActivityIndex
   return _IsLocalHost()
end disabled_CreateActivityIndex

private function _IsLocalHost
   put LocalArray ["wikiDomain"] = "localhost" into isLocalHost
   return isLocalHost
end _IsLocalHost


--> Global | Wiki | Browser | Create | Menu
-
on menu_CreateNewWiki wikiView
   put the wiki_Domain of wikiView into wikiDomain
   --
   wikiServer_Create wikiDomain
   --
   put merge ("Created new local wiki '[[wikiDomain]]'. Use these tools to create some initial content.") into sMarkdown
   put pageArray_Construct ("Site Construction", sMarkdown) into pageArray
   pageArray_AddReferenceIndex pageArray, wikiDomain
   --
   set the ghost_PageArray of wikiView to pageArray
end menu_CreateNewWiki

on menu_CreateBrowserMenu wikiView
   ask_CreateModuleMenu "View|Wiki|Browser", wikiView, "Global | Wiki | Browser | Garden | Menu"
end menu_CreateBrowserMenu

on _
end _

on menu_CreateSitesPage wikiView
   put the wiki_Domain of wikiView into wikiDomain
   put wikiPage_SitesIndex (wikiDomain) into pageArray
   set the ghost_PageArray of wikiView to pageArray
end menu_CreateSitesPage

on menu_CreateActivityPage wikiView
   put the wiki_Domain of wikiView into wikiDomain
   put wikiPage_SitesActivity (wikiDomain) into pageArray
   set the ghost_PageArray of wikiView to pageArray
end menu_CreateActivityPage

on menu_CreateActivityIndex wikiView
   put the wiki_Domain of wikiView into wikiDomain
   put wikiPage_ActivityIndex (wikiDomain) into pageArray
   set the ghost_PageArray of wikiView to pageArray
end menu_CreateActivityIndex

private on __
end __

on menu_DraftWelcomeVisitors wikiView
   put the wiki_Domain of wikiView into wikiDomain
   --
   put url_GetTLD (wikiDomain) into tldDomain
   put tldDomain into pageTitle
   replace "." with space in pageTitle
   put text_InitialCaps (pageTitle) into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   --
   put wikiDialogue_Get (pageSlug, tldDomain, "welcome-visitors-dialogue", "Welcome Visitors") into pageArray
   --
   set the ghost_PageArray of wikiView to pageArray
end menu_DraftWelcomeVisitors

on menu_DraftLocalActivity wikiView
   # First update the index from folders
   wikiGarden_Update
   
   # Construct Activity from all non-empty folders
   put wikiPage_LocalActivity() into pageArray
   --
   set the ghost_PageArray of wikiView to pageArray
end menu_DraftLocalActivity

private on ___
end ___

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Browser | Create | Menu")
end submenu_Dev
