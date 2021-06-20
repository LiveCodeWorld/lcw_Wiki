script "lib_AtopiaUpdate"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_AtopiaUpdate
type: library
version: 0.1

/*
There is a problem with this technique in that:
1) The "load" bug prevents succesful calling of wikidomain html while loading wiki json
2) It still does not allow for editing while laoding many sites so not much of an advantage over linear

However we like the faster errors returned when a site cannot be reached.

So for now we only use this library for asynch updating of metadata, not for generating creation information

This library contains handlers that update the Atopia Server.
We look to be able to do this daily at least.
This code uses "load" for asynchronous testing of domains

1) Trash empty Folders
2) Update Atopia Metadata (atopiaDomaindArray = atopiaFedray)
3) Update Fedray
*/

--> Variables
-
local AtopiaFedrayCache, FedrayCache, LoadResultArray, TestAtopiaFolders


--> Working on
-
function atopia_ModulesFolder
   return "/root/.nvm/versions/node/v12.16.1/lib/node_modules/wiki/node_modules/"
end atopia_ModulesFolder

function atopia_NpmPath
   return "/root/.nvm/versions/node/v12.16.1/bin/npm"
end atopia_NpmPath



--> Atopia | Update
-
command atopia_CheckDomainAndUpdateMetadata wikiURL, downLoadStatus
   put url_GetDomain (wikiURL) into wikiDomain
   --
   if downLoadStatus is "error" then
      atopia_DeleteSiteMetadata wikiDomain
      return "Error, DNS or url is not valid for" && wikiURL
   end if
   
   if downLoadStatus is "cached" then
      put url wikiURL into sitemapJSON
      --
      switch sitemapJSON
         case empty
         case "[]"
            -- legal url, but there is not sitemap (probebaly because of wildcard DNS)
            atopia_DeleteSiteMetadata wikiDomain
            --
            return "Error, empty sitemap for" && wikiURL
         default
            atopia_UpdateDomainMetadata wikiDomain, true
            put the result into resultArray
            return resultArray
      end switch
   end if
   
   put downLoadStatus
end atopia_CheckDomainAndUpdateMetadata

command atopia_DeleteSiteMetadata wikiDomain
   put atopia_FetchDomainArray() into atopiaFedray
   put fedray_FetchModel() into fedray
   --
   put fedray [wikiDomain] into resultArray ["removed"]
   delete variable fedray [wikiDomain]
   --
   atopia_StoreDomainArray atopiaFedray
   fedray_StoreModel fedray
   
   -- store atopia roster
   put keys (atopiaFedray) into atopiaDomains
   url_SortDomainIndex atopiaDomains
   atopia_StoreRosterDomains atopiaDomains
   --
   return atopiaDomains
end atopia_DeleteSiteMetadata


--> Atopia | Update
-
command atopia_UpdateLastModifiedDomains pIndexView, pForceAddFedrayCreate
   -- we assume all the domains are good (we have already trashed the  bad ones)
   
   -- now we check any recently modified atopia domains (which could be overestimate)
   -- and update their metadata (lastModified)
   put date_GetSinceSeconds ("1 week") into sinceSeconds 
   put atopia_ListRecentDomains (sinceSeconds) into recentlyModifiedAtopiaFolders -- uses tree to check modified dates of sitemaps
   --
   atopia_UpdateDomainMetadata recentlyModifiedAtopiaFolders, pForceAddFedrayCreate, pIndexView
   --
   return the result -- resultArray 
end atopia_UpdateLastModifiedDomains

command atopia_UpdateDomainMetadata recentlyModifiedAtopiaFolders, pForceAddFedrayCreate, pIndexView
   if exists (pIndexView) then
      sort recentlyModifiedAtopiaFolders
      set the displayed_Index of pIndexView to recentlyModifiedAtopiaFolders
   end if
   
   -- fetch both fedrays so we can update them
   put atopia_FetchDomainArray() into atopiaFedray
   put fedray_FetchModel() into fedray
   --
   repeat for each line wikiDomain in recentlyModifiedAtopiaFolders
      display_Spin wikiDomain, pIndexView
      --
      if fedray_AlreadyCreated (wikiDomain, fedray, pForceAddFedrayCreate) is true then
         put fedray [wikiDomain] into wikiDomainArray
      else
         put fedwiki_FetchSitemapArray (wikiDomain) into sitemapArray
         if sitemapArray is empty then
            put fedray [wikiDomain] into resultArray ["removed"]
            delete variable fedray [wikiDomain]
            next repeat
         end if
         put fedray_FetchNewCreateDomainArray (wikiDomain, sitemapArray) into wikiDomainArray
      end if
      
      fedray_UpdateWikiDomainArray wikiDomainArray, wikiDomain
      put wikiDomainArray into atopiaFedray [wikiDomain]
      put wikiDomainArray into fedray [wikiDomain]
      put wikiDomainArray into resultArray ["updated"][wikiDomain]
   end repeat
   
   -- store Fedrays
   atopia_StoreDomainArray atopiaFedray
   fedray_StoreModel fedray
   
   -- store atopia roster
   put keys (atopiaFedray) into atopiaDomains
   url_SortDomainIndex atopiaDomains
   atopia_StoreRosterDomains atopiaDomains
   
   -- we are not storing all federation domains in a roster
   -- use fedray_FetchDomains() instead if you need
   
   return resultArray 
end atopia_UpdateDomainMetadata


--> Atopia | Trash | OrMove
-
command atopia_MoveToUnhosted shortWikiFolder
   put atopia_GetData() into atopiaData
   
   -- let's do lot's of checks
   if shortWikiFolder is empty then
      breakpoint
      put "The wiki domain is empty!" into someQuestion
      lcw_AnswerWarning someQuestion
   end if
   -- /root/.wiki/sub.domain.wiki/ -- absolute path for safety
   put atopia_WikiDomainFolder (shortWikiFolder) into domainFolder
   if domainFolder begins with "/root/.wiki/" is false then
      breakpoint
      put "The wiki domain is invalid!" into someQuestion
      lcw_AnswerWarning someQuestion
   end if
   
   -- we are assuming it is a good folder
   get atopia_DomainIsBadInDomainArray (shortWikiFolder, atopiaData)
   if it is true then
      put "This wiki is not good!" into someQuestion
      lcw_AnswerWarning someQuestion
   end if
   
   -- it must have NOT a valid A record
   put dig_GetIP (shortWikiFolder) into aRecord
   put atopia_GetIP() into dropletIP
   if aRecord = dropletIP then
      put aRecord
      put "This wiki is hosted on Atopia!" into someQuestion
      lcw_AnswerWarning someQuestion
   end if
   
   --
   put atopia_UnhostedFolder() into unhostedFolder
   put "mv" && domainFolder && unhostedFolder into remoteShell
   atopia_DoRemoteShell remoteShell
   put the result into moveResult
   if moveResult is not empty then
      put moveResult
      lcw_AnswerWarning "Fail to move domain to wiki_trash folder"
   end if
   --
   
   -- tidy atopiaData
   put atopiaData ["good"][shortWikiFolder] into goodPageIndex
   put goodPageIndex into atopiaData ["_unhosted_sites"][shortWikiFolder] 
   delete variable atopiaData ["good"][shortWikiFolder]
   --
   atopia_SetData atopiaData
   --
   return atopiaData
end atopia_MoveToUnhosted

command atopia_TrashOrMoveDomain domainName, pIndexView, lineNum
   if domainName is empty then
      return "Error, domain is empty"
   end if
   
   put atopia_ListWikiPages (domainName) into wikiPages -- gets from file system using shell
   put the number of lines of wikiPages into pageNum
   if pageNum > 0 then
      if atopia_WikiIsHosted (domainName) then
         -- leave as is
         if exists (pIndexView) then
            set the line_Colour [lineNum] of pIndexView to green
         end if
         -- fedray_UpdateLastModified atopiaFedray, wikiDomain -- update by checking resut of this handler
         return empty
      else
         set the cursor to watch
         if exists (pIndexView) then
            set the line_Colour [lineNum] of pIndexView to red
         end if
         --
         atopia_MoveToUnhosted domainName
         --
         if exists (pIndexView) then
            set the deleted_Line of pIndexView to domainName
         end if
         return "atopia_MoveToUnhosted"
      end if
   else
      if exists (pIndexView) then
         set the line_Colour [lineNum] of pIndexView to red
      end if
      --
      set the cursor to watch
      atopia_MoveToTrash domainName
      --
      if exists (pIndexView) then
         set the deleted_Line of pIndexView to domainName
      end if
      return "atopia_MoveToTrash"
   end if
end atopia_TrashOrMoveDomain


--> Tests
-
command fedray_UpdateTestMetadata wikiURL, wikiDomain, sitemapJSON
   put json_ToArray (sitemapJSON) into sitemapArray
   if sitemapArray is not an array then
      -- some error fetching sitemap json
      put empty into LoadResultArray ["missing"][wikiDomain]
      return empty
   end if
   --
   put FedrayCache [wikiDomain] into wikiDomainArray
   if wikiDomainArray is not an array then
      -- it is a new domain
      -- we can't update here for an async load as there is an issue with fetching urls during repeat asyn load
      -- so we store for later processing
      
      put sitemapArray into LoadResultArray ["new"][wikiDomain]["sitemapArray"]
      display_FedrayNewDomain wikiDomain
      -- put fedray_FetchNewCreateDomainArray (wikiDomain, sitemapArray) into wikiDomainArray -- not working
      return ("Error, domain is new -" && wikiDomain)
   end if
   --
   fedray_UpdateWikiDomainArray wikiDomainArray, wikiDomain, sitemapArray, true
   --
   put wikiDomainArray into AtopiaFedrayCache [wikiDomain]
   put wikiDomainArray into FedrayCache [wikiDomain]
   --
   -- store the history
   put wikiDomainArray into LoadResultArray ["tested"]["cached"][wikiDomain]
   put wikiDomainArray into LoadResultArray ["history"][wikiDomain]
   --
   display_FedrayUpdatedDomain wikiDomain, wikiDomainArray
   return wikiDomainArray
end fedray_UpdateTestMetadata


--> Fedray | Update | Finished
-
function fedray_TestsAreFinished wikiDomain
   -- TestAtopiaFolders has been url_SortDomainIndex sorted by "fedray_LoadCache"
   put fedray_ListLoadedDomains() into loadedDomains -- sorted
   return loadedDomains = TestAtopiaFolders
end fedray_TestsAreFinished

function fedray_ListLoadedDomains
   put the keys of LoadResultArray ["history"] into loadedDomains
   url_SortDomainIndex loadedDomains
   return loadedDomains
end fedray_ListLoadedDomains


--> Fedray | Update | Async
-
command fedray_LoadUpdateTests atopiaFolders, pDisplayView
   -- put line 1 to 30 of atopiaFolders into atopiaFolders
   --
   fedray_LoadCache atopiaFolders
   display_StartFedrayUpdate atopiaFolders, pDisplayView
   --
   url_SortDomainIndex atopiaFolders
   repeat for each line wikiDomain in atopiaFolders
      put fedwiki_JsonSiteMapUrl (wikiDomain) into sitemapURL
      load url sitemapURL with "fedray_UpdateFromSitemapURL"
      -- wait 20 ticks -- this makes teh order linear!
   end repeat
end fedray_LoadUpdateTests

command fedray_AllTestsFinished
   -- here we can save the processed arrays
   -- and roster
   display_FinishedAtopiaUpdate
   --
   fedray_UnLoadedUrls
   fedray_ClearCache
end fedray_AllTestsFinished

command fedray_UnLoadedUrls
   repeat for each key wikiDomain in LoadResultArray ["tested"]["cached"]
      put fedwiki_JsonSiteMapUrl (wikiDomain) into sitemapURL
      unload url sitemapURL
   end repeat
end fedray_UnLoadedUrls

command fedray_UpdateFromSitemapURL wikiURL, downLoadStatus
   put url_GetDomain (wikiURL) into wikiDomain
   
   switch downLoadStatus
      case "cached"
         _UpdateCached wikiURL, wikiDomain
         break
      case "timeout"
      case "error"
         -- store the history
         _UpdateMissing wikiDomain, wikiURL, downLoadStatus
         break
      default
         _UpdateUnkown wikiDomain, downLoadStatus
         breakpoint
   end switch
   --
   if fedray_TestsAreFinished (wikiDomain) is true then
      fedray_AllTestsFinished
   end if
end fedray_UpdateFromSitemapURL


--> Fedray | Update | Model
-
function fedray_GetLoadResultArray
   -- available while laoding (before finish)
   return LoadResultArray
end fedray_GetLoadResultArray

command fedray_LoadCache atopiaFolders
   delete variable LoadResultArray
   --
   url_SortDomainIndex atopiaFolders
   put atopiaFolders into TestAtopiaFolders
   --
   put atopia_FetchDomainArray() into atopiaFedray
   put fedray_FetchModel() into fedray
   --
   fedray_SetAtopiaCache atopiaFedray
   fedray_SetCache fedray
end fedray_LoadCache

command fedray_ClearCache
   delete variable AtopiaFedrayCache
   delete variable FedrayCache
   --
   delete variable LoadResultArray
   delete variable TestAtopiaFolders
end fedray_ClearCache

function fedray_GetCache
   return FedrayCache
end fedray_GetCache

command fedray_SetCache fedray
   put fedray into FedrayCache
end fedray_SetCache

function fedray_GetAtopiaCache
   return AtopiaFedrayCache
end fedray_GetAtopiaCache

command fedray_SetAtopiaCache atopiaFedray
   put atopiaFedray into AtopiaFedrayCache
end fedray_SetAtopiaCache


--> Private
-
private command _UpdateCached wikiURL, wikiDomain
   put url wikiURL into sitemapJSON
   --
   switch sitemapJSON
      case empty
      case "[]"
         -- legal url, but there is not sitemap (probebaly because of wildcard DNS)
         _UpdateMissing wikiDomain, wikiURL, "cached"
         break
      default
         fedray_UpdateTestMetadata wikiURL, wikiDomain, sitemapJSON
   end switch
   return the result
end _UpdateCached

private command _UpdateUnkown wikiDomain, downLoadStatus
   -- store the history
   put empty into LoadResultArray ["tested"][downLoadStatus][wikiDomain]
   put FedrayCache [wikiDomain] into LoadResultArray ["history"][wikiDomain]
   --
   return "Unkown error for" && wikiDomain
end _UpdateUnkown

private command _UpdateMissing wikiDomain, wikiURL, downLoadStatus
   put empty into LoadResultArray ["tested"][downLoadStatus][wikiDomain]
   put FedrayCache [wikiDomain] into LoadResultArray ["history"][wikiDomain]
   --
   delete variable AtopiaFedrayCache [wikiDomain]
   delete variable FedrayCache [wikiDomain]
   --
   put "Error, DNS or url is not valid for" && wikiURL into errorMsg
   display_FedrayUpdatedDeleted wikiDomain, errorMsg
   return errorMsg
end _UpdateMissing

