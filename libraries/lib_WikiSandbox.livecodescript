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
function sandbox_FetchJSON sandBoxFragment, pApiRoot
   if pApiRoot is empty then put "https://en.wikipedia.org" into pApiRoot
   -- if pApiRoot is empty then put "https://en.wikipedia.org/w/api.php?" into pApiRoot   
   put pApiRoot & sandBoxFragment into restURL
   --
   put mediawiki_FetchJSON (restURL) into someJSON
   return someJSON
end sandbox_FetchJSON

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

command sandbox_DeconstructPageArray sandboxArray, @pageTitle, @pageDescription, @shortImageFile, @lastRevisionID
   put sandboxArray ["query"]["pages"] into pagesArray
   put line 1 of keys (pagesArray) into pageID
   put pagesArray [pageID] into sandboxPageArray
   
   put sandboxPageArray ["title"] into pageTitle
   put sandboxPageArray ["extract"] into pageDescription
   put sandboxPageArray ["pageprops"]["page_image"] into shortImageFile
   put sandboxPageArray ["lastrevid"] into lastRevisionID
   return sandboxPageArray
end sandbox_DeconstructPageArray

command sandbox_ArrayDeconstructImage sandboxArray, @imageTitle, @imageURL, @imageDescription, @imageCaption, @descriptionURL, @imageCategoryIndex
   -- let's deconstruct information about the file
   put sandboxArray ["query"]["pages"] into pageArray
   
   put line 1 of keys (pageArray) into pageID -- should only be one line
   put pageArray [pageID]["title"] into imageTitle -- same as shortImageFile
   put pageArray [pageID]["imageinfo"][1] into imageInfoArray
   
   put imageInfoArray ["descriptionurl"] into descriptionURL
   put imageInfoArray ["url"] into imageURL
   put imageInfoArray ["extmetadata"] into extmetArray
   
   put extmetArray ["Categories"]["value"] into imageCategoryIndex
   replace "|" with CR in imageCategoryIndex
   put extmetArray ["ImageDescription"]["value"] into imageDescription
   put extmetArray ["LicenseShortName"]["value"] into licenseDescription
   
   put imageDescription into imageCaption
   put word 1 to -1 of imageCaption into imageCaption
   if char 1 to 3 of imageCaption = "<p>" then
      delete char 1 to 3 of imageCaption
      if char -4 to -1 of imageCaption = "</p>" then
         delete char -4 to -1 of imageCaption
      end if
   end if
end sandbox_ArrayDeconstructImage


--> Sandbox | Construct
-
function sandbox_ConstructPageQueryFragment pageTitle, pSectionFormat, pIntroOnly, pPlain
   -- use parse like "sandbox_ConstructSectionFragment" instead?
   -- /w/api.php?action=query&format=json&prop=extracts%7Ccategories%7Cpageprops%7Cinfo&titles=Therion&exintro=1&explaintext=1&exsectionformat=wiki
   -- /w/api.php?action=query&format=json&prop=extracts%7Cinfo%7Cpageprops%7Cpageterms&continue=&titles=Trotsky&redirects=1&exintro=1&explaintext=1&exsectionformat=wiki
   
   -- /w/api.php?action=query&format=json
   -- &prop=extracts%7Cinfo%7Cpageprops%7Cpageterms%7Ccoordinates
   -- &titles=Alexanderplatz&redirects=1&exintro=1&explaintext=1&exsectionformat=wiki
   -- &inprop=url%7Cdisplaytitle
   
   -- put true into pPlain
   
   text_Utf8Encode pageTitle
   put urlencode (pageTitle) into pageTitle
   
   put "/w/api.php?action=query" into sandBoxFragment
   put "&prop=extracts" after sandBoxFragment
   -- put "&|info|pageprops|coordinates" after sandBoxFragment
   -- put "|pageterms"  after sandBoxFragment
   -- put "|categories" after sandBoxFragment
   
   if pIntroOnly is true then
      put "&exintro=" & "1" after sandBoxFragment
   end if
   
   if pPlain is true then
      put "&explaintext" after sandBoxFragment
   end if
   
   /*
   wiki — e.g., == Wikitext ==
   plain — no special decoration
   raw — this extension's internal representation
   */
   if pSectionFormat is not empty then
      put "&exsectionformat=" & pSectionFormat after sandBoxFragment
   end if
   
   put "&titles=" & pageTitle after sandBoxFragment
   -- put "&inprop=url|displaytitle" after sandBoxFragment
   put "&redirects" after sandBoxFragment
   put "&format=json" after sandBoxFragment
   return sandBoxFragment
end sandbox_ConstructPageQueryFragment

function sandbox_ConstructPageHtmlFragment pageTitle
   -- use parse like "sandbox_ConstructSectionFragment" instead?
   put "/w/api.php?action=query&prop=extracts&format=json&titles=" into sandBoxFragment
   put urlencode (pageTitle) after sandBoxFragment
   put "&redirects" after sandBoxFragment
   return sandBoxFragment
end sandbox_ConstructPageHtmlFragment


--> Sandbox | REST
-
function sandbox_FetchArray sandBoxFragment, pApiRoot
   put sandbox_FetchJSON (sandBoxFragment, pApiRoot) into someJSON -- use restbase_FetchSlugJSON() if possible
   put json_ToArray (someJSON) into someArray
   return someArray 
end sandbox_FetchArray


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
