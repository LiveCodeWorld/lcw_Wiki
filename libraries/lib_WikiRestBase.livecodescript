script "lib_WikiRestBase"
--> MetaData
-
license: GPLv3
name: lib_WikiRestBase
type: library
version: 0.5
deps: lib_MediaWiki, lib_Fedwiki, lib_FedwikiPedia


/*
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
function wikipedia_GetApiRoot pLang
   -- was "wikipedia_ConstructApiStem"
   -- https://de.wikipedia.org/wiki/Jo_Fabian
   if pLang is empty then put "en" into pLang
   put "https://" & pLang & ".wikipedia.org" into apiRoot
   return apiRoot
end wikipedia_GetApiRoot

command wikipedia_NormaliseTitle searchTitleString, @pageTitle, @pageID, pLang
   -- searches everything, not just title and finds best match
   put wikipedia_FindPageID (searchTitleString, true, pLang) into pageID
   
   -- /w/api.php?action=query&format=json&pageids=51071416&redirects=1&converttitles=1
   put "?action=query&format=json" into apiPath
   put "&pageids=" & pageID after apiPath
   put "&redirects=1&converttitles=1" after apiPath
   
   -- put "&prop=redirects" after apiPath
   -- put "&indexpageids=1" after apiPath
   
   put wikipedia_GetApiRoot (pLang) & "/w/api.php" into apiRoot
   put apiRoot & apiPath into restURL
   put mediawiki_FetchJSON (restURL) into someJSON
   
   put json_ToArray (someJSON) into batchResultArray
   --
   -- display_Array batchResultArray, searchTitleString
   --
   put batchResultArray ["query"] into queryArray
   put queryArray ["pages"] into pagesArray
   put keys(pagesArray) into newPageIDs -- should only be one
   put line 1 of newPageIDs into newPageID
   put pagesArray [newPageID]["title"] into pageTitle
   --
   put queryArray ["redirects"][1]["to"] into rTitle -- = pageTitle
   put queryArray ["redirects"][1]["from"] into oTitle
   put queryArray ["redirects"][1]["tofragment"] into toFragment
   --
   return batchResultArray
end wikipedia_NormaliseTitle


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


--> Wikipedia
-
function wikipedia_FindPage searchTitleString, pLang
   wikipedia_NormaliseTitle searchTitleString, pageTitle, pageID, pLang
   if pageTitle is empty then
      -- let's try adding some brackets to the slug
      put searchTitleString into pageSlug
      replace "-" with space in pageSlug
      put "(" & word -1 of pageSlug & ")" into word -1 of pageSlug -- quick hack
      wikipedia_NormaliseTitle pageSlug, pageTitle, pageID, pLang
      
      if pageTitle is empty then
         put searchTitleString into pageSlug
         replace "-" with space in pageSlug
         put "(" & word -2 to -1 of pageSlug & ")" into word -2 to -1 of pageSlug -- quick hack
         wikipedia_NormaliseTitle pageSlug, pageTitle, pageID, pLang
      end if
   end if
   return pageTitle
end wikipedia_FindPage

function wikicommons_ConstructPageArray pageSlug, pFirstSectionOnly, pApiStem, pLang
   /*
   -- uses "wikicommons_AddSectionToPageArray" and "mediawiki_FetchWikiText" to fetch multiple first lines from wiki
   
   This is slow and akward but attempts to be thorough.
   The handler processes the full wiki text of a page (truncating it to the first section before doing complicated stuff)
   It fetches metadata using modern rest api, and then uses older rest api to fetch the wiki text and info about any images it finds.
   
   It also adds the page image, even if it finds it in the text.
   Would need to use a different section api call to find if ther are images in the first section and not to add it if it is inserted manaully.
   For now you must delete the image manually.
   */
   
   put pFirstSectionOnly is not false into pFirstSectionOnly
   
   -- fetch some metadata
   put restbase_FetchSummaryArray (pageSlug, pLang) into summaryArray -- pageSlug updated if redirect
   if summaryArray is not an array then
      return empty -- not found???
   else
      put summaryArray ["content_urls"]["desktop"]["page"] into wikipediaURL
      put summaryArray ["title"] into pageTitle
   end if
   
   
   -- check if it is not found
   if pageTitle = "Not Found." then
      -- see wikipedia_FindPage()
      put "(" & word -1 of pageSlug & ")" into word -1 of pageSlug -- quick hack
      
      put restbase_FetchSummaryArray (pageSlug, pLang) into summaryArray
      put summaryArray ["title"] into pageTitle
      
      if pageTitle = "Not Found." then
         put "Cannot locate the Wikipidia page for" && kwote (pageSlug) into errorText
         put CR & CR & pageSlug after errorText
         put CR & CR & json_FromArray (summaryArray) after errorText
         put fedwiki_ConstructErrorArray (errorText, "Wikipedia page not found") into fedwikiPageArray
         return fedwikiPageArray
      end if
   end if
   
   -- Start constructing fedwikiPageArray
   put pageTitle into fedwikiPageArray ["title"]
   put empty into pSourceArray -- could credit wikipedia
   put fedwiki_ConstructJournalArray (pageTitle, pSourceArray) into fedwikiPageArray ["journal"]
   
   -- add wikiText to page
   put mediawiki_FetchWikiText (pageSlug, pApiStem) into wikiText -- actually all of it :)
   
   -- process wikiText and add
   wikicommons_AddSectionToPageArray fedwikiPageArray, wikiText, pFirstSectionOnly
   put the result into addedImages
   
   -- add original image (if not there)
   _AddOriginalImage fedwikiPageArray, summaryArray, addedImages -- maybe already added with wiktext
   
   -- add some utility tools
   fedwiki_AddTools fedwikiPageArray, pageTitle
   
   -- add "# Sections"
   put restbase_FetchMobileSectionArray (pageSlug) into mobileSectionArray
   put _ConstructSubSectionResultArray (mobileSectionArray) into resultArray
   _AddTOC fedwikiPageArray, resultArray 
   
   -- add see also
   _AddSeeAlsoSection fedwikiPageArray, mobileSectionArray, resultArray
   
   -- move image to item 2
   fedwiki_MakeTextParagraphFirst fedwikiPageArray -- in case image is first
   wikicommons_Moveimage fedwikiPageArray, 2
   
   -- add link back to wikipedia
   fedwiki_AddExternalLinkToFirstSection fedwikiPageArray, wikipediaURL
   
   -- strip journal
   fedwiki_StripJournalToCreate fedwikiPageArray
   return fedwikiPageArray
end wikicommons_ConstructPageArray

function wikipedia_FindPageID titleString, pNearMatch, pLang
   put wikipedia_FetchSearchJson (titleString, pNearMatch, pLang) into someJSON
   put json_ToArray (someJSON) into queryResultArray
   
   put queryResultArray ["query"]["search"] into searchResultArray
   repeat with indexNum = 1 to item 2 of the extents of searchResultArray
      put searchResultArray [indexNum]["pageid"] into pageID
      put pageID & CR after pageIDs
   end repeat
   delete char -1 of pageIDs
   return pageIDs
end wikipedia_FindPageID


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

function wikipedia_FetchSearchJson titleString, pNearMatch, pLang
   -- title search no longer works (using "nearmatch")
   -- /w/api.php?action=query&format=json&list=search&utf8=1&srsearch=Nelson%20Mandela
   -- /w/api.php?action=query&format=json&list=search&redirects=1&converttitles=1&utf8=1&srsearch=British%20Archaeological%20Awards&srlimit=50&srwhat=nearmatch
   
   put urlencode (titleString) into encodedSearchString
   replace "+" with "%20" in encodedSearchString
   
   put "?action=query&format=json&list=search&utf8=1" into apiPath
   if pNearMatch is true then
      put "&srwhat=nearmatch" after apiPath
   end if
   -- put "&prop=info" after apiPath
   put "&redirects=1&converttitles=1" after apiPath
   put "&srlimit=50" after apiPath
   --
   put "&srsearch=" & encodedSearchString after apiPath
   --
   put wikipedia_GetApiRoot(pLang) & "/w/api.php" into apiStem
   put apiStem & apiPath into restURL
   
   put mediawiki_FetchJSON (restURL) into someJSON
   return someJSON
end wikipedia_FetchSearchJson

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


--> RestBase | Fetch Summary Page
-
function restbase_FetchSummaryPageArray pageSlug, pLang
   -- consider using "put mediawiki_FetchWikiText("Ant")"
   
   -- also uses old "mediawiki_FetchSummaryDescription" to fetch multiple first lines
   -- as restbase won't do that except in html
   -- would be great to enable links in first paragraphs like "wikicommons_ConstructSectionPageArray" does
   -- using sectionnum = 0 does not work with "wikicommons_ConstructSectionPageArray"
   
   -- uses old stuff anyway to get more than one line
   put mediawiki_FetchSummaryDescription (pageSlug, true, true, pLang) into firstSection -- to fetch multiple first section lines
   put line 1 of firstSection into firstLine
   -- put summaryArray ["extract"] into firstLine -- only first line
   delete line 1 of firstSection
   
   -- fetch some metadata
   put restbase_FetchSummaryArray (pageSlug, pLang) into summaryArray
   put summaryArray ["title"] into pageTitle
   -- put summaryArray ["description"] into shortDescription
   
   -- create array and add page description
   put summaryArray ["content_urls"]["desktop"]["page"] into wikipediaURL
   fedwiki_AddExternalLink firstLine, wikipediaURL, "wikipedia"
   put fedwiki_ConstructNewPageArray (pageTitle, firstLine) into fedwikiPageArray
   
   _AddOriginalImage fedwikiPageArray, summaryArray
   
   -- add rest of first section
   repeat for each line nextLine in firstSection
      fedwiki_AddParagraphToPageArray fedwikiPageArray, nextLine
   end repeat
   
   -- now add maps, toc, see also etc
   _AddMapSection fedwikiPageArray, summaryArray
   
   put restbase_FetchMobileSectionArray (pageSlug) into mobileSectionArray
   put _ConstructSubSectionResultArray (mobileSectionArray) into resultArray
   _AddTOC fedwikiPageArray, resultArray
   
   _AddSeeAlsoSection fedwikiPageArray, mobileSectionArray, resultArray
   
   -- ensure image is second item
   wikicommons_Moveimage fedwikiPageArray, 2
   
   -- strip journal
   fedwiki_StripJournalToCreate fedwikiPageArray
   return fedwikiPageArray
end restbase_FetchSummaryPageArray

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


--> Private | Wikicommons | Page Array
-
private command _AddOriginalImage @pageArray, summaryArray, pAddedImages
   -- maybe already added with wiktext (so we check shortFile is not in pAddedImages)
   
   put summaryArray ["title"] into pageTitle
   put summaryArray ["description"] into shortDescription
   
   put summaryArray ["originalimage"]["source"] into imageURL
   put summaryArray ["thumbnail"]["source"] into thumbnailURL
   
   set the itemdelimiter to slash
   put item -1 of imageURL into shortImageFile
   switch
      case shortImageFile is among the lines of pAddedImages
         return 0
      case imageURL is not empty
         put pageTitle & "." && shortDescription into imageCaption -- could get it from somewhere (it's not in mobileSectionArray)
         put wikicommons_ConstructImageOrVideoHtml (thumbnailURL, imageCaption, imageURL) into imageHTML
         fedwiki_AddHtmlToPageArray pageArray, imageHTML
         put the result into lastitemNum
         --
         return lastitemNum
      default
         return 0
   end switch
end _AddOriginalImage

private command _AddTOC @fedwikiPageArray, resultArray
   put resultArray ["orderFormArray"] into orderFormArray
   
   if orderFormArray is not empty then
      fedwiki_AddMarkdownToPageArray fedwikiPageArray, "# Sections"
      --
      put item 2 of the extents of orderFormArray into maxNum
      repeat with subSectionIndexNum = 1 to maxNum
         put orderFormArray [subSectionIndexNum] into formHTML
         fedwiki_AddHtmlToPageArray fedwikiPageArray, formHTML
      end repeat
   end if
end _AddTOC

private command _AddSeeAlsoSection @pageArray, mobileSectionArray, resultArray
   -- add "# See also" section
   
   put resultArray ["seeAlsoSectionNum"] into seeAlsoSectionNum
   subtract 1 from seeAlsoSectionNum
   put mobileSectionArray ["remaining"]["sections"][seeAlsoSectionNum]["text"] into seeAlsoHtml
   put _ExtractTocFromHtmlLines (seeAlsoHtml) into seeAlsoMarkdown
   
   if word 1 to -1 of seeAlsoMarkdown is not empty then
      fedwiki_AddMarkdownToPageArray pageArray, "# See also"
      fedwiki_AddMarkdownToPageArray pageArray, seeAlsoMarkdown
   end if
end _AddSeeAlsoSection

private command _AddMapSection @pageArray, summaryArray
   -- add map section
   
   put summaryArray ["title"] into pageTitle
   put summaryArray ["description"] into shortDescription
   
   put summaryArray ["coordinates"]["lat"] into mapLat
   put summaryArray ["coordinates"]["lon"] into mapLong
   put 15 into mapZoom
   
   if mapLat is not empty then
      put "[[" & pageTitle & "]]." && shortDescription into pinTitle
      put fedwiki_ConstructOpenStreetMapLink (mapLat, mapLong, mapZoom, pinTitle) into mapText
      put fedwiki_ConstructStoryMapArray (mapLat, mapLong, mapText, mapZoom, pinTitle) into itemArray
      --
      fedwiki_AddItemArrayToStoryEnd itemArray, pageArray
   end if
end _AddMapSection


--> Private
-
private function _ExtractTocFromHtmlLines seeAlsoHtml
   -- extract <ul> section
   -- put html_ExtractNodeContents ("ul", seeAlsoHtml) into seeAlsoHtmlLines -- empty duce to the contents being tags
   -- put html_ExtractNode ("ul", seeAlsoHtml) into seeAlsoHtmlLines -- should work (but uses XML)
   
   -- not generic 
   -- uses specific for Wikipedia formatting (uses offset not XML)
   put offset ("<ul>", seeAlsoHtml) into startSection
   put offset ("</ul>", seeAlsoHtml, startSection) into extraChars
   put char (startSection + 4) to (startSection + extraChars -1) of seeAlsoHtml into seeAlsoHtmlLines
   
   /*
   repeat for each line htmlLine in seeAlsoHtmlLines
      -- <li><a href="/wiki/World_Economic_Forum" title="World Economic Forum">World Economic Forum</a></li></ul>
      -- html_DeconstructRefLink htmlLine, alsoTitle, alsoLink
      put html_ExtractAttribute ("title", "a", htmlLine) into alsoTitle
      put "- [[" & alsoTitle & "]]" & CR after markdownTOC
   end repeat
   delete char -1 of markdownTOC
   */
   
   put html_ExtractLinkNumArray (seeAlsoHtmlLines) into resultArray
   -- put resultArray ["linkNumArray"] into linkNumArray
   put resultArray ["markdownTOC"] into markdownTOC
   
   return markdownTOC
end _ExtractTocFromHtmlLines

private function _ConstructSubSectionResultArray mobileSectionArray
   -- put restbase_FetchMobileSectionArray (pageSlug) into mobileSectionArray
   
   constant notTheseSections = "Notes,References,Further reading,External links"
   
   put mobileSectionArray ["lead"]["displaytitle"] into displayTitle
   put mobileSectionArray ["lead"]["normalizedtitle"] into pageSlug
   
   put mobileSectionArray ["lead"]["sections"] into sectionArray
   put item 2 of the extents of sectionArray into maxNum
   
   put 1 into subSectionIndexNum
   repeat with indexNum = 2 to maxNum
      put sectionArray [indexNum]["toclevel"] into tocLevel
      put sectionArray [indexNum]["line"] into sectionTitle
      put sectionArray [indexNum]["id"] into sectionNum
      put sectionArray [indexNum]["anchor"] into sectionSlug
      
      switch
         case sectionTitle is among the items of notTheseSections
            next repeat
         case sectionTitle = "See also"
            put indexNum into seeAlsoSectionNum
            put mobileSectionArray ["remaining"]["sections"]["text"] into htmlTOC
            break
         case tocLevel = 1
            put "- [[" & sectionTitle & "]]" & CR after sectionMarkdownTOC
            --
            put wikicommons_ConstructSectionForm (pageSlug, sectionNum, sectionTitle) into formHTML
            put formHTML into orderFormArray [subSectionIndexNum]
            add 1 to subSectionIndexNum
            break
      end switch
   end repeat
   
   put orderFormArray into resultArray ["orderFormArray"]
   put htmlTOC into resultArray ["htmlTOC"]
   put sectionMarkdownTOC into resultArray ["sectionMarkdownTOC"]
   put seeAlsoSectionNum into resultArray ["seeAlsoSectionNum"]
   --
   return resultArray
end _ConstructSubSectionResultArray


--> Deps
-
function http_ConstructheaderArray receivedHeaders
   delete line 1 of receivedHeaders
   set the itemdelimiter to ":"
   repeat for each line headerLine in receivedHeaders
      put word 1 to -1 of item 1 of headerLine into someKey
      put word 1 to -1 of item 2 to -1 of headerLine into headerArray [someKey]
   end repeat
   return headerArray
end http_ConstructheaderArray

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

function html_ExtractLinkNumArray htmlLines
   /*
   Requires each link on a new line
   The regular expressions do not require that - and if you use XML handlers we get one big single line
   So could make more robust by deleting at end of each repeat
   
   <li><a href="/wiki/Victoria_Tower" title="Victoria Tower">Victoria Tower</a></li>
   <li><a href="/wiki/Big_Ben_Aden" title="Big Ben Aden">Big Ben Aden</a></li>
   
   -- U is for non-greedy
   put "(?miU)(<span style='color:).*(</span>)" into someReg
   put "(?Uim)(<\s*" & tagName & someEnding & ")" into openingReg
   */
   
   put "a" into tagName
   --
   put "([^>]*)" into notClosingBracket
   put "([^<]*)" into notOpeningBracket
   put "([^" & quote & "'" & "]*)" into notQuote
   put "(?Uim)" into ungreedyMultiReg
   put "['" & quote & "]" into anyQuote
   put "\s+" into someSpace
   put "<\s*/\s*" & tagName & "\s*>" into closingTagReg
   
   -- put quote into anyQuote
   -- put "\s*" into maybeSpace
   -- put "(" & ">" & "|" & "\s+.*>" & ")" into someEnding
   -- put "(<\s*" & tagName & someEnding & ")" into openingReg
   
   put "<" & tagName & someSpace & notClosingBracket & ">" & notOpeningBracket & closingTagReg into hrefReg
   put "href\s*=\s*" & anyQuote & notQuote & anyQuote into hrefAttributeReg
   --
   put 1 into linkNum
   repeat for each line htmlLine in htmlLines -- can just repeat
      if matchchunk (htmlLine, hrefReg, startAttributeBit, endAttributeBit, startTagContents, endTagContents) is false then exit repeat
      if startTagContents is not a number then exit repeat -- for bug safetey???
      --
      put char startTagContents to endTagContents of htmlLine into taggedText
      put char startAttributeBit to endAttributeBit of htmlLine into attributeBit
      -- href="/wiki/Apella" title="Apella"
      if matchtext (attributeBit, hrefAttributeReg, someLink) is false then exit repeat
      --
      put someLink into linkNumArray [linkNum]["link"]
      put taggedText into linkNumArray [linkNum]["text"]
      
      put "- [[" & taggedText & "]]" & CR after markdownTOC
      
      -- put taggedText into linkArray [taggedText]
      
      -- could delete char 1 to closingTagReg of htmlLines
      add 1 to linkNum
   end repeat
   delete char -1 of markdownTOC
   
   put markdownTOC into resultArray ["markdownTOC"]
   put linkNumArray into resultArray ["linkNumArray"]
   return resultArray
end html_ExtractLinkNumArray
