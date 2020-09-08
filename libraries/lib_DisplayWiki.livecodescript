script "lib_DisplayWiki"
--> MetaData
-
license: GPLv3
name: lib_DisplayWiki
type: library
version: 0.2


--> Fedwiki
-
command fedwiki_Launch wikiDomain, pPageTitle
   if pPageTitle is empty then
      put empty into pSlug
   else
      put fedwiki_ConstructSlug (pPageTitle) into pSlug
   end if
   --
   fedwiki_LaunchSlug wikiDomain, pSlug
   --
   put the result into wikiURL
   return wikiURL
end fedwiki_Launch

command fedwiki_LaunchSlug wikiDomain, pSlug
   switch pSlug
      case "welcome-visitors"
      case empty
         put "http://" & wikiDomain into wikiURL
         break
      default
         put "http://" & wikiDomain & "/view/welcome-visitors/view/" & pSlug into wikiURL
   end switch
   --
   launch url wikiURL
   return wikiURL
end fedwiki_LaunchSlug


--> Display | Events
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


--> Private
-
private command _UpdateFedrayDisplay @fedray, pIndexView
   -- if pIndexView exists then update the displayed index display
   -- but don't save to the server
   put keys (fedray) into fedDomains
   repeat for each line wikiDomain in fedDomains
      if exists (pIndexView) then
         display_Spin wikiDomain, pIndexView
         put the result into lineNum
      end if
      --
      fedray_UpdateDomain fedray, wikiDomain -- updates fedray without saving
      --
      if exists (pIndexView) then
         put the result into pageNum
         if pageNum is empty then
            set the line_Colour [lineNum] of pIndexView to red
         else
            set the line_Colour [lineNum] of pIndexView to green
         end if
      end if
   end repeat
   
   if exists (pIndexView) then
      -- now let's store fedray to the newly created indexView
      set the fedray_Data of indexView to fedray
      set the hilited_Lines of indexView to 0
   end if
end _UpdateFedrayDisplay


