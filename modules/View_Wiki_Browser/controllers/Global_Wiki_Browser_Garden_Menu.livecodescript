script "Global | Wiki | Browser | Garden | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Browser | Garden | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_CheckTarget [wikiView]
   put wikiGarden_ListUniqueNames() into LocalArray ["gardenNames"]
   return exists (wikiView)
end menu_CheckTarget

getprop startNodeGarden_Param [wikiView]
   return wikiFarm_GardenName()
end startNodeGarden_Param

getprop startNodeGarden_Params
   return "Farm,-" &CR& LocalArray ["gardenNames"]
end startNodeGarden_Params

getprop moveToGarden_Params
   return LocalArray ["gardenNames"]
end moveToGarden_Params

getprop moveSubDomains_Params
   return LocalArray ["gardenNames"]
end moveSubDomains_Params

getprop createGardenPage_Params
   return wikiGarden_ListUniqueNames()
end createGardenPage_Params

getprop backToFarm_Params
   return wikiGarden_ListUniqueNames()
end backToFarm_Params

getprop restoreGarden_Params
   return wikiGarden_ListUniqueNames()
end restoreGarden_Params

getprop disabled_RestoreGarden   
   return true
end disabled_RestoreGarden


--> Global | Wiki | Browser | Garden | Menu
-
on menu_StartNodeGarden wikiView, gardenName
   wikiServer_StartNodeGarden gardenName
end menu_StartNodeGarden

on menu_BackToFarm wikiView, gardenName
   put wikiGarden_ListShortFolders (gardenName) into shortWikiFolders
   --
   put wikiFarm_GetFolder() into farmFolder
   if there is not a folder farmFolder then
      put farmFolder
      lcw_AnswerWarning "Cannot locate farm folder!", wikiView
   end if
   --
   repeat for each line wikiDomain in shortWikiFolders
      set the cursor to busy
      put wikiFolder_FromRouter (wikiDomain) into gardenWikiFolder
      --
      switch
         case gardenWikiFolder = farmFolder
         case there is not a folder gardenWikiFolder
            next repeat
         default
            # Check Garden Folder
            put wikiFolder_HasNoPages (gardenWikiFolder, 0) into gardenEmpty
            if gardenEmpty is true then
               put wikiFolder_HasNoPages (gardenWikiFolder, 0) into gardenEmpty
               revDeleteFolder gardenWikiFolder                     
               next repeat
            end if
            
            # Check destination farmFolder
            put farmFolder & wikiDomain & slash into farmWikiFolder
            if there is a folder farmWikiFolder then
               put wikiFolder_HasNoPages (farmWikiFolder, 0) into farmEmpty
               --
               if farmEmpty is true then
                  revDeleteFolder farmWikiFolder                     
                  revMoveFolder gardenWikiFolder, farmWikiFolder
               else
                  lcw_Answer "Garden and Farm both have pages!"
                  finder_Reveal gardenWikiFolder
                  finder_Reveal farmWikiFolder
                  --
                  next repeat
               end if
            else
               revMoveFolder gardenWikiFolder, farmWikiFolder
            end if
      end switch
   end repeat
   
   wikiGarden_Update
   wikiGarden_Init
end menu_BackToFarm

on menu_RestoreGarden wikiView, gardenName
   put wikiPreference_ListGardenDomains (gardenName) into sGardenDomains
   --
end menu_RestoreGarden

private on _
end _

on menu_DraftGardenPreferencePage wikiView
   put wikiPage_LocalPreference() into pageArray
   set the ghost_PageArray of wikiView to pageArray
end menu_DraftGardenPreferencePage

on menu_DraftGardenPage wikiView, gardenName
   put the wiki_Domain of wikiView into wikiDomain
   --
   put wikiPage_GardenActivity (gardenName, wikiDomain) into pageArray
   --
   set the ghost_PageArray of wikiView to pageArray
end menu_DraftGardenPage

private on __
end __

on menu_MoveToGarden browserView, gardenName
   put the wiki_Domain of browserView into wikiDomain
   put wikiFolder_FromRouter (wikiDomain) into oldWikiFolder
   put wikiGarden_FindGardenFolder (gardenName) into newGardenFolder
   
   # Old Wiki Folder
   put newGardenFolder & wikiDomain & slash into newWikiFolder
   
   # Move
   revMoveFolder oldWikiFolder, newWikiFolder
   wikiGarden_Init true
end menu_MoveToGarden

on menu_MoveSubDomains wikiView, gardenName
   # Domains to Move
   put the wiki_Domain of wikiView into wikiDomain
   put url_GetTLD (wikiDomain) into tldDomain
   --
   put lcw_Ask ("Move all domains and subdomains to garden '[[var]]", tldDomain, wikiView, gardenName) into tldDomain
   
   breakpoint
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
end menu_MoveSubDomains

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Browser | Garden | Menu")
end submenu_Dev
