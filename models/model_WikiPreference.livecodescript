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
   put pageArray_Get ("localhost", "local-preference") into pageArray
   return pageArray
end wikiPreference_GetPageArray

command wikiPreference_SetPageArray pageArray
   pageArray_Set "localhost", "local-preference", pageArray
   return the result
end wikiPreference_SetPageArray
