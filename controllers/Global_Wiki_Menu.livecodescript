script "Global_Wiki_Menu"
--> MetaData
-
license: GPLv3
name: Global_Wiki_Menu
type: controller
version: 0.4


--> Global | Wiki | Tree | Menu
-
on menu_DisplayWiki arrayView, dreamDomain
   put fedwiki_FetchPageListArray (dreamDomain) into pageListArray
   
   display_Array pageListArray, dreamDomain, "Global | Wiki | Tree | Menu", "Global | Wiki | Tree | Line | Menu"
   
   -- put fedwiki_ListPageSlugs (dreamDomain)
end menu_DisplayWiki


--> Global | Wiki | Tree | Line | Menu
-
on menu_UploadPageJson arrayView, dreamDomain
   put the title_Text of arrayView into fedwikiDomain
   put the top_Array of arrayView into itemArray
   put itemArray ["slug"] into pageSlug
   
   put fedwiki_FetchPageJson (fedwikiDomain, pageSlug) into pageJSON
   fedwiki_StorePage pageSlug, dreamDomain, pageJSON
   put merge ("http://hosting.permanent.wiki/view/welcome-visitors/[[dreamDomain]]/[[pageSlug]]") into pageURL
   launch url pageURL
end menu_UploadPageJson

on menu_DisplayPageArray arrayView
   put the title_Text of arrayView into fedwikiDomain
   put the top_Array of arrayView into itemArray
   put itemArray ["slug"] into pageSlug
   
   display_WikiPageArray
end menu_DisplayPageArray


--> Global | Wiki | Menu
-
on menu_StartWiki
   set the cursor to watch
   open process wiki for update
   -- Federated Wiki server listening on 3000 in mode: development
   read from process wiki until "Federated Wiki server listening on 3000 in mode: development"
   put it into wikiInfoToParse
   
   put "http://localhost:3000" into localWikiURL
   launch url localWikiURL
end menu_StartWiki

on menu_StopWiki
   if the platform = "MacOS" then
      kill process wiki
   else
      close process wiki
   end if
   -- put the openprocesses
end menu_StopWiki

on _
end _

on menu_DisplayPages mTarget, topDomain
   switch topDomain
      case "Worldscape"
         put "http://space.thought.garden/view/welcome-visitors/view/changes-to-this-site/view/worldscape/video.livecode.world/projection-mapping/view/funkhaus" into someURL
         set the displayed_Domain of mTarget to someURL
         break
      case "Jelly Fish"
         put "http://arodic.github.io/p/jellyfish/" into someURL
         set the displayed_Domain of mTarget to someURL
         break
      default
         set the displayed_Domain of mTarget to topDomain
         --
         put fedwiki_FetchSitemapArray (topDomain) into sitemapArray
         put fedwiki_ConstructSiteMapTitleArray (sitemapArray) into sitemapTitleArray
         display_Array sitemapTitleArray, topDomain, "Global | Wiki | Tree | Menu", "Global | Wiki | Tree | Line | Menu"
         put the result into displayView
         set the displayed_Domain of displayView to topDomain
   end switch
end menu_DisplayPages

on menu_SetBrowserRect mTarget, whichRect
   put the browser_View of mTarget into browserView
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
   set the rect of browserView to someRect
end menu_SetBrowserRect

on menu_GoogleCustomSearch
   put lcw_Ask ("What do you want to search for", "FEAST") into googleQuery
   --
   put "AIzaSyBzXWSK8iB1I9Vl72OwMj5RjkVfyKW23Rg" into cseApiKey
   put merge ("https://www.googleapis.com/customsearch/v1?q=[[googleQuery]]&cx=004437460006508948617%3Axrqa9sithze&num=10&key=[[cseApiKey]]") into restURL
   --
   put url restURL into someJSON
   display_JSON someJSON
end menu_GoogleCustomSearch

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

on _
end _

on submenu_Medium
   return "Global | Medium | Menu"
end submenu_Medium

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Global | Wiki | Menu | Props
-
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


--> Global | Wiki | Menu | Disabled
-
getprop disabled_StartWiki
   put the openprocesses into oProcesses
   if "wiki" is among the lines of oProcesses then
      return "delete"
   else
      return false
   end if
end disabled_StartWiki

getprop disabled_StopWiki
   put the openprocesses into oProcesses
   if "wiki" is among the lines of oProcesses then
      return false
   else
      return "delete"
   end if
end disabled_StopWiki


--> Dev | Menu
-
on menu_UpdateWiki
   set the cursor to watch
   put shell ("npm install -g wiki")
end menu_UpdateWiki

on menu_RevealWikiSiteFolder
   put wiki_GetSiteFolder() into wikiSiteFolder
   finder_Reveal wikiSiteFolder
end menu_RevealWikiSiteFolder

on menu_ShowHiddenFiles mTarget, someBoolean
   finder_SetShowInvisibleFiles someBoolean
   finder_Restart
end menu_ShowHiddenFiles

on menu_RevealWikiModulesFolder
   put wiki_GetModulesFolder() into wikiModulesFolder
   finder_Reveal wikiModulesFolder
end menu_RevealWikiModulesFolder
