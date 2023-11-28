script "model_WikiPage"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_WikiPage
type: model
version: 0.3

/*
This is a model for fetching, storing Fedwiki pages.
See also "model_AtopiaWikiPage", "model_AtopiaFiles", "lib_PageArray" and "lib_FedwikiCreate"
*/


--> Working on
-
command fedwiki_DeleteWikiSitemap wikiDomain
   -- see "atopia_DeleteWikiSitemap"
   put fedwiki_ConstructSitemapPath (fedwikiDomain) into sitemapPath
   revDeleteFile sitemapPath
   return the result
end fedwiki_DeleteWikiSitemap


--> Fedwiki | Local | Home
-
command fedwiki_SetDefaultHome wikiDomain, pForkDomains
   fedwiki_SetDefaultPage wikiDomain, "welcome-visitors", pForkDomains
end fedwiki_SetDefaultHome

command fedwiki_SetDefaultPage wikiDomain, pageSlug, pForkDomains
   breakpoint
   --
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   pageArray_StripJournal pageArray
   pageArray_AddFork pageArray, pForkDomains
   --
   pageArray_SetDefault pageSlug, pageArray
   return the result
end fedwiki_SetDefaultPage


--> PageArray | Default | Model
-
function pageArray_GetDefault pageSlug
   put wiki_DefaultPagePath (pageSlug) into defaultPath
   put text_Get (defaultPath) into pageJSON
   put json_ToArray (pageJSON) into pageArray
   return pageArray
end pageArray_GetDefault

command pageArray_SetDefault pageArray
   put pageArray ["title"] into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put wiki_DefaultPagePath (pageSlug) into defaultPagePath
   --
   put json_FromArray (pageArray) into pageJSON
   text_Set defaultPagePath, pageJSON
   --
   return the result
end pageArray_SetDefault


--> PageArray | Fetch
-
function pageArray_FetchItem wikiDomain, pageSlug, itemID
   -- note use of "textDecode"
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   put pageArray_GetItemText (pageArray, itemID) into binaryData
   put textDecode (binaryData, "utf8") into sText
   return sText
end pageArray_FetchItem

function pageArray_FetchByTitle wikiDomain, pTitle
   put fedwiki_ConstructSlug (pTitle) into pSlug
   put pageArray_Fetch (wikiDomain, pSlug, true) into pageArray
   return pageArray
end pageArray_FetchByTitle

function pageArray_Fetch wikiDomain, pSlug, pDontCheck
   put pageJson_Fetch (wikiDomain, pSlug) into pageJson
   --
   if pageJson is empty then return empty
   put json_ToArray (pageJson) into pageArray
   if pDontCheck is true then return pageArray
   
   # Check pageArray
   if pageArray is not an array then return false
   --
   put pageArray ["title"] into pageTitle
   put pageArray ["journal"] into journalArray
   if pageTitle is empty or "story" is not among the keys of pageArray or journalArray is not an array then
      return empty
   else
      return pageArray
   end if
end pageArray_Fetch

function pageJson_Fetch wikiDomain, pSlug
   put pageJson_ConstructUrl (wikiDomain, pSlug) into someUrl
   put url someUrl into someJSON
   return someJSON
end pageJson_Fetch


--> PageArray | Model
-
function pageArray_Get wikiDomain, pageSlug
   put pageJson_Get (wikiDomain, pageSlug) into pageJson
   put json_ToArray (pageJson) into pageArray
   return pageArray
end pageArray_Get

command pageArray_Set wikiDomain, pageSlug, pageArray, pDeleteSiteMap
   put json_FromArray (pageArray) into pageJSON
   pageJson_Set wikiDomain, pageSlug, pageJSON
   put the result into shellResult
   --
   if pDeleteSiteMap then
      fedwiki_DeleteWikiSitemap wikiDomain
   end if
   --
   if shellResult is empty then
      put fedwiki_ConstructUrlFromSlug (wikiDomain, pageSlug) into wikiURL
      return wikiURL
   else
      return "Error," && shellResult
   end if
end pageArray_Set

command pageArray_Delete wikiDomain, pageSlug
   pageJson_Delete wikiDomain, pageSlug
   put the result into shellResult
   if shellResult is not empty then return shellResult
   --
   fedwiki_DeleteWikiSitemap wikiDomain
   return empty
end pageArray_Delete

function pageJson_Get wikiDomain, pageSlug
   put fedwiki_LocalPageJsonFile (pageSlug, wikiDomain) into wikiPagePath
   put text_Get (wikiPagePath) into pageJSON
   return pageJSON
end pageJson_Get

command pageJson_Set wikiDomain, pageSlug, pageJSON, pDeleteSiteMap
   put fedwiki_LocalPageJsonFile (pageSlug, wikiDomain) into wikiPagePath
   text_Set wikiPagePath, pageJSON
   --
   if pDeleteSiteMap is not false then
      -- deleting sitemap is the lazy way to update it
      fedwiki_DeleteWikiSitemap wikiDomain
   end if
   return wikiPagePath
end pageJson_Set

command pageJson_Delete wikiDomain, pageSlug
   put fedwiki_LocalPageJsonFile (pageSlug, wikiDomain) into wikiPagePath
   revDeleteFile wikiPagePath
   return the result
end pageJson_Delete


--> Fedwiki | DefaultPage | Model
-
function fedwiki_ListDefaultPages pListShort
   put wiki_DefaultPagesFolder() into wikiDefaultPagesFolder
   if pListShort is false then
      return file_ListLong (wikiDefaultPagesFolder)
   else
      return file_ListShort (wikiDefaultPagesFolder)
   end if
end fedwiki_ListDefaultPages

--> Fedwiki | Local | Sulgs
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

