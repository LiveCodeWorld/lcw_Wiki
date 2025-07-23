script "lib_Xkcd"
--> MetaData
-
license: GPLv3
name: lib_Xkcd
type: library
version: 0.1

/*
This library is all about interfacing with the Explain XKCD comic mediawiki.
- https://www.explainxkcd.com
*/


--> Tests
-
function test_WikipediaAntSummary
   put "ant" into pageSlug
   
   put mw_ApiStemFromUrl() into pApiStem
   
   put false into pIntroOnly
   put true into pPlain
   put "wiki" into pFormat
   
   put sandbox_ConstructPageQueryFragment (pageSlug, pFormat, pIntroOnly, pPlain) into sandBoxFragment   
   put sandbox_ConstructUrl (sandBoxFragment, pApiStem) into restURL
   put mw_FetchJSON (restURL, true) into someJSON
   put json_ToArray (someJSON) into sandboxArray
   
   return sandboxArray
end test_WikipediaAntSummary

function test_WikipediaAntJson
   put test_WikipediaAntUrl() into restURL
   put mw_FetchJSON (restURL, true) into someJSON
   return someJSON
end test_WikipediaAntJson

function test_WikipediaAntUrl
   -- put mediawiki_FetchPageArrayWithParse ("Ant", empty, "https://meta.wikimedia.org/w/api.php?", droppedURL) into pageArray
   put "Ant" into wikiSlug
   put empty into sectionNum
   --
   put sandbox_AddSectionFragment (wikiSlug, sectionNum, "action=parse&format=json&page=") into sandBoxFragment
   put sandbox_ConstructUrl (sandBoxFragment) into restURL
   return restURL
end test_WikipediaAntUrl


--> XKCD
-
function xkcd_FetchPageArray xkcdWikiUrl  
   put empty into pSourceArray
   get matchText (xkcdWikiUrl, "https://www.explainxkcd.com/wiki/index.php/(.+)", wikiSlug) 
   if it is false then
      put pageArray_Construct ("Error", xkcdWikiUrl) into pageArray
      return pageArray
   end if
   --
   put mediawiki_FetchParseArray (wikiSlug, 1, "https://www.explainxkcd.com/wiki/api.php?") into parseArray
   
   # Deconstruct
   put parseArray ["title"] into pageTitle
   put parseArray ["sections"] into sectionArray
   put parseArray ["images"] into imageArray
   put parseArray ["wikitext"]["*"] into pageDescription
   
   mediawiki_CleanPageDescription pageDescription, infoBoxArray
   delete line 1 of pageDescription -- "==Explanation=="
   delete line 1 of pageDescription -- was added already with "wikicommons_ConstructBasicSummaryPageArray"
   --
   set the itemdelimiter to ":"
   delete item 1 of pageTitle
   
   put wikicommons_ConstructBasicSummaryPageArray (pageTitle, pageDescription, xkcdWikiUrl, pSourceArray) into fedwikiPageArray
   --
   put xkcd_FetchArray (wikiSlug) into xkcdArray
   
   # Deconstruct
   put xkcdArray ["img"] into imageURL
   put xkcdArray ["alt"] into imageDescription
   put xkcdArray ["transcript"] into xkcdTranscript
   
   if imageURL is not empty then
      put fedwiki_ConstructImageHtml (imageURL, imageDescription, xkcdWikiUrl, false) into imageHTML
      pageArray_AddHtml fedwikiPageArray, imageHTML
   end if
   --
   wikicommons_AddSectionToPageArray fedwikiPageArray, pageDescription, true
   --
   pageArray_StripJournal fedwikiPageArray
   return fedwikiPageArray
end xkcd_FetchPageArray

function xkcd_TestPageArray wikiSlug
   put xkcd_FetchArray (wikiSlug) into xkcdArray
   
   # Deconstruct
   put xkcdArray ["img"] into imageURL
   put xkcdArray ["alt"] into imageDescription
   put xkcdArray ["transcript"] into xkcdTranscript
   
   put pageArray_Construct ("Test", imageURL) into pageArray
   return pageArray
end xkcd_TestPageArray

function xkcd_FetchArray comicNum
   put xkcd_FetchJson (comicNum) into someJSON
   put json_ToArray (someJSON) into someArray
   return someArray
end xkcd_FetchArray

function xkcd_FetchJson comicNum
   -- in case comicNum is a title like "927:_Standards"
   set the itemdelimiter to ":"
   put item 1 of comicNum into comicNum
   --
   put merge ("http://xkcd.com/[[comicNum]]/info.0.json") into someURL
   put url someURL into someJSON
   return someJSON
end xkcd_FetchJson
