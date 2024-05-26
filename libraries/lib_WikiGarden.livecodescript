script "lib_WikiGarden"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_WikiGarden
type: library
version: 0.2

/*Some help*/

--> Variables
-
local Garden_DomainData
local Router_Array


--> Working on
-
command wikiGarden_Close
   ecoData_Set empty
   wikiFarm_SetDomains empty
   wikiRouter_SetArray empty
   wikiGarden_SetDomainData empty
   --
   lcw_Notify "Closing wiki garden and deleting local variables..."
end wikiGarden_Close

function node_DefaultFarmFolder
   -- default location of node wikifarm
   put $HOME & "/.wiki/" into wikiRootFolder
   return wikiRootFolder
end node_DefaultFarmFolder


--> Display
-
command answer_SetDefaultFarm
   put wikiFarm_GetDefaultFolder() into farmFolder
   if there is not a folder farmFolder then
      put node_DefaultFarmFolder() into farmFolder
   end if
   --
   answer folder "Where is the farm folder containing localhost?" with farmFolder as sheet
   if it is empty then exit to top
   put it into farmFolder
   text_AddTrailing farmFolder, slash
   
   -- wikiFarm_SetFolder farmFolder, true
   wikiFarm_SetDefaultFolder farmFolder
   put the result into ecoData
   --
   display_GardenEcodata
end answer_SetDefaultFarm


--> WikiRouter | Model | Local
-
function wikiRouter_GetArray
   -- if Router_Array is not an array then wikiGarden_Init true
   --
   return Router_Array
end wikiRouter_GetArray

command wikiRouter_SetArray routerFolderArray
   put routerFolderArray into Router_Array
end wikiRouter_SetArray


--> WikiGarden | Update
-
command wikiGarden_Update pAsk  
   # Use stored folder
   put wikiFarm_GetDefaultFolder() into farmFolder -- essential
   
   # Simple version of "wikiGarden_UpdateEcoData"
   wikiGarden_SimpleRefresh farmFolder
   put the result into ecoData
   return ecoData
end wikiGarden_Update

command wikiGarden_SimpleRefresh pFarmFolder
   if pFarmFolder is empty then put ecoData_GetFarmFolder() into pFarmFolder
   if there is not a folder pFarmFolder then
      return "Error, farm folder does nto exist:" && pFarmFolder
   end if
   
   # Use single wikiPreference folder to rebuild from scratch
   put wikiPreference_GetDefaultEcoFolder() into ecoFolder -- optional
   
   local ecoData   
   ecoData_SetFarmFolder pFarmFolder
   put the result into ecoData
   -- put ecoData_Get() into ecoData
   
   if pAsk is true then
      wikiPreference_SetDefaultEcoFolder
      put the result into ecoFolder
   end if
   
   # Reconstruct Gardens from Ecofolder
   if there is a folder ecoFolder then
      put ecodata_ConstructArray (ecoFolder) into ecoArray
      put ecoArray into ecoData ["Eco"]
   end if
   
   # Store and Reload
   wikiGarden_SetModel ecoData
   wikiGarden_Init ecoData
   --
   return ecoData
end wikiGarden_SimpleRefresh


--> WikiGarden | EcoFolder | Update | Multiple (old)
-
command wikiGarden_UpdateEcoData pEcoFolders
   -- use "wikiGarden_Update" instead
   -- does not load local variables to models (use init)
   local ecoArray
   --
   if pEcoFolders is empty then
      put wikiGarden_ListEcoFolders (ecoData) into pEcoFolders
   else
      breakpoint
      wikiPreference_SetDefaultEcoFolder pEcoFolders
   end if
   put wikiGarden_GetModel() into ecoData
   
   # Construct ecoArray from folders
   repeat for each line ecoFolder in pEcoFolders
      _UpdateEcoArray ecoArray, ecoFolder
   end repeat
   
   # Save updated ecoData
   put ecoArray into ecoData ["Eco"]
   wikiGarden_SetModel ecoData
   
   if pLoadEcoData is not false then
      wikiGarden_Init ecoData
   end if
   return ecoData
end wikiGarden_UpdateEcoData

command wikiGarden_AddEcoFolder ecoFolder
   text_AddTrailing ecoFolder, slash
   put wikiGarden_ListEcoFolders() into ecoFolders
   -- if folder_Within (ecoFolder, ecoFolders) is false then return "Error, ecoFolder is within existing ecoFolders:" && ecoFolder
   
   # Add Ecofolder
   line_Add ecoFolder, ecoFolders
   wikiGarden_UpdateEcoData ecoFolders
   put the result into ecoData
   --
   wikiGarden_Init ecoData
   return ecoData
end wikiGarden_AddEcoFolder


--> WikiGarden | Init
-
command wikiGarden_Init ecoData
   local gardenDomainData
   if ecoData is not an array then
      -- put wikiGarden_GetModel() into ecoData
      put ecoData_Get() into ecoData
   end if
   
   # Get default farm domains from folder
   put ecoData ["Farm"]["folder"] into farmFolder
   put wikiFarm_DomainsFromFolder (farmFolder) into farmDomains
   wikiFarm_SetDomains farmDomains
   
   # Add default farmDomain to gardenDomainData
   repeat for each line farmDomain in farmDomains
      put "Farm" into gardenDomainData [farmDomain]["gardenName"]
      put wikiFolder_ConstructFromFarm (farmDomain) into farmFolder
      put farmFolder into gardenDomainData [farmDomain]["folder"]
   end repeat   
   
   # Add Garden folders to gardenDomainData
   put ecoData ["Eco"] into ecoFolderArray
   repeat for each key ecoName in ecoFolderArray
      put ecoFolderArray [ecoName] into ecoNameArray
      put ecoNameArray ["Gardens"] into gardenNameArray
      repeat for each key gardenName in gardenNameArray
         put gardenNameArray [gardenName] into gardenArray
         repeat for each key wikiDomain in gardenArray
            put gardenArray [wikiDomain]["folder"] into wikiFolder
            --
            put gardenName into gardenDomainData [wikiDomain]["gardenName"]
            put ecoName into gardenDomainData [wikiDomain]["ecoName"]
            put wikiFolder into gardenDomainData [wikiDomain]["folder"]
         end repeat
      end repeat
   end repeat
   
   # Garden_DomainData (used by "wikiFolder_FromRouter" and "wikiGarden_ListAllDomains")
   wikiGarden_SetDomainData gardenDomainData
   
   # Construct and store routerFolderArray
   put wikiGarden_ConstructRouterArray (ecoData) into routerFolderArray
   wikiRouter_SetArray routerFolderArray
   
   ecoData_Set ecoData
   return ecoData
end wikiGarden_Init


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
   
   wikiGarden_Update
   wikiGarden_Init
end wikiFarm_MoveGardenBack


--> WikiGarden | List
-
function wikiGarden_ListShortFolders gardenName
   put wikiGarden_FindGardenFolder (gardenName) into gardenFolder
   put folder_ListShort (gardenFolder) into wikiFolders
   return wikiFolders
end wikiGarden_ListShortFolders

function wikiGarden_ListFolders pGardenName
   if pGardenName is empty then
      put wikiGarden_GetDomainData() into domainData
      repeat for each key domainName in domainData
         put domainData [domainName]["folder"] into wikiFolder
         put wikiFolder & CR after wikiFolders
      end repeat
      delete char -1 of wikiFolders
   else
      put wikiGarden_FindGardenFolder (pGardenName) into gardenFolder
      if char 1 of gardenFolder = "~" then put $HOME into char 1 of gardenFolder
      put folder_ListLong (gardenFolder) into wikiFolders
   end if
   return wikiFolders
end wikiGarden_ListFolders

command wikiGarden_StartNodeServer gardenName
   put wikiGarden_Folder (gardenName) into gardenFolder
   if there is not a folder gardenFolder then
      return "Error, cannot locate folder for garden:" && gardenName
   end if
   
   # Stop Node Server
   wikiServer_StopNode
   
   # Start node folder with Garden folder as root
   wikiServer_StartNodeFarm gardenFolder
   put the result into wikiProcessID
   return wikiProcessID
end wikiGarden_StartNodeServer


--> WikiGarden | List
-
function wikiGarden_ListAllDomains pFilterDomain
   put wikiGarden_GetDomainData() into gardenDomainData
   put keys (gardenDomainData) into wikiDomains
   
   url_FilterDomains wikiDomains, pFilterDomain
   url_SortDomainIndex wikiDomains
   return wikiDomains
end wikiGarden_ListAllDomains

function wikiGarden_ListDomains pGardenName
   switch pGardenName
      case empty
         return wikiGarden_ListAllDomains()
      case "Farm"
         return wikiFarm_GetDomains()
      default
         put wikiRouter_GetArray() into routerFolderArray
         set the itemdelimiter to slash
         repeat for each key wikiDomain in routerFolderArray
            put routerFolderArray [wikiDomain] into wikiFolder
            put item -2 of wikiFolder into testName
            if testName = pGardenName then
               put wikiDomain & CR after gardenDomains
            end if
         end repeat
         delete char -1 of gardenDomains
         url_SortDomainIndex gardenDomains
         return gardenDomains
   end switch
end wikiGarden_ListDomains


--> WikiGarden
-
function wikiGarden_Exists wikiDomain
   put wikiFolder_FromRouter (wikiDomain) into gardenFolder
   return gardenFolder is not empty
end wikiGarden_Exists

function wikiGarden_Name wikiDomain
   put wikiGarden_GetDomainArray (wikiDomain) into gardenDomainArray
   return gardenDomainArray ["gardenName"]
end wikiGarden_Name

function wikiGarden_GetDomainArray wikiDomain
   put wikiGarden_GetDomainData() into gardenDomainData
   return gardenDomainData [wikiDomain]
end wikiGarden_GetDomainArray


--> DomainData | Model | Local
-
function wikiGarden_GetDomainData
   return Garden_DomainData
end wikiGarden_GetDomainData

command wikiGarden_SetDomainData gardenDomainData
   put gardenDomainData into Garden_DomainData
end wikiGarden_SetDomainData


--> Private
-
private command _DeleteEmptyFolder sFolder
   put wikiFolder_HasNoPages (sFolder, 0) into isEmpty
   if isEmpty is true then
      revDeleteFolder sFolder                     
   end if
end _DeleteEmptyFolder
