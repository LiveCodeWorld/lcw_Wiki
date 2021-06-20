script "lib_AtopiaTrash"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: lib_AtopiaTrash
type: library
version: 0.1

/*
This library is all about trashing folders on the Atopia Server.

For now we also include all new handlers for updating:

- 1) Atopia Domain Array (ie atopia fedray)
- 2) Atopia Domain Roster
- 3) Federation Fedray
- 4) Fedwiki Sites Index
*/


--> Working on
-
function dig_GetIP someDomain
   put merge ("dig [[someDomain]] +short") into someShell
   put shell (someShell) into someIP
   return word 1 to -1 of someIP
end dig_GetIP

command transport_TrashEmptyDomains emptyDomains
   local resultArray
   if emptyDomains is empty then return "Error, nothing to trash or update!"
   put atopia_FetchDomainArray() into atopiaFedray
   --
   repeat for each line emptyDomain in emptyDomains
      atopia_MoveToTrash emptyDomain
      put atopiaFedray [emptyDomain] into resultArray ["trashed"][emptyDomain]
      delete variable atopiaFedray [emptyDomain]
   end repeat
   --
   atopia_StoreDomainArray atopiaFedray
   --
   put atopiaFedray into resultArray ["atopiaFedray"]
   return resultArray   
end transport_TrashEmptyDomains

command atopia_AddNewDomainToFedrays newDomain
   -- create new wikiDomainArray
   put fedray_FetchNewCreateDomainArray (newDomain) into wikiDomainArray
   fedray_UpdateWikiDomainArray wikiDomainArray, newDomain
   
   -- update atopiaFedray and fedray
   put atopia_FetchDomainArray() into newAtopiaDomainArray
   put wikiDomainArray into newAtopiaDomainArray [newDomain]   
   atopia_UpdateDomainArrayAndRoster newAtopiaDomainArray
   --
   put fedray_FetchModel() into fedray
   put wikiDomainArray into fedray [newDomain]   
   fedray_StoreModel fedray
end atopia_AddNewDomainToFedrays

function atopia_FetchServerIP
   -- put digitalocean_FetchDropletIP ("Atopia") into atopiaSererIP
   return "46.101.23.193"
end atopia_FetchServerIP

function atopia_ConstructNewSiteButton newDomain
   put newDomain into inputKeyValueArray ["wikiDomain"]
   put "https://rest.livecode.world/update/createSite" into postURL
   put fedwiki_ConstructButtonForm (newDomain, postURL, inputKeyValueArray) into someHTML
   return someHTML
end atopia_ConstructNewSiteButton


--> Federation | LastUpdate
-
function federation_GetLastUpDate
   put pageArray_FetchLastUpdated ("fedwiki.org", "last-federation-update") into lastUpdate
   return lastUpdate
end federation_GetLastUpDate

command federation_SetLastUpDate pDateInSeconds
   pageArray_StoreLastUpdated "fedwiki.org", "last-federation-update", pDateInSeconds
   put the result into pageArray
   return pageArray
end federation_SetLastUpDate


--> Fedray
-
command fedray_UpdateWikiDomainArray @wikiDomainArray, wikiDomain, pSitemapArray, pUpdateIP
   if pSitemapArray is empty then put fedwiki_FetchSitemapArray (wikiDomain) into pSitemapArray
   --
   put item 2 of the extents of pSitemapArray into pageNum
   put pageNum into wikiDomainArray ["pages"]
   --
   put fedwiki_SitemapLastModified (pSitemapArray) into sitemapLastModified
   put sitemapLastModified into wikiDomainArray ["last modified"]
   --
   if pUpdateIP is true then
      put dig_GetIP (wikiDomain) into someIP
      put someIP into wikiDomainArray ["ipAddress"]
   end if
end fedray_UpdateWikiDomainArray


--> Atopia | LastUpdate
-
function atopia_GetLaterThanSeconds pSincePeriod
   -- converts user-friendly pSincePeriod to seconds
   switch pSincePeriod
      case "last update"
         put atopia_GetLastUpDate() into laterThanSeconds
         break
      case empty
         put date_GetSinceSeconds ("1 week") into laterThanSeconds
         break
      default
         put date_GetSinceSeconds (pSincePeriod) into laterThanSeconds
   end switch
   return laterThanSeconds
end atopia_GetLaterThanSeconds

function atopia_GetLastUpDate
   put pageArray_FetchLastUpdated ("fedwiki.org", "last-atopia-update") into lastUpdate
   return lastUpdate
end atopia_GetLastUpDate

command atopia_SetLastUpDate pDateInSeconds
   pageArray_StoreLastUpdated "fedwiki.org", "last-atopia-update", pDateInSeconds
   put the result into pageArray
   return pageArray
end atopia_SetLastUpDate


--> Atopia | Update | CatModel
-
command atopia_TrashAndUpdateModified
   put transport_FetchAtopiaCatModel() into atopiaCatModel
   atopia_TrashSpam atopiaCatModel
   atopia_UpdateModified atopiaCatModel
   return atopiaCatModel
end atopia_TrashAndUpdateModified

command atopia_TrashSpam atopiaCatModel
   put atopiaCatModel ["empty sites"] into emptyFedray
   --
   put keys (emptyFedray) into emptyDomains
   --
   transport_TrashEmptyDomains emptyDomains
   put the result into resultArray
   put resultArray ["atopiaFedray"] into atopiaFedray
   --
   put pageArray_Fetch ("fedwiki.org", "last-atopia-update") into pageArray
   pageArray_SetItemText pageArray, "e88ba1f3f71092cf", empty
   --
   return pageArray
end atopia_TrashSpam

command atopia_UpdateFromCatModel atopiaCatModel, pForceAddFedrayCreate  
   -- fetch both fedrays so we can update them
   put atopia_FetchDomainArray() into atopiaFedray
   put fedray_FetchModel() into fedray
   put atopia_ListFederationSitePages() into fedSitePages
   put the seconds into lastUpdateSeconds
   --
   _EmptySites atopiaCatModel, resultArray, atopiaFedray, fedray
   _EarlySites atopiaCatModel, resultArray, atopiaFedray, fedray
   _NewSites atopiaCatModel, resultArray, atopiaFedray, fedray
   --
   atopia_DeleteFederationSitesMap
   
   -- store Fedrays
   atopia_StoreDomainArray atopiaFedray
   fedray_StoreModel fedray
   
   -- store atopia roster
   put keys (atopiaFedray) into atopiaDomains
   url_SortDomainIndex atopiaDomains
   atopia_StoreRosterDomains atopiaDomains
   
   -- store the time of this update
   atopia_SetLastUpDate lastUpdateSeconds
   
   return resultArray 
end atopia_UpdateFromCatModel

command atopia_UpdateModified @atopiaCatModel  
   put atopia_FetchDomainArray() into atopiaFedray
   put fedray_FetchModel() into fedray
   --
   _EarlySites atopiaCatModel, resultArray, atopiaFedray, fedray
   --
   put atopiaCatModel ["earlier"] into earlyArray
   put empty into atopiaCatModel ["earlier"]
   put atopiaCatModel ["later"] into laterArray
   union laterArray with earlyArray
   put laterArray into atopiaCatModel ["later"]
   -- 
   -- store Fedrays
   transport_StoreAtopiaCatModel atopiaCatModel
   atopia_StoreDomainArray atopiaFedray
   fedray_StoreModel fedray
   --  
   return resultArray 
end atopia_UpdateModified

command atopia_UpdateNewSites @atopiaCatModel
   put atopia_FetchDomainArray() into atopiaFedray
   put fedray_FetchModel() into fedray
   --
   _NewSites atopiaCatModel, resultArray, atopiaFedray, fedray
   --   -- store Fedrays
   transport_StoreAtopiaCatModel atopiaCatModel
   atopia_StoreDomainArray atopiaFedray
   fedray_StoreModel fedray
   --  
   return resultArray 
end atopia_UpdateNewSites

private command _NewSites atopiaCatModel, @resultArray, @atopiaFedray, @fedray
   put fedwiki_ListSitemapPages ("sites.fedwiki.org") into fedSitePages
   --
   repeat for each key newSite in atopiaCatModel ["new sites"]
      set the cursor to busy
      
      -- create new wikiDomainArray
      put fedray_FetchNewCreateDomainArray (newSite) into wikiDomainArray
      fedray_UpdateWikiDomainArray wikiDomainArray, newSite
      
      -- create site wiki page
      if newSite is not among the lines of fedSitePages then
         atopia_CreateFederationSitePage newSite, false
      end if
      
      -- update atopiaFedray and fedray
      put wikiDomainArray into atopiaFedray [newSite]
      put wikiDomainArray into fedray [newSite]
      put wikiDomainArray into resultArray ["new site"][newSite]
   end repeat
end _NewSites

private command _EmptySites atopiaCatModel, @resultArray, @atopiaFedray, @fedray
   repeat for each key emptyDomain in atopiaCatModel ["empty sites"]
      set the cursor to busy
      -- let's delete the metadata
      put fedray [emptyDomain] into resultArray ["removed"][emptyDomain]
      delete variable atopiaFedray [emptyDomain]
      delete variable fedray [emptyDomain]
      
      -- trash the domain
      atopia_MoveToTrash emptyDomain
      
      -- delete sites page if it exists
      if emptyDomain is among the lines of fedSitePages then
         atopia_DeleteFederationSitePage
      end if
   end repeat
end _EmptySites

private command _EarlySites atopiaCatModel, @resultArray, @atopiaFedray, @fedray
   repeat for each key modifiedDomain in atopiaCatModel ["earlier"]
      set the cursor to busy
      
      -- get existing wikiDomainArray and update it
      put atopiaFedray [modifiedDomain] into wikiDomainArray
      if wikiDomainArray is empty then
         -- should not be, but let's recreate anyway
         put fedray_FetchNewCreateDomainArray (modifiedDomain) into wikiDomainArray
      end if
      fedray_UpdateWikiDomainArray wikiDomainArray, modifiedDomain
      
      -- update atopiaFedray and fedray
      put wikiDomainArray into atopiaFedray [modifiedDomain]
      put wikiDomainArray into fedray [modifiedDomain]
      put wikiDomainArray into resultArray ["updated"][modifiedDomain]
   end repeat
end _EarlySites

command atopia_SetLastAtopiaUpdateRosters atopiaCatModel
   put atopia_ConstructLastAtopiaUpdatePageArray (atopiaCatModel) into pageArray
   --
   pageArray_Store "fedwiki.org", "last-atopia-update", pageArray, true
   return pageArray
end atopia_SetLastAtopiaUpdateRosters

function atopia_ConstructLastAtopiaUpdatePageArray atopiaCatModel
   if atopiaCatModel is not an array then return empty
   --
   put pageArray_Fetch ("fedwiki.org", "last-atopia-update") into pageArray
   --
   put "Last Atopia Update:" && the internet date into dateString
   pageArray_SetFirstItem pageArray, "code", dateString
   --
   _SetRosterFromCatDateArray pageArray, "earlier", atopiaCatModel, "Recent Atopia Sites", "b0b5ac1acfb9bf61"
   _SetRosterFromCatDateArray pageArray, "new sites", atopiaCatModel, "New Atopia Sites", "bbbbc6dbd1923cff"
   --
   put the keys of atopiaCatModel ["empty sites"] into emptyDomains
   url_SortDomainIndex emptyDomains
   put fedwiki_MarkdownIndex (emptyDomains) into rosterText
   pageArray_SetItemText pageArray, "e88ba1f3f71092cf", rosterText
   --
   return pageArray
end atopia_ConstructLastAtopiaUpdatePageArray

private command _SetRosterFromCatDateArray @pageArray, someKey, atopiaCatModel, rosterTitle, rosterItemID
   put the keys of atopiaCatModel [someKey] into rosterDomains
   if rosterDomains is empty then
      put rosterTitle into rosterText
   else
      url_SortDomainIndex rosterDomains
      put rosterTitle & CR&CR & rosterDomains into rosterText
   end if
   pageArray_SetItemText pageArray, rosterItemID, rosterText
end _SetRosterFromCatDateArray

command atopia_UpdateDomainArrayAndRoster atopiaFedray
   atopia_StoreDomainArray atopiaFedray
   -- update Atopia roster
   put the keys of atopiaFedray into atopiaDomains
   atopia_StoreRosterDomains atopiaDomains
   --
   put the result into pageArray
   return pageArray
end atopia_UpdateDomainArrayAndRoster


--> Transport | Trash | Atopia
-
command transport_TrashAtopiaDomains emptyDomains
   local resultArray
   if emptyDomains is empty then return "Error, nothing to trash or update!"
   put atopia_FetchServerIP() into dropletIP
   put atopia_FetchDomainArray() into atopiaFedray
   --
   repeat for each line emptyDomain in emptyDomains
      _MoveOrTrash emptyDomain, atopiaFedray, resultArray
   end repeat
   --
   put atopiaFedray into resultArray ["atopiaFedray"]
   return resultArray   
end transport_TrashAtopiaDomains

private command _MoveOrTrash emptyDomain, atopiaFedray, resultArray
   put atopia_WikiHasPages (emptyDomain) into hasPages
   switch
      case hasPages is false
         -- wiki has no pages
         _TrashNoPages emptyDomain, atopiaFedray, resultArray
         break
      case dig_GetIP (emptyDomain) = dropletIP
         _UpdateLastModified emptyDomain, atopiaFedray, resultArray
         break
      default
         -- wiki is not hosted!
         atopia_SimpleMoveToUnhosted emptyDomain
   end switch 
end _MoveOrTrash

private command _TrashNoPages emptyDomain, @atopiaFedray, @resultArray
   atopia_MoveToTrash emptyDomain
   put atopiaFedray [emptyDomain] into resultArray ["trashed"][emptyDomain]
   delete variable atopiaFedray [emptyDomain]
end _TrashNoPages

private command _UpdateLastModified emptyDomain, @atopiaFedray, @resultArray
   fedray_UpdateLastModified atopiaFedray, emptyDomain
   put the result into sitemapArray
   if sitemapArray is empty then
      put atopiaFedray [emptyDomain] into resultArray ["bad"][emptyDomain]
   else
      put atopiaFedray [emptyDomain] into resultArray ["good"][emptyDomain]
   end if
end _UpdateLastModified


--> Atopia | Trash
-
command atopia_MoveToTrash shortWikiFolder
   if shortWikiFolder is empty then return "Error, shortWikiFolder is empty"
   put atopia_WikiDomainFolder (shortWikiFolder) into remoteWikiFolderPath
   if remoteWikiFolderPath begins with "/root/.wiki/" is false then return empty   
   --
   atopia_DeleteFolderInTrash shortWikiFolder
   --
   put atopia_TrashFolder() into trashFolder
   put "mv -f" && kwote (remoteWikiFolderPath) && kwote (trashFolder) into remoteShell
   --
   put "ssh root@fedwiki.org" && remoteShell into someShell
   put shell (someShell) into moveResult
   --    
   return moveResult
end atopia_MoveToTrash

command atopia_DeleteFolderInTrash trashDomain
   set the itemdelimiter to slash
   put item -1 of trashDomain into trashDomain
   --
   put atopia_TrashFolderExists (trashDomain) into alreadyThere
   if alreadyThere is false then return empty
   --
   put atopia_FolderInTrashFolder (trashDomain) into folderInTrashFolder
   put "rm -rf" && folderInTrashFolder into remoteShell
   --
   put "ssh root@fedwiki.org" && remoteShell into someShell
   put shell (someShell) into shellResult
   --
   put the result into deleteResult
   return deleteResult
end atopia_DeleteFolderInTrash

command atopia_SimpleMoveToUnhosted domainFolder
   put atopia_UnhostedFolder() into unhostedFolder
   put "mv" && domainFolder && unhostedFolder into remoteShell
   --
   put "ssh root@fedwiki.org" && remoteShell into someShell
   put shell (someShell) into shellResult
   --
   put the result into moveResult
   return moveResult
end atopia_SimpleMoveToUnhosted

function atopia_TrashFolderExists trashDomain
   put atopia_FolderInTrashFolder (trashDomain) into folderInTrashFolder
   put "ls -la" && folderInTrashFolder into remoteShell
   --
   put "ssh root@fedwiki.org" && remoteShell into someShell
   put shell (someShell) into shellResult
   --
   if the result begins with "ls: cannot access" then
      return false
   else
      return true
   end if
end atopia_TrashFolderExists
