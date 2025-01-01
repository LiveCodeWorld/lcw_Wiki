script "Global | Wiki | Server | Data | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Server | Data | Menu
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
   put the display_View of tObject into dView
   return dView
end menu_Target

getprop disabled_DisplayLoadedWikiEcoData
   put ecoData_Get() into ecoData
   return ecoData is not an array
end disabled_DisplayLoadedWikiEcoData

getprop disabled_DisplayGardenDomainData
   put wikiGarden_GetDomainData() into gardenDomainData
   return gardenDomainData is not an array
end disabled_DisplayGardenDomainData

getprop disabled_WikiGardenRefresh
   put ecoData_GetFarmFolder() into farmFolder
   return there is not a folder farmFolder
end disabled_WikiGardenRefresh


--> Global | Wiki | Server | Data | Menu
-
on menu_DisplayPerformativeDictionary
   put platform_WikiDomain ("rest") into wikiDomain
   put pageArray_Get (wikiDomain, "performative-dictionary") into pageArray
   put pageArray_RefDictionary (pageArray) into storyArray
   --
   display_Data storyArray
end menu_DisplayPerformativeDictionary

private on _
end _

on menu_WikiGardenUpdate
   ecoData_ConstructLoadAndStore
   --
   display_GardenEcodata
end menu_WikiGardenUpdate

on menu_ReconstructEcodata dView
   ecoData_ConstructLoadAndStore
   if item 1 of the result = "Error" then
      lcw_AnswerWarning "Ecodata is not loaded properly", dView
   end if
   --
   display_GardenEcodata
end menu_ReconstructEcodata

private on __
end __

on menu_DisplayStoredEcoData
   display_GardenEcodata
end menu_DisplayStoredEcoData

on menu_DisplayLoadedWikiEcoData
   put ecoData_Get() into ecoData
   display_GardenEcodata ecoData
end menu_DisplayLoadedWikiEcoData

on menu_DisplayGardenDomainData
   put wikiGarden_GetDomainData() into gardenDomainData
   --
   display_Data gardenDomainData, "wikiGarden_GetDomainData()", "Wiki Garden"
end menu_DisplayGardenDomainData

private on ___
end ___

on menu_SetFarmFolder dView
   answer_SetDefaultFarm
end menu_SetFarmFolder

on menu_FixLocalhost
   put ecoData_GetFarmFolder() into farmFolder
   --
   put farmFolder & "localhost/" into localHostFolder
   if there is not a folder localHostFolder then
      put "Error, there is not a localhost folder in the farm folder:" && localHostFolder into someQuestion
      lcw_AnswerWarning someQuestion, dView
   else
      breakpoint
   end if
end menu_FixLocalhost

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Server | Data | Menu")
end submenu_Dev
