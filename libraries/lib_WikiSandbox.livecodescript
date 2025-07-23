script "lib_WikiSandbox"
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

--> Sandbox | TOC
-
function sandbox_PageTocArray sandboxArray
   put sandboxArray ["parse"]["sections"] into sectionArray
   put sectionArray [1]["fromTitle"] into tocTitle
   
   repeat for each key tocNum in sectionArray
      put sectionArray [tocNum]["level"] into tocLevel
      put sectionArray [tocNum]["line"] into tocLine
      put sectionArray [tocNum]["number"] into tocNumber
      
      put tocNumber into tocArray ["index"][tocLine]["dot_number"]
      put tocNum into tocArray ["index"][tocLine]["section_number"]
      
      put tocNumber into dotKeyArray
      split dotKeyArray by "."
      put tocLine into tocArray [dotKeyArray]["meta"]["title"]
      put tocNumber into tocArray [dotKeyArray]["meta"]["dot_number"]
      put tocNum into tocArray [dotKeyArray]["meta"]["section_number"]
      put tocLevel into tocArray [dotKeyArray]["meta"]["section_level"]
   end repeat
   return tocArray
end sandbox_PageTocArray

command sandbox_TocData tocArray, @lookUpArray, @markdownTOC, pAddAll
   delete variable tocArray ["index"]
   repeat with itemNum = (the number of lines of the keys of tocArray) down to 1
      put tocArray [itemNum]["meta"] into metaTocArray
      put metaTocArray ["title"] into sectionTitle
      delete variable metaTocArray ["title"]
      --
      if pAddAll is not true AND sectionTitle is among the items of "See also,Notes,Further Reading,References,Sources,External links" then
         next repeat
      end if
      --
      put metaTocArray into lookUpArray ["wiki_links"][sectionTitle]
      put "- [[" & sectionTitle & "]]" & CR before markdownTOC
   end repeat
   delete char -1 of markdownTOC
end sandbox_TocData

command sandbox_ParseInfo pageSlug, @pageDescription, @pageTitle, @shortImageFile, @infoBoxArray, pSectionNum, pApiStem, pAddCors
   -- Uses "parse" to extract wiktext sections. Lot's of fiddling with text. Messy as it returns lots of page templates that need cleaning. But we get wiki links
   put sandbox_ParseInfoArray (pageSlug, pSectionNum, pApiStem, pAddCors) into sArray
   put sArray ["parse"] into pageArray
   --
   put pageArray ["title"] into pageTitle
   put pageArray ["wikitext"]["*"] into pDescription
   
   # Clean
   mediawiki_CleanPageDescription pDescription, infoBoxArray
   if infoBoxArray is an array then
      put infoBoxArray ["image"] into shortImageFile
   else
      put pageArray ["images"] into imageArray
      put mediawiki_ExtractFirstInterestingImage (imageArray) into shortImageFile
   end if
   return sArray
end sandbox_ParseInfo

function sandbox_ParseInfoArray pageSlug, pSectionNum, pApiStem, pAddCors
   if pSectionNum is empty then
      put sandbox_ConstructSectionFragment (pageSlug) into sFragment
   else
      put sandbox_ConstructSectionFragment (pageSlug, pSectionNum) into sFragment
   end if
   put sandbox_FetchData (sFragment, pApiStem, pAddCors) into sArray
   return sArray
end sandbox_ParseInfoArray


--> Sandbox
-
command sandbox_FetchPageQueryInfo pageSlug, @plainDescription, @pageTitle, @shortImageFile, @lastRevisionID, pIntroOnly, pPlain, pApiStem, pAddCors
   put sandbox_ConstructPageQueryFragment (pageSlug, "wiki", pIntroOnly, pPlain) into sandBoxFragment
   put sandbox_FetchData (sandBoxFragment, pApiStem, pAddCors) into sandboxArray
   sandbox_DeconstructPageArray sandboxArray, pageTitle, plainDescription, shortImageFile, lastRevisionID
   put the result into sandboxPageArray
   return sandboxPageArray
end sandbox_FetchPageQueryInfo

function sandbox_PageGeoData pageTitle, pApiRoot
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
end sandbox_PageGeoData

function sandbox_PageImageData pageTitle, pApiRoot
   put "/w/api.php?action=query&format=json&uselang=de&prop=pageimages&meta=filerepoinfo%7Cwikibase&titles=" into sandBoxFragment
   put urlencode (pageTitle) after sandBoxFragment
   put "&iiprop=" & "comment|url|dimensions|size|sha1|metadata|extmetadata|thumbmime" after sandBoxFragment
   put "&iiurlwidth=420" after sandBoxFragment
   put "&redirects=1" after sandBoxFragment
   
   put sandbox_FetchJSON (sandBoxFragment, pApiRoot) into someJSON
   put json_ToArray (someJSON) into sandboxArray
   return sandboxArray
end sandbox_PageImageData

function sandbox_WikiText pageTitle, pFirstOnly, pApiStem
   put sandbox_WikiTextData (pageTitle, pFirstOnly, pApiStem) into sData 
   put sandbox_GetRevision (sData) into wikiText
   return wikiText 
end sandbox_WikiText

function sandbox_WikiTextData pageTitle, pFirstOnly, pApiStem, pAddCors
   put sandbox_ConstructWikiTextFragment (pageTitle, pFirstOnly) into sandBoxFragment
   put sandbox_FetchData (sandBoxFragment, pApiStem, pAddCors) into sandboxArray
   return sandboxArray
end sandbox_WikiTextData

function sandbox_PageHtml pageTitle, pApiStem
   put sandbox_PageHtmlData (pageTitle, pApiStem) into sandboxArray
   put sandbox_GetExtract (sandboxArray) into pageHTML
   return pageHTML
end sandbox_PageHtml

function sandbox_PageHtmlData pageTitle, pFirstOnly, pApiStem, pAddCors
   put sandbox_ConstructPageHtmlFragment (pageTitle, pFirstOnly) into sandBoxFragment
   put sandbox_FetchData (sandBoxFragment, pApiStem, pAddCors) into sandboxArray
   return sandboxArray
end sandbox_PageHtmlData


--> Sandbox | Construct
-
function sandbox_ConstructPageHtmlFragment pageTitle
   -- use parse like "sandbox_ConstructSectionFragment" instead?
   put "/w/api.php?action=query&prop=extracts&format=json&titles=" into sandBoxFragment
   put urlencode (pageTitle) after sandBoxFragment
   put "&redirects" after sandBoxFragment
   return sandBoxFragment
end sandbox_ConstructPageHtmlFragment

function sandbox_ConstructPageQueryFragment pageTitle, pSectionFormat, pIntroOnly, pPlain
   -- use parse like "sandbox_ConstructSectionFragment" instead?
   put mw_ConstructSlug (pageTitle) into pageTitle
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
   put mw_ConstructSlug (pageTitle) after sandBoxFragment
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

function sandbox_FetchSectionArray pageTitle, sectionNum, pApiRoot, pAddCors
   put sandbox_ConstructSectionFragment (pageTitle, sectionNum) into sandBoxFragment
   put sandbox_FetchData (sandBoxFragment, pApiRoot, pAddCors) into sandboxArray
   return sandboxArray
end sandbox_FetchSectionArray


--> Sandbox | REST
-
function sandbox_FetchData sandBoxFragment, pApiRoot, pAddCors
   put sandbox_FetchJSON (sandBoxFragment, pApiRoot, pAddCors) into sJSON 
   put json_ToArray (sJSON) into sData
   return sData 
end sandbox_FetchData

function sandbox_FetchJSON sandBoxFragment, pApiRoot, pAddCors
   put sandbox_ConstructUrl (sandBoxFragment, pApiRoot) into restURL
   put mw_FetchJSON (restURL, pAddCors) into sJSON -- no need for cors
   return sJSON
end sandbox_FetchJSON

function sandbox_ConstructUrl sandBoxFragment, pApiRoot
   if pApiRoot is empty then
      put "https://en.wikipedia.org" into pApiRoot
   else
      set the itemdelimiter to slash
      put item 1 to 3 of pApiRoot into pApiRoot
   end if
   if char -1 of pApiRoot is not slash then
      put slash after pApiRoot
   end if
   put pApiRoot & sandBoxFragment into restURL
   return restURL
end sandbox_ConstructUrl


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


--> Deps
-
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
