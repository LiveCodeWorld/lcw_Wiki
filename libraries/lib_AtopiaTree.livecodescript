script "lib_AtopiaTree"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_AtopiaTree
type: library
version: 0.1

/*
This library is for code that relies on the "tree" coomandline utility.
This does not come by default on Ubuntu, but is. installed on the Atopia server
*/


--> Working on
-

--> Atopia | CatModel
-
function atopia_ConstructCatModel pSinceLastSeconds
   -- all folders changed since pSinceLastSeconds (split into all, ealier, later, empty sites, and new sites)
   if pSinceLastSeconds is empty then
      -- put atopia_GetLastUpDate() into pSinceLastSeconds
      put federation_GetLastUpDate() into pSinceLastSeconds
   end if
   
   set the cursor to watch
   put atopia_FetchDateSplitArray (pSinceLastSeconds) into atopiaCatModel
   put atopia_FetchTreeWelcomeInfoArray() into welcomeInfoArray
   --
   put atopiaCatModel ["earlier"] into earlierArray
   intersect earlierArray with welcomeInfoArray
   put earlierArray into atopiaCatModel ["earlier"]
   --
   put atopiaCatModel ["all"] into newDateArray
   put atopia_FetchDomainArray() into atopiaFedray
   --
   difference newDateArray with atopiaFedray
   if newDateArray is not empty then
      put newDateArray into emptyDateArray
      --
      intersect newDateArray with welcomeInfoArray
      put newDateArray into atopiaCatModel ["new sites"]
      --
      difference emptyDateArray with welcomeInfoArray
      put emptyDateArray into atopiaCatModel ["empty sites"]
   end if
   --
   return atopiaCatModel
end atopia_ConstructCatModel

function atopia_FetchNewSiteDateArray pSincePeriod
   -- all new folders (either modified, spam or newly created)
   put atopia_GetLaterThanSeconds (pSincePeriod) into sinceLastSeconds
   --
   put atopia_FetchNewDateArray (sinceLastSeconds) into newDateArray
   put atopia_FetchDomainArray() into atopiaFedray
   difference newDateArray with atopiaFedray
   return newDateArray
end atopia_FetchNewSiteDateArray


--> Atopia | Tree | List
-
function atopia_ListWelcomeFolders pFilterDomains
   put atopia_FetchTreeWelcomeInfoArray() into infoArray
   put the keys of infoArray into atopiaDomains
   --
   -- url_FilterDomainIndex atopiaDomains, pFilterDomain
   put url_ListFilteredDomains (atopiaDomains, pFilterDomains) into filteredAtopiaDomains
   url_SortDomainIndex filteredAtopiaDomains
   --
   return filteredAtopiaDomains
end atopia_ListWelcomeFolders

function atopia_FetchTreeSiteIndexInfo
   put atopia_FetchTreeInfo ("site-index.json") into shellResult
   return shellResult
end atopia_FetchTreeSiteIndexInfo

function atopia_FetchSiteIndexDateArray pIncludeEmptySites
   put _FetchAtopiaFileDateArray ("site-index.json", pIncludeEmptySites) into treeDateArray
   return treeDateArray
end atopia_FetchSiteIndexDateArray

function atopia_FetchFileInfo pShortFile, pUseAccessTimes
   get atopia_FetchFileTimes (pUseAccessTimes)
   if pShortFile is empty then return it
   
   put "*" && pShortFile into fileFilter
   filter it with fileFilter
   return it 
end atopia_FetchFileInfo


--> Atopia | Shell
-
function atopia_ListLastViewedPages wikiDomain, pSincePeriod
   if pSincePeriod is empty then
      put empty into laterThanSeconds
   else
      put atopia_GetLaterThanSeconds (pSincePeriod) into laterThanSeconds
   end if
   
   put atopia_FetchRecentlyViewedTable (wikiDomain) into recentPageTable
   set the itemdelimiter to tab
   repeat for each line someLine in recentPageTable
      put item 1 of someLine into shortFile -- = pageSlug
      put item 2 of someLine into viewedSeconds
      if viewedSeconds > laterThanSeconds then
         put shortFile & CR after recentPages
      else
         exit repeat
      end if
   end repeat
   delete char -1 of recentPages
   return recentPages
end atopia_ListLastViewedPages

function atopia_FetchRecentlyViewedTable wikiDomain, pPretty
   put wikiDomain & slash & "pages/" into pathBit
   get atopia_FetchFileTimes (pathBit, true)
   repeat with lineNum = 3 to the number of lines of it
      -- -rw-r--r-- 1 root root   7786 1607415835 fedwiki-tools
      put word -1 of line lineNum of it into shortFile
      put word 6 of line lineNum of it into someDate
      if pPretty is true then
         convert someDate from seconds to internet date
      end if
      put shortFile & tab & someDate & CR after recentPageTable
   end repeat
   delete char -1 of recentPageTable
   --
   set the itemdelimiter to tab
   sort descending datetime lines of recentPageTable by item 2 of each
   --
   return recentPageTable
end atopia_FetchRecentlyViewedTable

function atopia_ListLastModifiedPages wikiDomain, pSincePeriod
   if pSincePeriod is empty then
      put empty into laterThanSeconds
   else
      put atopia_GetLaterThanSeconds (pSincePeriod) into laterThanSeconds
   end if
   
   put atopia_FetchLastModifiedTable (wikiDomain) into recentPageTable
   set the itemdelimiter to tab
   repeat for each line someLine in recentPageTable
      put item 1 of someLine into shortFile -- = pageSlug
      put item 2 of someLine into viewedSeconds
      if viewedSeconds > laterThanSeconds then
         put shortFile & CR after recentPages
      else
         exit repeat
      end if
   end repeat
   delete char -1 of recentPages
   return recentPages
end atopia_ListLastModifiedPages

function atopia_FetchLastModifiedTable wikiDomain, pPretty
   put wikiDomain & slash & "pages/" into pathBit
   get atopia_FetchFileTimes (pathBit)
   repeat with lineNum = 3 to the number of lines of it
      -- -rw-r--r-- 1 root root   7786 1607415835 fedwiki-tools
      put word -1 of line lineNum of it into shortFile
      if shortFile begins with "." then next repeat
      
      put word 6 of line lineNum of it into someDate
      if pPretty is true then
         convert someDate from seconds to internet date
      end if
      put shortFile & tab & someDate & CR after recentPageTable
   end repeat
   delete char -1 of recentPageTable
   --
   set the itemdelimiter to tab
   sort descending datetime lines of recentPageTable by item 2 of each
   --
   return recentPageTable
end atopia_FetchLastModifiedTable

function atopia_FetchFileTimes pWikiDomain, pUseAccessTimes
   -- https://serverfault.com/questions/320074/listing-of-files-recursively-with-modified-time-in-tree-like-format
   -- ls -Rl --time-style=long-iso /path/to/directory
   -- we don't like doing this. We want handlers that depend on this built into the server (protected with ssh keys)
   
   put "ssh root@fedwiki.org" into someShell
   if pUseAccessTimes is true then
      put space & "ls -Rlpu" after someShell
   else
      put space & "ls -Rlap" after someShell
   end if
   --put space & "--time-style=long-iso" after someShell
   put space & "--time-style=+%s" after someShell
   --
   put space & "/root/.wiki/" & pWikiDomain after someShell
   put shell (someShell) into shellResult
   --
   return shellResult
end atopia_FetchFileTimes

function atopia_FetchTreeInfo shortFile
   get "tree --noreport --timefmt %s -ifDP '[[shortFile]]' -I '_old_sites|_unhosted_sites|_trash|pages|assets|recycle' /root/.wiki"
   put merge (it) into remoteShell
   put "ssh root@fedwiki.org" && kwote (remoteShell) into localShell
   put word 1 to -1 of shell (localShell) into shellResult
   return shellResult
end atopia_FetchTreeInfo

function atopia_FetchTreeInfoWithWelcome
   -- we don't like doing this. We want handlers that depend on this built into the server (protected with ssh keys)
   -- returns all domains with pages/welcome-visitors
   -- put "tree --noreport -fidD -P '*/pages/welcome-visitors' -L 1 -I '_unhosted_sites' /root/.wiki" into remoteShell -- welcome visitors --prune does not work
   constant AtopiaDomain = "fedwiki.org"
   constant AtopiaSshUser = "root"
   --
   put "tree --noreport --prune -fiDP 'welcome-visitors' -I '_old_sites' /root/.wiki" into remoteShell -- welcome visitors --prune does not work
   put "ssh" && AtopiaSshUser & "@" & AtopiaDomain && remoteShell into someShell
   put word 1 to -1 of shell (someShell) into shellResult
   return shellResult
end atopia_FetchTreeInfoWithWelcome


--> Atopia | Tree | List
-
function atopia_ListModifiedDayDomains pDate, pIncludeEmptySites, pTreeDateArray
   -- pick any day to list domains modified that  day
   if pTreeDateArray is empty then put atopia_FetchSiteIndexDateArray (pIncludeEmptySites) into pTreeDateArray
   switch pDate
      case empty
         put the date into pDate
         break
      case "yesterday"
         put the date into pDate
         convert pDate to dateItems
         subtract 1 from item 3 of pDate
         break
   end switch
   convert pDate to dateItems
   put item 1 of pDate into someYear
   put item 2 of pDate into someMonth
   put item 3 of pDate into someDay
   --
   get pTreeDateArray [someYear][someMonth][someDay]
   put the keys of it into wikiDomains
   return wikiDomains
end atopia_ListModifiedDayDomains


--> Fedwiki | List | Tree
-
function atopia_ListEmptySites
   put atopia_FetchFilteredFolderLsArray() into folderArray
   delete variable folderArray ["fedwiki_owners"]
   put atopia_ListWelcomeFolders() into treeInfoFolders
   split treeInfoFolders by CR as set
   --
   difference folderArray with treeInfoFolders
   --
   put the keys of folderArray into emptyFolders
   url_SortDomainIndex emptyFolders
   return emptyFolders
end atopia_ListEmptySites

function atopia_ListWelcomeDifference
   put atopia_ListWelcomeFolders() into welcomeFolders
   put atopia_FetchFolders() into atopiaFolders
   --
   put welcomeFolders = atopiaFolders into theSame
   if theSame then return empty
   --
   -- line_DeleteIndex atopiaFolders, welcomeFolders
   line_CommonDifference atopiaFolders, welcomeFolders
   put the result into dodgyFolders
   return dodgyFolders
end atopia_ListWelcomeDifference


--> Atopia | Sitemap | Dates
-
function atopia_GetWikiLastModified wikiDomain, pTreeDateArray
   -- "last modified" according to file system is updated in strange ways
   -- see "fedwiki_GetlastModified". and "display_TestLastmodified"
   if pTreeDateArray is empty then put atopia_FetchDateArray() into pTreeDateArray
   put pTreeDateArray [wikiDomain] into someDate
   convert someDate from seconds to internet date
   return someDate
end atopia_GetWikiLastModified

function atopia_GetFolderCreationDate wikiDomain, pTreeFileArray
   -- faster to just use "ls -la"
   if pTreeFileArray is empty then put atopia_FetchTreeWelcomeInfoArray() into pTreeFileArray
   put pTreeFileArray [wikiDomain] into treeDate
   put date_ConvertTree (treeDate) into someDate
   return someDate
end atopia_GetFolderCreationDate


--> Atopia | Tree | DateArray
-
function atopia_FetchDateArray pLaterThanSeconds
   -- good sites with welcome-visitors (removes empty sites)
   get atopia_FetchDateSplitArray (pLaterThanSeconds)
   put it ["earlier"] into treeDateArray
   return treeDateArray
end atopia_FetchDateArray

function atopia_FetchNewDateArray pDateInSeconds
   -- good sites with welcome-visitors (removes empty sites)
   if pDateInSeconds is empty then put date_GetSinceSeconds ("1 week") into pDateInSeconds
   --
   put atopia_FetchDateArray (pDateInSeconds) into treeDateArray
   return treeDateArray
end atopia_FetchNewDateArray

function atopia_FetchOldDateArray pDateInSeconds
   -- good sites with welcome-visitors (removes empty sites)
   if pDateInSeconds is empty then put date_GetSinceSeconds ("1 week") into pDateInSeconds
   --
   get atopia_FetchDateSplitArray (pDateInSeconds)
   put it ["later"] into treeDateArray
   return treeDateArray
end atopia_FetchOldDateArray

function atopia_FetchFilteredTree shortFile
   put atopia_FetchTreeInfo (shortFile) into treeIndex
   filter treeIndex with ("*/" & shortFile)
   return treeIndex
end atopia_FetchFilteredTree

function atopia_FetchDateSplitArray pLaterThanSeconds
   set the wholematches to false
   --
   put atopia_FetchFilteredTree ("site-index.json") into treeIndex
   repeat for each line someLine in treeIndex
      set the itemDelimiter to "]  "
      put item 2 of someLine into somePath
      put char 2 to -1 of item 1 of someLine into treeSeconds
      --
      set the itemDelimiter to slash
      put item -3 of somePath into wikiDomain
      --
      if treeSeconds > pLaterThanSeconds then -- true if pLaterThanSeconds is empty
         put treeSeconds into treeDateArray ["earlier"][wikiDomain]
      else
         put treeSeconds into treeDateArray ["later"][wikiDomain]
      end if
      put treeSeconds into treeDateArray ["all"][wikiDomain]
   end repeat
   return treeDateArray 
end atopia_FetchDateSplitArray

function atopia_FetchFolderDateArray pLaterThanSeconds
   put _FetchFolderDateArray ("site-index.json", pLaterThanSeconds)
end atopia_FetchFolderDateArray


--> Atopia | Tree | Array
-
function atopia_FetchTreeWelcomeInfoArray
   put atopia_FetchTreeInfoWithWelcome() into shellResult
   _FilterWelcome shellResult
   put atopia_ConstructTreeInfoArray (shellResult) into wikiDomainArray
   return wikiDomainArray
end atopia_FetchTreeWelcomeInfoArray

function atopia_ConstructTreeInfoArray shellResult
   put 4 into domainItemNum
   put "]  " into someDelim
   --
   repeat for each line someLine in shellResult
      set the itemDelimiter to someDelim
      put item 2 of someLine into somePath
      if char 1 of somePath = "_" then next repeat
      put char 2 to -1 of item 1 of someLine into treeDate
      --
      set the itemDelimiter to slash
      put item domainItemNum of somePath into wikiDomain
      put treeDate into wikiDomainArray [wikiDomain]
   end repeat
   return wikiDomainArray
end atopia_ConstructTreeInfoArray

function atopia_ConstructTreeDateArray shellResult
   delete line 1 of shellResult
   put "]  /root/.wiki/" into someDelim
   --
   repeat for each line someLine in shellResult
      set the itemDelimiter to someDelim
      put item 2 of someLine into somePath
      if char 1 of somePath = "_" then next repeat
      
      -- Oct 15 15:00,2050.greendeal.wiki/status
      put char 2 to -1 of item 1 of someLine into treeDate
      
      set the itemDelimiter to slash
      put item 1 of somePath into wikiDomain
      --
      _UpdateTreeDateArray treeDateArray, treeDate, wikiDomain
   end repeat
   return treeDateArray
end atopia_ConstructTreeDateArray


--> Private
-
private function _FetchAtopiaFileDateArray shortFile, pIncludeEmptySites
   -- sitemaps get there last modified date changed a lot on the Atopia server
   -- for instance every tiem the server crashes?
   local treeDateArray
   
   put "*/" & shortFile  into someFilter
   put atopia_FetchTreeInfo (shortFile) into jsonResult
   --
   if pIncludeEmptySites is true then
      filter jsonResult with someFilter
      put atopia_ConstructTreeDateArray (jsonResult) into treeDateArray
   else
      put atopia_FetchTreeInfoWithWelcome() into welcomeShellResult
      --
      delete line 1 of jsonResult
      delete line 1 of welcomeShellResult
      _FilterWelcome welcomeShellResult
      filter jsonResult with someFilter
      --
      put "]  " into someDelim
      set the wholematches to false
      repeat for each line someLine in jsonResult
         set the itemDelimiter to someDelim
         put item 2 of someLine into sitemapJsonPath
         put char 2 to -1 of item 1 of someLine into treeDate
         --
         set the itemDelimiter to slash
         put item 4 of sitemapJsonPath into wikiDomain
         if char 1 of wikiDomain = "_" then next repeat
         
         put item 1 to -3 of sitemapJsonPath & slash into sitemapJsonRoot
         put welcomeShellResult contains sitemapJsonRoot into isThere
         if isThere then
            _UpdateTreeDateArray treeDateArray, treeDate, wikiDomain
         end if
      end repeat   
   end if
   return treeDateArray
end _FetchAtopiaFileDateArray

private command _UpdateTreeDateArray @treeDateArray, treeDate, wikiDomain
   put date_ConvertTree (treeDate) into aDate
   convert aDate to dateItems
   --
   set the itemDelimiter to comma
   put item 1 of aDate into someYear
   put item 2 of aDate into someMonth
   put item 3 of aDate into someDay
   
   put aDate into treeDateArray [someYear][someMonth][someDay][wikiDomain]
end _UpdateTreeDateArray

private command _FilterWelcome @welcomeShellResult
   filter welcomeShellResult with "*/welcome-visitors"
   filter welcomeShellResult without "*/root/.wiki/_unhosted_sites/*"
   filter welcomeShellResult without "*/root/.wiki/_trash/*"
end _FilterWelcome


--> Deps
-
function date_ConvertTree treeDate
   -- Oct 15 15:11
   get word 3 of treeDate
   if it contains ":" then
      put word 1 to 2 of treeDate into aDate
      convert aDate to dateItems
      --
      set the itemdelimiter to ":"
      put item 1 it into someHour
      put item 2 it into someMin
      set the itemdelimiter to comma
      --
      put someHour into item 4 of aDate
      put someMin into item 5 of aDate
      -- put word -1 of the long date into item 1 of aDate
   else
      put treeDate into aDate      
      convert aDate to dateItems
   end if
   --
   convert aDate from dateItems to internet date
   return aDate
end date_ConvertTree
