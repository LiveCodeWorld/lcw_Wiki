script "model_WikiPreference"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_WikiPreference
type: model
version: 0.1


--> Working On
-

--> WikiPreference | EcoFolder | Model
-
function wikiPreference_GetDefaultEcoFolder
   put wikiPreference_Get ("Eco Folder") into ecoFolder
   return ecoFolder
end wikiPreference_GetDefaultEcoFolder

command wikiPreference_SetDefaultEcoFolder ecoFolder
   if there is not a folder ecoFolder then
      put wikiPreference_GetDefaultEcoFolder() into ecoFolder
      answer folder "Where is the eco-folder you keep your wiki farms?" with ecoFolder as sheet
      if it is empty then
         exit to top
         -- return "Error, eco folder does not exist:" && ecoFolder
      end if
      put it into ecoFolder
   end if
   
   # Tidy
   text_AddTrailing ecoFolder, slash
   file_StripHome ecoFolder
   
   # Set wiki-pageArray
   wikiPreference_Set "Eco Folder", ecoFolder
   --
   return ecoFolder
end wikiPreference_SetDefaultEcoFolder


--> WikiPreference | Model
-
function wikiPreference_Get sKey
   put wikiPreference_GetArray() into prefArray
   return prefArray [sKey]
end wikiPreference_Get

command wikiPreference_Set sKey, sValue
   put wikiPreference_GetArray() into prefArray
   put sValue into prefArray [sKey]
   wikiPreference_SetArray prefArray
   return prefArray
end wikiPreference_Set

command wikiPreference_Delete sKey
   put wikiPreference_GetArray() into prefArray
   delete variable prefArray [sKey]
   wikiPreference_SetArray prefArray
   return prefArray
end wikiPreference_Delete

function wikiPreference_ConstructPageArray prefArray
   put _DeconstructArray (prefArray, true) into codeText
   put wikiPreference_GetPageArray() into pageArray
   pageArray_SetFirstCode pageArray, codeText
   return pageArray
end wikiPreference_ConstructPageArray

function wikiPreference_GetArray
   put wikiPreference_GetPageArray() into pageArray
   put pageArray_GetFirstCode (pageArray) into codeText
   --
   set the itemdelimiter to ":"
   repeat for each line someLine in codeText
      if the number of items of someLine = 2 then
         put word 1 to -1 of item 1 of someLine into someKey
         put word 1 to -1 of item 2 of someLine into someValue
         put someValue into prefArray [someKey]
      end if
   end repeat
   return prefArray
end wikiPreference_GetArray

command wikiPreference_SetArray prefArray
   put wikiPreference_ConstructPageArray (prefArray) into pageArray
   wikiPreference_SetPageArray pageArray
   return pageArray
end wikiPreference_SetArray

function wikiPage_LocalPreference pGardenNames
   if pGardenNames is empty then
      put wikiGarden_ListUniqueNames() into pGardenNames
   else
      replace comma with CR in pGardenNames
   end if
   --
   repeat for each line gardenNames in pGardenNames
      put gardenNames && "Garden Sites" & CR after bulletIndex
   end repeat
   delete char -1 of bulletIndex
   --
   put wikiPreference_GetPageArray() into pageArray
   put "In this section we link to [[wiki-garden]]s hosted on your system:" into introText
   pageArray_SetSectionBulletIndex pageArray, "Gardens", bulletIndex, introText
   return pageArray
end wikiPage_LocalPreference


--> WikiGarden | LocalHost | Model
-
function wikiPreference_ListGardenDomains gardenName
   put tolower (gardenName) & "-" & "garden-sites" into gardenIndexSlug
   --
   put pageArray_Get ("localhost", gardenIndexSlug) into pageArray
   if pageArray is not an array then return empty
   
   put pageArray_ListReferenceDomains (pageArray) into refDomains
   return refDomains
end wikiPreference_ListGardenDomains


--> WikiPreference
-
function wikiPreference_GetGardenList
   put wikiPreference_GetPageArray() into pageArray
   --
   put pageArray_GetSectionBulletIndex (pageArray, "Gardens") into bulletIndex
   return bulletIndex
end wikiPreference_GetGardenList

command wikiPreference_SetGardenList pGardenNames
   put wikiPage_LocalPreference (pGardenNames) into pageArray
   return pageArray
end wikiPreference_SetGardenList

function wikiPreference_GetPageArray
   -- put pageArray_Get ("localhost", "local-preference") into pageArray -- depends on local arrays
   put wikiFile_ConstructLocalHost ("local-preference") into wikiFile
   if wikiFile is empty then return empty
   put jsonArray_FromFile (wikiFile) into pageArray
   return pageArray
end wikiPreference_GetPageArray

command wikiPreference_SetPageArray pageArray
   pageArray_Set "localhost", "local-preference", pageArray
   return the result
end wikiPreference_SetPageArray


--> Private
-
private function _DeconstructArray prefArray, pPretty
   if pPretty is false then
      combine prefArray using CR and ":"
      return prefArray
   else
      repeat for each key someKey in prefArray
         put prefArray [someKey] into someValue
         put someKey & ":" && someValue & CR after codeText
      end repeat
      delete char -1 of codeText
      return codeText
   end if
end _DeconstructArray
