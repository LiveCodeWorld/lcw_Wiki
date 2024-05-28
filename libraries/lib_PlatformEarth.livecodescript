script "lib_PlatformEarth" with behavior "youtube.lc"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_PlatformEarth
type: library
version: 0.2

/*
*/


--> Working on
-
function pageArray_FromURL droppedURL, pWikiDomain
   put "code.astralship.wiki" into pWikiDomain
   put platform_FetchPatternArray (pWikiDomain) into rPatternArray
   --
   put platform_MatchDroppedUrl (droppedURL, rPatternArray) into itemArray
   put itemArray ["hName"] into hName
   put itemArray ["cStackName"] into cStackName
   -- put itemArray ["paramList"] into paramList
   if exists (stack cStackName) then
      put the name of stack cStackName into cObject
      put hkey_Construct (hName, "c", cObject) into cHkey
      --
      if the shiftkey is down then
         hkey_Edit cHkey
         return empty
      else
         -- put hName & "_PageArray" into propName
         -- put the propName[droppedURL] of cObject into pageArray - not working for scriptonly vprops??
         -- put the index_PageArray [droppedURL] of cObject into pageArray -- works
         
         put hName & "_GetPageArray" into fName
         put fName & "(" & kwote (droppedURL) & ")" into sFunction
         put value (sFunction, cObject) into pageArray -- crashes Livecode if no object
         return pageArray
      end if
   else
      return empty
   end if
end pageArray_FromURL

function platform_MatchDroppedUrl droppedURL, rPatternArray
   repeat with itemNum = 1 to item 2 of the extents of rPatternArray
      put rPatternArray [itemNum] into itemArray
      --
      put itemArray ["regExp"] into regExp
      if matchText (droppedURL, regExp) is true then
         return itemArray
      end if
   end repeat
   return empty
end platform_MatchDroppedUrl

function platform_FetchPatternArray wikiDomain, pPort
   put pageArray_Fetch( wikiDomain, "domain-tools", pPort) into pageArray
   --
   put pageArray ["story"] into storyArray
   repeat with itemNum = 1 to item 2 of the extents of storyArray
      put storyArray [itemNum] into itemArray
      switch itemArray ["type"]
         case "code"
            put itemArray ["text"] into sCode
            _ParsePatternCode rPatternArray, sCode
            break
         case "reference"
            
            break
         default
            -- just description
      end switch
   end repeat
   return rPatternArray
end platform_FetchPatternArray


--> Platform
-
command platform_CleanJournal browserView
   put the clicked_FlagArray of browserView into flagArray
   --
   -- display_Data flagArray, "clicked_FlagArray", "Flag"
   put flagArray ["href"] into flagHref
   put flagArray ["pageTitle"] into pageTitle
   put flagArray ["target"] into wikidomain
   --
   set the itemdelimiter to slash
   put item -1 of flagHref into pageSlug
   --
   put the page_Array [pageTitle] of browserView into pageArray
   pageArray_CleanJournal pageArray
   -- display_PageArray pageArray, wikidomain
   -- set the page_Slug [wikidomain] of browserView to pageSlug
   set the ghost_PageArray of browserView to pageArray
end platform_CleanJournal

on platform_ToggleMenuBar browserView
   put the show_Menu of browserView into sBoolean
   set the show_Menu of browserView to (sBoolean is false)
end platform_ToggleMenuBar

on platform_Wikipedia browserView, pageSlug
   -- put mediawiki_FetchPageArray ("https://en.wikipedia.org/wiki/Well-being")
   put mediawiki_GetPageArrayFromSlug (pageSlug) into pageArray
   transport_ReturnPageArray pageArray
end platform_Wikipedia

on platform_Roster browserView
   put wikiDomain_List ("*astral*") into wikiDomains
   put roster_ConstructPageArray (wikiDomains) into pageArray
   transport_ReturnPageArray pageArray
end platform_Roster

on platform_Test browserView, otherItems
   -- put the target into browserView
   
   put the footer_IsVisible of browserView into sBoolean
   set the footer_IsVisible of browserView to (sBoolean is false)
end platform_Test

on platform_Pretty browserView, sBoolean
   set the pretty_Journal of browserView to sBoolean is true
end platform_Pretty

on platform_Colour browserView, otherItems
   put item 1 of otherItems into sColour
   put item 2 to -1 of otherItems into pSlugs
   --
   if pSlugs is empty then
      set the page_Colour of browserView to sColour
   else
      repeat for each item pSlug in pSlugs
         set the page_Colour [pSlug] of browserView to sColour
      end repeat
   end if
end platform_Colour


--> Platform | Earth
-
function platform_ConstructToolHandler toolName
   put "platform_"& text_InitialCaps (toolName) into hName
   return hName
end platform_ConstructToolHandler

function platform_IsToolUrl externalURL
   return platform_ToolItems (externalURL) is not empty
end platform_IsToolUrl

command platform_DeconstructURL externalURL, @toolItems, @urlExt, @hName
   if externalURL begins with "http://tools.platform.earth/" then
      set the itemdelimiter to slash
      put item 4 to -1 of externalURL into toolPath
      --
      set the itemdelimiter to "."
      put item 1 of toolPath into toolItems
      replace slash with comma in toolItems
      --
      delete item 1 of toolPath
      put toolPath into urlExt
      --
      set the itemdelimiter to comma
      put item 1 of toolItems into toolName
      put platform_ConstructToolHandler (toolName) into hName
   else
      put empty into toolItems
      put empty into urlExt
      put empty into hName
   end if   
end platform_DeconstructURL

function platform_ToolItems externalURL
   platform_DeconstructURL externalURL, toolItems, urlExt, hName
   return toolItems
   
   put "(http://tools\.platform\.earth/test\.json)" into sReg
   -- put "http://tools\.platform\.earth/(.+)\.json" into sReg
   -- put "(http|https)://tools\.platform\.earth/(.+)json" into sReg
   -- put "^(http|https)://tools\.platform\.earth/(.+)json$" into sReg
   -- put "(http|https)://tools\.platform\.earth/(.+)json" into sReg
   --
   if matchChunk (externalURL, sReg , toolName) is true then
      return toolName
   else
      return empty
   end if
end platform_ToolItems


--> Private
-
private command _ParsePatternCode @rPatternArray, sCode
   repeat for each line sLine in sCode
      switch
         case word 1 to -1 of sLine is empty
            next repeat
            break
         case char 1 of sLine = "#"
            -- # bbc/listenNotes: listenID
            delete char 1 of sLine
            --
            set the itemdelimiter to ":"
            put word 1 to -1 of item 1 of sLine into hPath
            put word 1 to -1 of item 2 to -1 of sLine into matchedItems
            --
            set the itemdelimiter to slash
            if the number of items of hPath = 1 then
               put hPath into cStackName
               put "index" into hName
            else
               put item -1 of hPath into hName
               put item 1 to -2 of hPath into cStackName
               replace slash with "-" in cStackName
            end if
            put ".lc" after cStackName
            break
         default
            put word 1 to -1 of sLine into regExp
            _AddToPatternArray rPatternArray, regExp, cStackName, hName, matchedItems
      end switch
   end repeat
end _ParsePatternCode

private command _AddToPatternArray @rPatternArray, regExp, cStackName, pHandlerName, pParamList
   if pHandlerName is empty then put "index" into pHandlerName
   --
   put regExp into itemArray ["regExp"]
   put cStackName into itemArray ["cStackName"]
   put pHandlerName into itemArray ["hName"]
   put pParamList into itemArray ["paramList"]
   --
   indexArray_AddToEnd rPatternArray, itemArray
end _AddToPatternArray
