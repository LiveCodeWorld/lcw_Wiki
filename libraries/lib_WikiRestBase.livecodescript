script "lib_WikiRestBase"
--> MetaData
-
license: GPLv3
name: lib_WikiRestBase
type: library
version: 0.6
deps: lib_MediaWiki, lib_Fedwiki, lib_FedwikiPedia, lib_FedwikiCreate


/*
The main handler for the mediawiki.lc transporter is "mediawiki_FetchPageArray".
It provides CORS headers, and is suitable for use with wiki.
*/


--> Working on
-
function mw_MarkdownTOC wSlug, pAddCors, pSectionNum, pApiStem
   put sandbox_ParseInfoArray (wSlug, pSectionNum, pApiStem, pAddCors) into sArray
   put sandbox_PageTocArray (sArray) into tocArray
   sandbox_TocData tocArray, lookUpArray, markdownTOC
   return markdownTOC
end mw_MarkdownTOC

function mw_WikiBaseNum pageSlug, pLang
   put mw_SummaryArray (pageSlug, pLang) into sArray
   put sArray ["wikibase_item"] into wbNum
   return wbNum
end mw_WikiBaseNum

function mw_SummaryThumb pageSlug, pLang
   put mw_SummaryArray (pageSlug, pLang) into sArray
   put sArray ["thumbnail"]["height"] into thumbHeight
   put sArray ["thumbnail"]["height"] into thumbWidth
   put sArray ["thumbnail"]["source"] into thumbURL
   return thumbURL
end mw_SummaryThumb

function mw_SummaryHtml pageSlug, pLang
   put mw_SummaryArray (pageSlug, pLang) into sArray
   put sArray ["extract_html"] into sHtml
   return sHtml
end mw_SummaryHtml

function mw_SummaryText pageSlug, pLang
   put mw_SummaryArray (pageSlug, pLang) into sArray
   put sArray ["extract"] into sText
   return sText
end mw_SummaryText

function mw_SummaryArray pageSlug, pLang
   put restbase_FetchSummaryJSON (pageSlug, pLang) into sJSON
   put json_ToArray (sJSON) into sArray
   return sArray
end mw_SummaryArray

function mw_PageExtract pageSlug, pFormat, pIntroOnly, pPlain, pAddCors, pLang
   put pAddCors is not false into pAddCors
   put mw_PageData (pageSlug, pFormat, pIntroOnly, pPlain, pAddCors, pLang) into pageData
   put pageData ["extract"] into pageExtract
   return pageExtract
end mw_PageExtract

function mw_PageData pageSlug, pFormat, pIntroOnly, pPlain, pAddCors, pLang
   put pIntroOnly is true into pIntroOnly
   put pPlain is not false into pPlain
   put "wiki" into pFormat -- "plain or html""
   
   put mw_ApiRoot (pLang) into apiRoot
   put sandbox_ConstructPageQueryFragment (pageSlug, pFormat, pIntroOnly, pPlain) into sandBoxFragment
   put sandbox_FetchData (sandBoxFragment, apiRoot, pAddCors) into sandData
   --
   put sandData ["query"]["pages"][1] into pageData
   return pageData
end mw_PageData

function mw_PageExtractUrl pageSlug, pFormat, pIntroOnly, pPlain, pLang
   -- for testing
   put pIntroOnly is true into pIntroOnly
   put pPlain is not false into pPlain
   put "wiki" into pFormat -- "plain or html""
   
   put mw_ApiRoot (pLang) into apiRoot
   put sandbox_ConstructPageQueryFragment (pageSlug, pFormat, pIntroOnly, pPlain) into sandBoxFragment
   put sandbox_ConstructUrl (sandBoxFragment, apiRoot) into restURL
   return restURL
end mw_PageExtractUrl


--> MediaWiki | Rest
-
function mw_ConstructSlug pageTitle
   -- Page title. Use underscores instead of spaces. Use percent-encoding. Example: Main_Page.
   replace space with "_" in pageTitle
   put textEncode (pageTitle, "UTF-8") into utf8Title
   put urlencode (utf8Title) into pageSlug
   return pageSlug
end mw_ConstructSlug

command mw_SetHeaders
   put "accept: application/json; charset=utf-8" into mwHeaders
   put CR & "profile=" & quote & "https://www.mediawiki.org/wiki/Specs/Media/1.3.1" & quote after userHeader
   put CR & "User-Agent: WikiApp/0.1 (http://fedwiki.club; david.bovill@gmail.com) MacOS Livecode/9.03" after userHeader -- mw_SetUserAgent
   set the httpheaders to mwHeaders
end mw_SetHeaders

function mw_FetchJSON restURL, pAddCors
   -- libURLFollowHttpRedirects true -- redirect does not seem to work, and not available on server
   if pAddCors is true then
      put url_AddCorsProxy (restURL) into restURL
   end if
   mw_SetHeaders
   put url restURL into sJSON
   return sJSON
end mw_FetchJSON

command mw_SetUserAgent
   -- https://www.mediawiki.org/wiki/API:Main_page#Identifying_your_client
   put "User-Agent: WikiApp/0.1 (http://fedwiki.club; david.bovill@gmail.com) MacOS Livecode/9.03" into userHeader
   set the httpheaders to userHeader
end mw_SetUserAgent

function mw_ApiStemFromUrl wikipediaURL
   -- was "mw_ApiRoot"
   if wikipediaURL is empty then
      return "https://en.wikipedia.org/w/api.php"
   else
      -- https://de.wikipedia.org/wiki/Jo_Fabian
      set the itemdelimiter to "/"
      put item 1 to 3 of wikipediaURL into apiRoot
      put "/w/api.php" after apiRoot
      return apiRoot
   end if
end mw_ApiStemFromUrl

function mw_ApiRoot pLang
   -- was "mw_ApiStemFromUrl"
   -- https://de.wikipedia.org/wiki/Jo_Fabian
   if pLang is empty then put "en" into pLang
   put "https://" & pLang & ".wikipedia.org" into apiRoot
   return apiRoot
end mw_ApiRoot


--> Restbase | List
-
function restbase_ListImages pageSlug, pLang
   put restbase_FetchImageArray (pageSlug, pLang) into imageArray
   put keys (imageArray) into imageTitles
   return imageTitles
end restbase_ListImages

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

function restbase_FetchImageArray pageSlug, pLang
   put restbase_FetchMediaArray (pageSlug, pLang) into mediaIndexArray
   repeat with itemNum = 1 to item 2 of the extents of mediaIndexArray
      put mediaIndexArray [itemNum]["title"] into shortImageFile
      put mediaIndexArray [itemNum]["srcSet"][1]["src"] into imageURL
      put mediaIndexArray [itemNum]["srcSet"][1]["scale"] into srcScale
      put imageURL into imageArray [shortImageFile]
   end repeat
   return imageArray
end restbase_FetchImageArray


--> Restbase | Fetch
-
function restbase_FetchMediaArray pageTitle, pLang 
   put restbase_FetchData (pageTitle, "page/media-list/", pLang) into rData
   put rData ["items"] into mediaItemArray
   return mediaItemArray
end restbase_FetchMediaArray

function restbase_FetchData pageTitle, restPath, pLang
   put mw_ConstructSlug (pageTitle) into pageSlug
   put restbase_FetchSlugJSON (pageSlug, restPath, pLang) into someJSON
   put json_ToArray (someJSON) into rData
   return rData
end restbase_FetchData

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

function restbase_FetchSummaryJSON pageSlug, pLang
   -- The summary response includes a text extract of the first several sentences, as well as information about a thumbnail that represents the page.
   -- https://en.wikipedia.org/api/rest_v1/page/summary/ANT?redirect=false
   
   put restbase_FetchSlugJSON (pageSlug, "page/summary/", pLang) into someJSON
   return someJSON
end restbase_FetchSummaryJSON


--> Restbase | Rest
-
function restbase_FetchSlugJSON pageSlug, restPath, pLang, pRestbaseEndpoint, pAddCors
   put restbase_ConstructSlugRestURL (pageSlug, restPath, pLang, pRestbaseEndpoint) into restURL
   put mw_FetchJSON (restURL, pAddCors) into someJSON
   
   # manual handling of redirects
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
function url_AddCorsProxy sURL
   return "https://corsproxy.io/?" & sURL
end url_AddCorsProxy

function http_ConstructHeaderArray receivedHeaders
   delete line 1 of receivedHeaders
   set the itemdelimiter to ":"
   repeat for each line headerLine in receivedHeaders
      put word 1 to -1 of item 1 of headerLine into someKey
      put word 1 to -1 of item 2 to -1 of headerLine into headerArray [someKey]
   end repeat
   return headerArray
end http_ConstructHeaderArray

function json_ToArray pJSON
   -- jsonImport version
   if pJSON is empty then return false
   try
      put jsonImport (pJSON) into tArray -- not the same
      return tArray
   catch e
      return empty
   end try
end json_ToArray
