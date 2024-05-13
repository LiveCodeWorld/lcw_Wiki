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

--> Variables
-
local WikiServer_Data


--> Working on
-
function wikiServer_View
   put view_GetTemplateObject ("View|Wiki|Server") into wikiServerView
   return wikiServerView
end wikiServer_View


--> WikiServer | List
-
function wikiServer_ListNames
   repeat for each key rServerObject in WikiServer_Data
      put WikiServer_Data [rServerObject]["name"] into serverName
      put serverName & CR after serverNames
   end repeat
   delete char -1 of serverNames
   return serverNames
end wikiServer_ListNames

function wikiServer_ListObjects
   put keys (WikiServer_Data) into rServerObjects
   return rServerObjects
end wikiServer_ListObjects

function wikiServer_ListPages pListShort
   put wikiServer_DefaultPagesFolder() into wikiDefaultPagesFolder
   if pListShort is false then
      return file_ListLong (wikiDefaultPagesFolder)
   else
      return file_ListShort (wikiDefaultPagesFolder)
   end if
end wikiServer_ListPages


--> WikiServer | Data
-
function wikiServer_GetData
   return WikiServer_Data
end wikiServer_GetData

command wikiServer_Register serverObject, pPortToListenOn, pServerName
   if pServerName is empty then
      put the short name of serverObject into pServerName
   end if
   put revRuggedId(serverObject) into rServerObject
   --
   put pPortToListenOn into WikiServer_Data [rServerObject]["port"]
   put pServerName into WikiServer_Data [rServerObject]["name"]
   --
   -- display_ServerData
   return WikiServer_Data
end wikiServer_Register

command wikiServer_UnRegister serverObject
   if exists (serverObject) is false then
      -- could dcheck target
      return "Error, serverObject does not exist:" && pServerObject
   end if
   
   put revRuggedId (serverObject) into rServerObject
   delete variable WikiServer_Data [rServerObject]
   --
   -- display_ServerData
   return WikiServer_Data
end wikiServer_UnRegister


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


--> WikiServer | Files
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
