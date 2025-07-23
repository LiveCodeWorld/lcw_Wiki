script "lib_DisplayWikiPedia"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_DisplayWikiPedia
type: library
version: 0.1


--> Working on
-


--> Display | Wikipedia
-
command display_RestBase pageSlug, pLang
   put mw_SummaryArray (pageSlug, pLang) into sArray
   display_Data sArray, pageSlug, "mw_SummaryArray()"
   return the result
end display_RestBase

command display_ListWikipediaImages pageSlug, pLang
   put restbase_FetchImageArray (pageSlug, pLang) into imageArray
   --
   display_Data imageArray, pageSlug, "restbase_FetchImageArray()"
   return the result
end display_ListWikipediaImages


--> Display | Wiki | Astral
-
command display_WikiCommonsPhotos
   put wikiFolder_ConstructCommons() into wikiCommonsFolder
   put file_ListShort (wikiCommonsFolder) into shortFiles
   --
   display_Data shortFiles, "Commons", "Photos", pDisplayView
   put the result into displayView
   --
   set the photo_Folder of displayView to wikiCommonsFolder
   display_SetMouseAndMenu displayView, "Wiki | Photos"
   return displayView
end display_WikiCommonsPhotos

command display_AstralMediaPhotos pDisplayView
   put wiki_MediaAssetFolder() into wikiMediaAssetFolder
   put file_ListShort (wikiMediaAssetFolder) into shortFiles
   --
   display_Data shortFiles, "media.localhost", "Photos", pDisplayView
   put the result into displayView
   --
   set the photo_Folder of displayView to wikiMediaAssetFolder
   display_SetMouseAndMenu displayView, "Wiki | Photos"
   return displayView
end display_AstralMediaPhotos


--> Deps
-
