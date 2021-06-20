script "lib_DisplayAtopiaUpdate"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: lib_DisplayAtopiaUpdate
type: library
version: 0.1

/*Some help*/


--> Working on
-
command display_TransportModels
   put transport_ListModelFiles() into shortFiles
   --
   display_Data shortFiles, "Models", "Transport Server"
   put the result into displayView
   --
   display_SetInteractions displayView, "Transport | Model", "doubleUp_TransportModel"
   return displayView
end display_TransportModels

command display_AtopiaCatModel pSinceLastSeconds
   if pSinceLastSeconds is empty then put atopia_GetLastUpDate() into pSinceLastSeconds
   put atopia_ConstructCatModel (pSinceLastSeconds) into atopiaCatModel
   --
   put sinceLastSeconds into displayTitle
   convert displayTitle to abbreviated date
   --
   put "Atopia Update" into stackLabel
   put display_FindView (stackLabel) into displayView
   display_Data atopiaCatModel, displayTitle, stackLabel, displayView
   put the result into displayView
   --
   display_SetInteractions displayView, "Atopia | Build"
   set the lastUpdate_Seconds of displayView to sinceLastSeconds
   --
   return displayView
end display_AtopiaCatModel

command display_TrashUpdateAtopiaDomains pIndexView, pAtopiaDomains
   -- simple linear update often used to trash empty domains
   local newAtopiaDomainArray
   if pIndexView is empty then put display_FindView ("Atopia") into pIndexView
   if pAtopiaDomains is empty then put atopia_ListNewRosterFolders() into pAtopiaDomains
   if pAtopiaDomains is empty then return "Error, nothing to trash or update!"
   
   _TrashUpdateAtopiaModified pAtopiaDomains, pIndexView
   put the result into trashResultArray
   --
   put the keys of trashResultArray ["good"] into updatedAtopiaDomains
   -- put the keys of trashResultArray ["atopia_MoveToUnhosted"] into movedToUnhosted
   put the keys of trashResultArray ["trashed"] into movedToTrash
   --
   display_Data trashResultArray, "Result", "Trash Empty Atopia Domains"
   
   -- store updated Atopia Domain Array
   put trashResultArray ["atopiaFedray"] into newAtopiaDomainArray
   atopia_UpdateDomainArrayAndRoster newAtopiaDomainArray
   -- put the result into pageArray
   
   -- update Federation array
   put trashResultArray ["good"] into goodAddedFedray
   atopia_AddFedray goodAddedFedray
   
   -- update site.fedwiki.org site-pages
   put the keys of goodAddedFedray into addedDomains
   atopia_CreateFederationSitePages addedDomains, pIndexView
   --
   return resultArray
end display_TrashUpdateAtopiaDomains


--> Display | Atopia | Update
-
command display_StartFedrayUpdate atopiaDomains, pDisplayView
   put "Update all metadata for the displayed domains?" into someQuestion
   lcw_Answer someQuestion, pDisplayView
   --
   url_SortDomainIndex atopiaDomains
   --
   display_Data atopiaDomains, "Updating", "Atopia Domains"
   put the result into displayView
   display_SetInteractions displayView, "Fedray | Update", "mDoubleUp_WikiDomain"
   --
   return displayView
end display_StartFedrayUpdate

command display_FedrayUpdatedDomain wikiDomain, wikiDomainArray
   put _GetUpdateDisplayView() into displayView
   display_Spin wikiDomain, displayView, "dark green"
end display_FedrayUpdatedDomain

command display_FedrayNewDomain wikiDomain
   put _GetUpdateDisplayView() into displayView
   display_Spin wikiDomain, displayView, "orange"
end display_FedrayNewDomain

command display_FedrayUpdatedDeleted wikiDomain, errorMsg
   put _GetUpdateDisplayView() into displayView
   display_Spin wikiDomain, displayView, "red"
end display_FedrayUpdatedDeleted

command display_FinishedAtopiaUpdate
   put _GetUpdateDisplayView() into displayView
   --
   put "Finished processing all the domains!" into someQuestion
   lcw_Answer someQuestion, displayView
   --
   set the atopia_DomainArray of displayView to fedray_GetAtopiaCache()
   set the federation_DomainArray of displayView to fedray_GetCache()
   set the fedray_LoadResultArray of displayView to fedray_GetLoadResultArray()
end display_FinishedAtopiaUpdate


--> Display | Atopia | Trash
-
command display_TrashUpdateAtopia pAtopiaDomains, pIndexView
   -- fetch both fedrays so we can update them
   put atopia_FetchDomainArray() into atopiaFedray
   put fedray_FetchModel() into fedray
   if pAtopiaDomains is empty then
      -- get modified domains since last update
      put atopia_ListSinceDomains() into pAtopiaDomains
   end if
   
   sort lines of pAtopiaDomains
   _DisplatStartUpdate pAtopiaDomains, pIndexView
   --
   repeat for each line wikiDomain in pAtopiaDomains
      display_Spin wikiDomain, pIndexView
      put the result into lineNum
      --
      atopia_TrashOrMoveDomain wikiDomain, pIndexView, lineNum
      --
      put the result into trashCommand
      if trashCommand is empty then
         put "Did not to trash domain as it was good. Updated with fedray_UpdateLastModified" into resultArray ["Updated"][wikiDomain]
         --
         fedray_AddCreateDomainEntry atopiaFedray, wikiDomain
         put the result into sitemapArray -- will not be empty if we have created new
         fedray_UpdateModified atopiaFedray, wikiDomain
         --
         fedray_AddCreateDomainEntry fedray, wikiDomain
         fedray_UpdateModified fedray, wikiDomain
      else
         put empty into resultArray [trashCommand][wikiDomain]
         delete variable atopiaFedray [wikiDomain]
      end if
   end repeat
   
   -- store Fedrays
   atopia_StoreDomainArray atopiaFedray
   fedray_StoreModel fedray
   
   -- store roster
   put keys (atopiaFedray) into atopiaDomains
   url_SortDomainIndex atopiaDomains
   atopia_StoreRosterDomains atopiaDomains
   
   -- add to Federation fedray
   return resultArray   
end display_TrashUpdateAtopia


--> Private
-
private command _DisplatStartUpdate pAtopiaDomains, pIndexView
   if exists (pIndexView) then
      set the displayed_Index ["Trashing folders..."] of pIndexView to pAtopiaDomains
   end if
end _DisplatStartUpdate

private command _TrashUpdateAtopiaModified atopiaDomains, pIndexView
   -- used by display_TrashUpdateAtopiaDomains
   if atopiaDomains is empty then return "Error, nothing to trash or update!"
   
   -- we do not update any metadata
   sort lines of atopiaDomains
   if exists (pIndexView) then
      set the displayed_Index of pIndexView to atopiaDomains
   end if
   
   put atopia_FetchDomainArray() into atopiaFedray
   --
   repeat for each line wikiDomain in atopiaDomains
      display_Spin wikiDomain, pIndexView
      put the result into lineNum
      --
      _CheckAndColourDomain wikiDomain, pIndexView
      if the result is empty then
         -- update lastModified
         fedray_UpdateLastModified atopiaFedray, wikiDomain
         put the result into sitemapArray
         --
         if sitemapArray is empty then
            put atopiaFedray [wikiDomain] into resultArray ["bad"][wikiDomain]
         else
            put atopiaFedray [wikiDomain] into resultArray ["good"][wikiDomain]
         end if
      else
         put atopiaFedray [wikiDomain] into resultArray ["trashed"][wikiDomain]
         atopia_TrashOrMoveDomain wikiDomain, pIndexView, lineNum
         delete variable atopiaFedray [wikiDomain]
      end if
   end repeat
   --
   put atopiaFedray into resultArray ["atopiaFedray"]
   return resultArray   
end _TrashUpdateAtopiaModified

private function _GetUpdateDisplayView
   put display_FindView ("Atopia Domains", "Updating") into displayView
   return displayView
end _GetUpdateDisplayView

private command _CheckAndColourDomain domainName, indexView
   put atopia_WikiHasPages (domainName) into hasPages 
   put the line_Number [domainName] of indexView into lineNum
   --
   if hasPages is false then
      set the line_Colour [lineNum] of indexView to red
      return "Error, wiki has no pages"
   else
      put digitalocean_FetchDropletIP ("Atopia") into dropletIP
      --
      put dig_GetIP (domainName) into testIP
      put testIP = dropletIP into isHosted
      --
      if isHosted then
         set the line_Colour [lineNum] of indexView to green
         return empty
      else
         set the line_Colour [lineNum] of indexView to blue
         return "Error, wiki is not hosted!"
      end if
   end if
end _CheckAndColourDomain
