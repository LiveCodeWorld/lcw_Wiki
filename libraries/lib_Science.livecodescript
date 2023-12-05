script "lib_Science"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_Science
type: library
version: 0.1

/*

*/

constant OpenAlexApiBaseUrl = "https://api.openalex.org/"
local OpenAlexEmail = "david@regovern.org"

--> Working on
-
command display_OpenAlex searchTerms, notTerms, pPageNum, pDisplayView
   put openalex_SearchBit (searchTerms, notTerms) into searchBit
   put openalex_SearchWorks (searchBit, pPageNum) into sData
   --
   display_Data sData, searchBit, "OpenAlex", pDisplayView
   return the result
end display_OpenAlex

function openalex_SearchWorks searchBit, pPageNum
   put openalex_RestUrl ("works", pPageNum) into restURL
   put "&search=" & urlencode (searchBit) after restURL
   --
   put openalex_RestGetData (restURL) into restData
   return restData
end openalex_SearchWorks

function openalex_SearchBit searchTerms, pNotTerms
   -- put "(elmo AND 'sesame street') NOT (cookie OR monster)" into searchBit
   
   # Search for
   repeat for each item searchTerm in searchTerms
      put kwote (searchTerm, "'") && "AND " after plusBit
   end repeat
   delete word -1 of plusBit
   
   put "(" & plusBit into searchBit
   if pNotTerms is empty then
      put ")" after searchBit
   else
      # Not these
      repeat for each item searchTerm in pNotTerms
         put kwote (searchTerm, "'") && "OR " after notBit
      end repeat
      delete word -1 of notBit
      
      put notBit & ")" after searchBit
   end if
   --
   return searchBit
end openalex_SearchBit

function openalex_RestGetData restURL
   put url restURL into sJSON
   put json_ToArray (sJSON) into sData
   return sData
end openalex_RestGetData

function openalex_RestUrl sEntity, pPageNum
   put OpenAlexApiBaseUrl & sEntity into restURL
   put "?mailto=" & OpenAlexEmail after restURL
   if pPageNum is not empty then
      put "&page=" & pPageNum after restURL
   end if
   return restURL
end openalex_RestUrl

function openalex_ListEntities
   put "works,authors,sources,institutions,concepts,publishers,funders,geo" into openAlexEntities
   replace comma with CR in openAlexEntities
   return openAlexEntities
end openalex_ListEntities


--> Science
-


--> Deps
-
