script "model_WikiSiteMap"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_WikiSiteMap
type: model
version: 0.1

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
   put wikiFile_ListPageSlugs (wikiDomain) into pageSlugs
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
   put wikiFile_ConstructSiteMap (wikiDomain) into siteMapFile
   put jsonArray_FromFile (siteMapFile) into sitemapArray
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
   put wikiFile_ConstructSiteMap (wikiDomain) into siteMapFile
   jsonArray_ToFile siteMapFile, siteMapArray
   return the result 
end wikiSiteMap_SetArray

function wikiSiteIndex_GetJson pWikiDomain
   put wikiFile_ConstructSiteIndex (pWikiDomain) into siteIndexFile
   if there is a file siteIndexFile then
      put url ("binfile:" & siteIndexFile) into binaryJSON
      return binaryJSON
   else
      return empty
   end if
end wikiSiteIndex_GetJson

function wikiSiteMap_GetJson pWikiDomain
   put wikiFile_ConstructSiteMap (pWikiDomain) into siteMapFile
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
   put wikiFile_ConstructSiteMap (pWikiDomain) into siteMapFile
   revDeleteFile siteMapFile
   return the result
end wikiSiteMap_DeleteFile



