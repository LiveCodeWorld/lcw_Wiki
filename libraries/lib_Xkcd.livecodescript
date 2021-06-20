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


--> XKCD
-
command xkcd_DeconstructArray xkcdArray, @imageURL, @imageDescription, @xkcdTranscript
   put xkcdArray ["img"] into imageURL
   put xkcdArray ["alt"] into imageDescription
   put xkcdArray ["transcript"] into xkcdTranscript
end xkcd_DeconstructArray

function xkcd_FetchPageArray xkcdWikiUrl
   put empty into pSourceArray
   get matchText (xkcdWikiUrl, "https://www.explainxkcd.com/wiki/index.php/(.+)", wikiSlug) 
   if it is false then return empty
   --
   put mediawiki_FetchParseArray (wikiSlug, 1, "https://www.explainxkcd.com/wiki/api.php?") into parseArray
   _DeconstructParseArray parseArray, pageTitle, pageDescription, sectionArray, imageArray
   delete line 1 of pageDescription -- "==Explanation=="
   --
   set the itemdelimiter to ":"
   delete item 1 of pageTitle
   put wikicommons_ConstructBasicSummaryPageArray (pageTitle, pageDescription, xkcdWikiUrl, pSourceArray) into fedwikiPageArray
   --
   put xkcd_FetchArray (wikiSlug) into xkcdArray
   xkcd_DeconstructArray xkcdArray, imageURL, imageDescription, xkcdTranscript
   if imageURL is not empty then
      put fedwiki_ConstructImageHtml (imageURL, imageDescription, xkcdWikiUrl, false) into imageHTML
      pageArray_AddHtml fedwikiPageArray, imageHTML
   end if
   --
   delete line 1 of pageDescription -- was added already with "wikicommons_ConstructBasicSummaryPageArray"
   wikicommons_AddSectionToPageArray fedwikiPageArray, pageDescription, true
   --
   pageArray_StripJournal fedwikiPageArray
   return fedwikiPageArray
end xkcd_FetchPageArray

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


--> Private
-
private command _DeconstructParseArray parseArray, @pageTitle, @pageDescription, @sectionArray, @imageArray
   put parseArray ["title"] into pageTitle
   put parseArray ["sections"] into sectionArray
   put parseArray ["images"] into imageArray
   put parseArray ["wikitext"]["*"] into pageDescription
   mediawiki_CleanPageDescription pageDescription, infoBoxArray
   return infoBoxArray
end _DeconstructParseArray


