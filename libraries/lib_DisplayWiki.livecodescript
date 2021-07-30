script "lib_DisplayWiki"
--> MetaData
-
license: GPLv3
name: lib_DisplayWiki
type: library
version: 0.2


--> Working on
-

--> Fedwiki | Launch
-
command launch_Fedwiki wikiDomain, pTitle, pProtocol
   put fedwiki_ConstructURL (wikiDomain, pTitle, pProtocol) into wikiURL
   launch url wikiURL
   return wikiURL
end launch_Fedwiki

command fedwiki_Launch wikiDomain, pTitle, pProtocol
   -- replace with "launch_Fedwiki"
   put fedwiki_ConstructURL (wikiDomain, pTitle, pProtocol) into wikiURL
   launch url wikiURL
   return wikiURL
end fedwiki_Launch

command fedwiki_LaunchSlug wikiDomain, pSlug, pProtocol
   put fedwiki_ConstructURLFromSlug (wikiDomain, pSlug, pProtocol) into wikiURL
   launch url wikiURL
   return wikiURL
end fedwiki_LaunchSlug


--> Events
-
on drop_Wiki displayView, dData
   -- http://roster.fedwiki.org/view/welcome-visitors/view/skunk-activity/michael.offersandwants.me/loveworker-project-scraps--introduction
   set the itemdelimiter to slash
   put dData ["text"] into droppedURL
   --
   put item 3 of droppedURL into wikiDomain
   if the number of items of droppedURL = 4 AND droppedURL ends with ".html" then
      -- it's a link to a wiki-page
      get item 4 of droppedURL
      set the itemdelimiter to "."
      put item 1 of it into pageSlug
      --
      put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
      display_PageArray pageArray
   else
      -- it's a lineUP
      put fedwiki_GetLineUpData (droppedURL) into lineUpData
      display_WikiLineUp lineUpData
   end if
end drop_Wiki

on mDoubleUp_PageArray displayView, someLine
   put the title_Text of displayView into someTitle
   return displayView
end mDoubleUp_PageArray

on mDoubleUp_DisplayWikiPage displayView, someValue
   put the title_Text of displayView into wikiDomain
   put the top_Array of displayView into tArray
   put the keys of tArray into pageTitle
   --
   put tArray [pageTitle]["slug"] into pageSlug
   --
   fedwiki_Launch wikiDomain, pageTitle
   -- display_Array tArray
end mDoubleUp_DisplayWikiPage

on mDoubleUp_WikiLineUp displayView, someValue
   put the params
   breakpoint
end mDoubleUp_WikiLineUp

on mDoubleUp_LineUp displayView, someLine
   put the title_Text of displayView into topDomain
   put the selected_Line of displayView into someKey
   put the selected_Path of displayView into somePath
   put the displayed_Data of displayView into lineupData
   --
   split somePath with comma
   -- display_Data somePath
   put lineupData [somePath]
end mDoubleUp_LineUp

on mDoubleUp_DisplayPage displayView, someLine
   put the top_Array ["slug"] of displayView into pSlug
   put the title_Text of displayView into wikiDomain
   --
   if the shiftKey is "Down" then
      fedwiki_LaunchSlug wikiDomain, pSlug
   else
      display_WikiPage wikiDomain, pSlug
   end if
   return the result
end mDoubleUp_DisplayPage

on mDoubleUp_WikiDomain tObject, wikiDomain
   fedwiki_Launch wikiDomain
end mDoubleUp_WikiDomain


--> Display | Wiki | Page
-
command display_WikiPage wikiDomain, pSlug
   put pageArray_Fetch (wikiDomain, pSlug) into pageArray
   display_PageArray pageArray, wikiDomain
   put the result into displayView
   --
   display_SetInteractions displayView, "Wiki | Page", ""
   set the wiki_Domain of displayView to wikiDomain
   set the page_Slug of displayView to pSlug
   --
   return displayView
end display_WikiPage


--> Display | Wiki | Pages
-
command display_WikiDomain wikiDomain, pDisplayView, pPalette
   set the cursor to watch
   --
   atopia_DeleteWikiSitemap wikiDomain
   --
   put fedwiki_FetchSitemapArray (wikiDomain) into sitemapArray
   put fedwiki_ConstructSitePageArray (sitemapArray) into sitePageArray
   --
   display_Data sitePageArray, wikiDomain, "Wiki", pDisplayView, pPalette
   put the result into displayView
   --
   display_SetInteractions displayView, "Wiki | Pages", "mDoubleUp_DisplayPage"
   --
   return displayView
end display_WikiDomain


command display_RecentDomainWikiPages wikiDomain, pSincePeriod, pDisplayView, pPalette
   if pSincePeriod is empty then put "1 week" into pSincePeriod
   --
   put fedwiki_FetchModifiedPageArray (wikiDomain, pSincePeriod) into sitemapArray
   put fedwiki_GetModifiedArray (sitemapArray, pSincePeriod) into sitemapArray
   put fedwiki_ConstructSitePageArray (sitemapArray) into sitePageArray
   --
   display_Data sitePageArray, "Recent Pages", wikiDomain, pDisplayView, pPalette
   put the result into displayView
   return displayView
end display_RecentDomainWikiPages

command display_RecentWikiPages wikiDomains, pSincePeriod, pDisplayView, pPalette
   local mDoubleUp
   
   -- default to display recent site pages in the last week
   if pSincePeriod is empty then put "1 Week" into pSincePeriod
   if wikiDomains is empty then
      put fedray_FetchRecentSites (sincePeriod, true) into wikiDomains
   end if
   --
   put fedwiki_FetchRecentDomainPageArray (wikiDomains, pSincePeriod) into domainPageArray
   --
   put "Global | Federation | Tree | Menu" into mTitle
   put "Global | Federation | Line | Menu" into mLineTitle
   --
   display_Data domainPageArray, pSincePeriod, "Recent Federation Pages", pDisplayView, pPalette
   put the result into pDisplayView
   display_SetIndexMenus pDisplayView, mTitle, mLineTitle, mDoubleUp
   --
   return pDisplayView
end display_RecentWikiPages

command display_RecentAtopiaPages pSincePeriod, pDisplayView, pPalette
   local mDoubleUp
   --
   put date_GetSinceSeconds (pSincePeriod) into sinceSeconds 
   put atopia_ListRecentDomains (sinceSeconds) into modifiedSites
   put fedwiki_FetchRecentDomainPageArray (modifiedSites, pSincePeriod) into domainPageArray
   --
   put "Global | Atopia | Tree | Menu" into mTitle
   put "Global | Atopia | Line | Menu" into mLineTitle
   --
   display_Data domainPageArray, "Recent Wiki Pages", "Atopia", pDisplayView, pPalette
   put the result into pDisplayView
   display_SetIndexMenus pDisplayView, mTitle, mLineTitle, mDoubleUp
   --
   return indexView
end display_RecentAtopiaPages

command display_RecentScrapePages pSincePeriod, pDisplayView, pPalette
   local mDoubleUp
   --
   -- put fedray_FetchRecentSites (pSincePeriod) into modifiedSites
   put fedray_FetchWardsRecentDomains() into modifiedSites
   put fedwiki_FetchRecentDomainPageArray (modifiedSites, pSincePeriod) into domainPageArray
   --
   put "Global | Federation | Tree | Menu" into mTitle
   put "Global | Federation | Line | Menu" into mLineTitle
   --
   display_Data domainPageArray, "Recent Wiki Pages", "Federation", pDisplayView, pPalette
   put the result into pDisplayView
   display_SetIndexMenus pDisplayView, mTitle, mLineTitle, mDoubleUp
   --
   return pDisplayView
end display_RecentScrapePages


--> Display | Wiki | Lineup
-
command display_WikiLineUp lineUpURL
   put fedwiki_FetchLineUpData (lineUpURL) into lineUpData
   --
   put lineUpData ["wikiDomain"] into wikiDomain 
   put lineUpData ["lineUp"] into lineUpArray
   --
   display_Data lineUpData, "Wiki LineUp", wikiDomain
   put the result into displayView
   display_SetInteractions displayView, "Wiki | Lineup", "mDoubleUp_WikiLineUp"
   return lineUpData
end display_WikiLineUp

--> Display | Wiki
-
command display_PageArray pageArray, pDomainTitle
   if pDomainTitle is empty then put "Wiki" into pDomainTitle
   put pageArray ["title"] into pTitle
   put pageArray ["story"] into storyArray
   put pageArray ["journal"] into journalArray
   --
   display_Data storyArray, pTitle, pDomainTitle
   put the result into displayView
   --
   display_SetInteractions displayView, "PageArray", "mDoubleUp_PageArray"
   set the page_Array of displayView to pageArray
   --
   return displayView
end display_PageArray

command display_FedwikiPageJson pageJson
   put json_ToArray (pageJson) into pageArray
   display_PageArray pageArray
   return the result
end display_FedwikiPageJson

command display_WikiPageArray fedwikiDomain, pageSlug
   put pageArray_Fetch (fedwikiDomain, pageSlug) into pageArray
   display_PageArray pageArray
   return the result
end display_WikiPageArray

command display_PageTitleArray wikiDomain, pSincePeriod
   -- put fedwiki_FetchSitemapArray (wikiDomain) into sitemapArray
   -- put fedwiki_ConstructSitePageArray (sitemapArray) into pageTitleArray
   put fedwiki_FetchModifiedPageArray (wikiDomain, pSincePeriod) into sitePageArray
   --
   display_Data sitePageArray, wikiDomain, "Site Page Array"
   put the result into displayView
   set the site_PageArray of displayView to sitePageArray
   --
   set the title_Menu of displayView to "Global | Wiki | Sitemap | Tree | Menu"
   set the line_Menu of displayView to "Global | Wiki | Sitemap | Line | Menu"
   set the mouse_DoubleUp of displayView to "mDoubleUp_DisplayWikiPage"
   return displayView
end display_PageTitleArray


--> Display | Podcasts
-
command display_Podcasts
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
      
      put listenNotes_FetchEpisodeArray (episodeID) into episodeArray
      --
      display_Array episodeArray, "listenNotes_FetchEpisodeArray()"
      exit to top
   end repeat
end display_Podcasts


--> Fedwiki | LineUp
-
command display_LineUpData lineUpURL
   get "http://liquidlaw.org/view/welcome-visitors/view/lexon/view/how-legislative-theatre-works/view/legislative-theatre-with-lexon/view/stress-test-contracts"
   put it into lineUpURL
   --
   put fedwiki_FetchLineUpData (lineUpURL) into lineUpData
   --
   url_Deconstruct lineUpURL, someProtocol, urlDomain, urlPath, shortName, fileExtension, uName, pWord
   display_Data lineUpData, urlDomain, "Lineup Data"
   put the result into displayView
   display_SetInteractions displayView, "Lineup | Tree", "mDoubleUp_LineUp"
   --
   return displayView
end display_LineUpData

function fedwiki_FetchLineUpData lineUpURL
   put fedwiki_GetLineUpData (lineUpURL) into lineUpData
   put lineUpData ["lineUp"] into lineUpArray
   repeat with lineUpNum = 1 to item 2 of the extents of lineUpArray
      put lineUpArray [lineUpNum]["slug"] into pSlug
      put lineUpArray [lineUpNum]["lineupDomain"] into wikiDomain
      --
      put pageArray_Fetch (wikiDomain, pSlug) into pageArray
      --
      put pageArray ["title"] into lineUpData ["lineUp"][lineUpNum]["title"]
      put pageArray ["story"] into lineUpData ["lineUp"][lineUpNum]["story"]
      put pageArray ["journal"] into lineUpData ["lineUp"][lineUpNum]["journal"]
   end repeat
   return lineUpData
end fedwiki_FetchLineUpData

function fedwiki_GetLineupSlugs lineUpArray
   -- bit dodgy
   set the wholeMatches to true
   repeat with lineUpNum = 1 to item 2 of the extents of lineUpArray
      put lineUpArray [lineUpNum]["slug"] into pageSlug
      put lineUpArray [lineUpNum]["lineupDomain"] into lineUpDomain
      --
      if pageSlug is among the lines of pageSlugs then
         put pageSlug && "of" && lineUpDomain & CR after pageSlugs
      else
         put pageSlug & CR after pageSlugs
      end if
   end repeat
   delete char -1 of pageSlugs
   return pageSlugs
end fedwiki_GetLineupSlugs

function fedwiki_ConstructLineUpURL lineUpArray, wikiDomain
   put "http://" & wikiDomain & slash into lineUpURL
   repeat with lineUpNum = 1 to item 2 of the extents of lineUpArray
      put lineUpArray [lineUpNum]["slug"] into pageSlug
      put lineUpArray [lineUpNum]["lineupDomain"] into lineUpDomain
      --
      if lineUpDomain = wikiDomain then
         put "view/" after lineUpURL
      else
         put lineUpDomain & slash after lineUpURL
      end if
      put pageSlug & slash after lineUpURL
   end repeat
   delete char -1 of lineUpURL
   return lineUpURL
end fedwiki_ConstructLineUpURL

function fedwiki_GetLineUpData lineUpURL
   set the itemdelimiter to slash
   put item 3 of lineUpURL into wikiDomain
   put item 4 to -1 of lineUpURL into lineUpBit
   --
   put wikiDomain into lineUpData ["wikiDomain"]
   put lineUpURL into lineUpData ["lineUpURL"]
   --
   put the number of items of lineUpBit / 2 into maxNum
   put 1 into lineUpNum
   repeat maxNum
      put item 1 of lineUpBit into viewOrDomain
      if viewOrDomain = "view" then
         put wikiDomain into lineUpDomain
      else
         put viewOrDomain into lineUpDomain
      end if
      put item 2 of lineUpBit into pageSlug
      put pageSlug into lineUpData ["lineUp"][lineUpNum]["slug"]
      put lineUpDomain into lineUpData ["lineUp"][lineUpNum]["lineupDomain"]
      --
      add 1 to lineUpNum
      delete item 1 to 2 of lineUpBit
   end repeat
   return lineUpData
end fedwiki_GetLineUpData

function fedwiki_FetchLastLineUpArray droppedURL, pNotTheseSlugs
   put fedwiki_FetchLastLineUpJson (droppedURL, pNotTheseSlugs) into pageJSON
   put json_ToArray (pageJSON) into pageArray
   return pageArray
end fedwiki_FetchLastLineUpArray

function fedwiki_FetchLastLineUpJson droppedURL, pNotTheseSlugs
   -- does not check that droppedURL is not a ".html" page
   if pNotTheseSlugs is empty then put "journal-cleaner-transport" into pNotTheseSlugs
   
   put fedwiki_ConstructUrlArray (droppedURL) into urlArray
   if urlArray is false then return false
   
   put item 2 of the extents of urlArray into lineUpNum
   put urlArray [lineUpNum]["slug"] into pageSlug
   if pageSlug is among the items of pNotTheseSlugs and lineUpNum is not 1 then
      subtract 1 from lineUpNum
   end if
   
   put fedwiki_FetchLineUpJson (urlArray, lineUpNum) into pageJSON
   return pageJSON
end fedwiki_FetchLastLineUpJson

function fedwiki_FetchLineUpJson urlArray, lineUpNum
   if lineUpNum = -1 then put item 2 of the extents of urlArray into lineUpNum
   
   put urlArray [lineUpNum]["slug"] into pageSlug
   put urlArray [lineUpNum]["someDomain"] into someDomain
   
   -- http://forage.david.bovill.me/entry-level-browser.json?random=72428048
   put "http://" & someDomain & "/" & pageSlug & ".json" into someUrl
   -- put "?random=" & the milliseconds after someUrl
   put url someUrl into someJSON
   return someJSON
end fedwiki_FetchLineUpJson

function fedwiki_ConstructUrlArray someUrl
   set the itemdelimiter to "/"
   put item 1 to 3 of someUrl into urlStem
   put item 3 of someUrl into urlDomain
   
   put item 4 to -1 of someUrl into pathBit
   put the number of items of pathBit into maxNum
   if (maxNum mod 2) is not 0 then 
      put item -1 of pathBit into extraBit
      delete item -1 of pathBit
      return false -- it is not a Fedwiki url ?
   end if
   
   put maxNum/2 into maxLineUpNum
   repeat with lineUpNum = 1 to maxLineUpNum
      put 2*lineUpNum - 1 into itemNum
      put item itemNum of pathBit into viewOrDomain
      put item (itemNum + 1) of pathBit into pageSlug
      _stripEndHashFromSlug pageSlug
      
      if viewOrDomain = "view" then
         put urlDomain into someDomain
      else
         put viewOrDomain into someDomain
      end if
      put pageSlug into urlArray [lineUpNum]["slug"]
      put someDomain into urlArray [lineUpNum]["someDomain"]
   end repeat
   return urlArray
end fedwiki_ConstructUrlArray


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


