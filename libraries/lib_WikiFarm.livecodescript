script "lib_WikiFarm"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_WikiFarm
type: library
version: 0.2

/*
Some help
*/

--> Variables
-
local Farm_Domains


--> Working on
-
--> WikiFarm | Move
-
command wikiFarm_RestoreToGarden gardenName
   put wikiGarden_ConstructFolder (gardenName) into gardenFolder
   text_AddTrailing gardenFolder, slash
   
   put ecoData_GetFarmFolder() into farmFolder
   -- put wikiFarm_GetDefaultFolder() into farmFolder
   text_AddTrailing farmFolder, slash
   --
   put wikiPreference_ListGardenDomains (gardenName) into sGardenDomains
   
   repeat for each line farmDomain in sGardenDomains
      set the cursor to busy
      --
      put farmFolder & farmDomain & slash into farmWikiFolder
      if there is not a folder farmWikiFolder then
         breakpoint
         next repeat
      end if
      
      put gardenFolder & farmDomain & slash into gardenWikiFolder
      if there is a folder gardenWikiFolder then
         breakpoint
         _DeleteEmptyFolder gardenWikiFolder
      end if
      
      revMoveFolder farmWikiFolder, gardenWikiFolder
      if the result is not empty then
         breakpoint
      end if
   end repeat
end wikiFarm_RestoreToGarden

command wikiFarm_MoveGardenBack gardenName
   -- put wikiGarden_ListShortFolders (gardenName) into shortWikiFolders
   put wikiGarden_ListFolders (gardenName) into wikiFolders
   --
   put ecoData_GetFarmFolder() into farmFolder
   if there is not a folder farmFolder then
      put farmFolder
      lcw_AnswerWarning "Cannot locate farm folder!", wikiView
   end if
   --
   set the itemdelimiter to slash
   repeat for each line gardenWikiFolder in wikiFolders
      set the cursor to busy
      --
      put item -1 of gardenWikiFolder into wikiDomain
      -- put wikiFolder_FromRouter (wikiDomain) into gardenWikiFolder
      --
      switch
         case wikiDomain = "commons"
            put farmFolder & wikiDomain & slash into farmCommonsFolder
            if there is a folder farmCommonsFolder then
               lcw_Answer "There is a commons folder that remains unmerged!"
            else
               revMoveFolder gardenWikiFolder, farmCommonsFolder
            end if
            break
         case gardenWikiFolder = farmFolder
         case there is not a folder gardenWikiFolder
            next repeat
         default
            # Check Garden Folder
            put wikiFolder_HasNoPages (gardenWikiFolder, 0) into gardenEmpty
            if gardenEmpty is true then
               put wikiFolder_HasNoPages (gardenWikiFolder, 0) into gardenEmpty
               revDeleteFolder gardenWikiFolder                     
               if the result is not empty then
                  breakpoint
               end if
               next repeat
            end if
            
            # Check destination farmFolder
            put farmFolder & wikiDomain & slash into farmWikiFolder
            if there is a folder farmWikiFolder then
               put wikiFolder_HasNoPages (farmWikiFolder, 0) into farmEmpty
               --
               if farmEmpty is true then
                  revDeleteFolder farmWikiFolder                     
                  if the result is not empty then
                     breakpoint
                  end if
                  
                  revMoveFolder gardenWikiFolder, farmWikiFolder
                  if the result is not empty then
                     breakpoint
                  end if
               else
                  lcw_Answer "Garden and Farm both have pages!"
                  finder_Reveal gardenWikiFolder
                  finder_Reveal farmWikiFolder
                  --
                  next repeat
               end if
            else
               revMoveFolder gardenWikiFolder, farmWikiFolder
               if the result is not empty then
                  breakpoint
               end if
            end if
      end switch
   end repeat
   
   ecoData_ConstructLoadAndStore
   ecoData_SetFarmAndGardens
end wikiFarm_MoveGardenBack

function wikiFarm_ListSubdomains wikiDomain
   -- use wikiDomain_List()?
   put wikiFarm_GetDomains() into subDomains
   url_FilterDomains subDomains, wikiDomain
   line_Delete wikiDomain, subDomains
   return subDomains
end wikiFarm_ListSubdomains

function wikiFarm_ListDomains
   put ecoData_GetFarmFolder() into farmFolder
   put wikiFolder_ListDomains (farmFolder) into wikiDomains
   return wikiDomains
end wikiFarm_ListDomains

function wikiFarm_ListTopDomains pStripEmpty
   put wikiFarm_GetDomains() into farmDomains
   put wikiFarm_ListEmptyFolders(pListShort)
   repeat for each line wikiDomain in farmDomains
      put url_GetTLD (wikiDomain) into tldDomain
      put empty into tldArray [tldDomain][someDomain]
   end repeat
   put keys (tldArray) into topDomains
   url_SortDomainIndex topDomains
   return topDomains
end wikiFarm_ListTopDomains

function wikiFarm_HasLocalHost
   put wikiFarm_Found() into foundFarmFolder
   put ecoData_GetFarmFolder() into ecoFarmFolder
   --
   put foundFarmFolder = ecoFarmFolder into isFound
   return isFound
end wikiFarm_HasLocalHost

function wikiFarm_Found
   put wikiFarm_FoundLocalhost() into foundLocalHost
   set the itemdelimiter to slash
   delete item -1 of foundLocalHost
   return foundLocalHost
end wikiFarm_Found

function wikiFarm_FoundLocalhost
   put ecoData_GetEcoFolder() into ecoFolder
   put ecoData_GetFarmFolder() into farmFolder
   --
   put wikiFolder_FindLocalHost (ecoFolder, farmFolder) into foundLocalHost
   return foundLocalHost
end wikiFarm_FoundLocalhost

command wikiFarm_MoveAndRestart gardenName
   wikiFarm_Move gardenName
   put the result into newFarmFolder
   if item 1 of newFarmFolder = "Error" then
      put newFarmFolder
      breakpoint
      return empty
   end if
   
   wikiGarden_StartNodeServer gardenName
   put the result into wikiProcessID
   return wikiProcessID
end wikiFarm_MoveAndRestart

command wikiFarm_Move gardenName
   put ecoData_GetFarmFolder() into oldFarmFolder
   switch gardenName
      case "Farm"
         put wikiFarm_GetDefaultFolder() into newFarmFolder
         break
      default
         put wikiGarden_ConstructFolder (gardenName) into newFarmFolder
   end switch
   text_AddTrailing newFarmFolder, slash
   text_AddTrailing oldFarmFolder, slash
   if newFarmFolder = oldFarmFolder then return empty
   
   put oldFarmFolder & "localhost/" into oldLocalhostFolder
   if there is not a folder oldLocalhostFolder then
      return "Error, cannot locate old localhost folder in garden:" && gardenName
   end if
   
   put newFarmFolder & "localhost/" into newLocalhostFolder
   if there is a folder newLocalhostFolder then
      return "Error, new localhost folder already exists:" && newLocalhostFolder
   end if
   
   # Move Localhost from old farm to gardenFarmFolder
   revMoveFolder oldLocalhostFolder, newLocalhostFolder
   put the result into moveResult
   --
   if moveResult is not empty then
      breakpoint
      return "Error, moving localhost folder:" && moveResult
   else
      # Set Farm Folder in EcoData
      ecoData_SetFarmFolder newFarmFolder
      return newFarmFolder
   end if
end wikiFarm_Move

command wikiFarm_SetFolder farmFolder, pSaveEcoData
   if there is not a folder farmFolder then
      return "Error, farm folder does not exist:" && farmFolder
   end if
   text_AddTrailing farmFolder, slash
   
   # Set EcoData 
   ecoData_SetFarmFolder farmFolder
   put the result into ecoData
   ecoData_SetFarmAndGardens ecoData
   
   # Optionally save
   if pSaveEcoData is true then
      wikiGarden_SetModel ecoData
   end if
   return ecoData
end wikiFarm_SetFolder


--> WikiFarm
-
function wikiFarm_EarthFolder
   -- moved location of default node wikifarm
   put env_GetRepoFolder() into sFolder
   set the itemdelimiter to slash
   put "Earth" into item -1 of sFolder
   return sFolder
end wikiFarm_EarthFolder

function wikiFarm_GardenName
   put ecoData_GetFarmFolder() into farmFolder
   set the itemdelimiter to slash
   put item -1 of farmFolder into farmGardenName
   return farmGardenName
end wikiFarm_GardenName


--> WikiFarm | Domains
-
function wikiFarm_DomainsFromFolder farmFolder, pFilterDomain, pSimple
   # List Farm
   put folder_ListShort (farmFolder) into shortWikiFolders 
   
   # Tidy
   wikiFolder_TidyList shortWikiFolders
   url_FilterDomains shortWikiFolders, pFilterDomain, pSimple
   
   # Sort
   url_SortDomainIndex shortWikiFolders
   return shortWikiFolders
end wikiFarm_DomainsFromFolder


--> FarmDomains | Model | Local
-
function wikiFarm_GetDomains
   return Farm_Domains
end wikiFarm_GetDomains

command wikiFarm_SetDomains farmDomains
   url_SortDomainIndex farmDomains
   --
   put farmDomains into Farm_Domains
end wikiFarm_SetDomains


--> WikiFarm | Default | Model
-
/* This is the fallback for restarting and reconstituting the routing table. Saved in the ecodata project array.*/

function wikiFarm_GetDefaultFolder
   -- wee "ecoData_GetFarmFolder"
   put wikiGarden_GetModel() into ecoData
   put ecoData ["Farm"]["folder"] into farmFolder
   --
   file_AddHome farmFolder
   return farmFolder
end wikiFarm_GetDefaultFolder

command wikiFarm_SetDefaultFolder farmFolder
   if there is not a folder farmFolder then
      return "Error, farm folder does not exist:" && farmFolder
   end if
   file_StripHome farmFolder
   -- wikiPreference_Set "Farm Folder", farmFolder -- recursive
   
   put wikiGarden_GetModel() into ecoData
   put farmFolder into ecoData ["Farm"]["folder"]
   wikiGarden_SetModel ecoData
   --
   return ecoData
end wikiFarm_SetDefaultFolder
