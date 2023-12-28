script "lib_FedwikiSitemap"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_FedwikiSitemap
type: library
version: 0.1

/*
This library works with sitemaps or the results of the shell "tree command"

The last modified dates of folders on Linux does nto reflect the contents of changes  in the folder.
Therefore for to work out if a site has been modified we check either the sitemap by:
- 1) Fetching it with http and processing (slow)
- 2) Checking the last modified of the sitemap.json file (fast but includes spam sites with empty files folder)
- 3) Checks last modified of sitemap.json file AND existance of welcome-visitors file (pain)
*/

--> Variables
-
local localArray


--> Working on
-
function wiki_FetchExportData wikiDomain
   put fedwiki_JsonExportUrl (wikiDomain) into exportURL
   put url exportURL into someJson
   if someJson is empty then return empty
   put textDecode (someJson, "utf8") into someJson
   put json_ToArray (someJson) into exportData
   if exportData is false then return empty
   return exportData
end wiki_FetchExportData

function fedwiki_JsonExportUrl wikiDomain   
   put "http://" & wikiDomain & "/system/export.json" into exportURL
   return exportURL
end fedwiki_JsonExportUrl


--> Fedwiki | Sitemap
-
function fedwiki_FetchSitemapArray wikiDomain
   put fedwiki_FetchSitemap (wikiDomain) into someJson
   if someJson is empty then return empty
   put json_ToArray (someJson) into sitemapArray
   if sitemapArray is false then return empty
   return sitemapArray
end fedwiki_FetchSitemapArray

function fedwiki_FetchSitemap wikiDomain
   put fedwiki_JsonSiteMapUrl (wikiDomain) into sitemapURL
   put url sitemapURL into sitemapJSON
   return sitemapJSON
end fedwiki_FetchSitemap

function fedwiki_JsonSiteMapUrl wikiDomain   
   put "http://" & wikiDomain into sitemapURL
   put "/system/sitemap.json" after sitemapURL
   return sitemapURL
end fedwiki_JsonSiteMapUrl

command fedwiki_UnloadSitemaps pWikiDomains
   if pWikiDomains is empty then
      repeat for each line sitemapURL in the cachedURLs
         set the cursor to busy
         unload url sitemapURL
      end repeat
   else
      repeat for each line wikiDomain in pWikiDomains
         set the cursor to busy
         put fedwiki_JsonSiteMapUrl (wikiDomain) into sitemapURL
         unload url sitemapURL
      end repeat
   end if
end fedwiki_UnloadSitemaps


--> Fedwiki | Sitemap | LastModified
-
function fedwiki_GetlastModified wikiDomain
   put fedwiki_FetchSitemapArray (wikiDomain) into sitemapArray
   put fedwiki_SitemapLastModified (sitemapArray) into lastModified
   return lastModified
end fedwiki_GetlastModified

function fedwiki_SitemapLastModified sitemapArray
   put item 2 of the extents of sitemapArray into maxNum
   put 0 into maxUpdate
   repeat with indexNum = 1 to maxNum
      put sitemapArray [indexNum]["slug"] into pageSlug
      put sitemapArray [indexNum]["date"] into lastUpdate
      if lastUpdate > maxUpdate then
         put lastUpdate into maxUpdate
      end if
   end repeat
   return maxUpdate
end fedwiki_SitemapLastModified


--> Sitemap | List
-
function fedwiki_ListSitemapTitles wikiDomain
   put fedwiki_FetchSitemapArray (wikiDomain) into sitemapArray
   put fedwiki_GetSitemapTitles (sitemapArray) into pageTitles
   return pageTitles
end fedwiki_ListSitemapTitles

function fedwiki_GetSitemapTitles sitemapArray
   repeat for each key indexNum in sitemapArray
      put sitemapArray [indexNum]["title"] into pageTitle
      put pageTitle & CR after pageTitles
   end repeat
   delete char -1 of pageTitles
   return pageTitles
end fedwiki_GetSitemapTitles

function fedwiki_ListSitemapSlugs wikiDomain
   put fedwiki_FetchSitemapArray (wikiDomain) into sitemapArray
   put fedwiki_GetSitemapSlugs (sitemapArray) into pageSlugs
   return pageSlugs
end fedwiki_ListSitemapSlugs

function fedwiki_GetSitemapSlugs sitemapArray
   repeat for each key indexNum in sitemapArray
      put sitemapArray [indexNum]["slug"] into pageSlug
      put pageSlug & CR after pageSlugs
   end repeat
   delete char -1 of pageSlugs
   return pageSlugs
end fedwiki_GetSitemapSlugs

function fedwiki_CheckWithSitemapArray wikiDomains, pDaysAgo, pIndexView
   if pDaysAgo is a number then
      put date_DaysAgoInSeconds (pDaysAgo) * 1000 into daysAgoInMilliseconds
      if daysAgoInMilliseconds is empty then
         return "Error, pDaysAgo needs to be empty or a number."
      end if
   else
      put atopia_FetchTreeSitemapJsonInfoArray() into wikiDomainArray
   end if
   --
   repeat for each line wikiDomain in wikiDomains
      display_Spin wikiDomain, pIndexView
      --
      put fedwiki_GetLastModified (wikiDomain) into actualLastModified
      put date_MillisecondsToInternetDate (actualLastModified) into actualDisplayLastModified
      
      if pDaysAgo is empty then
         get atopia_GetWikiLastModified (wikiDomain, wikiDomainArray)
         if it is empty then
            get atopia_GetWikiLastModified (wikiDomain, wikiDomainArray)
            put "Error, could not find using atopia_GetWikiLastModified()" into resultArray ["no sitemap"][wikiDomain]
            next repeat
         end if
         convert it to seconds
         put it * 1000 into daysAgoInMilliseconds
      end if
      --
      switch
         case lastModified is empty
            put actualDisplayLastModified into resultArray ["no sitemap"][wikiDomain]
            break
         case actualLastModified = daysAgoInMilliseconds
            put actualDisplayLastModified into resultArray ["same"][wikiDomain]
         case actualLastModified > daysAgoInMilliseconds
            put actualDisplayLastModified into resultArray ["recent"][wikiDomain]
            break
         default
            put actualDisplayLastModified into resultArray ["earlier"][wikiDomain]
      end switch
   end repeat
   return resultArray
end fedwiki_CheckWithSitemapArray

function fedwiki_SearchSitemapArray pageSlug, siteMapArray
   -- was "fedwiki_FindSlug"
   repeat for each key indexNum in siteMapArray
      if siteMapArray [indexNum]["slug"] is pageSlug then
         return indexNum
      end if
   end repeat
   return 0
end fedwiki_SearchSitemapArray


--> Deps
-
