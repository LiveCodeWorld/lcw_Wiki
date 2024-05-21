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


--> Working on
-
function wikiGarden_ListEmptyFolders pGardenName, pListShort, pNum
   if pNum is empty then put 0 into pNum
   put wikiGarden_ListFolders (pGardenName) into wikiFolders
   --
   set the itemdelimiter to slash
   repeat for each line wikiFolder in wikiFolders
      set the cursor to busy
      put wikiFolder_HasNoPages (wikiFolder, pNum) into noPages
      if noPages is false then next repeat
      
      if pListShort is true then
         put item -1 of wikiFolder & CR after emptyFolders
      else
         put wikiFolder & CR after emptyFolders
      end if
   end repeat
   delete char -1 of emptyFolders
   
   url_SortDomainIndex emptyFolders
   return emptyFolders
end wikiGarden_ListEmptyFolders

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
      put folder_ListLong (gardenFolder) into wikiFolders
   end if
   return wikiFolders
end wikiGarden_ListFolders


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

function wikiGarden_Folder wikiDomain
   put wikiGarden_GetDomainArray (wikiDomain) into gardenDomainArray
   switch gardenDomainArray ["gardenName"]
      case empty
      case "Farm"
         return empty
      default
         put gardenDomainArray ["folder"] into gardenFolder
         return gardenFolder
   end switch
end wikiGarden_Folder

function wikiGarden_GetDomainArray wikiDomain
   put wikiGarden_GetDomainData() into gardenDomainData
   return gardenDomainData [wikiDomain]
end wikiGarden_GetDomainArray

function wikiGarden_ConstructFolder gardenName, pEcoName
   put ecoData_GetEcoFolder (pEcoName) into ecoFolder
   if ecoFolder is empty then return empty
   --
   put ecoFolder & gardenName & slash into gardenFolder
   return gardenFolder
end wikiGarden_ConstructFolder

command wikiGarden_Close
   ecoData_Set empty
   wikiFarm_SetDomains empty
   wikiRouter_SetArray empty
   wikiGarden_SetDomainData empty
end wikiGarden_Close


--> WikiGarden | List
-
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

function wikiGarden_ListAllDomains pFilterDomain
   put wikiGarden_GetDomainData() into gardenDomainData
   put keys (gardenDomainData) into wikiDomains
   
   url_FilterDomains wikiDomains, pFilterDomain
   url_SortDomainIndex wikiDomains
   return wikiDomains
end wikiGarden_ListAllDomains


--> DomainData | Model | Local
-
function wikiGarden_GetDomainData
   return Garden_DomainData
end wikiGarden_GetDomainData

command wikiGarden_SetDomainData gardenDomainData
   put gardenDomainData into Garden_DomainData
end wikiGarden_SetDomainData


--> Deps
-
