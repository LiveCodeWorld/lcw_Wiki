﻿script "lib_WikiSandbox"
--> MetaData
-
license: GPLv3
name: lib_WikiSandbox
type: library
version: 0.1

/*
These handlers are designed to work with the mediawiki sandbox interface - https://en.wikipedia.org/wiki/Special:ApiSandbox

You should be able to explore the api, and copy the sandbox fragments from the web interface,
and add them to a handler below in order to code simple rest calls that return arrays.
*/


--> Working on
-
function sandbox_ConstructPageQueryFragment pageTitle, pSectionFormat, pIntroOnly, pPlain
   -- use parse like "sandbox_ConstructSectionFragment" instead?
   
   text_Utf8Encode pageTitle
   put urlencode (pageTitle) into pageTitle
   
   put "/w/api.php?action=query" into sandBoxFragment
   put "&prop=" after sandBoxFragment
   -- put "info|pageprops|coordinates|description|imageinfo|videoinfo|mapdata|info|pageimages" into propList
   put "coordinates|description|imageinfo|videoinfo|mapdata|info|pageimages|pageprops" into propList
   put "|extracts"  after propList
   -- put "|pageterms"  after propList
   -- put "|categories" after propList
   put urlencode (propList) after sandBoxFragment
   
   if pPlain is true then put "&explaintext=1" after sandBoxFragment
   if pIntroOnly is true then put "&exintro=1" after sandBoxFragment
   
   # Format
   if pSectionFormat is empty then put "wiki" into pSectionFormat --  wiki, plain, raw
   put "&exsectionformat=" & pSectionFormat after sandBoxFragment
   
   # Essentials
   put "&titles=" & pageTitle after sandBoxFragment
   put "&redirects" after sandBoxFragment
   put "&formatversion=2" after sandBoxFragment
   put "&format=json" after sandBoxFragment
   return sandBoxFragment
end sandbox_ConstructPageQueryFragment

command sandbox_DeconstructPageArray sandboxArray, @pageTitle, @pageDescription, @shortImageFile, @lastRevisionID   
   put sandboxArray ["query"]["pages"] into pagesArray
   put line 1 of keys (pagesArray) into pageID
   put pagesArray [pageID] into sandboxPageArray
   
   # Basics
   put sandboxPageArray ["title"] into pageTitle
   put sandboxPageArray ["extract"] into pageDescription
   put sandboxPageArray ["lastrevid"] into lastRevisionID
   
   # Page Image
   get sandboxPageArray ["pageimage"]
   put it into shortImageFile
   -- put textDecode (it, "UTF-8") into shortImageFile
   put sandboxPageArray ["thumbnail"]["source"] into thumbURL
   
   # Page Props
   -- put sandboxPageArray ["pageprops"]["page_image_free"] into shortImageFile
   put sandboxPageArray ["pageprops"]["wikibase_item"] into wikibaseID
   
   # Coords
   put sandboxPageArray ["coordinates"][1]["lat"] into sLat
   put sandboxPageArray ["coordinates"][1]["lat"] into sLong
   
   return sandboxPageArray
end sandbox_DeconstructPageArray


--> Wikipedia
-
function wikipedia_FetchPageGeolocation pageTitle, pApiRoot
   -- https://en.wikipedia.org/w/api.php?action=query&format=json&prop=coordinates&titles=Wikimedia%20Foundation
   put "/w/api.php?action=query&format=json&prop=coordinates&titles=" into sandBoxFragment
   put urlencode (pageTitle) after sandBoxFragment
   
   put sandbox_FetchJSON (sandBoxFragment, pApiRoot) into someJSON
   put json_ToArray (someJSON) into sandboxArray
   --
   -- display_Data sandboxArray
   if "batchcomplete" is not among the keys of sandboxArray then return ("Error, with query -" && sandBoxFragment)
   
   put sandboxArray ["query"]["pages"] into pagesGeoArray
   put the keys of pagesGeoArray into pageIDs
   if the number of lines of pageIDs = 1 then
      put pagesGeoArray [pageIDs]["title"] into foundTitle
      put pagesGeoArray [pageIDs]["coordinates"][1]["globe"] into foundGlobe
      --
      put pagesGeoArray [pageIDs]["coordinates"][1]["lat"] into foundLat
      put pagesGeoArray [pageIDs]["coordinates"][1]["lon"] into foundLong
      --
      return foundLat,foundLong,foundTitle
   else
      return pagesGeoArray
   end if
end wikipedia_FetchPageGeolocation

function wikpedia_FetchPageImageSandboxArray pageTitle, pApiRoot
   put "/w/api.php?action=query&format=json&uselang=de&prop=pageimages&meta=filerepoinfo%7Cwikibase&titles=" into sandBoxFragment
   put urlencode (pageTitle) after sandBoxFragment
   put "&iiprop=" & "comment|url|dimensions|size|sha1|metadata|extmetadata|thumbmime" after sandBoxFragment
   put "&iiurlwidth=420" after sandBoxFragment
   put "&redirects=1" after sandBoxFragment
   
   put sandbox_FetchJSON (sandBoxFragment, pApiRoot) into someJSON
   put json_ToArray (someJSON) into sandboxArray
   return sandboxArray
end wikpedia_FetchPageImageSandboxArray


--> Fedwikipedia | FetchWikiText
-
function fedwikipedia_FetchWikiText pageTitle, pFirstOnly, pApiStem
   put fedwikipedia_FetchWikiTextArray (pageTitle, pFirstOnly, pApiStem) into anotherArray   
   put sandbox_GetRevision (anotherArray) into wikiText
   return wikiText 
end fedwikipedia_FetchWikiText

function fedwikipedia_FetchWikiTextArray pageTitle, pFirstOnly, pApiStem
   put sandbox_ConstructWikiTextFragment (pageTitle, pFirstOnly) into sandBoxFragment
   put sandbox_FetchArray (sandBoxFragment, pApiStem) into sandboxArray
   return sandboxArray
end fedwikipedia_FetchWikiTextArray

--> FedWikiPedia | Fetch | Html
-
function fedwikipedia_FetchPageHtml pageTitle, pApiStem
   put fedwikipedia_FetchPageHtmlArray (pageTitle, pApiStem) into sandboxArray
   put sandbox_GetExtract (sandboxArray) into pageHTML
   return pageHTML
end fedwikipedia_FetchPageHtml

function fedwikipedia_FetchPageHtmlArray pageTitle, pFirstOnly, pApiStem
   put sandbox_ConstructPageHtmlFragment (pageTitle, pFirstOnly) into sandBoxFragment
   put sandbox_FetchArray (sandBoxFragment, pApiStem) into sandboxArray
   return sandboxArray
end fedwikipedia_FetchPageHtmlArray


--> Sandbox
-
function sandbox_ConstructSectionFragment pageTitle, pSectionNum
   -- pSectionNum = 0 returns the summary section
   /*
   -- {"warnings":{"main":{"*":"Unrecognized parameters: mobileformat, mainpage."},"parse":{"*":"Unrecognized values for parameter \"prop\": extracts, info, pageprops, pageterms."}
   */   
   put "/w/api.php?action=parse&format=json&page=" into sandBoxFragment
   get sandbox_AddSectionFragment (pageTitle, pSectionNum, sandBoxFragment) 
   return it
end sandbox_ConstructSectionFragment

function sandbox_AddSectionFragment pageTitle, pSectionNum, sandBoxFragment
   text_Utf8Encode pageTitle
   put urlencode (pageTitle) after sandBoxFragment
   --
   put "&prop=wikitext|images|revid" after sandBoxFragment
   put "|sections" after sandBoxFragment
   --
   if pSectionNum is a number then
      put "&section=" & pSectionNum after sandBoxFragment
   end if
   put "&redirects" after sandBoxFragment
   return sandBoxFragment
end sandbox_AddSectionFragment

function sandbox_ConstructWikiTextFragment pageTitle, pFirstOnly
   -- use parse like "sandbox_ConstructSectionFragment" instead?
   --action=query&format=json&prop=revisions&titles=Pliocene&rvprop=content&rvexpandtemplates=1&rvsection=0
   
   put "/w/api.php?action=query&format=json&prop=revisions&titles=" into sandBoxFragment
   put urlencode (pageTitle) after sandBoxFragment
   put "&rvprop=content&rvexpandtemplates=1"after sandBoxFragment
   if pFirstOnly is true then
      put "&rvsection=0" after sandBoxFragment
   end if
   put "&redirects" after sandBoxFragment
   return sandBoxFragment
end sandbox_ConstructWikiTextFragment


--> Sandbox | Array
-
command sandbox_DeconstructSectionArray sandboxArray, @pageTitle, @sectionDescription, @imageArray, @sectionArray, @wikipediaRevisionID
   -- display_Array sandboxArray, "sandbox_DeconstructSectionArray"
   put sandboxArray ["parse"] into parseArray
   put parseArray ["pageid"] into pageID
   put parseArray ["title"] into pageTitle
   put parseArray ["wikitext"]["*"] into sectionDescription
   put parseArray ["images"] into imageArray
   put parseArray ["sections"] into sectionArray
   -- put parseArray ["text"]["*"] into sectionHTML
   put parseArray ["revid"] into wikipediaRevisionID
end sandbox_DeconstructSectionArray

function sandbox_FetchSectionArray pageTitle, sectionNum, pApiStem
   -- was "sandbox_FetchSectionArray"
   put sandbox_ConstructSectionFragment (pageTitle, sectionNum) into sandBoxFragment
   put sandbox_FetchArray (sandBoxFragment, pApiStem) into sandboxArray
   return sandboxArray
end sandbox_FetchSectionArray


--> Sandbox | Construct
-
function sandbox_ConstructPageHtmlFragment pageTitle
   -- use parse like "sandbox_ConstructSectionFragment" instead?
   put "/w/api.php?action=query&prop=extracts&format=json&titles=" into sandBoxFragment
   put urlencode (pageTitle) after sandBoxFragment
   put "&redirects" after sandBoxFragment
   return sandBoxFragment
end sandbox_ConstructPageHtmlFragment


--> Private
-
private function sandbox_GetRevision sandboxArray
   put sandboxArray ["query"]["pages"] into pagesArray
   put line 1 of keys (pagesArray) into pageID -- assume only one
   put pagesArray [pageID] into pageArray
   put pageArray ["revisions"]["1"]["*"] into someExtract
   return someExtract
end sandbox_GetRevision

private function sandbox_GetExtract sandboxArray
   put sandboxArray ["query"]["pages"] into pagesArray
   put line 1 of keys (pagesArray) into pageID -- assume only one
   put pagesArray [pageID] into pageArray
   put pageArray ["extract"] into someExtract
   return someExtract
end sandbox_GetExtract
