script "Global | Wiki | Data | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Data | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray

--> Menu | Props
-
on menu_Init tObject
   -- called only once for top menu
   pass menu_Init
end menu_Init

getprop menu_Target [tObject]
   put the dv_LinkedDataView of tObject into dView
   return dView
end menu_Target

private function _TestData
   put "Line 1" into tA[1]["label"]
   put "Line 2" into tA[2]["label"]
   put "markdown" into tA[2]["@style"]
   put "Line 3" into tA[3]["label"]
   put "Line 4" into tA[4]["label"]
   --
   return tA
end _TestData

-- getprop disabled_SetTestData
put _GetLinkedDataView() into dView
return exists (dView) is false
end disabled_SetTestData

getprop checked_ThoughtData [dView]
   put the dv_Metadata ["wikiDomain"] of dView into wikiDomain
   put the dv_Metadata ["pSlug"] of dView into pageSlug
   return wikiDomain = "thought.garden" AND pageSlug = ""
end checked_ThoughtData

getprop checked_TheatreData [dView]
   put the dv_Metadata ["wikiDomain"] of dView into wikiDomain
   put the dv_Metadata ["pSlug"] of dView into pageSlug
   return wikiDomain = "thought.garden" AND pageSlug = "legislative-theatre"
end checked_TheatreData

getprop checked_LexonData [dView]
   put the dv_Metadata ["wikiDomain"] of dView into wikiDomain
   return wikiDomain = "lexon.wiki"
end checked_LexonData

getprop checked_ParkData [dView]
   put the dv_Metadata ["wikiDomain"] of dView into wikiDomain
   put the dv_Metadata ["pSlug"] of dView into pageSlug
   --
   return wikiDomain = "spacenet.work" AND pageSlug = "finsbury-park"
end checked_ParkData

getprop checked_FestivalData [dView]
   put the dv_Metadata ["wikiDomain"] of dView into wikiDomain
   put the dv_Metadata ["pSlug"] of dView into pageSlug
   --
   return wikiDomain = "spacenet.work" AND pageSlug = "festivals-in-finsbury-park"
end checked_FestivalData


--> Global | Wiki | Data | Menu
-
on menu_LaunchWiki dView
   put the dv_Metadata ["wikiDomain"] of dView into wikiDomain
   put the dv_Metadata ["pSlug"] of dView into pageSlug
   --
   fedwiki_LaunchSlug wikiDomain, pageSlug
end menu_LaunchWiki

on _
end _

on menu_ThoughtData dView
   set the dv_Wikidomain of dView to "thought.garden"
end menu_ThoughtData

on menu_ParkData dView
   set the dv_Wikidomain ["finsbury-park"] of dView to "spacenet.work"
end menu_ParkData

on menu_FestivalData dView
   set the dv_Wikidomain ["festivals-in-finsbury-park"] of dView to "spacenet.work"
end menu_FestivalData

on menu_TheatreData dView
   set the dv_Wikidomain ["legislative-theatre"] of dView to "thought.garden"
end menu_TheatreData

on _
end _

on menu_LexonWikiData dView
   set the dv_Wikidomain of dView to "lexon.wiki"
end menu_LexonWikiData

on menu_LexonContract dView
   put lexon_FetchDataViewArray ("HyQ8s2di_") into dData
   set the dvData of dView to dData
   --
   set the dv_Metadata ["wikiDomain"] of dView to empty
   set the dv_Metadata ["pSlug"] of dView to empty
end menu_LexonContract

on _
end _

on menu_Empty dView
   set the dvData of dView to empty
end menu_Empty

on menu_DisplayDataViewData dView
   put the dvData of dView into tArray
   put "DataView"  && kwote (the short name of dView) into sTitle
   --
   display_Data tArray, "dvData", sTitle
end menu_DisplayDataViewData

on _
end _

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Dev | Menu
-
on menu_SimpleTestData dView
   put _TestData() into tA
   set the dvData of dView to tA
   set the dv_Metadata ["wikiDomain"] of dView to "local test"
end menu_SimpleTestData
