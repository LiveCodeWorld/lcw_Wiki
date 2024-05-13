script "lib_WikiFix"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_WikiFix
type: library
version: 0.3

/*
This si a place for handlers that fix broken wiki's or other assorted things.
*/

--> Variables
-
local TunnelDomainArray


--> Working on
-
function wiki_ReDomain wikiDomain, pReDomain
   if pReDomain is empty then return wikiDomain
   --
   set the itemdelimiter to "."
   put item 1 to -3 of wikiDomain into fistBit
   put fistBit & "." & pReDomain into newDomain
   return newDomain
   
   put the number of items of pReDomain into dNum
   put pReDomain into item -dNum to -1 of wikiDomain
   return wikiDomain
end wiki_ReDomain

function wiki_SearchExport exportData, sKey, sValue, pSearchHow, pFirst
   local rData
   repeat for each key pageSlug in exportData
      put exportData [pageSlug]["story"] into storyArray
      --
      switch pSearchHow
         case "ends"
            put indexArray_FindEndsWith (storyArray, sKey, sValue) into itemNum
            break
         case "contains"
            put indexArray_FindContains (storyArray, sKey, sValue) into itemNum
            break
         default
            put indexArray_Find (storyArray, sKey, sValue) into itemNum
      end switch 
      --
      if itemNum > 0 then
         put itemNum into rArray ["itemNum"]
         put storyArray [itemNum] into rArray ["itemArray"]
         if pFirst is true then
            put pageSlug into rArray ["slug"]
            return rArray
         else
            put rArray into rData [pageSlug]
         end if
      end if
   end repeat
   return rData
end wiki_SearchExport

function wiki_FindImageListData wikiDomain, imageHash, pFirst
   put wiki_FetchExportData (wikiDomain) into exportData
   put wiki_SearchExport (exportData, "url", imageHash, "ends", pFirst) into rData
   return rData
end wiki_FindImageListData


--> Wiki | Fix
-
on wiki_DroppedURL sURL
   answer the params
end wiki_DroppedURL

command wiki_LoadTunnel
   -- could load Dynadot as well
   put tunnel_FetchDomainArray() into TunnelDomainArray
end wiki_LoadTunnel


--> Gitwiki | SymLinks
-
/*
We no longer use symlinks as the node wiki server does not let you write to folders that are symlinked.
*/

command hardlink_Create fromFile, toFile
   if there is not a file fromFile then return "Error," && fromFile && "does not exist."
   --
   if there is a file toFile then
      breakpoint
      return "Error, not overwriting existing file" & toFile
   end if
   
   put merge ("ln '[[fromFile]]' '[[toFile]]'") into someShell
   replace "'" with quote in someShell
   put shell (someShell) into shellResult
   return shellResult
end hardlink_Create

command wiki_CreateHardLink fromDomain, fromSlug, toDomain, toSlug
   put wikiFile_Construct (fromDomain, fromSlug) into fromFile
   if there is not a file fromFile then return "Error, file" && fromFile && "does not exist."
   put wiki_ConstructPageJsonFile (toDomain, toSlug) into toFile
   if there is not a file toFile then return "Error, domain" && toDomain && "does not exist."
   --
   hardlink_Create fromFile, toFile
   --
   return the result
end wiki_CreateHardLink

command wiki_CreateSymLink wikiDomain, pSymLinkDomain
   if pSymLinkDomain is empty then put wikiDomain into pSymLinkDomain
   --
   put wikiFolder_Get (wikiDomain) into wikiFolder
   put wikiFolder_Get (pSymLinkDomain) into symWikiFolder
   --
   symlink_CreateFolder wikiFolder, symWikiFolder
   return the result
end wiki_CreateSymLink
