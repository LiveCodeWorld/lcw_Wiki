script "lib_WikiPageArray"
--> MetaData
-
license: GPLv3
name: lib_WikiPageArray
type: library
version: 0.3
also: model_PageArray

/*
In this library we look to collect the key handlers we use to create wiki-page arrays from wikipedia url's

# Refactoring
This is part of the refactoring process for the various messy wikipedia and mediawiki libraries that have evolved over a long period of time.
We take key handlers from mediawiki.lc and bring dependencies here. We choose the ones that are specific to the task,
keeping more general, abstracted handlers in their own libraries.

See also "fedwiki_FetchWikipediaSummaryPageArray of "lib_FedWikiPedia"
There may be map and other stuff in that code that is not here?
*/


--> Working on
-
private command _AddPosterImage @pageArray, summaryArray, pAddedImages
   -- maybe already added with wiki-text (so we check shortFile is not in pAddedImages)
   
   put summaryArray ["title"] into pageTitle
   put summaryArray ["description"] into shortDescription
   
   put summaryArray ["originalimage"]["source"] into imageURL
   put summaryArray ["originalimage"]["height"] into imageHeight
   put summaryArray ["originalimage"]["width"] into imageWidth
   
   put summaryArray ["thumbnail"]["source"] into thumbURL
   put summaryArray ["thumbnail"]["height"] into thumbHeight
   put summaryArray ["thumbnail"]["width"] into thumbWidth
   
   set the itemdelimiter to slash
   put urldecode (item -1 of imageURL) into shortImageFile
   set the itemdelimiter to "."
   set the wholematches to true
   switch
      case shortImageFile is among the lines of pAddedImages
      case imageURL is empty
         return empty
      case item -1 of imageURL is among the items of "webm.ogv"
         wikicommons_AddVideoToPageArray pageArray, shortImageFile
         break
      default
         put pageTitle & "." && shortDescription into imageCaption
         pageArray_AddImage pageArray, thumbURL, imageCaption, imageURL, pLat, pLong
   end switch
   return shortImageFile
end _AddPosterImage

private function _MediawikiTryAgain pageSlug, pFirstSectionOnly, pWikipediaURL, pLang, pApiStem
   -- called by "mediawiki_FetchPageArray"
   mediawiki_NormaliseTitle pageSlug, pageTitle, pageID, pLang
   --
   if pageTitle is empty then
      put mediawiki_FetchDialoguePageArray (pageSlug) into fedwikiPageArray
   else
      if pWikipediaURL is empty then
         -- should figure it out for new found pageTitle
      end if
      put mediawiki_FetchWikiText (pageSlug, pApiStem) into wikiText -- need all of the text
      -- put restbase_FetchMobileSectionArray (pageSlug) into mobileSectionArray
      --
      put mediawiki_ConstructPageArray (pageTitle, pageSlug, wikiText, summaryArray, mobileSectionArray, pFirstSectionOnly, pWikipediaURL) into fedwikiPageArray
   end if
   return fedwikiPageArray
end _MediawikiTryAgain

private command _AddMapSection @pageArray, summaryArray, pTileType
   -- add map section
   
   put summaryArray ["title"] into pageTitle
   put summaryArray ["description"] into shortDescription
   
   put summaryArray ["coordinates"]["lat"] into mapLat
   put summaryArray ["coordinates"]["lon"] into mapLong
   put 15 into mapZoom
   
   if mapLat is not empty then
      put "[[" & pageTitle & "]]." && shortDescription into pinTitle
      put fedwiki_ConstructOpenStreetMapLink (mapLat, mapLong, mapZoom, pinTitle) into mapText
      --
      pageArray_AddMap pageArray, mapText, mapLat, mapLong, mapZoom, pinTitle
   end if
end _AddMapSection


--> Mediawiki | Titles
-
command mediawiki_NormaliseTitle searchTitleString, @pageTitle, @pageID, pLang
   -- searches everything, not just title and finds best match
   put mediawiki_FindPageID (searchTitleString, true, pLang) into pageID
   
   -- /w/api.php?action=query&format=json&pageids=51071416&redirects=1&converttitles=1
   put wikipedia_GetApiRoot (pLang) & "/w/api.php" into apiRoot
   --
   put "?action=query&format=json" into apiPath
   put "&pageids=" & pageID after apiPath
   put "&redirects=1&converttitles=1" after apiPath
   put apiRoot & apiPath into restURL
   --
   put mediawiki_FetchJSON (restURL) into someJSON
   put json_ToArray (someJSON) into batchResultArray
   --
   put batchResultArray ["query"] into queryArray
   put queryArray ["pages"] into pagesArray
   put keys(pagesArray) into newPageIDs -- should only be one
   put line 1 of newPageIDs into newPageID
   put pagesArray [newPageID]["title"] into pageTitle
   --
   put textDecode (pageTitle, "utf-8") into pageTitle
   
   put queryArray ["redirects"][1]["to"] into rTitle -- = pageTitle
   put queryArray ["redirects"][1]["from"] into oTitle
   put queryArray ["redirects"][1]["tofragment"] into toFragment
   --   
   return batchResultArray
end mediawiki_NormaliseTitle

function mediawiki_FindPageID titleString, pNearMatch, pLang
   put mediawiki_FetchSearchJson (titleString, pNearMatch, pLang) into someJSON
   put json_ToArray (someJSON) into queryResultArray
   
   put queryResultArray ["query"]["search"] into searchResultArray
   repeat with indexNum = 1 to item 2 of the extents of searchResultArray
      put searchResultArray [indexNum]["pageid"] into pageID
      put pageID & CR after pageIDs
   end repeat
   delete char -1 of pageIDs
   return pageIDs
end mediawiki_FindPageID

function mediawiki_FetchSearchJson titleString, pNearMatch, pLang
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
end mediawiki_FetchSearchJson


--> Mediawiki
-
function mediawiki_FetchDialoguePageArray pageSlug
   put pageSlug into curlyData ["all"]["New Page Title"]
   put pageArray_Fetch ("future.fedwiki.org", "future-dialogue-template") into pageArray
   curly_MergePageArray pageArray, curlyData
   return pageArray
end mediawiki_FetchDialoguePageArray

command mediawiki_DeconstructURL mediawikiURL, @pageSlug, @apiStem, @wikiLanguage
   if mediawikiURL is empty then return false
   put empty into wikiLanguage
   switch
      case matchText (mediawikiURL, "http://wiki.p2pfoundation.net/(.+)", pageSlug)
         put "http://wiki.p2pfoundation.net/api.php?" into apiStem
         break  
      case matchText (mediawikiURL, "https://www.explainxkcd.com/wiki/index.php/(.+)", pageSlug)
         put "https://www.explainxkcd.com/wiki/api.php?" into apiStem
         break
      case matchText (mediawikiURL, "https://rationalwiki.org/wiki/(.+)", pageSlug)
         put "https://rationalwiki.org/w/api.php?" into apiStem
         break
      case matchText (mediawikiURL, "https://(.+).bitcoin.it/wiki/(.+)", wikiLanguage, pageSlug)
         put "https://en.bitcoin.it/w/api.php?" into apiStem
         break
      case matchText (mediawikiURL, "https://sterbalssundrystudies.miraheze.org/wiki/(.+)", pageSlug)
         put "https://sterbalssundrystudies.miraheze.org/w/api.php?" into apiStem
         break
      case matchText (mediawikiURL, "https://(.+).wikipedia.org/wiki/(.+)", wikiLanguage, pageSlug)
         -- bug: think "wikipedia_ConstructApiStem" should return "https://en.wikipedia.org/w/api.php?" ???
         put wikipedia_ConstructApiStem() into apiStem -- -- https://en.wikipedia.org/w/api.php
         break
      default
         -- "Not a Wikipedia page!"
         put "en" into wikiLanguage
         put wikipedia_ConstructApiStem() into apiStem -- -- https://en.wikipedia.org/w/api.php
         return false
   end switch
   return true
end mediawiki_DeconstructURL


--> Mediawiki | Fetch
-
function mediawiki_FetchPageArray wikipediaURL, pFirstSectionOnly
   /*
   -- was "wikicommons_ConstructPageArray"
   -- uses "wikicommons_AddSectionToPageArray" and "mediawiki_FetchWikiText" to fetch multiple first lines from wiki
   
   This is slow and akward but attempts to be thorough.
   The handler processes the full wiki text of a page (truncating it to the first section before doing complicated stuff)
   It fetches metadata using modern rest api, and then uses older rest api to fetch the wiki text and info about any images it finds.
   
   It also adds the page image, even if it finds it in the text.
   Would need to use a different section api call to find if ther are images in the first section and not to add it if it is inserted manaully.
   For now you must delete the image manually.
   */
   
   mediawiki_DeconstructURL wikipediaURL, pageSlug, apiStem, wikiLang
   put mediawiki_GetPageArrayFromSlug (pageSlug, wikiLang, apiStem, pFirstSectionOnly) into fedwikiPageArray
   --
   return fedwikiPageArray
end mediawiki_FetchPageArray

function mediawiki_GetPageArrayFromSlug pageSlug, wikiLang, pApiStem, pFirstSectionOnly
   -- fetch some metadata
   put pFirstSectionOnly is not false into pFirstSectionOnly
   if pApiStem is empty then put wikipedia_ConstructApiStem() into pApiStem
   --
   put restbase_FetchSummaryArray (pageSlug, wikiLang) into summaryArray -- pageSlug updated if redirect
   if summaryArray is not an array then
      -- don't think this happens. Not found???
      put _MediawikiTryAgain (pageSlug, pFirstSectionOnly, empty, wikiLang, pApiStem) into notFoundPageArray
      return notFoundPageArray
   end if
   
   put summaryArray ["content_urls"]["desktop"]["page"] into wikipediaURL
   put summaryArray ["title"] into pageTitle
   if pageTitle = "Not Found." then
      put _MediawikiTryAgain (pageSlug, pFirstSectionOnly, wikipediaURL, wikiLang, pApiStem) into notFoundPageArray
      return notFoundPageArray
   end if
   
   -- now fetch
   put mediawiki_FetchWikiText (pageSlug, pApiStem) into wikiText -- need all of the text   
   -- put restbase_FetchMobileSectionArray (pageSlug) into mobileSectionArray -- used for TOC
   
   -- and construct
   put mediawiki_ConstructPageArray (pageTitle, pageSlug, wikiText, summaryArray, mobileSectionArray, pFirstSectionOnly, wikipediaURL) into fedwikiPageArray
   return fedwikiPageArray
end mediawiki_GetPageArrayFromSlug

function mediawiki_FetchPageArrayWithParse wikiSlug, pSectionNum, pApiRoot, pWikiUrl
   put mediawiki_FetchParseArray (wikiSlug, pSectionNum, pApiRoot) into parseArray
   _DeconstructParseArray parseArray, pageTitle, pageDescription, sectionArray, imageArray
   --
   put empty into pSourceArray
   put wikicommons_ConstructBasicSummaryPageArray (pageTitle, pageDescription, pWikiUrl, pSourceArray) into fedwikiPageArray
   put mediawiki_ExtractFirstInterestingImage (imageArray) into shortImageFile
   if shortImageFile is not empty then
      -- put wikicommons_FetchImageSandboxArray (shortImageFile, pApiRoot) into imageSandboxArray
      wikicommons_FetchAndAddTwoImages fedwikiPageArray, shortImageFile, pApiRoot
   end if
   --
   delete line 1 of pageDescription -- was added already with "wikicommons_ConstructBasicSummaryPageArray"
   wikicommons_AddSectionToPageArray fedwikiPageArray, pageDescription
   --
   return fedwikiPageArray
end mediawiki_FetchPageArrayWithParse

function mediawiki_FetchParseArray wikiSlug, pSectionNum, pApiRoot
   -- used by "mediawiki_FetchPageArrayWithParse" and "xkcd_FetchPageArray"
   put sandbox_AddSectionFragment (wikiSlug, pSectionNum, "action=parse&format=json&page=") into sandBoxFragment
   put sandbox_FetchArray (sandBoxFragment, pApiRoot) into sandboxArray
   put sandboxArray ["parse"] into parseArray
   return parseArray
end mediawiki_FetchParseArray


--> PageArray | Construct | Mediawiki
-
function mediawiki_ConstructPageArray pageTitle, pageSlug, wikiText, summaryArray, mobileSectionArray, pFirstSectionOnly, pWikipediaURL
   -- used by mediawiki_FetchPageArray
   -- does not call "_MediawikiTryAgain()" so can avoid recursion
   
   # Start constructing fedwikiPageArray
   put pageTitle into fedwikiPageArray ["title"]
   put empty into pSourceArray -- could credit wikipedia
   put journalArray_Construct (pageTitle, pSourceArray) into fedwikiPageArray ["journal"]
   
   # Process wikiText and add
   wikicommons_AddSectionToPageArray fedwikiPageArray, wikiText, pFirstSectionOnly
   put the result into addedImages
   
   # Add original image (if not there)
   _AddPosterImage fedwikiPageArray, summaryArray, addedImages -- maybe already added with wiktext
   put the result into posterImageFile
   
   -- add some utility tools
   -- fedwiki_AddTools fedwikiPageArray, pageTitle
   
   /* -- old mobileSectionArray dependent stuff
   # Add "# Sections"
   put _ConstructSubSectionResultArray (mobileSectionArray) into resultArray
   _AddTOC fedwikiPageArray, resultArray 
   
   # Add see also
   _AddSeeAlsoSection fedwikiPageArray, mobileSectionArray, resultArray
   */
   
   # Move image to item 2
   fedwiki_MakeTextParagraphFirst fedwikiPageArray -- in case image is first
   wikicommons_Moveimage fedwikiPageArray, 2
   
   # Add link back to wikipedia
   fedwiki_AddExternalLinkToFirstSection fedwikiPageArray, pWikipediaURL
   
   -- add map if it exists
   _AddMapSection fedwikiPageArray, summaryArray
   
   -- strip journal
   pageArray_StripJournal fedwikiPageArray
   return fedwikiPageArray
end mediawiki_ConstructPageArray

function mediawiki_ConstructSummaryPageArray firstSection, summaryArray, mobileSectionArray
   -- used by "mw_SummaryPageArray"
   
   put summaryArray ["title"] into pageTitle
   put line 1 of firstSection into firstLine
   delete line 1 of firstSection
   
   -- create array and add page description
   put summaryArray ["content_urls"]["desktop"]["page"] into wikipediaURL
   fedwiki_AddExternalLink firstLine, wikipediaURL, "wikipedia"
   put pageArray_Construct (pageTitle, firstLine) into fedwikiPageArray
   
   _AddPosterImage fedwikiPageArray, summaryArray
   
   # Add rest of first section
   repeat for each line nextLine in firstSection
      pageArray_AddText fedwikiPageArray, nextLine
   end repeat
   
   # Add maps
   _AddMapSection fedwikiPageArray, summaryArray
   
   # Add TOC
   -- put _ConstructSubSectionResultArray (mobileSectionArray) into resultArray
   -- _AddTOC fedwikiPageArray, resultArray
   
   # Add See also
   -- _AddSeeAlsoSection fedwikiPageArray, mobileSectionArray, resultArray
   
   -- ensure image is second item
   wikicommons_Moveimage fedwikiPageArray, 2
   
   -- strip journal
   pageArray_StripJournal fedwikiPageArray
   return fedwikiPageArray
end mediawiki_ConstructSummaryPageArray


--> Private | Wikicommons | Page Array
-
private command _DeconstructParseArray parseArray, @pageTitle, @pageDescription, @sectionArray, @imageArray
   put parseArray ["title"] into pageTitle
   put parseArray ["sections"] into sectionArray
   put parseArray ["images"] into imageArray
   put parseArray ["wikitext"]["*"] into pageDescription
   mediawiki_CleanPageDescription pageDescription, infoBoxArray
   return infoBoxArray
end _DeconstructParseArray

private command _AddTOC @fedwikiPageArray, resultArray
   put resultArray ["orderFormArray"] into orderFormArray
   
   if orderFormArray is not empty then
      pageArray_AddMarkdown fedwikiPageArray, "# Sections"
      --
      put item 2 of the extents of orderFormArray into maxNum
      repeat with subSectionIndexNum = 1 to maxNum
         put orderFormArray [subSectionIndexNum] into formHTML
         pageArray_AddHtml fedwikiPageArray, formHTML
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
      pageArray_AddMarkdown pageArray, "# See also"
      pageArray_AddMarkdown pageArray, seeAlsoMarkdown
   end if
end _AddSeeAlsoSection

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
private function html_ExtractLinkNumArray htmlLines
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
