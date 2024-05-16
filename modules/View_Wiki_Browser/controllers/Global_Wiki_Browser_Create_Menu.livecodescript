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
getprop menu_Target [tObject]
   put the browser_View of tObject into wikiView
   if exists (wikiView) is false then
      put the display_View of tObject into dView
      put the displayed_Object of dView into wikiView
      if exists (wikiView) is false then
         return empty
      end if
   end if
   
   put the wiki_Domain of wikiView into wikiDomain
   put wikiDomain into LocalArray ["wikiDomain"]
   return wikiView
end menu_Target

getprop menu_CheckTarget [dView]
   return exists (dView)
end menu_CheckTarget

getprop createGardenPage_Params
   return wikiGarden_ListUniqueNames()
end createGardenPage_Params

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

getprop checked_AddOwnerJson [wikiView]
   put the wiki_Domain of wikiView into wikiDomain
   return wikiServer_OwnerExists (wikiDomain)
end checked_AddOwnerJson

getprop disabled_AddOwnerJson [wikiView]
   put the wiki_Domain of wikiView into wikiDomain
   switch wikiDomain
      case "localhost"
         return "delete"
      default
         return false
   end switch
end disabled_AddOwnerJson


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
   wikiGarden_UpdateEcoData
   
   # Construct Activity from all non-empty folders
   put wikiPage_LocalActivity() into pageArray
   --
   set the ghost_PageArray of wikiView to pageArray
end menu_DraftLocalActivity

private on ___
end ___

on menu_AddOwnerJson wikiView
   put the wiki_Domain of wikiView into wikiDomain
   --
   if wikiServer_OwnerExists (wikiDomain) then
      display_WikiOwner wikiDomain
   else
      wikiServer_SetFriendlyData wikiDomain
   end if
end menu_AddOwnerJson

on menu_CreateGardenPage wikiView, gardenName
   put the wiki_Domain of wikiView into wikiDomain
   --
   put wikiPage_GardenActivity (gardenName, wikiDomain) into pageArray
   --
   set the ghost_PageArray of wikiView to pageArray
end menu_CreateGardenPage

private on ____
end ____

on menu_MoveWiki browserView
   put the wiki_Domain of browserView into wikiDomain
   put wikiFolder_FromRouter (wikiDomain) into oldWikiFolder
   
   put wikiGarden_GetEcoFolder() into oldEcoFolder
   put oldWikiFolder into oldEcoFolder
   set the itemdelimiter to slash
   delete item -1 of oldEcoFolder
   
   answer folder "Select a garden folder for the new farm..." with oldEcoFolder as sheet
   if it is empty then exit to top
   put it into newGardenFolder
   put slash after newGardenFolder
   --
   put newGardenFolder into newEcoFolder
   delete item -1 of newEcoFolder
   
   # Old Wiki Folder
   put newGardenFolder & wikiDomain & slash into newWikiFolder
   
   # Move
   revMoveFolder oldWikiFolder, newWikiFolder
   
   # ReIndex
   if folder_Within (ecoFolder, ecoFolders) is true then
      wikiGarden_Init true
   else
      wikiGarden_AddEcoFolder newEcoFolder
   end if
end menu_MoveWiki

on menu_MoveDomains wikiView, gardenName
   # Domains to Move
   put the wiki_Domain of wikiView into wikiDomain
   put url_GetTLD (wikiDomain) into tldDomain
   --
   put wikiGarden_ListAllDomains (tldDomain) into domainsToMove
   
   put wikiGarden_FindGardenFolder (gardenName) into toGarden
   repeat for each line wikiDomain in domainsToMove
      put toGarden & wikiDomain & slash into toFolder
      put wikiFolder_FromRouter (wikiDomain) into fromFolder
      --
      if there is not a folder fromFolder then next repeat
      if fromFolder = toFolder then next repeat
      if there is a folder toFolder then next repeat
      
      revMoveFolder fromFolder, toFolder
   end repeat
   
   wikiGarden_Init true
end menu_MoveDomains

private on _____
end _____

on menu_SetGardenEcoFolder
   put wikiFarm_EarthFolder() into rootFolder
   answer folder "Choose a Garden eco-folder for your Gardens..." with rootFolder as sheet
   if it is empty then exit to top
   put it into ecoFolder
   
   wikiGarden_AddEcoFolder ecoFolder
   --
   display_GardenEcodata
   finder_Reveal ecoFolder
end menu_SetGardenEcoFolder

on menu_UpdateGardenEcoData
   wikiGarden_UpdateEcoData
   --
   display_GardenEcodata
end menu_UpdateGardenEcoData

on menu_DisplayGardenEcoData
   display_GardenEcodata
end menu_DisplayGardenEcoData

on menu_DisplayWikiRouterArray
   display_WikiRouterArray
end menu_DisplayWikiRouterArray

private on ______
end ______

on menu_SetWikiFarmFolder
   put wikiFarm_EarthFolder() into rootFolder
   answer folder "Choose a default folder for wiki..." with rootFolder as sheet
   if it is empty then exit to top
   put it into newFarmFolder
   
   wikiFarm_SetFolder newFarmFolder
   wikiGarden_StoreCachedEcoData
   --
   display_GardenEcodata
   finder_Reveal newRootFolder
end menu_SetWikiFarmFolder

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Browser | Create | Menu")
end submenu_Dev
