script "lib_FederationUpdate"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: lib_FederationUpdate
type: library
version: 0.2

/*
This library is for updating the federtion fedray.
It includes the display element as well.

And the toplevel "display_UpdateFederation" which starts with the Atopia Server.
*/


--> Working on
-

--> Display | Metadata | Update
-
command display_UpdateFederation pIndexView
   --First we check for empty Atopia Domains and trash if needed updating metadata
   _UpdateNewAtopiaSites pIndexView
   put the result into pIndexView
   
   -- Second we check for recent Atopia activity and update metadata for both fedrays
   -- this may be duplicated below with "_UpdateRecentlyModifiedFederationDomains"
   atopia_UpdateLastModifiedDomains pIndexView
   put the result into resultArray
   
   -- Third we check the federation fedray for recent activity and update metadata
   _UpdateRecentlyModifiedFederationDomains
   
   /*
   -- should already have addedSitesArray to recentSites when updating Atopia
   put resultArray ["good"] into goodsites
   union addedSitesArray with goodsites
   put the keys of addedSitesArray into newSites
   set the displayed_Index ["Indexing recent pages..."] of indexView to newSites
   display_RecentWikiPages newSites, pSincePeriod
   --
   set the displayed_Index [pSincePeriod] of indexView to newSites
   */
   
   fedwiki_UnloadSitemaps -- newSites
end display_UpdateFederation

command display_RecentFedrayUpdater recentSites, pDisplayView
   -- put fedray_FetchModel() into TempFedray
   --
   sort recentSites
   display_Data recentSites, "Updater", "Federation", pDisplayView
   put the result into pDisplayView
   display_SetInteractions pDisplayView, "Federation | Updater", "mDoubleUp_WikiDomain"
   --
   put pDisplayView into LocalArray ["indexView"]
   --
   repeat for each line wikiDomain in recentSites
      display_Spin wikiDomain, indexView, "dark green"
      put the result into lineNum
      put lineNum into LocalArray ["lineNum"]
      put wikiDomain into LocalArray ["wikiDomain"]
      --
      put fedwiki_JsonSiteMapUrl (wikiDomain) into sitemapURL
      --
      _SpinUpdateFedray sitemapURL
      if the result is true then
         put empty into resultArray ["good"][wikiDomain]
      else
         -- can't find sitemap
         -- remove from fedray
         put TempFedray [wikiDomain] into resultArray ["bad"][wikiDomain]
         delete variable TempFedray [wikiDomain]
      end if
   end repeat
   --
   fedray_StoreModel TempFedray
   delete variable TempFedray
   fedwiki_UnloadSitemaps recentSites
   --
   return resultArray
end display_RecentFedrayUpdater


--> Federation | Domains | Update
-
function federation_FetchSitesNeedingUpdate pSincePeriod, pFedray
   -- load sitemaps
   if pFedray is empty then
      put fedray_FetchModel() into pFedray
   end if
   put federation_FetchRecentSites (pSincePeriod) into recentSites
   _FilterFedrayAlreadyUpdated recentSites, pFedray, true
   return recentSites
end federation_FetchSitesNeedingUpdate


--> Private
-
private command _FilterFedrayAlreadyUpdated @recentSites, fedray
   repeat for each line wikiDomain in recentSites
      set the cursor to busy
      put fedwiki_FetchSitemapArray (wikiDomain) into sitemapArray
      if sitemapArray is empty then
         put empty into resultArray ["bad"][wikiDomain]
         next repeat
      end if
      --
      put fedwiki_SitemapLastModified (sitemapArray) into sitemapLastModified
      put fedray [wikiDomain]["last modified"] into previouslyLast
      
      if previouslyLast = sitemapLastModified then
         put sitemapArray into resultArray ["same"][wikiDomain]
      else
         put sitemapArray into resultArray ["old"][wikiDomain]
      end if
   end repeat
   --
   put the keys of resultArray ["old"] into recentSites
   url_SortDomainIndex recentSites
   return resultArray
end _FilterFedrayAlreadyUpdated

private command _UpdateRecentlyModifiedFederationDomains
   -- fetch all recent federation sites and update fedray
   put "1 week" into pSincePeriod
   put fedray_FetchModel() into TempFedray
   put federation_FetchSitesNeedingUpdate (pSincePeriod, TempFedray) into updateSites
   --
   display_RecentFedrayUpdater updateSites -- "display_AndAddNewFederationSites"
   put the result into resultArray
   put resultArray ["bad"] into badSites
   if badSites is not empty then
      display_Data badSites, "Removed Sites", "Fedray"
   end if
   return resultArray
end _UpdateRecentlyModifiedFederationDomains

private command _UpdateNewAtopiaSites pIndexView
   -- let's update the Atopia Server for any new sites trashing any bad ones
   put atopia_FetchNewRosterFolders() into newAtopiaNotInRosterFolders -- roster + recent folders
   display_Data newAtopiaNotInRosterFolders, "Updating Atopia...", "Federation"
   put the result into pIndexView
   --
   display_TrashUpdateAtopia newAtopiaNotInRosterFolders, pIndexView
   --
   put the result into resultArray
   display_Data resultArray, "Trashed empty new sites", "Atopia Server"
   lcw_Answer "Updated the Atopia Server for new sites - trashing any bad ones!"
   -- set the displayed_Index ["New Atopia Sites"] of indexView to newAtopiaSites
   --
   return pIndexView
end _UpdateNewAtopiaSites

private command _SpinUpdateFedray sitemapURL
   -- load url sitemapURL with message "_SpinUpdateFedray"
   -- if downloadStatus is not "cached" then return false -- for "load" option which is not working (too fast?)
   
   set the itemdelimiter to slash
   put item 3 of sitemapURL into wikiDomain
   set the itemdelimiter to comma   
   --
   put url sitemapURL into someJson
   if someJson is empty then return false
   --
   put json_ToArray (someJson) into sitemapArray
   put item 2 of the extents of sitemapArray into pageNum
   put pageNum into TempFedray [wikiDomain]["pages"]
   --
   put TempFedray [wikiDomain]["last modified"] into previouslyLast
   put fedwiki_SitemapLastModified (sitemapArray) into sitemapLastModified
   if previouslyLast = previouslyLast then
      -- no need to update
      return "empty"
   end if
   
   put sitemapLastModified into TempFedray [wikiDomain]["last modified"]
   if TempFedray [wikiDomain]["created"] is empty then
      -- only do these (slow) thing first time
      -- working out the creation date loops through fetching every page json for the site
      
      put fedwiki_FetchSiteCreationDate (wikiDomain) into wikiCreationDate
      put wikiCreationDate into TempFedray [wikiDomain]["created"]
      
      -- assume IP address (iee server) has not changed
      put dig_GetIP (wikiDomain) into someIP
      put someIP into TempFedray [wikiDomain]["ipAddress"]
      
      -- assume owner has not changed
      put fedwiki_FetchOwnerName (wikiDomain) into ownerName
      put ownerName into TempFedray [wikiDomain]["owner"]
   end if
   --
   put LocalArray ["lineNum"] into lineNum
   put LocalArray ["indexView"] into indexView
   if exists (indexView)  then
      set the line_Colour [lineNum] of indexView to "red"
   end if
   return true
end _SpinUpdateFedray


--> Deps
-
