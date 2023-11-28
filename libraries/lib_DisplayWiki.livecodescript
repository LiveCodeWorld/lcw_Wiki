script "lib_DisplayWiki"
--> MetaData
-
license: GPLv3
name: lib_DisplayWiki
type: library
version: 0.2


--> Working on
-
command gitwiki_FixLocalDomain localhostDomain, pDisplayView
   put wiki_GetFolder (localhostDomain) into wikiFolder
   put gitwiki_GetFolder (localhostDomain) into gitWikiFolder
   --
   put wiki_NumberOfpages (wikiFolder) into wikiPageNum
   put wiki_NumberOfpages (gitWikiFolder) into gitWikiPageNum
   --
   switch
      case (wikiPageNum = 0) AND (gitWikiPageNum > 0)
         revDeleteFolder wikiFolder
         folder_CreateSymLink gitWikiFolder, wikiFolder
         break
      case wikiPageNum < 1
         if folder_IsSymLink (wikiFolder) then
            breakpoint
         else
            revDeleteFolder wikiFolder
         end if
         break
      default
         breakpoint
   end switch
   
   if exists (pDisplayView) then
      display_EmptyLocalWikis pDisplayView
   end if
end gitwiki_FixLocalDomain

command display_WikiConfig
   put wiki_GetConfigFile() into wikiConfigFile
   put text_EditorApplicationPath() into applicationPath
   launch wikiConfigFile with applicationPath
end display_WikiConfig

on mDoubleUp_WikiLocal displayView, shortFolder
   mDoubleUp_WikiLocalIndex displayView, shortFolder
end mDoubleUp_WikiLocal

on mDoubleUp_WikiLocalIndex displayView, shortFolder
   if the optionKey is "down" then
      breakpoint
      gitwiki_FixLocalDomain shortFolder, displayView
      exit to top
      breakpoint
   end if
   --
   if the shiftKey is "down" then
      launch_LocalhostWiki shortFolder
   else
      put wiki_GetFolder (shortFolder) into wikiFolder
      finder_Reveal wikiFolder
      
      /*
      put display_ListBrowsers ("Local Wiki") into browserViews
      put line 1 of browserViews into browserView
      --
      put wiki_LocalUrl (sDomain) into localWikiUrl
      display_Browser localWikiUrl, browserView, "Local Wiki"
      */
   end if
end mDoubleUp_WikiLocalIndex

command display_EmptyLocalWikis pDisplayView, pFilter, pTitle
   if pTitle is empty then put "Empty Local Wikis" into pTitle
   put "Wiki | Local" into menuBit -- was "Wiki | Git"
   
   put wiki_ListEmptyLocalFolders (true) into emptyFolders
   --
   display_WikiFolders emptyFolders, menuBit, pDisplayView, pFilter, pTitle, "Local Wikis"
   put the result into dView
   return dView
end display_EmptyLocalWikis dView, pFilter

command display_LocalWithoutAstral dView, pFilter
   put wiki_RootFolder() into wikiFolder
   put folder_ListShortAll (wikiFolder) into wikiFolders
   --
   put wikiFolders into localhostFolders
   filter localhostFolders with "*localhost"
   --
   repeat for each line localhostDomain in localhostFolders
      put wiki_AstralFromLocalhost (localhostDomain) into astralDomain
      if astralDomain is not among the lines of wikiFolders then
         put localhostDomain & CR after wihtouAstralDomains
      end if
   end repeat
   delete char -1 of wihtouAstralDomains
   --
   url_SortDomainIndex wihtouAstralDomains
   --
   display_WikiFolders wihtouAstralDomains, "Wiki | Local", dView, pFilter, "Local Without Astral", "Local Wikis"
   return the result
end display_LocalWithoutAstral

command display_LocalWikis pDisplayView, pTitle, pFilter
   if pTitle is empty then put "All" into pTitle
   put "Local Wikis" into pStackLabel
   put "Wiki | Local" into menuBit -- was "Wiki | Git"
   --
   put wiki_RootFolder() into wikiFolder
   --
   switch token 1 of pTitle
      case "Dynadot"
         put dynadot_ListAstralDomains() into wikiFolders
         break
      case "astral"
         put folder_ListShortAll (wikiFolder) into localAstralDomains
         filter localAstralDomains with "*.astralship.wiki"
         put dynadot_StripSubDomainNames (localAstralDomains, "astralship.wiki") into wikiFolders
         break
      case "non"
         put folder_ListShortNonSymLinked (wikiFolder) into wikiFolders
         break
      case "sym"
         put folder_ListShortSymLinked (wikiFolder) into wikiFolders
         break
      default
         put folder_ListShortAll (wikiFolder) into wikiFolders
   end switch
   if pFilter is not empty then filter wikiFolders with pFilter
   url_SortDomainIndex wikiFolders
   --
   display_WikiFolders wikiFolders, menuBit, pDisplayView, pWikiFilter, pTitle, pStackLabel
   put the result into dView
   return dView
end display_LocalWikis

command display_GitWikis gitWikiFolders, pDisplayView, pWikiFilter, pTitle
   if pTitle is empty then put "Git Folders" into pTitle
   display_WikiFolders gitWikiFolders, "Wiki | Git", pDisplayView, pWikiFilter, pTitle
   put the result into dView
   return dView
end display_GitWikis

command display_WikiFolders wikiFolders, menuBit, pDisplayView, pWikiFilter, pTitle, pStackLabel
   if pStackLabel is empty then put "Wiki" into pStackLabel
   if exists (pDisplayView) is false then
      put display_FindIndexView ("Wiki", "Git Folders") into pDisplayView
   end if
   if exists (pDisplayView) is true then
      if pWikiFilter is "none" then
         put empty into pWikiFilter
      else if pWikiFilter is empty then
         put the wiki_Filter of pDisplayView into pWikiFilter
      end if
   end if
   --
   lock screen
   display_Data wikiFolders, pTitle, pStackLabel, pDisplayView
   put the result into dView
   
   # Colour lines
   put dynadot_ListEarthWikis() into dynadotEarthWikis
   set the coloured_lines ["red"] of dView to dynadotEarthWikis
   unlock screen
   --
   if pWikiFilter is not empty then
      set the wiki_Filter of dView to pWikiFilter
   end if
   --
   display_SetToolMenus menuBit, dView, "lcw_Wiki"
   return dView
end display_WikiFolders


--> Events
-
on mDoubleUp_WikiGit dView, sDomain
   if the optionKey is "down" then breakpoint
   --
   put gitwiki_GetFolder (sDomain) into gitWikiFolder
   --
   switch
      case the shiftKey is "down"
         breakpoint
         
         put gitwiki_GetFolder ("dead.anarchive.earth") into toFolder
         --
         if folder_IsSymLink (gitWikiFolder) then
            breakpoint
         end if
         --
         if wiki_FolderHasNoPages (wikiFolder) then
            
         end if
         --
         revMoveFolder gitWikiFolder, toFolder
         set the deleted_Line of dView to sDomain
         break
      case there is not a folder gitWikiFolder
         breakpoint
         break
      default
         finder_Reveal gitWikiFolder
         -- launch url ("http://" & sDomain)
   end switch
end mDoubleUp_WikiGit

on mDoubleUp_WikiEarth displayView, earthDomain
   if the optionKey is "down" then breakpoint
   launch_LocalhostWiki earthDomain
end mDoubleUp_WikiEarth

command launch_LocalhostWiki wikiDomain
   put wiki_LocalhostUrl (wikiDomain) into localWikiUrl
   launch url localWikiUrl
   return localWikiUrl
end launch_LocalhostWiki

command launch_LocalWiki sDomain
   put wiki_LocalUrl (sDomain) into localWikiUrl
   launch url localWikiUrl
   return localWikiUrl
end launch_LocalWiki

function wiki_LocalhostUrl wikiDomain
   put wiki_LocalHostDomain (wikiDomain) into localhostDomain
   put wiki_LocalUrl (localhostDomain) into localhostURL
   return localhostURL
end wiki_LocalhostUrl

function wiki_LocalUrl sDomain
   put "http://" & sDomain & ":3000" into localWikiUrl
   return localWikiUrl
end wiki_LocalUrl

command display_DynadotWikis domainName, pDisplayView, pFilter
   if exists (pDisplayView) is false then
      put display_FindIndexView ("Dynadot", "Earth Wikis") into pDisplayView
   end if
   --
   put dynadot_ListAllSubDomain (domainName) into wikiDomains
   --
   if pFilter is not empty then
      filter wikiDomains with pFilter
   end if
   --
   display_Data wikiDomains, domainName, "Dynadot", pDisplayView
   put the result into dView
   display_SetToolMenus "Wiki | Earth", dView, "lcw_Wiki"
   return dView
end display_DynadotWikis

command display_SitemapArray wikiDomain, pSincePeriod, pDisplayView, pPalette
   -- if pSincePeriod is empty then put "1 week" into pSincePeriod
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
end display_SitemapArray


--> Display | Wiki
-
command display_EarthWikis pDisplayView
   put dynadot_ListEarthWikis() into wikiDomains
   --
   if exists (pDisplayView) is false then
      put display_FindIndexView ("Dynadot", "Earth Wikis") into pDisplayView
   end if
   --
   display_Data wikiDomains, "Earth Wikis", "Dynadot", pDisplayView
   put the result into dView
   display_SetToolMenus "Wiki | Earth", dView, "lcw_Wiki"
   return dView
end display_EarthWikis

command diplay_GitWikiFolders pDisplayView, pWikiFilter
   put gitwiki_ListFolders (pWikiFilter, true) into gitWikiFolders
   --
   display_WikiFolders gitWikiFolders, pDisplayView, pWikiFilter
   return the result
end diplay_GitWikiFolders

command display_Wiki pWikiURL
   wiki_Start
   --
   if pWikiURL is empty then put wiki_DefaultLocalUrl() into pWikiURL
   put line 1 of wiki_ListBrowsers() into browserView
   send "display_WikiBrowser pWikiURL,browserView" to me in 20 ticks
   return the result
end display_Wiki

command display_WikiBrowser pWikiURL, pBrowserView, pStackLabel, pStackStyle
   if pStackLabel is empty then put "Wiki" into pStackLabel
   if pWikiURL is empty then put wiki_DefaultLocalUrl() into pWikiURL
   if pStackStyle is empty then put "toplevel" into pStackStyle
   --
   display_Browser pWikiURL, pBrowserView, pStackLabel, pStackStyle, "View|Obeya|Studio"
   -- display_View "View|Obeya|Studio", pWikiURL, pStackLabel, empty, "browser_URL", pStackStyle
   put the result into browserView
   display_SetMenu browserView, "Obeya | Studio", "title_Menu"
   --
   return browserView
end display_WikiBrowser


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
   --
   _DisplayPageArray pageArray, wikiDomain
   put the result into displayView
   --
   set the tool_Menus of displayView to "Wiki | Page"
   return displayView
end display_WikiPage


--> Display | Wiki | Pages
-
command display_RecentDomainWikiPages wikiDomain, pSincePeriod, pDisplayView, pPalette
   if pSincePeriod is empty then put "1 week" into pSincePeriod
   --
   put fedwiki_FetchModifiedPageArray (wikiDomain, pSincePeriod) into sitePageArray
   --
   display_Data sitePageArray, "Recent Pages", wikiDomain, pDisplayView, pPalette
   put the result into displayView
   return displayView
end display_RecentDomainWikiPages

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
   _DisplayPageArray pageArray, pDomainTitle
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


--> Wiki
-
function wiki_ListBrowsers
   return display_List ("View|Browser", "Wiki")
end wiki_ListBrowsers

function wiki_DefaultLocalUrl
   put "http://localhost:3000" into wikiURL
   return wikiURL
end wiki_DefaultLocalUrl


--> Private
-
private command _DisplayPageArray pageArray, pDomainTitle
   if pDomainTitle is empty then put "Wiki" into pDomainTitle
   put pageArray ["title"] into pTitle
   put pageArray ["story"] into storyArray
   put pageArray ["journal"] into journalArray
   --
   display_Data storyArray, pTitle, pDomainTitle
   put the result into displayView
   --
   set the wiki_Domain of displayView to wikiDomain
   set the page_Slug of displayView to pSlug
   set the page_Aray of displayView to pageArray
   --
   return displayView
end _DisplayPageArray

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

