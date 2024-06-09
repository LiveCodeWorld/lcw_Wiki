script "lib_DisplayWiki"
--> MetaData
-
license: GPLv3
name: lib_DisplayWiki
type: library
version: 0.3

/*
command display_WikiDomain wikiDomain, pDisplayView, pPalette
   set the cursor to watch
   -- atopia_DeleteWikiSitemap wikiDomain
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
*/


--> Working on
-
command display_WikiGhost wikiDomain, pageArray
   put pageArray ["title"] into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   
   # Find Wiki Browser
   put display_ListWikiBrowsers (wikiDomain) into wikiBrowser
   if exists (wikiBrowser) is true then
      object_GoTo wikiBrowser
   else
      display_Wiki wikiDomain
      put the result into wikiBrowser
      wait 40 ticks
   end if
   
   # Display Ghost
   set the ghost_PageArray of wikiBrowser to pageArray
   --
   return wikiBrowser
end display_WikiGhost


--> Display | Wiki | list
-
function display_ListWikiBrowsers pWikiDomain
   return display_List ("View|Wiki|Browser", pWikiDomain)
end display_ListWikiBrowsers

command display_WikiPage wikiDomain, pSlug
   put line 1 of display_ListWikiBrowsers (wikiDomain) into wikiView
   if exists (wikiView) is false then
      display_Wiki wikiDomain
      put the result into wikiView
   end if
   
   set the page_Slug of wikiView to pSlug
   -- set the tool_MenuBit of displayView to "Wiki | Page"
   return displayView
end display_WikiPage

private command _DisplayWikiPage wikiDomain, pSlug
   put pageArray_Fetch (wikiDomain, pSlug) into pageArray
   --
   _DisplayPageArray pageArray, pSlug, wikiDomain
   put the result into displayView
   --
   set the wiki_Domain of displayView to wikiDomain
   set the page_Slug of displayView to pSlug
   --
   set the tool_MenuBit of displayView to "Wiki | Page"
   return displayView
end _DisplayWikiPage


command display_WikiPrefArray
   put wikiPreference_GetArray() into prefArray
   display_Tool prefArray, "prefArray", "Localhost"
   return the result
end display_WikiPrefArray

command display_WikiOwner wikiDomain, pDisplayView
   -- display_OwnerJson
   put wikiServer_GetOwnerData (wikiDomain) into ownerData
   display_Tool ownerData, wikiDomain, "Wiki Owner", pDisplayView
   put the result into dView
   return dVIEW
end display_WikiOwner


--> Display
-
command display_ServerData
   put wikiServer_GetData() into wsData
   display_Array wsData, "WikiServer_Data", "Wiki"
   put the result into dView
   return dView
end display_ServerData

command display_GardenEcodata pEcoData
   if pEcoData is not an array then
      put wikiGarden_GetModel() into pEcoData
   end if
   
   display_Tools pEcoData, "Eco Data", "Wiki | Eco", "Wiki", "lcw_Wiki"
   return the result
end display_GardenEcodata


--> Display | Wiki
-
command display_WikiDomain wikiDomain
   put display_ListWikiBrowsers (wikiDomain) into dViews
   if dViews is empty then
      wikiServer_SwitchIfGarden wikiDomain
      display_Wiki wikiDomain
   else
      repeat for each line dView in dViews
         put the stack_Name of dView into stackName
         topLevel stack stackName
      end repeat
   end if
end display_WikiDomain

command display_Wiki wikiDomain, pBrowserView, pStackLabel, pStackStyle
   -- display_LocalWiki
   _NormalizeWikiBrowser pBrowserView
   
   if pStackLabel is empty then put wikiDomain into pStackLabel
   put wiki_ConstructUrl (wikiDomain) into wikiURL
   
   # Start server
   -- wikiServer_StartNode -- wikiServer_Start
   -- if the result is not empty then wait 20 ticks
   
   # Display Browser
   display_WikiBrowser wikiURL, pBrowserView, pStackLabel, pStackStyle
   return the result
end display_Wiki

command display_WikiBrowser pWikiURL, pBrowserView, pStackLabel, pStackStyle, pWikiViewName
   if pWikiURL is empty then put "http://livecode.world" into pWikiURL
   -- if pWikiURL is empty then put wiki_DefaultLocalUrl() into pWikiURL
   --
   if pStackLabel is empty then put "Browser" into pStackLabel
   if pWikiViewName is empty then
      put "View|Wiki|Browser" into pWikiViewName
      -- put "View|Browser" into pWikiViewName
      -- put "View|Obeya|Studio" into pWikiViewName
   end if
   
   if pStackLabel is empty then put "Wiki" into pStackLabel
   if pStackStyle is empty then put "toplevel" into pStackStyle
   --
   # Display
   display_ModuleInstance pWikiViewName, pWikiURL, pStackLabel, pBrowserView, "browser_URL", pStackStyle
   put the result into browserView
   
   # Set Menus
   -- display_SetMenu browserView, "Browser"
   display_SetMenu browserView, "Obeya | Studio"
   --
   return browserView
end display_WikiBrowser

private command _NormalizeWikiBrowser @browserView
   switch
      case browserView = "New"
         put empty into browserView
         break
      case exists (browserView) is false
         put wiki_Browser() into browserView
         break
      default
         # But is is a browser
         put the browser_View of browserView into browserView
   end switch
   return exists (browserView)
end _NormalizeWikiBrowser


--> Display | Wiki | Page
-
command display_PageArray pageArray, pPageTitle
   _DisplayPageArray pageArray, pPageTitle, "PageArray"
   put the result into displayView
   --
   display_SetInteractions displayView, "PageArray", "mDoubleUp_PageArray"
   return displayView
end display_PageArray

private command _DisplayPageArray pageArray, pTitle, pDomainTitle
   put pageArray ["title"] into pTitle
   put pageArray ["story"] into storyArray
   put pageArray ["journal"] into journalArray
   --
   display_Data pageArray, pTitle, pDomainTitle
   put the result into displayView
   set the page_Aray of displayView to pageArray
   --
   return displayView
end _DisplayPageArray


--> Display | SiteMapArray
-
command display_LocalSiteMapArray wikiDomain, pSincePeriod, pDisplayView, pPalette
   put wikiSiteMap_GetArray (wikiDomain) into sitemapArray
   --
   display_SiteMapArray sitemapArray, wikiDomain, pSincePeriod
   put the result into displayView
   --
   put wikiFile_ConstructSiteMap (pWikiDomain) into siteMapFile
   set the sitemap_File of displayView to siteMapFile
   return displayView
end display_LocalSiteMapArray

command display_WikiSitePageArray wikiDomain, pSincePeriod, pDisplayView, pPalette
   put fedwiki_FetchSitemapArray (wikiDomain) into sitemapArray
   --
   display_SiteMapArray sitemapArray, wikiDomain, pSincePeriod
   put the result into displayView
   return displayView
end display_WikiSitePageArray

command display_SiteMapArray sitemapArray, pTitle, pSincePeriod
   put fedwiki_FilteredSitePageArray (sitemapArray, pSincePeriod) into sitePageArray
   --
   display_Data sitePageArray, pTitle, "Site Page Array"
   put the result into displayView
   set the sitemap_Array of displayView to sitemapArray
   set the site_PageArray of displayView to sitePageArray
   --
   set the title_Menu of displayView to "Global | Wiki | Sitemap | Tree | Menu"
   set the line_Menu of displayView to "Global | Wiki | Sitemap | Line | Menu"
   set the mouse_DoubleUp of displayView to "mDoubleUp_DisplayWikiPage"
   --
   return displayView
end display_SiteMapArray

function wiki_CheckFolderColour wikiDomain
   put gitwiki_GetFolder (wikiDomain) into gitWikiFolder
   put wikiFolder_Get (wikiDomain) into wikiFolder
   switch
      case there is not a folder gitWikiFolder
         return "red"
      case folder_IsSymLink (wikiFolder)
         return "green"
      case there is a folder wikiFolder
         return "black" -- it's a normal folder
      default
         return "orange" -- not created
   end switch
end wiki_CheckFolderColour

command display_WikiSiteMap wikiDomain, pDisplayView
   -- put "media.localhost:3000" into wikiDomain
   put fedwiki_FetchSitemapArray (wikiDomain) into siteMapArray
   --
   display_Data siteMapArray, wikiDomain, "Wiki Sitemap", pDisplayView
   put the result into dView
   return dView
end display_WikiSiteMap


--> Events
-
on mDoubleUp_WikiGit dView, wikiDomain
   if the optionKey is "down" then breakpoint
   --
   put gitwiki_GetFolder (wikiDomain) into gitWikiFolder
   put url_Construct (wikiDomain) into localURL
   put wiki_Browser() into browserView
   switch
      case there is not a folder gitWikiFolder
         finder_Reveal gitWikiFolder
         break
      case the shiftKey is "down" AND exists (browserView)
         wiki_AddPortToDomain wikiDomain
         set the page_Title [wikiDomain] of wiki_Browser() to "welcome-visitors"
         -- launch url localURL
         break
      default
         -- put wiki_Browser() into browserView
         -- put pageArray_Fetch (wikiDomain, "welcome-visitors", "3000") into pageArray
         -- put ":3000" after wikiDomain
         -- set the page_Title [wikiDomain] of browserView to "welcome-visitors"
         display_Wiki wikiDomain
   end switch
end mDoubleUp_WikiGit

on mDoubleUp_WikiEarth displayView, earthDomain
   if the optionKey is "down" then breakpoint
   launch_LocalhostWiki earthDomain
end mDoubleUp_WikiEarth

on mDoubleUp_WikiPhotos displayView, shortFile
   if the optionKey is "Down" then breakpoint
   --
   put the photo_Folder of displayView into photoFolder
   put photoFolder & shortFile into photoFile
   --
   display_Image photoFile
   --
   put the title_Text of displayView into wikiDomain
   if wikiDomain = "Commons" then
      put "media.localhost:3000" into wikiDomain
   else
      put ":3000" after wikiDomain
   end if
   put wiki_FindImageListData (wikiDomain, shortFile) into imageListdata
   display_Data imageListdata, "Found Images", wikiDomain
end mDoubleUp_WikiPhotos

on mDoubleUp_WikiLocalIndex dView, wikiDomain
   if the optionKey is "down" then breakpoint
   --
   put wiki_Browser() into browserView
   if the shiftKey is "down" then
      if exists (browserView) then
         set the page_Title [wikiDomain] of browserView to "welcome-visitors"
      else
         put wikiFolder_Get (wikiDomain) into wikiFolder
         finder_Reveal wikiFolder
         launch_LocalhostWiki wikiDomain
      end if
   else
      display_Wiki wikiDomain, browserView
   end if
end mDoubleUp_WikiLocalIndex


--> Wiki | Browser
-
function wiki_Browser
   -- put display_FindCloned ("View|Obeya|Studio", "Wiki") into browserView
   put line 1 of wiki_ListBrowsers() into browserView
   return browserView
end wiki_Browser

function wiki_ListBrowsers
   return display_List ("View|Browser,View|Obeya|Studio")
end wiki_ListBrowsers


--> Launch
-
command launch_LocalhostWiki wikiDomain
   put wiki_LocalhostUrl (wikiDomain) into localWikiUrl
   launch url localWikiUrl
   return localWikiUrl
end launch_LocalhostWiki

command launch_LocalWiki sDomain
   put wiki_ConstructUrl (sDomain) into localWikiUrl
   launch url localWikiUrl
   return localWikiUrl
end launch_LocalWiki

command launch_EtcHosts
   put text_EditorApplicationPath() into applicationPath
   launch "/etc/hosts" with applicationPath
   put the result into launchResult
   return launchResult
end launch_EtcHosts

command launch_WikiConfig
   put wikiFile_Config() into wikiConfigFile
   put text_EditorApplicationPath() into applicationPath
   launch wikiConfigFile with applicationPath
end launch_WikiConfig

command launch_TunnelConfig
   put tunnel_GetYamlFile() into yamlFile
   put text_EditorApplicationPath() into applicationPath
   launch yamlFile with applicationPath
end launch_TunnelConfig

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


--> Display | Wiki | List
-
command display_LocalWikis pDisplayView, pTitle, pFilter
   if pTitle is empty then put "All" into pTitle
   --
   put wikiDomain_List (pFilter) into wikiFolders
   --
   display_WikiFolders wikiFolders, "Wiki | Local", pDisplayView, pFilter, pTitle, "Local Wikis"
   put the result into dView
   return dView
end display_LocalWikis

command display_NonSymLinked pDisplayView, pFilter, pTitle
   breakpoint
   if pTitle is empty then put "Non-symlinked" into pTitle
   --
   put ecoData_GetFarmFolder() into wikiFolder
   put folder_ListShortNonSymLinked (wikiFolder) into wikiFolders
   url_SortDomainIndex wikiFolders
   --
   display_WikiFolders wikiFolders, "Wiki | Local", pDisplayView, pFilter, pTitle, "Local Wikis"
   put the result into dView
   return dView
end display_NonSymLinked

command display_LocalAstralWikis pDisplayView, pStripDynadot
   put wikiDomain_List() into localAstralDomains
   --
   if pStripDynadot is true then
      put dynadot_StripSubDomainNames (localAstralDomains, "astralship.wiki") into wikiFolders
      put "Without Dynadot" into sTitle
   else
      put "All Astral" into sTitle
   end if
   --
   display_WikiFolders wikiFolders, "Wiki | Local", pDisplayView, "*.astralship.wiki", sTitle, "Local Astral Wikis"
   put the result into dView
   return dView
end display_LocalAstralWikis

command display_LocalSymWikis pDisplayView, pFilter, pTitle
   if pTitle is empty then put "Symlinked Wikis" into pTitle
   --
   put ecoData_GetFarmFolder() into wikiFolder
   put folder_ListShortSymLinked (wikiFolder) into wikiFolders
   --
   display_WikiFolders wikiFolders, "Wiki | Local", pDisplayView, pFilter, pTitle, "Local Wikis"
   put the result into dView
   return dView
end display_LocalSymWikis


--> Working on
-
command display_GitWikiFolders pDisplayView, pWikiFilter
   if pWikiFilter is empty then
      put "Git Folders" into pTitle
   else
      put pWikiFilter into pTitle
   end if
   --
   if exists (pDisplayView) is false then
      put display_FindView ("Git Wikis") into pDisplayView
   end if
   --
   if exists (pDisplayView) then
      put the wiki_Filter of pDisplayView into pWikiFilter
      if pWikiFilter is not empty then
         put pWikiFilter into pTitle
      end if
   end if
   --
   put gitwiki_ListAllLocalFolders() into gitWikiShortFolders
   --
   display_GitWikis gitWikiShortFolders, pDisplayView, pWikiFilter, pTitle
   put the result into dView
   return dView
end display_GitWikiFolders

command display_GitWikis gitWikiShortFolders, pDisplayView, pWikiFilter, pTitle
   if pTitle is empty then put "Git Folders" into pTitle
   display_WikiFolders gitWikiShortFolders, "Wiki | Git", pDisplayView, pWikiFilter, pTitle, "Git Wikis"
   put the result into dView
   return dView
end display_GitWikis

command display_EtcHosts pSystemPassword
   if pSystemPassword is empty then
      put lcw_Ask ("Enter system password...") into pSystemPassword
   end if
   put hosts_Get (pSystemPassword) into hostsText
   --
   display_Text hostsText, "Current", "/etc/hosts"
   return the result
end display_EtcHosts

command display_LocalWithoutAstral dView, pFilter
   put ecoData_GetFarmFolder() into wikiFolder
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
      --
      display_PageArray pageArray, wikiDomain
      put the result into displayView
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
command display_FedwikiPageJson pageJson
   put json_ToArray (pageJson) into pageArray
   display_PageArray pageArray, "pageJson"
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
