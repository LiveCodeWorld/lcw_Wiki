script "model_WikiServer"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_WikiServer
type: model
version: 0.1

/*
Wiki Server pages are default wiki pages that are avaialable to all wikis.

This model lets you read, write and list these pages.
*/

--> Working on
-


--> WikiPage | Default
-
command wikiServer_CopyHomeToDefault wikiDomain, pForkDomains
   wikiServer_CopyPageToDefault wikiDomain, "welcome-visitors", pForkDomains
end wikiServer_CopyHomeToDefault

command wikiServer_CopyPageToDefault wikiDomain, pageSlug, pForkDomains
   breakpoint
   --
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   pageArray_StripJournal pageArray
   pageArray_AddFork pageArray, pForkDomains
   --
   wikiServer_SetPageArray pageSlug, pageArray
   return the result
end wikiServer_CopyPageToDefault

function wikiServer_ListPages pListShort
   put wikiServer_DefaultPagesFolder() into wikiDefaultPagesFolder
   if pListShort is false then
      return file_ListLong (wikiDefaultPagesFolder)
   else
      return file_ListShort (wikiDefaultPagesFolder)
   end if
end wikiServer_ListPages


--> PageArray | Default | Model
-
function wikiServer_GetPageArray pageSlug
   put wikiServer_GetPageJson (pageSlug) into pageJSON
   put json_ToArray (pageJSON) into pageArray
   return pageArray
end wikiServer_GetPageArray

command wikiServer_SetPageArray pageArray
   put pageArray ["title"] into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put wikiServer_ConstructDefaultPagePath (pageSlug) into defaultPagePath
   --
   put json_FromArray (pageArray) into pageJSON
   text_Set defaultPagePath, pageJSON
   --
   return the result
end wikiServer_SetPageArray

function wikiServer_GetPageJson pageSlug
   put wikiServer_ConstructDefaultPagePath (pageSlug) into defaultPath
   put text_Get (defaultPath) into pageJSON
   return pageJSON
end wikiServer_GetPageJson


--> WikiServer | Default | Paths
-
function wikiServer_ConstructDefaultPagePath pageSlug
   put wikiServer_DefaultPagesFolder() & pageSlug into wikiPagePath
   return wikiPagePath
end wikiServer_ConstructDefaultPagePath


--> WikiServer | Folders
-
function wikiServer_DefaultStatusFolder
   put wikiServer_DefaultDataFolder() & "status/" into defaultStatusFolder
   if there is a folder defaultStatusFolder then
      return defaultStatusFolder
   else
      return empty
   end if
end wikiServer_DefaultStatusFolder

function wikiServer_DefaultPagesFolder
   put wikiServer_DefaultDataFolder() & "pages/" into defaultPagesFolder
   if there is a folder defaultPagesFolder then
      return defaultPagesFolder
   else
      return empty
   end if
end wikiServer_DefaultPagesFolder

function wikiServer_DefaultDataFolder
   put node_WikiModulesFolder() & "wiki-server/default-data/" into defaultDataFolder
   if there is a folder defaultDataFolder then
      return defaultDataFolder
   else
      return empty
   end if
end wikiServer_DefaultDataFolder

function wikiServer_Folder
   put node_WikiModulesFolder() & "wiki-server/" into wikiServerFolder
   if there is a folder wikiServerFolder then
      return wikiServerFolder
   else
      return empty
   end if
end wikiServer_Folder
