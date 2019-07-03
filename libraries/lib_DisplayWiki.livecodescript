script "lib_DisplayWiki"
--> MetaData
-
license: GPLv3
name: lib_DisplayWiki
type: library
version: 0.2


--> Display
-
on mDoubleUp_Test indexView, wikiDomain
   put the fedray_Data of indexView into fedray
   put fedray [wikiDomain] into domainArray
   if domainArray is an array then
      put empty
      display_Array domainArray, wikiDomain
   else
      put wikiDomain && "is not indexed!"
   end if
   
   if the shiftkey is "Down" then
      put "http://" & wikiDomain into someURL
      launch url someURL
   end if
end mDoubleUp_Test

command display_FedrayUpdate fedray, titleText
   put keys (fedray) into fedDomains
   url_SortDomainindex fedDomains
   --
   put display_FindView ("Federation", titleText) into indexView
   if exists (indexView) then
      set the displayed_Index of indexView to fedDomains
   else
      display_Lines fedDomains, titleText, "mDoubleUp_Test", "Federation"
      put the result into indexView
      set the title_Menu of indexView to "Global | Federation | Build | Menu"
   end if
   
   -- does the same as "fedray_Fetch()" but with display
   repeat for each line wikiDomain in fedDomains
      display_Spin wikiDomain, indexView
      put the result into lineNum
      --
      fedray_UpdateDomain fedray, wikiDomain, true -- updates fedray without saving
      put the result into pageNum
      if pageNum is empty then
         set the line_Colour [lineNum] of indexView to red
      else
         set the line_Colour [lineNum] of indexView to green
      end if
   end repeat
   
   -- now let's store fedray to the newly created indexView
   set the fedray_Data of indexView to fedray
   set the hilited_Lines of indexView to 0
   return indexView
end display_FedrayUpdate


--> Display | Wiki
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


--> Display | Podcasts
-
command display_Podcasts
   /*
   put lcw_Ask ("Enter exact episode search term") into searchTerm
   put listenNotes_FindEpisode (searchTerm, true) into someJSON
   display_JSON someJSON
   */
   
   put lcw_Ask ("Enter podcast search term", "GraalVM") into searchTerm
   put listenNotes_FindPodcast (searchTerm) into someJSON
   put json_ToArray (someJSON) into listenNotesPodcastArray
   display_Array listenNotesPodcastArray, "listenNotes_FindPodcast()"
   --
   put listenNotesPodcastArray ["results"] into resultArray
   --
   put listenNotesPodcastArray ["count"] into maxNum -- ??
   put item 2 of the extents of resultArray into maxNum
   --
   repeat with itemNum = 1 to maxNum
      put resultArray [itemNum] into itemArray
      --
      put itemArray ["id"] into episodeID
      --
      put itemArray ["image"] into imageURL
      put itemArray ["thumbnail"] into thumbnailURL
      put itemArray ["title_original"] into podTitle
      put itemArray ["description_original"] into podDescription
      put itemArray ["listennotes_url"] into listenURL
      -- put itemArray ["genres"] into genreArray
      
      put listenNotes_FetchEpisodeInfo (episodeID) into episodeArray
      --
      display_Array episodeArray, "listenNotes_FetchEpisodeInfo()"
      exit to top
   end repeat
end display_Podcasts
