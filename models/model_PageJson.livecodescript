script "model_PageJson"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_PageJson
type: model
version: 0.1

/*
This model is for wiki json files. PageJson and other json files.
It is not for fetching them by http or url's, but reading and writing to the local disk.
*/

--> Working on
-


--> PageJson | Fetch
-
function pageJson_Fetch wikiDomain, pSlug, pPort
   put pageJson_ConstructUrl (wikiDomain, pSlug, pPort) into someUrl
   put url someUrl into binaryJSON
   --
   put textDecode (binaryJSON, "UTF-8") into sJSON
   --
   return sJSON
end pageJson_Fetch

function pageJson_ConstructUrl wikiDomain, pSlug, pPort, pProtocol
   -- http://film.thought.garden:3000/welcome-visitors.json
   
   if pProtocol is empty then put "http" into pProtocol
   if pSlug is empty then put "welcome-visitors" into pSlug
   put tolower (pSlug) into pSlug -- just in case
   
   # Base URL
   put pProtocol & "://" & wikiDomain into wikiURL
   
   # Add Port
   if pPort is a number then
      put ":" & pPort after wikiURL
   end if
   
   # Add Slug
   put "/" & pSlug & ".json" after wikiURL
   
   # For Caching
   put "?random=" & the milliseconds after wikiURL
   return wikiURL
end pageJson_ConstructUrl


--> Wiki | Pages
-
function wiki_ListPageSlugs sDomain
   put wiki_PagesFolder (sDomain) into wikiPagesFolder
   if there is a folder wikiPagesFolder then
      put folder_ShortFiles (wikiPagesFolder) into pageSlugs
      return pageSlugs
   else
      return empty
   end if
end wiki_ListPageSlugs


--> Wiki | SiteMap | Working on
-
function wikiSiteMap_ListPageTitles sitemapJSON
   put json_ToArray (sitemapJSON) into sitemapArray
   repeat for each key indexNum in sitemapArray
      put sitemapArray [indexNum]["title"] into someTitle
      put someTitle & CR after someIndex
   end repeat
   delete char -1 of someIndex
   sort someIndex
   return someIndex
end wikiSiteMap_ListPageTitles

function wikiSiteMap_Construct wikiDomain
   put wiki_ListPageSlugs (wikiDomain) into pageSlugs
   put 1 into indexNum
   repeat for each line pageSlug in pageSlugs
      put pageArray_Get (wikiDomain, pageSlug) into pageArray
      put pageArray_GetLastModified (pageArray) into dateInMilliseconds
      --
      wikiSiteMap_SetIndexItemArray siteMapArray, indexNum, pageSlug, pageArray, dateInMilliseconds
      add 1 to indexNum
   end repeat
   return siteMapArray
end wikiSiteMap_Construct

command wikiSiteMap_SetIndexItemArray @siteMapArray, indexNum, pageSlug, pageArray, dateInMilliseconds
   put pageArray ["title"] into siteMapArray [indexNum]["title"]
   put pageArray ["story"][1]["text"] into siteMapArray [indexNum]["synopsis"]
   put pageSlug into siteMapArray [indexNum]["slug"]
   put dateInMilliseconds into siteMapArray [indexNum]["date"]
   
   put pageArray ["story"] into storyArray
   put item 2 of the extents of storyArray into lastItemNum
   repeat with itemNum = lastItemNum down to 1
      put storyArray [itemNum]["id"] into itemID
      put storyArray [itemNum]["type"] into itemType
      -- if itemType is among the items of "text,html,markdown" then
      put storyArray [itemNum]["text"] into itemText
      put fedwiki_GetLinks (itemText) into linkIndex
      repeat for each line linkedText in linkIndex
         put itemID into siteMapArray [indexNum]["links"][linkedText]
      end repeat
      -- end if
   end repeat
end wikiSiteMap_SetIndexItemArray


--> Wiki | SiteMap
-
command wikiSiteMap_Create wikiDomain
   put wikiSiteMap_Construct (wikiDomain) into newSitemapArray
   wikiSiteMap_SetArray newSitemapArray, wikiDomain
   put the result into writeResult
   if writeResult is empty then
      return newSitemapArray
   else
      return writeResult
   end if
end wikiSiteMap_Create

function wikiSiteMap_GetArray wikiDomain
   put wikiJson_ConstructSiteMapFile (wikiDomain) into siteMapFile
   put json_GetArray (siteMapFile) into sitemapArray
   --
   switch
      case sitemapArray is an array
         return sitemapArray
         break
      case sitemapArray is empty
      case item 1 of sitemapArray is "Error"
         if there is a file siteMapFile then
            revDeleteFile siteMapFile
         end if
         wikiSiteMap_Create wikiDomain
         put the result into newSitemapArray
         return newSitemapArray
   end switch
end wikiSiteMap_GetArray

command wikiSiteMap_SetArray siteMapArray, wikiDomain
   put wikiJson_ConstructSiteMapFile (wikiDomain) into siteMapFile
   json_SetArray siteMapFile, siteMapArray
   return the result 
end wikiSiteMap_SetArray

function wikiSiteIndex_GetJson pWikiDomain
   put wikiJson_ConstructSiteIndexFile (pWikiDomain) into siteIndexFile
   if there is a file siteIndexFile then
      put url ("binfile:" & siteIndexFile) into binaryJSON
      return binaryJSON
   else
      return empty
   end if
end wikiSiteIndex_GetJson

function wikiSiteMap_GetJson pWikiDomain
   put wikiJson_ConstructSiteMapFile (pWikiDomain) into siteMapFile
   if there is a file siteMapFile then
      -- put url ("file:" & siteMapFile) into binaryJSON
      put url ("binfile:" & siteMapFile) into binaryJSON
      -- put textDecode (binaryJSON, "UTF-8") into binaryJSON
      return binaryJSON
   else
      return empty
   end if
end wikiSiteMap_GetJson

command wikiSiteMap_DeleteFile pWikiDomain
   -- see "atopia_DeleteWikiSitemap"
   put wikiJson_ConstructSiteMapFile (pWikiDomain) into siteMapFile
   revDeleteFile siteMapFile
   return the result
end wikiSiteMap_DeleteFile


--> PageArray | File | Model
-
function pageArray_Get wikiDomain, pageSlug
   put pageJson_ConstructFile (wikiDomain, pageSlug) into wikiFile
   put json_GetArray (wikiFile) into pageArray
   return pageArray
end pageArray_Get

command pageArray_Set wikiDomain, pageSlug, pageArray, pDeleteSiteMap
   put pageJson_ConstructFile (wikiDomain, pageSlug) into wikiFile
   json_SetArray wikiFile, pageArray
   --
   if pDeleteSiteMap is not false then
      wikiSiteMap_DeleteFile wikiDomain
   end if
end pageArray_Set

command pageArray_Delete wikiDomain, pageSlug
   pageJson_Delete wikiDomain, pageSlug
   put the result into shellResult
   if shellResult is not empty then return shellResult
   --
   wikiSiteMap_DeleteFile wikiDomain
   return empty
end pageArray_Delete


--> PageJson | Get
-
function pageJson_GetRecycled wikiDomain, pageSlug
   put pageJson_ConstructRecycledFile (wikiDomain, pageSlug) into recycledPagePath
   put json_Get (recycledPagePath) into pageJSON
   return pageJSON
end pageJson_GetRecycled

function pageJson_Get wikiDomain, pageSlug
   put pageJson_ConstructFile (wikiDomain, pageSlug) into wikiPagePath
   put json_Get (wikiPagePath) into pageJSON
   return pageJSON
end pageJson_Get

command pageJson_Set wikiDomain, pageSlug, pageJSON, pDeleteSiteMap
   put pageJson_ConstructFile (wikiDomain, pageSlug) into wikiPagePath
   json_Set wikiPagePath, pageJSON
   --
   if pDeleteSiteMap is not false then
      wikiSiteMap_DeleteFile wikiDomain
   end if
   return wikiPagePath
end pageJson_Set

command pageJson_Delete wikiDomain, pageSlug
   put pageJson_ConstructFile (wikiDomain, pageSlug) into wikiPagePath
   revDeleteFile wikiPagePath
   return the result
end pageJson_Delete

command pageJson_Trash wikiDomain, pageSlug
   put pageJson_ConstructFile (wikiDomain, pageSlug) into wikiPagePath
   put pageJson_ConstructRecycledFile (wikiDomain, pageSlug) into recycledPagePath
   if recycledPagePath is empty then
      return "Error, recycle folder for wiki domain does not exists:" && wikiDomain
   else
      rename wikiPagePath to recycledPagePath
      return the result
   end if
end pageJson_Trash

function json_Get sFile
   if there is not a file sFile then return empty
   put url ("binfile:" & sFile) into binaryJSON
   put textDecode (binaryJSON, "UTF-8") into sJSON
   return sJSON
end json_Get

command json_Set sFile, sJSON, pCreateFolder
   if pCreateFolder is true then
      put sFile into sFolder
      set the itemdelimiter to slash
      put empty into item -1 of sFolder
      folder_CreateNested sFolder
   end if
   --
   put word 1 to -1 of sJSON into sJSON
   put textEncode (sJSON, "UTF-8") into binaryJSON
   put binaryJSON into url ("binfile:" & sFile)
   put the result into writeResult
   return writeResult
end json_Set

function json_GetArray sFile
   if there is not a file sFile then
      return "Error, json file does not exist." && sFile
   end if
   return _GetMergJsonArray (sFile)
end json_GetArray

command json_SetArray sFile, jsonArray, pCreateFolder
   _SetMergJsonArray sFile, jsonArray, pCreateFolder
   return the result
end json_SetArray


--> Private
-
private function _GetMergJsonArray sFile
   put url ("binfile:" & sFile) into binaryJSON
   if binaryJSON is empty then return empty
   
   try
      # Use binary and not textDecode with JSONToArray
      put JSONToArray (binaryJSON) into jsonArray
      -- put json_ToArray (binaryJSON) into jsonArray
      if jsonArray is an array then
         return jsonArray
      else
         return "Error, json file cannot be turned into an array." && sFile
      end if
   catch e
      return "Error, json file cannot be turned into an array." && sFile
   end try
end _GetMergJsonArray

private command _SetMergJsonArray sFile, jsonArray, pCreateFolder
   /* Use of ArrayToJSON and mergJsonEncode creates correct json.
   But accepts binary json and not result of textencode/decode.*/
   
   try
      # Use binary and not textEncode with JSONToArray
      put ArrayToJSON (jsonArray) into binaryJSON
      -- put json_FromArray (jsonArray) into binaryJSON
      --
      put binaryJSON into url ("binfile:" & sFile)
      put the result into writeResult
      return writeResult
   catch e
      return "Error, encoding jsonArray with _SetMergJsonArray."
   end try
end _SetMergJsonArray

private function _GetJsonArray sFile
   -- put _GetMergJsonArray (sFile) into jsonArray
   put json_Get (sFile) into sJSON
   try
      # More tolerant and uses textDecode with json_Get
      put jsonImport (sJSON) into jsonArray
      if jsonArray is an array then
         return jsonArray
      else
         return "Error, json file cannot be turned into an array." && sFile
      end if
   catch e
      breakpoint
      return "Error, json file cannot be turned into an array." && sFile
   end try
end _GetJsonArray

private command _SetJsonArray  sFile, jsonArray, pCreateFolder
   /* Use of jsonExport does not create correct json.
   Temporarily using ArrayToJSON and mergJson.*/
   
   try
      # More tolerant and uses textEncode with json_Set
      put jsonExport (jsonArray) into sJSON
      json_Set sFile, sJSON, pCreateFolder
      put the result into writeResult
      return writeResult
   catch e
      return "Error, problem decoding array to json for:" && sFile & CR & e
   end try
end _SetJsonArray
