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
function wikiServer_View
   put view_GetTemplateObject ("View|Wiki|Server") into wsView
   return wsView
end wikiServer_View

command wikiServer_Reset pWikiServer, pCloseAll
   wikiServer_Stop pWikiServer, pCloseAll
   put the result into pWikiServer
   --
   resetAll
   --
   wikiServer_Start pWikiServer
   --
   return pWikiServer
end wikiServer_Reset

command wikiServer_Start pWikiServer, pPortToListenOn
   if exists (pWikiServer) is false then put wikiServer_View() into pWikiServer
   --
   dispatch "daemon_Start" to pWikiServer with pPortToListenOn
   put the result into pPortToListenOn
   --
   return pWikiServer
end wikiServer_Start

command wikiServer_Stop pWikiServer, pCloseAll
   if exists (pWikiServer) is false then put wikiServer_View() into pWikiServer
   put pCloseAll is not false into sBoolean
   --
   dispatch "daemon_Stop" to pWikiServer with sBoolean
   return pWikiServer
end wikiServer_Stop

command wikiServer_Create wikiDomain
   # Create folders
   put wikiFolder_Construct (wikiDomain) into wikiFolder
   repeat for each item shortFolder in "pages,recycle,status"
      put wikiFolder & shortFolder & slash into sFolder
      folder_CreateNested sFolder
   end repeat
   
   # Create Image and Assets folders
   put wikiFolder & "assets/plugins/image" & slash into sFolder
   folder_CreateNested sFolder
   
   # Add domain to /etc/hosts
   put system_GetAdminPassword() into systemPassword
   hosts_Add wikiDomain, systemPassword
   
   # Create files
   put "welcome-visitors" into pageSlug
   put wikiServer_GetPageJson (pageSlug) into pageJSON
   pageJson_Set wikiDomain, pageSlug, pageJSON
   
   put wikiServer_GetFavicon() into pngData
   wiki_SetFavicon wikiDomain, pngData
end wikiServer_Create


--> WikiPage | Default
-
command wikiServer_CopyHomeToDefault wikiDomain, pForkDomains
   wikiServer_CopyPageToDefault wikiDomain, "welcome-visitors", pForkDomains
end wikiServer_CopyHomeToDefault

command wikiServer_CopyPageToDefault wikiDomain, pageSlug, pForkDomains
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   pageArray_StripJournal pageArray
   pageArray_AddFork pageArray, pForkDomains
   --
   wikiServer_SetPageArray pageArray
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


--> WikiServer | Favicon
-
function wikiServer_GetFavicon
   put wikiServer_DefaultStatusFolder() into defaultStatusFolder
   put defaultStatusFolder & "favicon.png" into faviconFile
   if there is a file faviconFile then
      put url ("binfile:" & faviconFile) into pngData
      return pngData
   else
      return empty
   end if
end wikiServer_GetFavicon


--> WikiServer | PageArray
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
