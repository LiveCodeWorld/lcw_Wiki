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


--> Global | Wiki | Server | Data | Menu
-
on menu_WikiGardenRefresh
   wikiGarden_SimpleRefresh
   --
   display_GardenEcodata
end menu_WikiGardenRefresh

on menu_WikiGardenUpdate
   wikiGarden_Update
   --
   display_GardenEcodata
end menu_WikiGardenUpdate

private on _
end _

on menu_WikiGardenInit
   wikiGarden_Init
   --
   menu_DisplayLoadedWikiEcoData
end menu_WikiGardenInit

on menu_DisplayGardenEcoData
   display_GardenEcodata
end menu_DisplayGardenEcoData

on menu_DisplayLoadedWikiEcoData
   put ecoData_Get() into ecoData
   display_GardenEcodata ecoData
end menu_DisplayLoadedWikiEcoData

private on __
end __

on menu_DisplayWikiRouterArray
   display_WikiRouterArray
end menu_DisplayWikiRouterArray

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
