script "lib_WikiPageArray"
--> MetaData
-
license: GPLv3
name: lib_WikiPageArray
type: library
version: 0.1
also: model_PageArray

/*
In this library we look to collect the key handlers we use to create wiki-page arrays from wikipedia url's

# Refactoring
This is part of the refactoring process for the various messy wikipedia and mediawiki libraries that have evolved over a long period of time.
We take key handlers from mediawiki.lc and bring dependencies here. We choose the ones that are specific to the task,
keeping more general, abstracted handlers in their own libraries.
*/


--> Working on
-
function restbase_FetchSummaryPageArray pageSlug, pLang
   -- Can't find anything that uses this - test and see what it does?
   
   /*   
   -- consider using "put mediawiki_FetchWikiText("Ant")"
   -- also uses old "mediawiki_FetchSummaryDescription" to fetch multiple first lines
   -- as restbase won't do that except in html
   -- would be great to enable links in first paragraphs like "wikicommons_ConstructSectionPageArray" does
   -- using sectionnum = 0 does not work with "wikicommons_ConstructSectionPageArray"
   */
   
   put mediawiki_FetchSummaryDescription (pageSlug, true, true, pLang) into firstSection -- uses old stuff anyway to get more than one line
   put restbase_FetchSummaryArray (pageSlug, pLang) into summaryArray -- fetch some metadata
   put restbase_FetchMobileSectionArray (pageSlug) into mobileSectionArray
   --
   put mediawiki_ConstructSummaryPageArray (firstSection, summaryArray, mobileSectionArray) into pageArray
   return pageArray
end restbase_FetchSummaryPageArray


--> Mediawiki | Fetch
-
function mediawiki_FetchPageArray pageSlug, pFirstSectionOnly, pApiStem, pLang
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
   
   put pFirstSectionOnly is not false into pFirstSectionOnly
   
   -- fetch some metadata
   put restbase_FetchSummaryArray (pageSlug, pLang) into summaryArray -- pageSlug updated if redirect
   if summaryArray is not an array then
      -- don't think this happens. Not found???
      put _MediawikiTryAgain (pageSlug, pFirstSectionOnly, empty, pLang, pApiStem) into notFoundPageArray
      return notFoundPageArray
   end if
   
   put summaryArray ["content_urls"]["desktop"]["page"] into wikipediaURL
   put summaryArray ["title"] into pageTitle
   if pageTitle = "Not Found." then
      put _MediawikiTryAgain (pageSlug, pFirstSectionOnly, wikipediaURL, pLang, pApiStem) into notFoundPageArray
      return notFoundPageArray
   end if
   
   -- now fetch
   put mediawiki_FetchWikiText (pageSlug, pApiStem) into wikiText -- need all of the text
   put restbase_FetchMobileSectionArray (pageSlug) into mobileSectionArray -- used for TOC
   
   -- and construct
   put mediawiki_ConstructPageArray (pageTitle, pageSlug, wikiText, summaryArray, mobileSectionArray, pFirstSectionOnly, pWikipediaURL) into fedwikiPageArray
   return fedwikiPageArray
end mediawiki_FetchPageArray

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

function mediawiki_FetchDialoguePageArray pageSlug
   put pageSlug into curlyData ["all"]["New Page Title"]
   put pageArray_Fetch ("future.fedwiki.org", "future-dialogue-template") into pageArray
   pageArray_MergeCurly pageArray, curlyData
   return pageArray
end mediawiki_FetchDialoguePageArray


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


--> PageArray | Construct | Mediawiki
-
function mediawiki_ConstructPageArray pageTitle, pageSlug, wikiText, summaryArray, mobileSectionArray, pFirstSectionOnly, pWikipediaURL
   -- used by mediawiki_FetchPageArray
   -- does not call "_MediawikiTryAgain()" so can avoid recursion
   
   -- Start constructing fedwikiPageArray
   put pageTitle into fedwikiPageArray ["title"]
   put empty into pSourceArray -- could credit wikipedia
   put fedwiki_ConstructJournalArray (pageTitle, pSourceArray) into fedwikiPageArray ["journal"]
   
   -- process wikiText and add
   wikicommons_AddSectionToPageArray fedwikiPageArray, wikiText, pFirstSectionOnly
   put the result into addedImages
   
   -- add original image (if not there)
   _AddPosterImage fedwikiPageArray, summaryArray, addedImages -- maybe already added with wiktext
   put the result into posterImageFile
   
   -- add some utility tools
   -- fedwiki_AddTools fedwikiPageArray, pageTitle
   
   -- add "# Sections"
   put _ConstructSubSectionResultArray (mobileSectionArray) into resultArray
   _AddTOC fedwikiPageArray, resultArray 
   
   -- add see also
   _AddSeeAlsoSection fedwikiPageArray, mobileSectionArray, resultArray
   
   -- move image to item 2
   fedwiki_MakeTextParagraphFirst fedwikiPageArray -- in case image is first
   wikicommons_Moveimage fedwikiPageArray, 2
   
   -- add link back to wikipedia
   fedwiki_AddExternalLinkToFirstSection fedwikiPageArray, pWikipediaURL
   
   -- strip journal
   fedwiki_StripJournal fedwikiPageArray
   return fedwikiPageArray
end mediawiki_ConstructPageArray

function mediawiki_ConstructSummaryPageArray firstSection, summaryArray, mobileSectionArray
   -- used by "restbase_FetchSummaryPageArray"
   
   put summaryArray ["title"] into pageTitle
   put line 1 of firstSection into firstLine
   delete line 1 of firstSection
   
   -- create array and add page description
   put summaryArray ["content_urls"]["desktop"]["page"] into wikipediaURL
   fedwiki_AddExternalLink firstLine, wikipediaURL, "wikipedia"
   put fedwiki_ConstructNewPageArray (pageTitle, firstLine) into fedwikiPageArray
   
   _AddPosterImage fedwikiPageArray, summaryArray
   
   -- add rest of first section
   repeat for each line nextLine in firstSection
      fedwiki_AddParagraphToPageArray fedwikiPageArray, nextLine
   end repeat
   
   -- now add maps, toc, see also etc
   _AddMapSection fedwikiPageArray, summaryArray
   put _ConstructSubSectionResultArray (mobileSectionArray) into resultArray
   _AddTOC fedwikiPageArray, resultArray
   
   _AddSeeAlsoSection fedwikiPageArray, mobileSectionArray, resultArray
   
   -- ensure image is second item
   wikicommons_Moveimage fedwikiPageArray, 2
   
   -- strip journal
   fedwiki_StripJournal fedwikiPageArray
   return fedwikiPageArray
end mediawiki_ConstructSummaryPageArray


--> Private | Wikicommons | Page Array
-
private command _AddPosterImage @pageArray, summaryArray, pAddedImages
   -- maybe already added with wiktext (so we check shortFile is not in pAddedImages)
   
   put summaryArray ["title"] into pageTitle
   put summaryArray ["description"] into shortDescription
   
   put summaryArray ["originalimage"]["source"] into imageURL
   put summaryArray ["thumbnail"]["source"] into thumbnailURL
   
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
         put pageTitle & "." && shortDescription into imageCaption -- could get it from somewhere (it's not in mobileSectionArray)
         put fedwiki_ConstructImageHtml (thumbnailURL, imageCaption, imageURL, false) into imageHTML
         fedwiki_AddHtmlToPageArray pageArray, imageHTML
         put the result into lastitemNum
   end switch
   return shortImageFile
end _AddPosterImage

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
      put restbase_FetchMobileSectionArray (pageSlug) into mobileSectionArray
      --
      put mediawiki_ConstructPageArray (pageTitle, pageSlug, wikiText, summaryArray, mobileSectionArray, pFirstSectionOnly, pWikipediaURL) into fedwikiPageArray
   end if
   return fedwikiPageArray
end _MediawikiTryAgain


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
