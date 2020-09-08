script "Global_D4A_Menu"
--> MetaData
-
license: GPLv3
name: Global_D4A_Menu
type: controller
version: 0.1


--> Global | D4A | Menu
-
on menu_TestCode
   -- http://vincent.proto.institute/view/welcome-visitors/view/test-page
   put "graph.democracy.garden" into wikiDomain
   put "test-page" into pageSlug
   --
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   put pageArray_GetPageLinkSlugs (pageArray) into pSlugs
   --
   put gephi_ConstructTableArray (pSlugs, wikiDomain) into gephiTableArray
   put gephiTableArray ["csvLines"] into csvLines
   put gephiTableArray ["nodeTableLines"] into nodeTableLines
   --
   display_Array gephiTableArray
end menu_TestCode

on menu_GenerateCsv
   put "speaker.democracy.garden" into wikiDomain
   
   put "workshop-digital-republics" & CR after pSlugs
   put "workshop-future-law" & CR after pSlugs
   put "workshop-age-of-consent" & CR after pSlugs
   delete char -1 of pSlugs
   --
   put gephi_ConstructCsv (pSlugs, wikiDomain) into gephiCSV
   --
   put gephiCSV
end menu_GenerateCsv

on menu_DisplayProblemTree
   put "problem.democracy.garden" into wikiDomain
   put pageArray_Fetch (wikiDomain, "problem-with-democracy") into pageArray
   put pageArray_GetPageLinks (pageArray) into wikiLinks
   
   repeat for each line wikiLink in wikiLinks
      set the cursor to busy
      put fedwiki_ConstructSlug (wikiLink) into pSlug
      put pageArray_Fetch (wikiDomain, pSlug) into pageArray
      
      put pageArray_FindTitle (pageArray, "This problem causes...") into itemNum
      put pageArray ["story"][itemNum]["text"] into itemText
      put fedwiki_GetLinks (itemText) into itemLinks
      --
      put itemLinks into problemArray [wikiLink]
   end repeat
   
   -- display_Array problemArray
   --
   ask file "Where do you want to save this file?"
   put it into someFile
   --
   dot_CreateFromLinkArray problemArray, someFile, "Problem Tree"
   put the result into svgFile
   --
   display_SVG svgFile, "Probelm Tree"
end menu_DisplayProblemTree

on menu_DisplaySiteTree
   breakpoint
   put "problem.democracy.garden" into wikiDomain
   
   put fedwiki_FetchSitemapArray (wikiDomain) into sitemapArray
   repeat for each key indexNum in sitemapArray
      put sitemapArray [indexNum]["slug"] into pSlug
      put pageArray_Fetch (wikiDomain, pSlug) into pageArray
      
   end repeat
   display_Array sitemapArray
end menu_DisplaySiteTree

on _
end _

on menu_DownloadWikipediaImages dislayView
   put the displayed_Index of dislayView into pageTitles
   repeat for each line pageTitle in pageTitles
      put dropbox_MediaWikiImageFolder (pageTitle) into someFolder
      if there is a folder someFolder then next repeat
      
      set the cursor to busy
      wikipedia_DownloadImages pageTitle
   end repeat
end menu_DownloadWikipediaImages

on menu_DisplayKeywords displayView
   put pageArray_Fetch ("carlos.proto.institute", "imagine-keywords") into pageArray
   put pageArray_GetPageLinks (pageArray) into wikiLinks
   --
   set the displayed_Index of displayView to wikiLinks
end menu_DisplayKeywords

on _
end _

on menu_TestApi
   put lcw_Ask ("Enter Wikipedia Title...", "Democracy") into pageTitle
   
   /*
   put fedwikipedia_FetchWikiTextArray (pageTitle) into pageArray
   display_Array pageArray, "wikipedia_FetchPageImages"
   */
   
   put wikipedia_FetchPageImages (pageTitle)into pageJson
   display_Json pageJson, "wikipedia_FetchPageImages"
   
   put mediawiki_ListPageImages (pageTitle)into shortImages
   display_Index shortImages, "wikicommons_ListImages"
   
   put wikicommons_ListImages (pageTitle)into pageJson
   display_Json pageJson, "wikicommons_ListImages"
end menu_TestApi
