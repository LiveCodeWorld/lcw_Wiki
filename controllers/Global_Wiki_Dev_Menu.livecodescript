script "Global | Wiki | Dev | Menu"
--> MetaData
-
license: GPLv3
name: Global | Wiki | Dev | Menu
type: controller
author: David Bovill
version: 0.2

/*
Here you can describe this menu.
Full help text should be provided on the linked wiki.
*/

--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_Target [tObject]
   -- return display_MenuTarget(tObject)
   return the display_View of tObject
end menu_Target


--> Global | Wiki | Dev | Menu
-
on menu_ListLocalWikis
   display_LocalWikis
end menu_ListLocalWikis

on submenu_Tunnel
   return "Global | Tunnel | Menu"
end submenu_Tunnel

-- on submenu_ObeyaStudio
return "Global | Obeya | Studio | Menu"
end submenu_ObeyaStudio

on menu_DisplayEtcHosts
   launch_EtcHosts
   if the shiftKey is "Down" then
      display_EtcHosts
   end if
end menu_DisplayEtcHosts

on menu_UpdateEtcHosts dView
   display_LocalWikis dView
   --
   put the displayed_Index of dView into localHosts
   filter localHosts with "*localhost" -- just in case
   --
   breakpoint
   put hosts_ConstructText (localHosts) into hostsText
   hosts_Set hostsText
end menu_UpdateEtcHosts

private on ____
end ____

on menu_Xterm
   display_Xterm true
end menu_Xterm

on menu_XtermClear browserView
   put line 1 of xterm_ListBrowsers() into xtermView
   if exists (xtermView) is false then
      display_Xterm true
      put the result into xtermView
   end if
   --
   ttyd_Execute "clear", xtermView
end menu_XtermClear

on menu_TestFaasd
   post "Hello world" to url "https://faasd.platform.earth/function/activity"
   put it
end menu_TestFaasd

on menu_MatrixChat
   display_Browser "https://app.element.io/#/room/#fedwiki:matrix.org"
end menu_MatrixChat

on menu_ImageSearch
   -- https://commons.wikimedia.org/w/api.php?action=query&generator=images&prop=imageinfo&gimlimit=500&redirects=1&titles=Cat&iiprop=timestamp|user|userid|comment|canonicaltitle|url|size|dimensions|sha1|mime|thumbmime|mediatype|bitdepth
   -- /w/api.php?action=query&format=json&origin=*&titles=North%20Africa&generator=allimages
   put lcw_Ask ("What do you want to search for", "Cat") into someTitle
   put urlencode (someTitle) into encodedTitle
   -- replace "+" with "%20" in encodedTitle
   --
   put "https://commons.wikimedia.org" into restURL
   put "/w/api.php?action=query&generator=images&prop=imageinfo" after restURL
   put "&gimlimit=100"  after restURL
   put "&redirects=1"  after restURL
   
   -- put "/w/api.php?action=query&format=json&origin=*&generator=allimages" after restURL
   put "&titles=" & encodedTitle after restURL
   put "&iiprop=timestamp|user|userid|comment|canonicaltitle|url|size|dimensions|sha1|mime|thumbmime|mediatype|bitdepth" after restURL
   put "&format=json" after restURL
   
   put url restURL into someJSON
   display_JSON  someJSON
end menu_ImageSearch

on submenu_Medium
   return "Global | Medium | Menu"
end submenu_Medium

on menu_IplayerDownloadsFolder
   put _GetDomain() into wikiDomain
   put fedwiki_LocalAssetsFolder (wikiDomain) into assetsFolder
   --
   answer folder "Iplayer downloads..." with assetsFolder
   put it into dFolder
   --
   iplayer_SetDefaultOutupFolder dFolder
end menu_IplayerDownloadsFolder

on menu_AssetsFolder
   put _GetDomain() into wikiDomain
   put fedwiki_LocalAssetsFolder (wikiDomain) into assetsFolder
   finder_Reveal assetsFolder
end menu_AssetsFolder

on menu_WikiRootFolder
   put fedwiki_GetLocalWikiRoot() into wikiRootFolder
   finder_Reveal wikiRootFolder
end menu_WikiRootFolder

private on ____
end ____

on menu_DisplayJellyBrowser
   go to stack "Fedwiki Editor"
end menu_DisplayJellyBrowser

on menu_DisplayWikiBrowser
   go to stack "Wiki"
end menu_DisplayWikiBrowser

private on _
end _

on menu_DisplayPages mTarget, topDomain
   put _GetWikiView (mTarget) into wikiView
   --
   switch topDomain
      case "Worldscape"
         put "http://space.thought.garden/view/welcome-visitors/view/changes-to-this-site/view/worldscape/video.livecode.world/projection-mapping/view/funkhaus" into someURL
         set the browser_URL of wikiView to someURL
         break
      case "Jelly Fish"
         put "http://arodic.github.io/p/jellyfish/" into someURL
         set the browser_URL of wikiView to someURL
         break
      default
         put "http://" & topDomain into someURL
         set the browser_URL of wikiView to someURL
         --
         put fedwiki_FetchSitemapArray (topDomain) into sitemapArray
         put fedwiki_ConstructSiteMapTitleArray (sitemapArray) into sitemapTitleArray
         display_Array sitemapTitleArray, topDomain, "Global | Wiki | Tree | Menu", "Global | Wiki | Tree | Line | Menu"
         put the result into displayView
         set the wiki_Domain of displayView to topDomain
   end switch
end menu_DisplayPages

on menu_SetBrowserRect mTarget, whichRect
   put _GetWikiView (mTarget) into wikiView
   --
   switch whichRect
      case "Left"
         put "24,23,536,1183" into someRect
         break
      case "Right"
         break
      case "Full"
         break
      case "Screen"
         -- 0,0,1920,1200
         put the screen_Rect of the target into someRect
         break
   end switch
   
   -- put the rect of browserView
   set the rect of wikiView to someRect
end menu_SetBrowserRect

on menu_FetchPageArray wikiView
   put pageArray_Fetch ("thought.garden", "welcome-visitors") into pageArray
   set the page_Array of wikiView to pageArray
end menu_FetchPageArray

on menu_DisplayPageArray wikiView
   put the page_Array of wikiView into pageArray
   display_Data pageArray
end menu_DisplayPageArray

on menu_DisplayKeywords
   -- "http://carlos.proto.institute/view/welcome-visitors/view/imagine-keywords"
   put pageArray_Fetch ("carlos.proto.institute", "imagine-keywords") into pageArray
   put pageArray_GetPageLinks (pageArray) into wikiLinks
   --
   display_Lines wikiLinks, "D4A Keywords", "mDoubleUp_DownloadImages", "carlos.proto.institute"
   put the result into displayView
   
   set the title_Menu of displayView to "Global | D4A | Menu"
   set the line_Menu of displayView to "Global | D4A | Line | Menu"
end menu_DisplayKeywords

on menu_FetchChromeFedwiki
   put chrome_GetURl() into wikiURL
   fedwiki_DeconstructURL wikiURL, pageSlug, wikiDomain
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   --
   display_Array pageArray
end menu_FetchChromeFedwiki

private on ______
end ______

function _GetWikiView mTarget
   -- "browser_View" is on card script of stack "Fedwiki Editor"
   put the wiki_View of cd 1 of stack "Fedwiki Editor" into wikiView
   return wikiView
end _GetWikiView

getprop checked_Ngrok
   return ngrok_ListProcessIds() is not empty
end checked_Ngrok

getprop dream_Domains
   put "Jelly Fish" & CR after topDomains
   put "-" & CR after topDomains
   put "david.icotopia.io" & CR after topDomains
   put "trevor.icotopia.io" & CR after topDomains
   put "video.icotopia.io" & CR after topDomains
   put "david.culturecollective.cc" & CR after topDomains
   --
   delete char -1 of topDomains
   return topDomains
end dream_Domains

getprop top_Domains
   put "Jelly Fish" & CR after topDomains
   put "Worldscape" & CR after topDomains
   put "-" & CR after topDomains
   put "outlandish.academy" & CR after topDomains
   put "david.outlandish.academy" & CR after topDomains
   put "nina.outlandish.academy" & CR after topDomains
   put "trevor.outlandish.academy" & CR after topDomains
   --
   delete char -1 of topDomains
   return topDomains
end top_Domains

getprop show_HiddenFiles
   put finder_GetShowInvisibleFiles() into someBoolean
   return someBoolean
end show_HiddenFiles

on menu_TestFaasd
   post "Hello world" to url "https://faasd.platform.earth/function/activity"
   put it
end menu_TestFaasd

on menu_Xterm
   display_Xterm true
end menu_Xterm

on menu_XtermClear browserView
   put line 1 of xterm_ListBrowsers() into xtermView
   if exists (xtermView) is false then
      display_Xterm true
      put the result into xtermView
   end if
   --
   ttyd_Execute "clear", xtermView
end menu_XtermClear
