script "lib_DisplayWiki"
--> MetaData
-
license: GPLv3
name: lib_DisplayWiki
type: library
version: 0.1


--> Display
-
command display_FedwikiPageJson pageJson
   put json_ToArray (pageJson) into pageArray
   display_FedwikiPageArray pageArray
   put the result into arrayView
   return arrayView
end display_FedwikiPageJson
   
command display_FedwikiPageArray pageArray
   display_Array pageArray, "Fedwiki Page JSON"
   put the result into arrayView
   return arrayView
end display_FedwikiPageArray

command display_WikiPageArray fedwikiDomain, pageSlug
   put pageArray_Fetch (fedwikiDomain, pageSlug) into pageArray
   put pageSlug,fedwikiDomain into someTitle
   display_Array pageArray, someTitle
end display_WikiPageArray


