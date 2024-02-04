script "lib_Wikipedia"
--> MetaData
-
license: GPLv3
name: lib_Wikipedia
type: library
version: 0.1

/*
In this library we keep handlers that are hard wired to wikipedia, rather than handlers that work with any general mediawiki installation.
*/


--> Working on
-
function wikpedia_Accreditation mwTitle, mwSlug
   put scaffold_Get ("Wikipedia Accreditation") into mdCred
   curly_ReplaceText mdCred, "mwSlug", mwSlug
   curly_ReplaceText mdCred, "mwTitle", mwTitle
   return mdCred
end wikpedia_Accreditation


--> Wikipedia | Construct
-
function wikipedia_ConstructUrl pageTitle, pSectionTitle
   replace "-" with space in pageTitle
   -- with a proper pageTitle we keep capitalisation?
   -- put text_InitialCaps (pageTitle) into pageSlug
   replace space with "_" in pageSlug
   put "https://en.wikipedia.org/wiki/" & pageSlug into wikipediaUrl
   if pSectionTitle is not empty then
      replace space with "_" in pSectionTitle
      put "#" & pSectionTitle after wikipediaUrl
   end if
   return wikipediaUrl
end wikipedia_ConstructUrl


-- Not Working
-
function wikipedia_ExtractSummary someTitles
   -- return html with warnings
   -- same as "wikipedia_FetchPageExtract"
   -- does not work for old mediawikis
   -- /w/api.php?action=query&prop=extracts&format=json&exintro=&explaintext=&exsectionformat=wiki&titles=North%20Africa&uselang=de
   if pFormat is empty then put "json" into pFormat
   
   put wikipedia_ConstructApiStem() & "?action=query&prop=extracts&exintro=&titles=" into apiStem
   put apiStem & urlEncode(someTitles) into someURL
   put "&format=" & pFormat after someURL
   put url someURL into someValue
   return someValue
end wikipedia_ExtractSummary

function wikipedia_FetchPageImageInfo pageTitle, pApiStem
   -- /w/api.php?action=query&
   -- prop=pageimages
   -- &format=json
   -- &piprop=thumbnail%7Cname%7Coriginal
   -- &titles=San_Francisco
   
   put "piprop=thumbnail|name|original" into pOtherBits
   put mediawiki_FetchPageBits (pageTitle, "pageimages", pOtherBits, pApiStem) into someJSON
   return someJSON
end wikipedia_FetchPageImageInfo

function wikipedia_FetchPageImages pageTitle, pApiStem
   -- /w/api.php?action=query&prop=images&format=json&titles=Albert%20Einstein
   put mediawiki_FetchPageBits (pageTitle, "images", empty, pApiStem) into someJSON
   return someJSON
end wikipedia_FetchPageImages


--> WikiPedia
-
function wikipedia_FetchPageExtract pageTitle, pApiStem
   put mediawiki_FetchPageBits (pageTitle, "extracts", "exintro=true", pApiStem) into someJSON
   return someJSON
end wikipedia_FetchPageExtract

function wikipedia_FetchPageStuff pageTitle, pApiStem
   put mediawiki_FetchPageBits (pageTitle, "extracts|links|extlinks|categories|images|pageimages|pageterms", "exintro=true", pApiStem) into someJSON
   return someJSON
end wikipedia_FetchPageStuff

function wikipedia_ExtractInfo someTitles
   if pFormat is empty then put "json" into pFormat
   
   -- prop=info for basic page info 
   put wikipedia_ConstructApiStem() & "?action=query&prop=info&titles=" into apiStem
   
   put apiStem & urlEncode(someTitles) into someURL
   put "&format=" & pFormat after someURL
   put url someURL into someValue
   return someValue
end wikipedia_ExtractInfo
