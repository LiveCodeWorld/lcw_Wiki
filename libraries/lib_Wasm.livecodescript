script "lib_Wasm"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_Wasm
type: library
version: 0.2


--> Working on
-
function fedwiki_UrlFromPath wDomain, sPath, pProtocol, pPort
   if pProtocol is empty then put "http" into pProtocol
   
   # Base URL
   put pProtocol & "://" & wDomain into wikiURL
   
   # Add Port
   if pPort is a number then
      put ":" & pPort after wikiURL
   end if
   
   switch
      case sPath is empty
         return wikiURL
      case char 1 of sPath = slash
         return wikiURL & sPath
      default
         return wikiURL & slash & sPath
   end switch
end fedwiki_UrlFromPath

function fedwiki_JsonSiteMapUrl wDomain, pProtocol, pPort
   put fedwiki_UrlFromPath (wDomain, "/system/sitemap.json", pProtocol, pPort) into sURL
   return sURL
end fedwiki_JsonSiteMapUrl

function pageArray_Fetch wikiDomain, pSlug, pPort, pProtocol, pDecode
   put pageJson_Fetch (wikiDomain, pSlug, pPort, pDecode, pProtocol) into pageJson
   --
   if pageJson is empty then return empty
   try
      put JsonImport (pageJSON) into pageArray
      -- put pageArray_FromJson (pageJson) into pageArray
      return pageArray
   catch e
      return empty
   end try
end pageArray_Fetch

function pageArray_ToJson pageArray
   put pageArray ["title"] into pageTitle
   --
   put pageArray ["story"] into storyArray
   put pageArray ["journal"] into journalArray
   --
   put indexArray_ToJson (storyArray) into storyJSON
   put indexArray_ToJson (journalArray) into journalJSON
   
   # Start JSON
   put "{" into pageJSON
   
   # Title
   put kwote ("title") & ":" && kwote (pageTitle) & comma after pageJSON
   
   # Story
   put kwote ("story") & ":" && "[" & storyJSON & "]" & comma after pageJSON
   
   # Journal 
   put kwote ("journal") & ":" && "[" & journalJSON & "]" after pageJSON
   
   # End JSON
   put "}" after pageJSON
   --
   return pageJSON
end pageArray_ToJson

function pageJson_ConstructUrl wDomain, pSlug, pPort, pProtocol
   local sPath
   
   # Construct path
   if pSlug is empty then
      put "welcome-visitors" into pSlug
   end if
   put "/" & pSlug & ".json" into sPath
   
   # For Caching
   put "?random=" & the milliseconds after sPath
   
   put fedwiki_UrlFromPath (wDomain, sPath, pProtocol, pPort) into wikiURL
   return wikiURL
end pageJson_ConstructUrl


--> Display
-
command wikiFrame_DisplayPage pageTitle, pWikiDomain
   if the platform is "web" then
      put wikiFrame_ConstructInternalMessage (pageTitle, pWikiDomain) into sJavascript
      do sJavascript as "JavaScript" -- do "document.location" as "JavaScript"
      return sJavascript
   end if
end wikiFrame_DisplayPage

command controller_Dispatch dUrl, cStackName, pHandlerName
   put controller_GetPageArray (dUrl, cStackName, pHandlerName) into pArray
   --
   if the platform is "web" then
      ghost_PageArray pArray
   else
      display_PageArray pArray
   end if
   return the result
end controller_Dispatch

command ghost_PageArray pageArray
   if the platform is "web" then
      put pageArray_ToJson (pageArray) into pageJSON
      if pageJSON is empty then 
         put "Error decoding array." into someMarkdown
         put pageArray_Construct ("Error", someMarkdown, "markdown") into pageArray
         put pageArray_ToJson (pageArray) into pageJSON
      end if
      
      put wikiFrame_ConstructGhostMessage (pageJSON) into sJavascript
      do sJavascript as "JavaScript" -- do "document.location" as "JavaScript"
      return sJavascript
   else
      display_Data pageArray, "ghost_PageArray"
   end if
end ghost_PageArray


--> Dropped | Url
-
function dropped_WikiPageArray droppedURL
   put the origin_Protocol of the target into sProtocol
   -- set the itemdelimiter to ":"
   -- put item 1 of droppedURL into sProtocol
   
   set the itemdelimiter to slash
   put item 3 of droppedURL into wikiDomain
   put item -1 of droppedURL into pageSlug
   
   put pageArray_Fetch (wikiDomain, pageSlug, empty, sProtocol) into pageArray
   if pageArray is not an array then
      put "The dropped url failed to return a pageArray." into mdText
      put CR after mdText
      put CR & "Protocol:" && sProtocol after mdText
      put CR & "PageSlug:" && pageSlug after mdText
      put CR & "WikiDomain:" && wikiDomain after mdText
      --
      put pageArray_Construct ("Error", mdText) into pageArray
   end if
   return pageArray
end dropped_WikiPageArray


--> Fetch
-
function fedwiki_FetchSitemapArray wDomain, pProtocol, pPort
   put fedwiki_FetchSitemap (wDomain, pProtocol, pPort) into sJSON
   if sJSON is empty then return empty
   
   -- put json_ToArray (sJSON) into sMapArray
   put JsonImport (sJSON) into sMapArray
   --
   if sMapArray is false then return empty
   return sMapArray
end fedwiki_FetchSitemapArray


--> ToArray
-
-- function json_ToArray pJSON
local tArray,tKeys
if pJSON is empty then return false
-- put jsonImport (pJSON) into tArray -- not the same

try -- as otherwise an error with non-json causes script to exit
   if pJSON is empty then return empty
   repeat for each line tKey in mergJSONDecode(pJSON,"tArray")
      put json_ToArray(tArray[tKey]) into tArray[tKey]
   end repeat
   if tArray is an array then
      return tArray
   else
      return empty
   end if
catch e
   return empty
end try
end json_ToArray

function indexArray_ToJson indexArray
   local jsonBit
   repeat with itemNum = 1 to item 2 of the extents of indexArray
      put indexArray [itemNum] into itemArray
      put JSONExport (itemArray) into itemJSON
      put itemJSON & comma & CR after jsonBit
   end repeat
   delete char -2 to -1 of jsonBit
   return jsonBit
end indexArray_ToJson


--> Controller | MatchData
-
function regExp_fromLinkKey linkKey
   put "\[\[" & linkKey & "\]\]:\s*" into regBit
   return regBit
end regExp_fromLinkKey

function rexp_FromRex sRex
   -- either https or http
   put "(?:https?://)" & sRex into regExp
   return regExp
end rexp_FromRex

function rex_FromLine qLine
   set the itemdelimiter to ":"
   get word 1 to -1 of item 1 of qLine
   if it = "[[Rex]]" then
      put word 1 to -1 of item 2 to -1 of qLine into sRex
      return sRex
   else
      return empty
   end if
end rex_FromLine

function rex_MatchUrl dURL, mData
   -- was "controller_MatchedItemArray"
   put item 2 of the extents of mData into maxNum
   repeat with iNum = 1 to maxNum
      put mData [iNum] into iArray
      put iArray ["synopsis"] into qLine
      put rex_FromLine (qLine) into sRex
      if sRex is empty then next repeat -- checked
      
      put rexp_FromRex(sRex) into regExp
      try
         if matchText (dURL, regExp) then
            return iArray
         end if
      catch e
         -- wiki defined regExp is broken
      end try
   end repeat
   return empty
end rex_MatchUrl


--> Controller | MatchData
-
function controller_MatchedPageArray dUrl, matchData, pHandlerName
   get rex_MatchUrl (dURL, matchData)
   put it ["title"] into cStackName
   put controller_GetPageArray (dUrl, cStackName, pHandlerName) into pageArray
   return pageArray
end controller_MatchedPageArray

function controller_FetchMatchData pProt, pPort
   put "controller.livecode.wiki" into wDom
   
   # Construct regExp
   put regExp_fromLinkKey ("Rex") into rExp
   
   put wikiSite_MatchData (rExp, wDom, pProt, pPort) into matchData
   return matchData
end controller_FetchMatchData


--> Controler
-
function controller_GetPageArray dUrl, cStackName, pHandlerName
   if exists (stack cStackName) is false then
      gitHub_LaunchStack
   end if
   
   if exists (stack cStackName) is false then
      if pHandlerName is not empty then
         set the default_Handler of stack cStackName to pHandlerName
      end if
      put the page_Array [dUrl] of stack cStackName into pArray
   else
      put "Cannot load stack" && kwote (cStackName) & "!" into mdText
      put pageArray_Construct ("Error", mdText) into pArray
   end if
   return pArray
end controller_GetPageArray

function wikiSite_FirstLinkedKeyTitles linkKey, wDomain, pProtocol, pPort
   # Construct regExp
   put regExp_fromLinkKey (linkKey) into regExp
   
   put wikiSite_MatchData (regExp, wDomain, pProtocol, pPort) into matchData
   repeat with iNum = 1 to item 2 of the extents of matchData
      put matchData [iNum]["title"] into pTitle
      put pTitle & CR after pTitles
   end repeat
   return pTitles
end wikiSite_FirstLinkedKeyTitles

function wikiSite_MatchData regExp, wDomain, pProtocol, pPort
   put fedwiki_FetchSitemapArray (wDomain, pProtocol, pPort) into sMapArray
   
   put 1 into mNum
   repeat with iNum = 1 to item 2 of the extents of sMapArray
      put sMapArray [iNum] into iArray
      --
      put iArray ["synopsis"] into firstLine
      try
         if matchText (firstLine, regExp) then
            put iNum into iArray ["iNum"]
            put iArray into matchData [mNum]
            add 1 to mNum
         end if
      catch e
         -- problem with provided regExp
      end try
   end repeat
   return matchData
end wikiSite_MatchData

function wikiSite_FirstMatchPageArray regExp, wDomain, pProtocol, pPort
   put wikiSite_FirstMatchArray (regExp, wDomain) into iArray
   put iArray ["slug"] into foundSlug
   put pageArray_Fetch (wDomain, foundSlug, pPort, pProtocol) into pArray
   return pArray
end wikiSite_FirstMatchPageArray

function wikiSite_FirstMatchArray regExp, wDomain, pProtocol, pPort
   put fedwiki_FetchSitemapArray (wDomain, pProtocol, pPort) into sMapArray
   -- display_Data sMapArray
   
   repeat with iNum = 1 to item 2 of the extents of sMapArray
      put sMapArray [iNum] into iArray
      --
      put iArray ["synopsis"] into firstLine
      if matchText (firstLine, regExp) then
         return iArray
      end if
   end repeat
   return empty
end wikiSite_FirstMatchArray


--> WikiFrame
-
function wikiFrame_GetContextData
   switch the platform
      case "web"
         put wikiFrame_GetContextJson() into contextJson
         put JsonImport (contextJson) into contextArray
         return contextArray
         break
      default
         return empty
   end switch
end wikiFrame_GetContextData

function wikiFrame_FetchPageArray
   put wikiFrame_FetchPageJson() into pageJSON
   put JsonImport (pageJSON) into pageArray
   return pageArray
end wikiFrame_FetchPageArray

function wikiFrame_FetchPageArray
   put wikiFrame_FetchPageJson() into pageJSON
   put JsonImport (pageJSON) into pageArray
   return pageArray
end wikiFrame_FetchPageArray

function wikiFrame_GetItemArray itemID
   put wikiFrame_GetPageArray() into pageArray
   get pageArray_GetItemArray (pageArray, itemID) 
   if it is an array then
      return it
   else
      wikiFrame_DisplayHelp "fix-item-id"
      return empty
   end if
end wikiFrame_GetItemArray


--> Fedwiki | Url | Working on
-
function favicon_FetchPng wDomain, pProtocol
   if pProtocol is empty then
      put the origin_Protocol of the target into pProtocol
   end if
   
   put fedwiki_FaviconURL (wDomain, pProtocol) into faviconUrl
   put url faviconUrl into pngImage
   return pngImage
end favicon_FetchPng

function fedwiki_FaviconURL wDomain, pProtocol
   if pProtocol is empty then put "http" into pProtocol
   --
   put pProtocol & "://" & wDomain & "/favicon.png" into someUrl
   return someUrl
end fedwiki_FaviconURL

function fedwiki_JsonSiteExportUrl wDomain, pProtocol
   if pProtocol is empty then put "http" into pProtocol
   --
   put pProtocol & "://" & wDomain & "/system/export.json" into someUrl
   return someUrl
end fedwiki_JsonSiteExportUrl

function fedwiki_ConstructAssetUrl shortFile, wDomain, pSubFolder, pProtocol
   if pProtocol is empty then put "http" into pProtocol
   --
   put pProtocol & "://" into assetURL -- could be "https"
   put wDomain after assetURL
   put "/assets/" after assetURL
   --
   if pSubFolder is not empty then
      text_AddTrailing pSubFolder, slash
      put pSubFolder after assetURL
   end if
   --
   put shortFile after assetURL
   return assetURL
end fedwiki_ConstructAssetUrl

function fedwiki_UrlFromSlug wDomain, pSlug, pProtocol
   if pProtocol is empty then put "http" into pProtocol
   
   put pProtocol & "://" & wDomain & slash into someURL
   if pSlug is empty then
      put "view/welcome-visitors" & pSlug after someURL
   else
      put "view/welcome-visitors/view/" & pSlug after someURL
   end if
   return someURL
end fedwiki_UrlFromSlug


--> Fedwiki | Lineup
-
function fedwiki_GetLineUpData lineUpURL
   set the itemdelimiter to slash
   put item 3 of lineUpURL into wikiDomain
   put item 4 to -1 of lineUpURL into lineUpBit
   --
   put wikiDomain into lineUpData ["wikiDomain"]
   put lineUpURL into lineUpData ["lineUpURL"]
   --
   put the number of items of lineUpBit / 2 into maxNum
   put 1 into lineUpNum
   repeat maxNum
      put item 1 of lineUpBit into viewOrDomain
      if viewOrDomain = "view" then
         put wikiDomain into lineUpDomain
      else
         put viewOrDomain into lineUpDomain
      end if
      put item 2 of lineUpBit into pageSlug
      put pageSlug into lineUpData ["lineUp"][lineUpNum]["slug"]
      put lineUpDomain into lineUpData ["lineUp"][lineUpNum]["lineupDomain"]
      --
      add 1 to lineUpNum
      delete item 1 to 2 of lineUpBit
   end repeat
   return lineUpData
end fedwiki_GetLineUpData

function fedwiki_FetchLineUpData lineUpURL, pProtocol, pPort
   put fedwiki_GetLineUpData (lineUpURL) into lineUpData
   put lineUpData ["lineUp"] into lineUpArray
   repeat with lineUpNum = 1 to item 2 of the extents of lineUpArray
      put lineUpArray [lineUpNum]["slug"] into pSlug
      put lineUpArray [lineUpNum]["lineupDomain"] into wikiDomain
      --
      put pageArray_Fetch( wikiDomain, pSlug, pPort, pProtocol) into pageArray
      --
      put pageArray ["title"] into lineUpData ["lineUp"][lineUpNum]["title"]
      put pageArray ["story"] into lineUpData ["lineUp"][lineUpNum]["story"]
      put pageArray ["journal"] into lineUpData ["lineUp"][lineUpNum]["journal"]
   end repeat
   return lineUpData
end fedwiki_FetchLineUpData

function fedwiki_ConstructLineUpURL lineUpArray, wikiDomain
   put "http://" & wikiDomain & slash into lineUpURL
   repeat with lineUpNum = 1 to item 2 of the extents of lineUpArray
      put lineUpArray [lineUpNum]["slug"] into pageSlug
      put lineUpArray [lineUpNum]["lineupDomain"] into lineUpDomain
      --
      if lineUpDomain = wikiDomain then
         put "view/" after lineUpURL
      else
         put lineUpDomain & slash after lineUpURL
      end if
      put pageSlug & slash after lineUpURL
   end repeat
   delete char -1 of lineUpURL
   return lineUpURL
end fedwiki_ConstructLineUpURL



--> Fedwiki | URL
-
function fedwiki_UrlPathToSlug urlPath
   set the itemdelimiter to "/"
   get item -1 of urlPath
   set the itemdelimiter to "."
   put item 1 of it into pageSlug
   return pageSlug
end fedwiki_UrlPathToSlug

function fedwiki_ExtractPageSlugsFromPath urlPath
   set the itemdelimiter to "/"
   repeat with itemNum = 2 to the number of items of urlPath step 2
      put item itemNum of urlPath into someSlug
      put someSlug & CR after someSlugs
   end repeat
   return word 1 to -1 of someSlugs
end fedwiki_ExtractPageSlugsFromPath

command fedwiki_DeconstructURL wikiURL, @pageSlug, @wDomain
   url_Deconstruct wikiURL, someProtocol, wDomain, urlPath, pageSlug, fileExtension, uName, pWord
   return someProtocol
end fedwiki_DeconstructURL

function fedwiki_ConstructTitle pageSlug
   replace "-" with space in pageSlug
   repeat for each word someWord in pageSlug
      put toupper (char 1 of someWord) into char 1 of someWord
      put someWord & space after pageTitle
   end repeat
   delete char -1 of pageTitle
   return pageTitle
end fedwiki_ConstructTitle

function fedwiki_ConstructHtmlUrl wDomain, pSlug, pProtocol
   if pProtocol is empty then put "http" into pProtocol
   if pSlug is empty then put "welcome-visitors" into pSlug
   --
   put pProtocol & "://" & wDomain & slash into someURL
   put pSlug & ".html" after someURL
   --
   return someURL
end fedwiki_ConstructHtmlUrl


--> Favicon
-
function favicon_ListLocalShortFiles
   put favicon_ConstructFolder() into faviconFolder
   --
   put files (faviconFolder) into faviconPaths
   return faviconPaths
end favicon_ListLocalShortFiles

command favicon_StorePng wDomain, pForce, pProtocol
   put favicon_ConstructFolder() into faviconFolder
   if there is not a folder faviconFolder then
      create folder faviconFolder
   end if
   put favicon_ConstructFile (wDomain) into faviconPath
   if pForce is not true AND there is a file faviconPath then
      return faviconPath
   end if
   
   # Else create file
   put favicon_FetchPng (wDomain, pProtocol) into faviconPng
   put faviconPng into url ("binfile:" & faviconPath)
   return faviconPath
end favicon_StorePng


--> Favicon | Paths
-
function favicon_PathFromShortFile shortFile
   put favicon_ConstructFolder() into faviconFolder
   put faviconFolder & "/" & shortFile into faviconPath
   return faviconPath
end favicon_PathFromShortFile

function favicon_GetFromShortFile shortFile
   put favicon_PathFromShortFile (shortFile) into faviconPath
   put url ("binfile:" & faviconPath) into pngData
   return pngData
end favicon_GetFromShortFile

function favicon_Get wDomain
   put favicon_ConstructFile (wDomain) into faviconPath
   put url ("binfile:" & faviconPath) into pngData
   return pngData
end favicon_Get

command favicon_Set wDomain, pngData
   put favicon_ConstructFile (wDomain) into faviconPath
   put pngData into url ("binfile:" & faviconPath)
   return faviconPath
end favicon_Set

function favicon_ConstructFile wDomain
   put favicon_ConstructFolder() into faviconFolder
   --
   replace "." with "_" in wDomain
   put faviconFolder & "/" & wDomain & ".png" into faviconPath
   return faviconPath
end favicon_ConstructFile

function favicon_ConstructFolder
   if the platform is "web" then
      put "/favicons" into faviconFolder
   else
      put the desktop folder & "/favicons" into faviconFolder
   end if
   return faviconFolder
end favicon_ConstructFolder


--> WikiFrame
-
command wikiFrame_Resize pHeight
   put wikiFrame_ConstructResizeMessage (pHeight) into sJavascript
   if the platform is not "web" then  return sJavascript
   
   do sJavascript as "JavaScript"
   return sJavascript
end wikiFrame_Resize

function wikiFrame_GetContextJson
   do "getFrameContext()" as "javascript"
   put the result into contextJson
   return contextJson
end wikiFrame_GetContextJson

function wikiFrame_GetFirstCode
   put wikiFrame_GetPageArray() into pageArray
   put pageArray_GetFirstCode (pageArray) into itemText
   --
   put text_ReplaceWord (itemText, "brandom", "colour_GetRandom()") into doScript
   return doScript
end wikiFrame_GetFirstCode

function wikiFrame_Array
   put wikiFrame_Items() into frameValues
   repeat with itemNum = 1 to the number of items of Frame_ItemKeys
      put item itemNum of Frame_ItemKeys into sKey
      put item itemNum of frameValues into sValue
      --
      put sValue into frameArray [sKey]
   end repeat
   return frameArray
end wikiFrame_Array

function wikiFrame_Items
   -- put wikijs_Frame() into sJavascript
   put "const identifiers = Object.fromEntries(new URLSearchParams(window.location.hash.substr(1)).entries())" into sJavascript
   
   -- identifiers.site + "," +  identifiers.slug + "," + identifiers.origin + "," + identifiers.title + "," + identifiers.pageKey + "," + identifiers.itemId
   put CR&CR after sJavascript
   put "+ " & kwote (comma) && "+ " into addBit
   repeat for each item sParam in Frame_ItemKeys
      put "identifiers." & sParam && addBit after sJavascript
   end repeat
   delete word -3 to -1 of sJavascript
   
   do sJavascript as "Javascript"
   put the result into frameInfoItems
   return frameInfoItems
end wikiFrame_Items

function wikiFrame_GetPageArray
   put wikiFrame_GetContextData() into contextArray
   
   /*
   put contextArray ["site"] into wikiDomain
   put contextArray ["slug"] into pageSlug
   put contextArray ["title"] into pageTitle
   --
   put contextArray ["origin"] into wikiURL
   put contextArray ["item"] into frameItemArray
   put contextArray ["pageKey"] into pageKey
   */
   
   put contextArray ["page"] into pageArray
   return pageArray
end wikiFrame_GetPageArray


--> pageArray
-=
function pageArray_GetFirstCode pageArray
   put pageArray ["story"] into storyArray
   repeat with itemNum = 1 to item 2 of the extents of storyArray
      put storyArray [itemNum] into itemArray
      if itemArray ["type"] = "code" then
         put storyArray [itemNum]["text"] into itemText
         return itemText
      end if
   end repeat
   return empty
end pageArray_GetFirstCode


--> PageArray
-
command pageArray_StripJournal @pageArray, pSourceArray, pMilliseconds
   put pageArray ["title"] into pageTitle
   put pageArray ["story"] into storyArray
   --
   put journalArray_Construct (pageTitle, pSourceArray, pMilliseconds, storyArray) into journalArray
   put journalArray into pageArray ["journal"]
end pageArray_StripJournal

function pageArray_Construct pageTitle, someMarkdown, pPlugin
   put pageTitle into pageArray ["title"]
   pageArray_AddMarkdown pageArray, someMarkdown
   put journalArray_Construct (pageTitle) into pageArray ["journal"]
   --
   if pPlugin is not empty then
      put pPlugin into pageArray ["plugin"]
   end if
   return pageArray
end pageArray_Construct

command pageArray_AddMarkdown @pageArray, someMarkdown, pID
   if someMarkdown is empty then return 0
   put itemArray_Construct ("markdown", pID, someMarkdown) into itemArray
   itemArray_Add itemArray, pageArray
   return the result
end pageArray_AddMarkdown


--> PageJson
-
function pageJson_Fetch wikiDomain, pSlug, pPort, pDecode, pProtocol
   put pageJson_ConstructUrl (wikiDomain, pSlug, pPort, pProtocol) into someUrl
   put url someUrl into sJSON
   if pDecode is true then
      put textDecode (sJSON, "UTF-8") into sJSON
   end if
   return sJSON
end pageJson_Fetch

function fedwiki_FetchSitemap wDomain, pProtocol, pPort
   put fedwiki_JsonSiteMapUrl (wDomain, pProtocol, pPort) into sitemapURL
   put url sitemapURL into sitemapJSON
   return sitemapJSON
end fedwiki_FetchSitemap


--> itemArray
-
command itemArray_Add itemArray, @pageArray
   if itemArray is not an array then return 0
   
   put pageArray ["story"] into storyArray
   put pageArray ["journal"] into journalArray
   put itemArray ["id"] into itemID
   
   # Add the item to the end of the story
   itemArray_AddToEnd itemArray, storyArray
   put the result into afterID -- this can be empty if it is the first entry
   put storyArray into pageArray ["story"]
   
   # Now let's add the edit or add to the journal
   put itemArray_ConstructFactory (itemID) into factoryArray
   journalArray_Add journalArray, factoryArray, "add", afterID -- after the id of the end paragraph
   
   # Finally add the journal entry for editing the factory
   journalArray_Add journalArray, itemArray, "edit"
   put journalArray into pageArray ["journal"]
   
   put pageArray ["story"] into storyArray
   put item 2 of the extents of storyArray into lastItemNum
   return lastItemNum
end itemArray_Add

function itemArray_ConstructFactory pID
   put itemArray_Construct ("factory", pID) into factoryArray
   return factoryArray
end itemArray_ConstructFactory

function itemArray_ConstructAssets sText, pID
   put itemArray_Construct ("assets", pID, sText) into itemArray
   return itemArray
end itemArray_ConstructAssets

function itemArray_Construct itemType, pID, pText
   itemArray_NormalizeID pID
   put pID into itemArray ["id"]
   --
   put itemType into itemArray ["type"]
   --
   if pText is not empty then  
      put pText into itemArray ["text"]
   end if
   return itemArray
end itemArray_Construct

command itemArray_AddToEnd itemArray, @indexArray
   # Figure out what we just added it after
   put item 2 of the extents of indexArray into indexNum
   put indexArray [indexNum]["id"] into afterID
   
   # Add itemArray to end
   add 1 to indexNum
   put itemArray into indexArray [indexNum]
   return afterID
end itemArray_AddToEnd

function itemArray_Construct itemType, pID, pText
   itemArray_NormalizeID pID
   put pID into itemArray ["id"]
   --
   put itemType into itemArray ["type"]
   --
   if pText is not empty then  
      put pText into itemArray ["text"]
   end if
   return itemArray
end itemArray_Construct

command itemArray_NormalizeID @pID
   if pID is empty then 
      put uuid () into pID
   end if
end itemArray_NormalizeID


--> journalArray
-
command journalArray_Add @journalArray, itemArray, journalType, pAfterID, pMilliseconds
   if pMilliseconds is empty then put the milliseconds into pMilliseconds
   if pAfterID is not empty then put pAfterID into journalEntryArray ["after"]
   
   # Construct journalEntryArray
   put pMilliseconds into journalEntryArray ["date"]
   put itemArray ["id"] into journalEntryArray ["id"]
   put itemArray into journalEntryArray ["item"]
   put journalType into journalEntryArray ["type"]
   
   # Add to end
   itemArray_AddToEnd journalEntryArray, journalArray
   --
   return pMilliseconds
end journalArray_Add

function journalArray_Construct pageTitle, pSourceArray, pMilliseconds, pStoryArray
   if pMilliseconds is not a number then put the milliseconds into pMilliseconds
   --
   put "create" into createArray ["type"]
   put pMilliseconds into createArray ["date"]
   put pageTitle into createArray ["item"]["title"]
   if pStoryArray is an array then put pStoryArray into createArray ["item"]["story"]
   if pSourceArray is an array then put pSourceArray into createArray ["source"]
   --
   put createArray into journalArray [1]
   return journalArray
end journalArray_Construct


--> Frame | Construct
-
function wikiFrame_ConstructResizeMessage pHeight
   if pHeight is empty then put 200 into pHeight
   --
   put "{ action: 'resize', height:" && pHeight into wikiJS
   put "}, '*'" after wikiJS
   --
   put wikiFrame_ConstructPostMessage (wikiJS) into sJavascript
   return sJavascript
end wikiFrame_ConstructResizeMessage

function wikiFrame_ConstructGhostMessage pageJSON
   if pageJSON is empty then
      put pageArray_Construct ("Test Ghost Page", "Helo world!") into pageArray
      put pageArray_ToJson (pageArray) into pageJSON
   end if
   --   
   put "{action:" & kwote("showResult") & ",page: " into wikiJS
   put CR & pageJSON & CR after wikiJS
   put ",keepLineup: event.shiftKey}," && kwote("*") after wikiJS
   --
   put wikiFrame_ConstructPostMessage (wikiJS) into sJavascript
   return sJavascript
end wikiFrame_ConstructGhostMessage

function wikiFrame_ConstructInternalMessage pageTitle, pWikiDomain
   -- was "jsPostMessage_Internal"
   if pageTitle is empty then put "About Frame Plugin" into pageTitle
   --
   put wikiFrame_ConstructInternalAction (pageTitle, pWikiDomain) into wikiJS
   put wikiFrame_ConstructPostMessage (wikiJS) into sJavascript
   --
   return sJavascript
end wikiFrame_ConstructInternalMessage

function wikiFrame_ConstructInternalAction pageTitle, pWikiDomain
   -- was "wikijs_DoInternal"
   put "{action:'doInternalLink'," into wikiJS
   put "title:" && kwote (pageTitle) & comma after wikiJS
   --
   if pWikiDomain is not empty then
      put "site:" && kwote (pWikiDomain) & comma after wikiJS
   end if
   --
   put "keepLineup: event.shiftKey" after wikiJS
   put "}, '*'" after wikiJS
   --
   return wikiJS
end wikiFrame_ConstructInternalAction

function wikiFrame_FetchPageJson pSlug
   put wikiFrame_Array() into frameArray
   --
   if pSlug is empty then put frameArray ["slug"] into pSlug
   --
   put frameArray ["origin"] into wUrl
   -- put frameArray ("site") into wDomain
   -- 
   put wUrl & slash & pSlug & ".json" into jsonURL
   put url jsonURL into pJSON
   --
   return pJSON
end wikiFrame_FetchPageJson

function wikiFrame_ConstructPostMessage wikiJS
   put "window.parent.postMessage(" into postJS
   put wikiJS after postJS
   put ");"  after postJS
   return postJS
end wikiFrame_ConstructPostMessage


--> Wasm
-
function wasm_StandaloneFolder
   return "/boot/standalone/"
end wasm_StandaloneFolder

function wasm_StackPath shortFile, pLiveExt
   if pLiveExt is empty then put "livecodescript" into pLiveExt
   put wasm_StandaloneFolder() & shortFile into sPath
   return sPath
end wasm_StackPath


--> Wasm | Required
-
command wasm_UseLibs
   put wasm_ListShortUseFiles() into shortLibFiles
   wasm_UseShortFiles shortLibFiles
   return the result
end wasm_UseLibs

command wasm_UseShortFiles shortLibFiles
   repeat for each line shortLibFile in shortLibFiles
      put wasm_StackPath (shortLibFile) into sPath
      start using stack sPath
      put sPath & CR after sPaths
   end repeat
   delete char -1 of sPaths
   return sPaths
end wasm_UseShortFiles

function wasm_ListShortUseFiles
   put wasm_ListShortFiles() into shortLibFiles
   filter shortLibFiles with regEx pattern "^(lib_|model_)"
   return shortLibFiles
end wasm_ListShortUseFiles

function wasm_ListShortModelFiles
   put wasm_ListShortFiles() into shortLibFiles
   filter shortLibFiles with "model_*"
   return shortLibFiles
end wasm_ListShortModelFiles

function wasm_ListShortFiles
   put wasm_StandaloneFolder() into sFolder
   put files (sFolder) into shortLibFiles
   return shortLibFiles
end wasm_ListShortFiles


--> Ghost
-
command ghost_PageArray pageArray
   if the platform is "web" then
      put pageArray_ToJson (pageArray) into pageJSON
      if pageJSON is empty then 
         put "Error decoding array." into someMarkdown
         put pageArray_Construct ("Error", someMarkdown, "markdown") into pageArray
         put pageArray_ToJson (pageArray) into pageJSON
      end if
      
      put wikiFrame_ConstructGhostMessage (pageJSON) into sJavascript
      if the platform is "web" then
         do sJavascript as "JavaScript" -- do "document.location" as "JavaScript"
         return sJavascript
      else
         return sJavascript
      end if
   else
      display_Data pageArray, "ghost_PageArray"
   end if
end ghost_PageArray


--> Deps
-
function text_ReplaceWord sString, sWord, newWord
   put "\" & sWord & "\b" into matchExp
   put replaceText (sString, matchExp, newWord) into newString
   return newString
end text_ReplaceWord

function kwote someText, pQuoteChar
   if pQuoteChar is empty then put quote into pQuoteChar
   return pQuoteChar & someText & pQuoteChar
end kwote
