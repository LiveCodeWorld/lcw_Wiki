script "lib_WikiRestBase"
--> MetaData
-
license: GPLv3
name: lib_WikiRestBase
type: library
version: 0.6
deps: lib_MediaWiki, lib_Fedwiki, lib_FedwikiPedia, lib_FedwikiCreate


/*
The main handler for the mediawiki.lc transporter is "mediawiki_FetchPageArray"
It's now probably in the wrong library and should be factored out into a new librarys with only clean code.

--
This library is for interfacing with the Wikimedia REST API - https://en.wikipedia.org/api/rest_v1/
This (newer) API provides cacheable and straightforward access to Wikimedia content and data, in machine-readable formats.
See - https://en.wikipedia.org/api/rest_v1/#!/Page_content/get_page_summary_title for swagger test bed

See also - https://www.mediawiki.org/wiki/REST_API

# Examples:
-- https://rest.wikimedia.org/en.wikipedia.org/v1/page/summary/wiki -- old
-- https://en.wikipedia.org/api/rest_v1/page/summary/ANT
-- put url "https://en.wikipedia.org/api/rest_v1/page/summary/Ant"

*/

--> Working on
-

--> Wikipedia | List
-
function wikipedia_ListPages titleString, pNearMatch, pLang
   -- if pNearMatch is true then the title is not returned properly capitalised
   put wikipedia_FetchSearchJson (titleString, pNearMatch, pLang) into someJSON
   put json_ToArray (someJSON) into queryResultArray
   -- display_Array queryResultArray
   
   put queryResultArray ["query"]["search"] into searchResultArray
   repeat with indexNum = 1 to item 2 of the extents of searchResultArray
      put searchResultArray [indexNum]["title"] into pageTitle
      put pageTitle & CR after pageTitles
   end repeat
   delete char -1 of pageTitles
   sort lines of pageTitles
   return pageTitles
end wikipedia_ListPages

function wikicommons_ListImages fromName, pFormat
   -- this does not seem to return good lists of images
   -- lot's of dodgy characters = spam? in file names etc?
   -- api.php?action=query&list=allimages&ailimit=5&aifrom=Albert&aiprop=dimensions|mime [try in ApiSandbox]
   -- put "Albert Einstein" into fromName
   -- put "IndustrialSymbiosisWasteHeatExchange.png" into shortImageFile
   if pFormat is empty then put "json" into pFormat
   
   put "action=query&list=allimages&format=[[pFormat]]" into urlPattern
   put "&titles=Image:[[shortImageFile]]" after urlPattern
   put wikicommons_GetApiStem() & merge (urlPattern) into restURL
   
   put mediawiki_FetchJSON (restURL) into someJSON
   -- put url someURL into someJSON
   return someJSON
end wikicommons_ListImages


--> Restbase | Fetch
-
function restbase_FetchSlugArray @pageSlug, restPath, pLang
   -- updates pageSlug if there is a redirect
   
   put restbase_FetchSlugJSON (pageSlug, restPath, pLang) into someJSON
   put json_ToArray (someJSON) into someArray
   return someArray
end restbase_FetchSlugArray

function restbase_FetchSlugJSON @pageSlug, restPath, pLang, pRestbaseEndpoint   
   put restbase_ConstructSlugRestURL (pageSlug, restPath, pLang, pRestbaseEndpoint) into restURL
   put mediawiki_FetchJSON (restURL) into someJSON
   
   -- manual handling of redirects
   if the environment = "server" then return someJSON -- need to use libUrlLastRHHeaders() on the server
   put libUrlLastRHHeaders() into receivedHeaders
   if word 2 of receivedHeaders is among the items of "301,302" then
      -- "HTTP/1.1 301 Moved Permanently"
      put http_ConstructheaderArray (receivedHeaders) into headerArray
      put headerArray ["location"] into newTitle -- location: Ant
      if newTitle is empty then return empty
      put newTitle into pageSlug
      put restbase_FetchSlugJSON (pageSlug, restPath, pLang) into someJSON
   end if
   --
   return someJSON
end restbase_FetchSlugJSON


--> RestBase | Fetch Summary Page
-
function restbase_FetchWikipediaSectionPageArray pageSlug, sectionNum, someLang
   -- Retrieve the latest HTML for a page title optimised for viewing with native mobile applications. 
   -- Note that the output is split by sections.
   -- also uses wikicommons_ConstructTwoImagePageArray
   
   put restbase_FetchMobileSectionArray (pageSlug, someLang) into sectionPageArray
   
   put sectionPageArray ["lead"]["description"] into pageDescription
   put sectionPageArray ["lead"]["displayTitle"] into pageTitle
   put sectionPageArray ["lead"]["image"] into imageArray
   put imageArray ["file"] into shortImageFile
   put "https:" & imageArray ["640"] into imageURL
   put sectionPageArray ["lead"]["sections"]["1"]["text"] into htmlPageDescription
   
   put sectionPageArray ["remaining"]["sections"] into sectionArray
   put sectionArray [sectionNum]["line"] into sectionTitle
   put sectionArray [sectionNum]["tocLevel"] into tocLevel
   put sectionArray [sectionNum]["text"] into sectionHTML
   
   put empty into wikipediaUrl
   put wikicommons_ConstructTwoImagePageArray (pageTitle, pageDescription, shortImageFile, wikipediaUrl) into fedwikiPageArray
   
   return fedwikiPageArray
end restbase_FetchWikipediaSectionPageArray


--> Restbase | REST
-
function restbase_FetchPageMetadata @pageSlug, pLang
   -- https://en.wikipedia.org/api/rest_v1/page/metadata/Ant?redirect=true
   
   put restbase_FetchSlugArray (pageSlug, "page/metadata/", pLang) into mobileSectionArray
   return mobileSectionArray
end restbase_FetchPageMetadata

function restbase_FetchMobileSectionArray pageSlug, pLang
   -- Retrieve the latest HTML for a page title optimised for viewing with native mobile applications. 
   -- Note that the output is split by sections.
   
   put restbase_FetchMobileSectionJSON (pageSlug, pLang) into someJSON
   put json_ToArray (someJSON) into mobileSectionArray
   return mobileSectionArray
end restbase_FetchMobileSectionArray

function restbase_FetchMobileSectionJSON pageSlug, pLang
   -- https://en.wikipedia.org/api/rest_v1/page/mobile-sections/Ant
   -- Retrieve the latest HTML for a page title optimised for viewing with native mobile applications. Note that the output is split by sections.
   
   put restbase_FetchSlugJSON (pageSlug, "page/mobile-sections/", pLang) into someJSON
   return someJSON
end restbase_FetchMobileSectionJSON

function restbase_FetchMobileLeadArray pageSlug
   put restbase_FetchMobileLeadJSON (pageSlug) into someJSON
   put json_ToArray (someJSON) into mobileSectionArray
   return mobileSectionArray
end restbase_FetchMobileLeadArray

function restbase_FetchMobileLeadJSON pageSlug, pLang
   -- https://en.wikipedia.org/api/rest_v1/page/mobile-sections-lead/Ant
   -- Retrieve the lead section of the latest HTML for a page title optimised for viewing with native mobile applications.
   
   put restbase_FetchSlugJSON (pageSlug, "page/mobile-sections-lead/", pLang) into someJSON
   return someJSON
end restbase_FetchMobileLeadJSON

function restbase_FetchSummaryArray @pageSlug, pLang
   put restbase_FetchSummaryJSON (pageSlug, pLang) into someJSON
   put json_ToArray (someJSON) into mobileSectionArray
   return mobileSectionArray
end restbase_FetchSummaryArray

function restbase_FetchSummaryJSON @pageSlug, pLang
   -- The summary response includes a text extract of the first several sentences, as well as information about a thumbnail that represents the page.
   -- https://en.wikipedia.org/api/rest_v1/page/summary/ANT?redirect=false
   
   put restbase_FetchSlugJSON (pageSlug, "page/summary/", pLang) into someJSON
   return someJSON
end restbase_FetchSummaryJSON


--> Restbase | Construct
-
function restbase_ConstructSlugRestURL pageSlug, restPath, pLang, pRestbaseEndpoint
   if pLang is empty then put "en" into pLang
   if pRestbaseEndpoint is empty then put ".wikipedia.org/api/rest_v1/" into pRestbaseEndpoint
   --
   put restPath & pageSlug into apiPath
   put "https://" & pLang & pRestbaseEndpoint into restURL
   put apiPath after restURL
   put "?redirect=true" after restURL -- don't get 302 redirect page
   return restURL
end restbase_ConstructSlugRestURL


--> Deps
-
function http_ConstructHeaderArray receivedHeaders
   delete line 1 of receivedHeaders
   set the itemdelimiter to ":"
   repeat for each line headerLine in receivedHeaders
      put word 1 to -1 of item 1 of headerLine into someKey
      put word 1 to -1 of item 2 to -1 of headerLine into headerArray [someKey]
   end repeat
   return headerArray
end http_ConstructHeaderArray

function http_GetReceivedHeaderArray
   -- does not work with server
   -- does not work with repeated values like 2 or more "cookie:"
   put libUrlLastRHHeaders() into receivedHeaders
   
   put word -2 of line 1 of receivedHeaders into statusNum
   switch statusNum
      case 503
         put "Error, service unavailable" into someError
         return someError
      case 200
         put http_ConstructheaderArray (receivedHeaders) into headerArray
         return headerArray
      default
         return "Error," && word 2 to -1 of statusLine
   end switch
end http_GetReceivedHeaderArray
