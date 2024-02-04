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
function mediaWiki_ConstructSlug pageTitle
   -- Page title. Use underscores instead of spaces. Use percent-encoding. Example: Main_Page.
   replace space with "_" in pageTitle
   put textEncode (pageTitle, "UTF-8") into utf8Title
   put urlencode (utf8Title) into pageSlug
   return pageSlug
end mediaWiki_ConstructSlug

function restbase_FetchWikipediaSectionPageArray pageSlug, sectionNum, someLang
   -- Retrieve the latest HTML for a page title optimised for viewing with native mobile applications. 
   -- Note that the output is split by sections.
   -- also uses wikicommons_ConstructTwoImagePageArray
   
   -- put restbase_FetchMobileSectionArray (pageSlug, someLang) into sectionPageArray
   
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


--> Restbase | Fetch
-
function restbase_FetchRelated pageTitle, pLang
   put restbase_FetchData (pageTitle, "page/related/", pLang) into rData
   --
   put rData ["pages"] into pageIndexArray
   return pageIndexArray
end restbase_FetchRelated

function restbase_ListImageUrls pageTitle, pLang  
   put restbase_FetchMediaArray (pageTitle, pLang) into mediaIndexArray
   repeat with itemNum = 1 to item 2 of the extents of mediaIndexArray
      -- put mediaIndexArray [itemNum]["title"] into shortImageFile
      -- put mediaIndexArray [itemNum]["srcSet"][1]["scale"] into srcScale
      put mediaIndexArray [itemNum]["srcSet"][1]["src"] into imageURL
      put imageURL & CR after imageURLs
   end repeat
   delete char -1 of imageUrls
   return imageUrls
end restbase_ListImageUrls

function restbase_ListImages pageSlug, pLang
   put restbase_FetchMediaArray (pageSlug, pLang) into mediaIndexArray
   repeat with itemNum = 1 to item 2 of the extents of mediaIndexArray
      put mediaIndexArray [itemNum]["title"] into shortImageFile
      put mediaIndexArray [itemNum]["srcSet"][1]["src"] into imageURL
      put mediaIndexArray [itemNum]["srcSet"][1]["scale"] into srcScale
      put imageURL into imageArray [shortImageFile]
   end repeat
   put keys (imageArray) into imageTitles
   return imageTitles
end restbase_ListImages

function restbase_FetchMediaArray pageTitle, pLang
   -- https://en.wikipedia.org/api/rest_v1/page/media-list/Ant?redirect=false
   put restbase_FetchData (pageTitle, "page/media-list/", pLang) into rData
   put rData ["items"] into mediaItemArray
   return mediaItemArray
end restbase_FetchMediaArray

function restbase_FetchData pageTitle, restPath, pLang
   put mediaWiki_ConstructSlug (pageTitle) into pageSlug
   put restbase_FetchSlugJSON (pageSlug, restPath, pLang) into someJSON
   put json_ToArray (someJSON) into rData
   return rData
end restbase_FetchData


--> Restbase | REST
-
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

function restbase_FetchSummaryArray pageSlug, pLang
   put restbase_FetchSummaryJSON (pageSlug, pLang) into someJSON
   put json_ToArray (someJSON) into mobileSectionArray
   return mobileSectionArray
end restbase_FetchSummaryArray

function restbase_FetchSummaryJSON pageSlug, pLang
   -- The summary response includes a text extract of the first several sentences, as well as information about a thumbnail that represents the page.
   -- https://en.wikipedia.org/api/rest_v1/page/summary/ANT?redirect=false
   
   put restbase_FetchSlugJSON (pageSlug, "page/summary/", pLang) into someJSON
   return someJSON
end restbase_FetchSummaryJSON


--> Restbase | Rest
-
function restbase_FetchSlugJSON pageSlug, restPath, pLang, pRestbaseEndpoint   
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

function restbase_ConstructSlugRestURL pageSlug, restPath, pLang, pRestbaseEndpoint
   if pLang is empty then put "en" into pLang
   if pRestbaseEndpoint is empty then put ".wikipedia.org/api/rest_v1/" into pRestbaseEndpoint
   
   # Construct URL
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
