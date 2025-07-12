script "lib_WikiScript"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_WikiScript
type: library
version: 0.1


--> Working on
-


--> Wiki | Script
-
function wikiScript_Match tLine
   put "Hello" & CR & "get page '42_Reasons' of wiki 'gameb.wiki'" into tLine
   -- put "put page '42_Reasons' of wiki 'gameb.wiki' into pArray" into tLine
   
   wikiScript_PageTagOffsets tLine, startNum, endNum
   if the result is true then
      put char startNum to endNum of tLine into tContent
      replace "'" with quote in tContent
      put token 2 of tContent into pageTitle
      put token 5 of tContent into wDomain
      get kwote (pageTitle) & comma && kwote (wDomain)
      put "pageArray_Fetch (" & it & ")" into fLine
      --
      put fLine into char startNum to endNum of tLine
      return tLine
   else
      return empty
   end if
end wikiScript_Match

command wikiScript_PageTagOffsets tLine, @startNum, @endNum
   local tPhrase
   
   put "(?i)(?:get|put)\s+(page\s+([' " & quote & "])[^' " & quote & "]+\2\s+of\s+wiki\s+\2[^' " & quote & "]+\2)" into tRegex
   if matchChunk (tLine, tRegex, startNum, endNum) then
      return true
   else
      put 0 into startNum
      put 0 into endNum
      return false
   end if
end wikiScript_PageTagOffsets


--> Deps
-
