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
getprop menu_Target [tObject]
   put the displayed_Object of tObject into wikiView
   return wikiView
end menu_Target

getprop menu_CheckTarget [wikiView]
   put wikiGarden_ListUniqueNames() into gardenNames
   -- put ecoData_GetFarmName() & CR  before gardenNames
   put gardenNames into LocalArray ["gardenNames"]
   --
   repeat for each line gardenName in gardenNames
      if wikiGarden_ListFolders (gardenName) is empty then
         put gardenName & CR after emptyGardenNames
      else
         put gardenName & CR after fullGardenNames
      end if
   end repeat
   delete char -1 of emptyGardenNames
   delete char -1 of fullGardenNames
   --
   put emptyGardenNames into LocalArray ["emptyGardenNames"]
   put fullGardenNames into LocalArray ["fullGardenNames"]
   --
   return exists (wikiView)
end menu_CheckTarget

getprop moveAndRestart_Param [wikiView]
   return wikiFarm_GardenName()
end moveAndRestart_Param

getprop moveAndRestart_Params
   return "Farm,-" &CR& LocalArray ["fullGardenNames"]
end moveAndRestart_Params

getprop restoreGarden_Params
   return LocalArray ["emptyGardenNames"]
end restoreGarden_Params

getprop disabled_RestoreGarden
   return LocalArray ["emptyGardenNames"] is empty
end disabled_RestoreGarden

getprop backToFarm_Params
   return LocalArray ["fullGardenNames"]
end backToFarm_Params

getprop disabled_BackToFarm
   return LocalArray ["fullGardenNames"] is empty
end disabled_BackToFarm

getprop draftGardenActivity_Params
   return LocalArray ["gardenNames"]
end draftGardenActivity_Params

getprop draftGardenIndex_Params
   return LocalArray ["gardenNames"]
end draftGardenIndex_Params

getprop draftGardenPage_Params
   return LocalArray ["gardenNames"]
end draftGardenPage_Params

getprop checked_FixLocalhost
   return wikiFarm_HasLocalHost()
end checked_FixLocalhost

getprop disabled_FixLocalhost
   return wikiFarm_HasLocalHost()
end disabled_FixLocalhost

getprop revealGarden_Params
   return "Farm,-" &CR& LocalArray ["gardenNames"]
end revealGarden_Params


--> Global | Wiki | Browser | Garden | Menu
-
on menu_MoveAndRestart wikiView, gardenName
   wikiFarm_MoveAndRestart gardenName
end menu_MoveAndRestart

private on _
end _

on menu_RestoreGarden wikiView, gardenName
   wikiFarm_RestoreToGarden gardenName
   --
   lcw_Notify "Restored garden [[var]]", "Wiki Garden", gardenName
end menu_RestoreGarden

on menu_BackToFarm wikiView, gardenName
   wikiFarm_MoveGardenBack gardenName
   --
   lcw_Notify "Moved to garden [[var]]", "Wiki Garden", gardenName
end menu_BackToFarm

private on __
end __

on menu_RevealDefaultFarm
   put wikiFarm_GetDefaultFolder() into farmFolder
   finder_Reveal farmFolder
end menu_RevealDefaultFarm

on menu_RevealGarden wikiView, gardenName
   put wikiGarden_Folder (gardenName) into gardenFolder
   --
   finder_Reveal gardenFolder
end menu_RevealGarden

on menu_FixLocalhost
   if wikiFarm_HasLocalHost() is false then
      put wikiFarm_Found() into foundFarmFolder
      if there is a folder foundFarmFolder then
         wikiFarm_SetFolder foundFarmFolder, true
         --
         lcw_Notify "Set farm folder!"
         put ecoData_Get() into ecoData
         display_GardenEcodata ecoData
      else
         breakpoint
      end if
   end if
end menu_FixLocalhost

on menu_SetDefaultFarmFolder
   answer_SetDefaultFarm
end menu_SetDefaultFarmFolder

private on ___
end ___

on menu_DraftGardenPage wikiView, gardenName
   put the wiki_Domain of wikiView into wikiDomain
   put wikiPage_GardenSites (gardenName, wikiDomain) into pageArray
   set the ghost_PageArray of wikiView to pageArray
end menu_DraftGardenPage

on menu_DraftGardenActivity wikiView, gardenName
   put the wiki_Domain of wikiView into wikiDomain
   put wikiPage_GardenActivity (gardenName, wikiDomain) into pageArray
   set the ghost_PageArray of wikiView to pageArray
end menu_DraftGardenActivity

on menu_DraftGardenIndex wikiView, gardenName
   put the wiki_Domain of wikiView into wikiDomain
   put wikiPage_GardenIndex (gardenName, wikiDomain) into pageArray
   set the ghost_PageArray of wikiView to pageArray
end menu_DraftGardenIndex

private on ____
end ____

on menu_DraftLocalPreferencePage wikiView
   put wikiPage_LocalPreference() into pageArray
   set the ghost_PageArray of wikiView to pageArray
end menu_DraftLocalPreferencePage

on menu_EmptyFarmWikis
   display_EmptyWikiFolders
end menu_EmptyFarmWikis

private on _____
end _____

on submenu_WorkInProgress
   return "Global | Wiki | Browser | Garden | Dev | Menu"
end submenu_WorkInProgress
