script "lib_WikiCommons"
--> MetaData
-
license: GPLv3
name: lib_WikiCommons
type: library
version: 0.5
deps: lib_MediaWiki, lib_Fedwiki, lib_FedwikiPedia


/*
In this library we store handlers used to manipulate wikimedia (images, videos etc on Wikipedias Wikimedia Commons servers)

We also have the code for parsing wikitext fetched using the older Mediwiki API's (not restbase API's) - ie "wikicommons_ConstructSectionPageArray()"
That code is used for importing wikipedia pages and sections that include mediawiki images.

The wikiText "clean" functions are in "lib_FedwikiPedia"
*/


--> Working on
-
function wikicommons_ConstructBasicSummaryPageArray pageTitle, pageDescription, pWikiURL, pSourceArray
   local fedwikiPageArray
   
   put pageTitle into fedwikiPageArray ["title"]
   put fedwiki_ConstructJournalArray (pageTitle, pSourceArray) into fedwikiPageArray ["journal"]
   
   -- let's add wikipedia url link to first line
   put word 1 to -1 of pageDescription into pageDescription
   put line 1 of  pageDescription into firstLine
   delete line 1 of pageDescription
   
   fedwiki_AddExternalLink firstLine, pWikiURL
   wikicommons_AddSectionToPageArray fedwikiPageArray, firstLine, true
   return fedwikiPageArray
end wikicommons_ConstructBasicSummaryPageArray

function wikicommons_FetchImageArray shortImageFile, pApiStem
   -- simlified and generalised from "wikicommons_FetchImageSandboxArray"
   
   if pApiStem is empty then
      put "https://en.wikipedia.org/w/api.php?" into pApiStem
   end if
   if not (shortImageFile begins with "File:") then put "File:" before shortImageFile
   
   put "action=query&format=json&prop=imageinfo" after sandBoxFragment
   put "&titles=" & shortImageFile after sandBoxFragment
   put "&iiprop=" & "comment|url|dimensions|size|sha1|metadata|extmetadata|thumbmime" after sandBoxFragment
   put "&iiurlwidth=420" after sandBoxFragment
   
   put sandbox_FetchArray (sandBoxFragment, pApiStem) into sandboxArray
   return sandboxArray
end wikicommons_FetchImageArray

function wikicommons_FetchImageSandboxArray shortImageFile, pApiStem
   if pApiStem is empty then put wikicommons_GetApiStem() into pApiStem
   if not (shortImageFile begins with "File:") then put "File:" before shortImageFile
   
   -- put "/w/api.php?" into sandBoxFragment -- bug: this might change
   
   put "action=query&format=json&prop=imageinfo" after sandBoxFragment
   put "&titles=" & shortImageFile after sandBoxFragment
   put "&iiprop=" & "comment|url|dimensions|size|sha1|metadata|extmetadata|thumbmime" after sandBoxFragment
   put "&iiurlwidth=420" after sandBoxFragment
   
   put sandbox_FetchArray (sandBoxFragment, pApiStem) into sandboxArray
   return sandboxArray
end wikicommons_FetchImageSandboxArray

function wikicommons_GetApiRoot
   put "https://commons.wikimedia.org" into apiStem   
   return apiStem
end wikicommons_GetApiRoot

function wikicommons_GetApiStem
   put wikicommons_GetApiRoot() & "/w/api.php?" into apiRoot
   return apiRoot
end wikicommons_GetApiStem

command wikicommons_FetchAndAddTwoImages @fedwikiPageArray, shortImageFile
   -- put urlencode (word 1 to -1 of shortImageFile) into shortImageFile
   if shortImageFile is among the items of mediawiki_ListBuiltInImages() then
      return false
   end if
   
   -- could work out from wikipediaURL
   put wikicommons_GetApiStem() into apiStem
   
   -- fetch and deconstruct
   put wikicommons_FetchImageSandboxArray (shortImageFile, apiStem) into sandboxArray
   _DeconstructSandboxImageArray sandboxArray, imageTitle, imageURL, imageDescription, imageCaption, descriptionURL, imageMime, thumbURL, thumbWidth, thumbMime
   switch
      case imageMime = "image/svg+xml"
         -- don't use thumb
         break
      case thumbWidth > 400
         put thumbURL into imageURL
         break
   end switch
   
   set the itemdelimiter to "."
   switch 
      case imageURL = empty
         return false
      case item -1 of imageURL = "webm"
         -- should not be
         return false
         break
      default
         -- construct description
         put html_StripTags (imageCaption) into plainCaption
         --  " - [" & descriptionURL && "wikimedia]" after plainCaption
         
         -- create html image
         put fedwiki_ConstructImageHtml (imageURL, plainCaption, descriptionURL, false) into imageHTML
         fedwiki_AddHtmlToPageArray fedwikiPageArray, imageHTML
         
         -- create encoded image
         put url thumbURL into someImage
         
         set the itemdelimiter to slash
         put item -1 of thumbMime into imageType -- png
         put fedwiki_ConstructEncodedImageArray (someImage, imageType, plainCaption) into imageArray
         
         fedwiki_AddItemArrayToStoryEnd imageArray, fedwikiPageArray
         return true
   end switch
end wikicommons_FetchAndAddTwoImages

function wikicommons_ProcessGallery
   -- https://en.wikipedia.org/w/index.php?title=Cross-country_skiing&action=edit&section=22
   /*
   ==Gallery==
   <gallery mode="packed" heights="150px">
   Image:Skigudinne.jpg|An early depiction of a skier—a [[Sami people|Sami]] woman or goddess hunting on skis by [[Olaus Magnus]]  (1553).
   File:Birkebeinerne ski01.jpg|Loyal retainers transporting [[Haakon IV of Norway|Prince Haakon IV]] of Norway to safety on skis during the winter of 1206—1869 depiction by [[Knud Bergslien]].
   File:138. Kronprins Olav - no-nb digifoto 20150710 00006 bldsa pk kgl0061.jpg|[[Olav V of Norway]] as crown-prince in 1939
   Image:olympic skier in ice storm.jpg|A skate-skier in [[Gatineau Park]], [[Quebec]], a North American groomed-trail ski venue.
   File:AchenseeWinter01.JPG|A recreational cross-country trail, groomed for classic skiing only, in  [[Tyrol (state)|Tyrol]].
   File:Blind skier and guide.jpg|A blind cross-country skier with guide at a regional [[Ski for Light]] event.
   File:Skijor worlds.jpg|Dog skijoring—dogs provide added propulsion to the cross-country skier.
   </gallery>
   */
   
   put html_ExtractHonde ("gallery") into galleryLines
end wikicommons_ProcessGallery


--> WikiCommons | Wikipedia Section
-
function wikicommons_ConstructSectionPageArray pageSlug, sectionNum, droppedURL, pFirstSectionOnly, pSourceArray
   put pFirstSectionOnly is not false into pFirstSectionOnly
   
   set the itemdelimiter to slash
   put item 1 to 3 of droppedURL into apiStem -- https://en.wikipedia.org
   put sandbox_FetchSectionArray (pageSlug, sectionNum, apiStem) into sandboxArray
   --
   put sandboxArray ["parse"] into parseArray
   put parseArray ["title"] into pageTitle
   put parseArray ["wikitext"]["*"] into sectionWikiText
   
   -- can't figure out how to use this info
   put parseArray ["sections"][1] into sectionInfoArray
   put sectionInfoArray ["line"] into sectionTitle
   
   -- construct wikipediaURL section link
   put _ConstructWikipediaURL (pageSlug, sectionTitle, apiStem) into wikipediaURL
   
   -- figure out what images are in section 
   put parseArray ["images"] into sectionImageArray
   repeat for each key indexNum in sectionImageArray
      put sectionImageArray [indexNum] & CR after sectionImages 
   end repeat
   delete char -1 of sectionImages
   
   /*
   -- stuff not needed (yet)
   put sectionInfoArray ["toclevel"] into toclevel
   put sectionInfoArray ["index"] into indexLevel
   put sectionInfoArray ["number"] into indexNum
   
   put parseArray ["text"]["*"] into sectionHTML
   put parseArray ["links"] into sectionLinks
   put parseArray ["categories"] into sectionCategories
   put parseArray ["externallinks"] into sectionExternalLinks
   */
   
   -- Start constructing fedwikiPageArray
   put sectionTitle into fedwikiPageArray ["title"]
   put fedwiki_ConstructJournalArray (sectionTitle, pSourceArray) into fedwikiPageArray ["journal"]
   
   -- let's remove section title and put it at the end in case needed
   delete line 1 of sectionWikiText -- == sectionTitle ==
   -- here the section could be empty
   
   wikicommons_AddSectionToPageArray fedwikiPageArray, sectionWikiText, pFirstSectionOnly
   
   -- add some utility tools
   put pageTitle && sectionTitle into seachWords
   fedwiki_AddTools fedwikiPageArray, seachWords
   
   -- add "# Sections"
   _AddTocFromSectionTitle fedwikiPageArray, pageSlug, sectionTitle
   
   -- add draggable markDownTitles
   put "#" && sectionTitle into markDownTitle
   fedwiki_AddMarkdownToPageArray fedwikiPageArray, markDownTitle
   put "- [[" & sectionTitle & "]]" into markDownTitle
   fedwiki_AddMarkdownToPageArray fedwikiPageArray, markDownTitle
   
   -- move first image to second paragraph
   fedwiki_MakeTextParagraphFirst fedwikiPageArray -- in case image is first
   wikicommons_MoveImage fedwikiPageArray, 2
   
   -- add link back to wikipedia
   fedwiki_AddExternalLinkToFirstSection fedwikiPageArray, wikipediaURL
   
   -- strip journal
   fedwiki_StripJournal fedwikiPageArray
   return fedwikiPageArray
end wikicommons_ConstructSectionPageArray

command wikicommons_MoveImage @fedwikiPageArray, pToItemNum
   -- moves image or media item
   -- fedwiki_MakeTextParagraphFirst fedwikiPageArray
   
   if pToItemNum is empty then put 2 into pToItemNum -- move image to item 2
   
   put fedwiki_FindFirstPicture (fedwikiPageArray) into foundItemNum
   pageArray_MoveStoryItem fedwikiPageArray, foundItemNum, pToItemNum
   put the result into moveBoolean
   return moveBoolean
end wikicommons_MoveImage

function wikicommons_ConstructTwoImagePageArray pageTitle, pageDescription, shortImageFile, wikipediaUrl, pSourceArray
   put wikicommons_ConstructBasicSummaryPageArray (pageTitle, pageDescription, wikipediaUrl, pSourceArray) into fedwikiPageArray
   
   if shortImageFile is an array then
      put shortImageFile into imageArray
      repeat for each key imageNum in imageArray
         put imageArray [imageNum] into shortImageFile
         wikicommons_FetchAndAddTwoImages fedwikiPageArray, shortImageFile
      end repeat
   else
      wikicommons_FetchAndAddTwoImages fedwikiPageArray, shortImageFile
   end if
   
   -- add the other lines
   delete line 1 of pageDescription -- was added alrady with "wikicommons_ConstructBasicSummaryPageArray"
   wikicommons_AddSectionToPageArray fedwikiPageArray, pageDescription, true
   return fedwikiPageArray
end wikicommons_ConstructTwoImagePageArray

function wikicommons_ConstructSectionForm pageSlug, sectionNum, sectionTitle
   -- https://en.wikipedia.org/w/index.php?title=Alps&action=edit&section=7
   
   put merge ("<form action='https://rest.livecode.world/mediawiki/importSection'><input name=section_title size=60 value='[[sectionTitle]]'>") into formHTML
   put CR & merge ("<input name=url type=hidden value='https://en.wikipedia.org/w/index.php?title=[[pageSlug]]&action=edit&section=[[sectionNum]]'>") after formHTML
   put CR & "<input type=submit value=create></form>" after formHTML
   --
   return formHTML
end wikicommons_ConstructSectionForm

function wikicommons_FetchSubSectionMarkdown sectionTitle, pageSlug
   local subsectionInfoArray, subsectionArray
   put wikicommons_FetchTocArray (pageSlug) into tocArray
   wikicommons_ConstructSubSectionArrays sectionTitle, tocArray, subsectionInfoArray, subsectionArray
   
   put item 2 of the extents of subsectionArray into maxNum
   repeat with indexNum = 1 to maxNum
      put subsectionArray [indexNum]["info"]["html"] into subSectionTitle
      put "- [[" & subSectionTitle & "]]" & CR after tocSectionMarkdown
   end repeat
   delete char -1 of tocSectionMarkdown
   return tocSectionMarkdown
end wikicommons_FetchSubSectionMarkdown

function wikicommons_FindTocDotNum sectionTitle, tocArray
   -- finds the first title that matches and returns a dotSectionNumber
   
   put wikicommons_FindTocDetailArray (sectionTitle, tocArray) into tocDetailArray
   put tocDetailArray ["number"] into dotNumber
   return dotNumber
end wikicommons_FindTocDotNum

function wikicommons_FindTocDetailArray sectionTitle, tocArray
   -- finds the first title that matches and returns a dotSectionNumber
   put item 2 of the extents of tocArray into maxIndexNum
   put 1 into subSectionNum
   repeat with indexNum = 1 to maxIndexNum -- for each key indexNum in tocArray
      if tocArray [indexNum]["html"] = sectionTitle then
         put tocArray [indexNum] into tocDetailArray
         return tocDetailArray
      end if
   end repeat
   return empty
end wikicommons_FindTocDetailArray

function wikicommons_FetchSubSectionTitles sectionTitle, pageTitle
   local subsectionInfoArray, subsectionArray
   put wikicommons_FetchTocArray (pageTitle) into tocArray
   wikicommons_ConstructSubSectionArrays sectionTitle, tocArray, subsectionInfoArray, subsectionArray
   
   put item 2 of the extents of subsectionArray into maxNum
   repeat with indexNum = 1 to maxNum
      put subsectionArray [indexNum]["info"]["html"] into subSectionTitle
      put subSectionTitle & CR after subSectionTitles
   end repeat
   delete char -1 of subSectionTitles
   return subSectionTitles
end wikicommons_FetchSubSectionTitles

command wikicommons_ConstructSubSectionArrays sectionTitle, tocArray, @subsectionInfoArray, @subsectionArray
   put wikicommons_FindTocDotNum (sectionTitle, tocArray) into dotNumber
   put wikicommons_ConstructNestedTocArray (tocArray) into nestedArray
   --
   put dotNumber into dotArrayKey
   split dotArrayKey with "."
   put nestedArray [dotArrayKey] into subsectionArray
   
   put subsectionArray ["info"] into subsectionInfoArray
   delete variable subsectionArray ["info"]
end wikicommons_ConstructSubSectionArrays

function wikicommons_ConstructNestedTocArray tocArray   
   repeat for each key indexNum in tocArray
      put tocArray [indexNum] into lineNumArray
      put lineNumArray ["number"] into dotNumber
      put lineNumArray ["level"] into levelNumber
      
      -- this does not work with lower nesting
      -- if levelNumber = 1 then put ".0" after dotNumber
      
      put dotNumber into dotArrayKey
      split dotArrayKey with "."
      put lineNumArray into nestedArray [dotArrayKey]["info"]
   end repeat
   return nestedArray
end wikicommons_ConstructNestedTocArray

function wikicommons_FetchTocArray pageTitle
   put restbase_FetchPageMetadata (pageTitle) into metadataArray
   put metadataArray ["toc"]["entries"] into tocArray
   return tocArray
end wikicommons_FetchTocArray


--> Wikicommons | File
-
function wikicommons_FetchFileMetadata shortImageFile, pExtended
   /*
   -- ?action=query&titles=Image:Commons-logo.svg&prop=imageinfo&iiprop=metadata&iimetadataversion=latest
   Raw metadata that is embedded in file. More information on the format
   -- ?action=query&titles=Image:Commons-logo.svg&prop=imageinfo&iiprop=extmetadata
   Includes metadata from file page
   */
   if pExtended is false then
      put wikicommons_FetchImageJson (shortImageFile, "imageinfo", "iiprop=metadata|url&iimetadataversion=latest") into someJSON
   else
      put wikicommons_FetchImageJson (shortImageFile, "imageinfo", "iiprop=extmetadata|url") into someJSON
   end if
   return someJSON
end wikicommons_FetchFileMetadata

function wikicommons_FetchNearbyFiles someLat, someLong, pRadius, pFormat
   /*
   -- action=query&generator=geosearch&ggsprimary=all&ggsnamespace=6&ggsradius=500
   -- &ggscoord=51.5|11.95&prop=imageinfo&iiprop=url&iiurlwidth=200
   
   put wikicommons_FetchNearbyFiles ( " 51.5", "11.95")
   */
   
   if pFormat is empty then put "json" into pFormat
   if pRadius is empty then put 500 into pRadius
   
   get merge ("action=query&generator=geosearch&ggsprimary=all&ggsnamespace=6&ggsradius=[[pRadius]]&format=[[pFormat]]")
   
   put wikicommons_GetApiStem() & it into someUrl
   put "&ggscoord=" & someLat & "|" & someLong after someUrl -- 51.5|11.95
   put "&prop=imageinfo&iiprop=url&iiurlwidth=200" after someUrl
   
   mediawiki_SetUserAgent
   put url someURL into someJSON
   return someJSON
end wikicommons_FetchNearbyFiles

function wikicommons_FetchFilesInCategory someCategory, pFormat
   -- api.php?action=query&list=categorymembers&cmtype=file&cmtitle=Category:CC-BY-2.0
   if pFormat is empty then put "json" into pFormat
   
   get merge ("action=query&list=categorymembers&cmtype=file&cmtitle=Category:[[someCategory]]&format=[[pFormat]]")
   put wikicommons_GetApiStem() & it into someUrl
   
   mediawiki_SetUserAgent
   put url someURL into someJSON
   return someJSON
end wikicommons_FetchFilesInCategory

function wikicommons_FetchFileCategories shortImageFile
   -- put wikimedia_FetchCommonsCategories ("Commons-logo.svg")
   put wikicommons_FetchImageJson (shortImageFile, "categories") into someJSON
   return someJSON
end wikicommons_FetchFileCategories


--> Wikicommons | Image
-
function wikicommons_ListImageRepos pApiStem
   put wikpedia_FetchPageImageSandboxArray ("File:Twttr_sketch-Dorsey-2006.jpg", pApiStem) into queryArray
   put queryArray ["query"]["pages"] into pageListArray
   put line 1 of the keys of pageListArray into pageID
   put pageListArray [pageID] into pageArray
   
   put pageArray ["pageimage"] into shortImageFile
   put pageArray ["thumbnail"]["source"] into thumbNailURL
   put pageArray ["thumbnail"]["width"] into thumbNailWidth
   
   put queryArray ["query"]["repos"] into repoListArray
   repeat for each line repoNum in the keys of repoListArray
      put repoListArray [repoNum]["rootUrl"] into rootUrl
      put repoListArray [repoNum]["thumbUrl"] into repoThumbRootUrl
      put repoListArray [repoNum]["url"] into someUrl -- ???
      
      /*
      -- no idea how to construct the url from the available information
      
      put "https://" & rootURL & "/" & shortImageFile into imageURL
      put url imageURL into someImage
      
      put "https://" & repoThumbRootUrl & "/" & shortImageFile into thumbURL
      put url thumbURL into thumbImage
      */
      
      put repoListArray [repoNum]["displayName"] into displayName
      switch displayName
         case "Wikimedia Commons"
            -- https://upload.wikimedia.org/wikipedia/en/9/9f/Twitter_bird_logo_2012.svg
            break
         case "Wikipedia"
            break
         default
            -- do nothing
      end switch  
   end repeat
end wikicommons_ListImageRepos


--> Wiki Commons | Image
-
command wikicommons_AddAllImages @fedwikiPageArray, mwPageTitle, pLimitNum
   put mediawiki_ListPageImages (mwPageTitle) into pageImages
   if pLimitNum is a number then put line 1 to pLimitNum of pageImages into pageImages
   repeat with lineNum =1 to the number of lines of pageImages
      put line lineNum of pageImages into shortImageFile -- what if it is not an image???
      if shortImageFile is empty then next repeat
      if shortImageFile is among the items of "Commons-logo.svg,Wikisource-logo.svg" then next repeat
      if shortImageFile begins with "Coat of arms of " then next repeat
      if shortImageFile begins with "Flag of " then next repeat
      
      put wikicommons_FetchImageSandboxArray (shortImageFile) into sandboxArray
      if sandboxArray is an array then
         put sandboxArray ["query"]["pages"] into pagesArray
         put pagesArray ["-1"] into pageArray
         wikicommons_AddImageToPageArray fedwikiPageArray, pageArray
      end if
   end repeat
end wikicommons_AddAllImages


--> Wiki Commons | Two Images
-
function wikicommons_FetchBasicTwoImagePageArray shortImageFile, pPageTitle, pSomeText, pWikipediaUrl
   if pPageTitle is empty then put "Wikimedia Image" into pPageTitle
   if pSomeText is empty then put "Drag these images to your source page..." into pSomeText
   
   put fedwiki_ConstructPageArray (pPageTitle, pSomeText) into fedwikiPageArray   
   set the itemdelimiter to "."
   if item -1 of shortImageFile is "webm" then
      put wikicommons_ConstructVideoPageArray (pPageTitle, pSomeText, pWikipediaUrl, shortImageFile) into fedwikiPageArray
   else
      wikicommons_FetchAndAddTwoImages fedwikiPageArray, shortImageFile
   end if
   fedwiki_StripJournal fedwikiPageArray
   return fedwikiPageArray
end wikicommons_FetchBasicTwoImagePageArray


--> WikiCommons | REST
-
function wikicommons_FetchImageJson shortImageFile, pProps, pExtraProps, pFormat
   if pFormat is empty then put "json" into pFormat
   get merge ("action=query&titles=Image:[[shortImageFile]]&prop=[[pProps]]&format=[[pFormat]]")
   if pExtraProps is not empty then put "&" & pExtraProps after it
   put wikicommons_GetApiStem() & it into someURL
   
   mediawiki_SetUserAgent
   put url someURL into someJSON
   if the number of words of someJSON = 0 then
      return someURL
   else
      return someJSON
   end if
end wikicommons_FetchImageJson


--> Private
-
private command _DeconstructSandboxImageArray sandboxArray, @imageTitle, @imageURL, @imageDescription, @imageCaption, @descriptionURL, @imageMime, @thumbURL, @thumbWidth, @thumbMime
   -- let's deconstruct information about the file
   put sandboxArray ["query"]["pages"] into pageArray
   
   put line 1 of keys (pageArray) into pageID -- should only be one line
   put pageArray [pageID]["title"] into imageTitle -- same as shortImageFile
   put pageArray [pageID]["imageinfo"][1] into imageInfoArray
   
   put imageInfoArray ["descriptionurl"] into descriptionURL
   put imageInfoArray ["url"] into imageURL
   put imageInfoArray ["thumburl"] into thumburl
   put imageInfoArray ["thumbwidth"] into thumbwidth -- 420
   put imageInfoArray ["mime"] into imageMime
   put imageInfoArray ["thumbmime"] into thumbMime
   
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
end _DeconstructSandboxImageArray

private function _ConstructWikipediaURL pageSlug, sectionTitle, apiStem
   -- an ugly hack that seems to work?
   
   -- https://en.wikipedia.org/wiki/Ant#Behaviour_and_ecology
   replace space with "_" in pageSlug
   --
   put sectionTitle into sectionTitleSlug
   replace space with "_" in sectionTitleSlug
   put apiStem & "/wiki/" & pageSlug & "#" & sectionTitleSlug after wikipediaURL
   return wikipediaURL
end _ConstructWikipediaURL

command _AddTocFromSectionTitle @fedwikiPageArray, pageSlug, sectionTitle
   local subsectionInfoArray, subsectionArray
   
   put wikicommons_FetchTocArray (pageSlug) into tocArray
   wikicommons_ConstructSubSectionArrays sectionTitle, tocArray, subsectionInfoArray, subsectionArray
   --
   if subsectionArray is an array then
      fedwiki_AddMarkdownToPageArray fedwikiPageArray, "# Sections"
      _AddTocToPageArray fedwikiPageArray, pageSlug, subsectionArray, tocArray
   end if
end _AddTocFromSectionTitle

command _AddTocToPageArray @pageArray, pageSlug, subsectionArray, tocArray
   put item 2 of the extents of subsectionArray into maxNum
   repeat with indexNum = 1 to maxNum
      -- put wikicommons_FindTocDetailArray (sectionTitle, tocArray) into sectionInfoArray
      put subsectionArray [indexNum]["info"] into sectionInfoArray
      _DeconstructSectionInfoArray sectionInfoArray, sectionTitle, sectionSlug, sectionNum, dotNumber, sectionLevel
      
      put wikicommons_ConstructSectionForm (pageSlug, sectionNum, sectionTitle) into formHTML
      fedwiki_AddHtmlToPageArray pageArray, formHTML
   end repeat
end _AddTocToPageArray

command _DeconstructSectionInfoArray sectionInfoArray, @sectionTitle, @pageSlug, @sectionNum, @dotNumber, @sectionLevel
   put sectionInfoArray ["html"] into sectionTitle
   put sectionInfoArray ["anchor"] into pageSlug
   
   put sectionInfoArray ["section"] into sectionNum
   put sectionInfoArray ["number"] into dotNumber
   put sectionInfoArray ["level"] into sectionLevel
end _DeconstructSectionInfoArray
