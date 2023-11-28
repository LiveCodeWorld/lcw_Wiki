script "lib_WikiLineUp"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_WikiLineUp
type: library
version: 0.1

/*Some help*/


--> Working on
-

--> Fedwiki | Lineup
-
function fedwiki_FetchLineUpData lineUpURL
   put fedwiki_GetLineUpData (lineUpURL) into lineUpData
   put lineUpData ["lineUp"] into lineUpArray
   repeat with lineUpNum = 1 to item 2 of the extents of lineUpArray
      put lineUpArray [lineUpNum]["slug"] into pSlug
      put lineUpArray [lineUpNum]["lineupDomain"] into wikiDomain
      --
      put pageArray_Fetch (wikiDomain, pSlug) into pageArray
      --
      put pageArray ["title"] into lineUpData ["lineUp"][lineUpNum]["title"]
      put pageArray ["story"] into lineUpData ["lineUp"][lineUpNum]["story"]
      put pageArray ["journal"] into lineUpData ["lineUp"][lineUpNum]["journal"]
   end repeat
   return lineUpData
end fedwiki_FetchLineUpData

function fedwiki_GetLineupSlugs lineUpArray
   -- bit dodgy
   set the wholeMatches to true
   repeat with lineUpNum = 1 to item 2 of the extents of lineUpArray
      put lineUpArray [lineUpNum]["slug"] into pageSlug
      put lineUpArray [lineUpNum]["lineupDomain"] into lineUpDomain
      --
      if pageSlug is among the lines of pageSlugs then
         put pageSlug && "of" && lineUpDomain & CR after pageSlugs
      else
         put pageSlug & CR after pageSlugs
      end if
   end repeat
   delete char -1 of pageSlugs
   return pageSlugs
end fedwiki_GetLineupSlugs

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

function fedwiki_FetchLastLineUpArray droppedURL, pNotTheseSlugs
   put fedwiki_FetchLastLineUpJson (droppedURL, pNotTheseSlugs) into pageJSON
   put json_ToArray (pageJSON) into pageArray
   return pageArray
end fedwiki_FetchLastLineUpArray

function fedwiki_FetchLastLineUpJson droppedURL, pNotTheseSlugs
   -- does not check that droppedURL is not a ".html" page
   if pNotTheseSlugs is empty then put "journal-cleaner-transport" into pNotTheseSlugs
   
   put fedwiki_ConstructUrlArray (droppedURL) into urlArray
   if urlArray is false then return false
   
   put item 2 of the extents of urlArray into lineUpNum
   put urlArray [lineUpNum]["slug"] into pageSlug
   if pageSlug is among the items of pNotTheseSlugs and lineUpNum is not 1 then
      subtract 1 from lineUpNum
   end if
   
   put fedwiki_FetchLineUpJson (urlArray, lineUpNum) into pageJSON
   return pageJSON
end fedwiki_FetchLastLineUpJson

function fedwiki_FetchLineUpJson urlArray, lineUpNum
   if lineUpNum = -1 then put item 2 of the extents of urlArray into lineUpNum
   
   put urlArray [lineUpNum]["slug"] into pageSlug
   put urlArray [lineUpNum]["someDomain"] into someDomain
   
   -- http://forage.david.bovill.me/entry-level-browser.json?random=72428048
   put "http://" & someDomain & "/" & pageSlug & ".json" into someUrl
   -- put "?random=" & the milliseconds after someUrl
   put url someUrl into someJSON
   return someJSON
end fedwiki_FetchLineUpJson

function fedwiki_ConstructUrlArray someUrl
   set the itemdelimiter to "/"
   put item 1 to 3 of someUrl into urlStem
   put item 3 of someUrl into urlDomain
   
   put item 4 to -1 of someUrl into pathBit
   put the number of items of pathBit into maxNum
   if (maxNum mod 2) is not 0 then 
      put item -1 of pathBit into extraBit
      delete item -1 of pathBit
      return false -- it is not a Fedwiki url ?
   end if
   
   put maxNum/2 into maxLineUpNum
   repeat with lineUpNum = 1 to maxLineUpNum
      put 2*lineUpNum - 1 into itemNum
      put item itemNum of pathBit into viewOrDomain
      put item (itemNum + 1) of pathBit into pageSlug
      _stripEndHashFromSlug pageSlug
      
      if viewOrDomain = "view" then
         put urlDomain into someDomain
      else
         put viewOrDomain into someDomain
      end if
      put pageSlug into urlArray [lineUpNum]["slug"]
      put someDomain into urlArray [lineUpNum]["someDomain"]
   end repeat
   return urlArray
end fedwiki_ConstructUrlArray
