script "model_WikiLocal"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_WikiLocal
type: model
version: 0.1


--> Working on
-
function fedwiki_LocalPageSlugs pFedwikiDomain
   put fedwiki_GetLocalWikiFolder (pFedwikiDomain) into localPagesFolder
   if there is a folder localPagesFolder then
      put folder_ShortFiles (localPagesFolder) into pageSlugs
      return pageSlugs
   else
      return empty
   end if
end fedwiki_LocalPageSlugs

function fedwiki_LocalPageJsonFile pageSlug, pFedwikiDomain, pCreateFolder, pLocalWikiFolder
   put fedwiki_LocalPagesFolder (pFedwikiDomain, pLocalWikiFolder) into localPagesFolder
   if pCreateFolder is true then
      folder_CreateNested localPagesFolder
   end if
   put localPagesFolder & pageSlug into someFile
   return someFile
end fedwiki_LocalPageJsonFile


--> Fedwiki | Local | Folders
-
function fedwiki_GetLocalFolders
   put fedwiki_GetLocalWikiRoot() into localWikiFolder
   put the defaultfolder into oFolder
   set the defaultfolder to localWikiFolder
   put the folders into fedwikiFolders
   set the defaultfolder to oFolder
   filter fedwikiFolders without ".*"
   line_Delete "pages", fedwikiFolders
   line_Delete "status", fedwikiFolders
   return fedwikiFolders
end fedwiki_GetLocalFolders

function fedwiki_LocalAssetsFolder pFedwikiDomain
   put fedwiki_GetLocalWikiFolder (pFedwikiDomain) into wikiFolder
   put wikiFolder & "assets/" into assetsFolder
   return assetsFolder
end fedwiki_LocalAssetsFolder

function fedwiki_LocalPagesFolder pFedwikiDomain
   -- fedwiki_PagesFolder
   put fedwiki_GetLocalWikiFolder (pFedwikiDomain) into wikiRootFolder
   put wikiRootFolder & "pages/" into localPagesFolder
   return localPagesFolder
end fedwiki_LocalPagesFolder

function fedwiki_LocalStatusFolder pFedwikiDomain
   put fedwiki_GetLocalWikiFolder (pFedwikiDomain) into wikiFolder
   put wikiFolder & "status/" into wikiPageFolder
   return localStatusFolder
end fedwiki_LocalStatusFolder

function fedwiki_GetLocalWikiFolder pFedwikiDomain
   put fedwiki_GetLocalWikiRoot() into localWikiFolder
   if localWikiFolder is empty then return empty
   
   if pFedwikiDomain is not empty then
      put pFedwikiDomain after localWikiFolder
      folder_Format localWikiFolder
   end if
   return localWikiFolder
end fedwiki_GetLocalWikiFolder

function fedwiki_GetLocalWikiRoot
   put fedwiki_GetLocalData() into localWikiData
   put localWikiData ["localWikiRoot"] into localWikiRoot
   --
   if localWikiRoot is empty then
      put "~/.wiki/" into localWikiRoot -- this is the default root for a wiki-node server on OSX and Linux
   end if
   return localWikiRoot
end fedwiki_GetLocalWikiRoot

command fedwiki_SetLocalWikiRoot localWikiRoot
   folder_Format localWikiRoot
   put fedwiki_GetLocalData() into localWikiData
   put localWikiRoot into localWikiData ["localWikiRoot"]
   fedwiki_SetLocalData localWikiData
end fedwiki_SetLocalWikiRoot 


--> Fedwiki | Local | Model
-
function fedwiki_GetLocalData
   put the model_Data of me into localWikiData
   return localWikiData
end fedwiki_GetLocalData

command fedwiki_SetLocalData localWikiData
   set the model_Data of me to localWikiData
   put the result into modelFile
   return modelFile
end fedwiki_SetLocalData
