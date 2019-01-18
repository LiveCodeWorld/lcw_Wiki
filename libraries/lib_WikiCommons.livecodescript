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

command wikicommons_FetchAndAddTwoImages @fedwikiPageArray, shortImageFile, pApiRoot
   put urlencode (word 1 to -1 of shortImageFile) into shortImageFile
   if shortImageFile is among the items of mediawiki_ListBuiltInImages() then
      return false
   end if
   
   put wikicommons_FetchImageSandboxArray (shortImageFile, pApiRoot) into sandboxArray
   sandbox_ArrayDeconstructImage sandboxArray, imageTitle, imageURL, imageDescription, imageCaption, descriptionURL, imageCategoryIndex
   
   set the itemdelimiter to "."
   switch 
      case imageURL = empty
         return false
      case item -1 of imageURL = "webm"
         -- should not be
         return false
         break
      default
         mediawiki_SetUserAgent
         put url imageURL into someImage
         if someImage is empty then return ("Error, image" && imageURL && "is empty")
         
         set the itemdelimiter to "."
         put item -1 of imageURL into imageType -- bit of a hack
         put html_StripTags (imageCaption) into plainCaption
         put " - [" & descriptionURL && "wikimedia]" after plainCaption
         
         put fedwiki_ConstructImageHtml (imageURL, plainCaption, descriptionURL, false) into imageHTML
         
         fedwiki_AddHtmlToPageArray fedwikiPageArray, imageHTML
         
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
   fedwiki_StripJournalToCreate fedwikiPageArray
   return fedwikiPageArray
end wikicommons_ConstructSectionPageArray

command wikicommons_AddSectionToPageArray @fedwikiPageArray, wikiText, pFirstSectionOnly
   -- don't like this way of doing it
   -- structure data first then write it out logically instead of looping and writing
   
   local firstSection
   fedwikipedia_CleanWikiText wikiText
   
   put empty into markDownBulletSection
   put 0 into lineNum
   repeat for each line wikisectionLine in wikiText
      add 1 to lineNum
      put word 1 to - 1 of wikisectionLine into wikisectionLine
      switch
         case wikisectionLine is empty
            next repeat
         case char 1 to 8 of wikisectionLine = "[[Image:"
            _AddImageToPageArray fedwikiPageArray, wikisectionLine
            put the result into shortImageFile
            
            put shortImageFile & CR after addedImages
            break
         case char 1 to 7 of wikisectionLine = "[[File:"
            put wikicommons_FindFileTag (wikisectionLine) into fileTag
            wikicommons_DeconstructFileWikiText fileTag, shortImageFile, captionBit
            
            -- put wikicommons_FetchImageHtml (shortImageFile, captionBit) into imageHTML
            wikicomons_FetchImageUrls shortImageFile, imageURL, descriptionURL, captionBit
            put wikicommons_ConstructImageOrVideoHtml (imageURL, captionBit, descriptionURL) into imageHTML
            fedwiki_AddHtmlToPageArray fedwikiPageArray, imageHTML
            
            put shortImageFile & CR after addedImages
            break
         case char 1 to 2 of wikisectionLine = "* "
            put "-" into char 1 of wikisectionLine
            put wikisectionLine & CR after markDownBulletSection
            next repeat
         case markDownBulletSection is not empty
            delete char -1 of markDownBulletSection
            fedwiki_AddMarkdownToPageArray fedwikiPageArray, markDownBulletSection
            put empty into markDownBulletSection
            break
         case char 1 of wikisectionLine = "<"
            fedwikipedia_CleanInternalLinks wikiSectionLine
            fedwiki_AddHtmlToPageArray fedwikiPageArray, wikisectionLine
            break
         case char 1 of wikisectionLine = "=" and char -1 of wikisectionLine = "="
            if pFirstSectionOnly is true then
               -- put line 1 to (lineNum-1) of wikiText into firstSection -- not needed
               exit repeat
            end if
            mediawiki_ConvertSectionTitle wikisectionLine
            fedwiki_AddMarkdownToPageArray fedwikiPageArray, wikisectionLine
            break
         default
            -- we use markdown now instead of text
            fedwikipedia_CleanInternalLinks wikiSectionLine
            
            -- fedwiki_AddParagraphToPageArray fedwikiPageArray, wikisectionLine
            fedwiki_AddMarkdownToPageArray fedwikiPageArray, wikisectionLine
            break
      end switch
   end repeat
   
   if markDownBulletSection is not empty then
      -- exitted without adding markDownBulletSection
      delete char -1 of markDownBulletSection
      fedwiki_AddMarkdownToPageArray fedwikiPageArray, markDownBulletSection
      -- put empty into markDownBulletSection
   end if
   
   delete char -1 of addedImages
   return addedImages
end wikicommons_AddSectionToPageArray

function wikicommons_ConstructTwoImagePageArray pageTitle, pageDescription, shortImageFile, wikipediaUrl, pSourceArray, pApiRoot
   put wikicommons_ConstructBasicSummaryPageArray (pageTitle, pageDescription, wikipediaUrl, pSourceArray) into fedwikiPageArray
   
   if shortImageFile is an array then
      put shortImageFile into imageArray
      repeat for each key imageNum in imageArray
         put imageArray [imageNum] into shortImageFile
         wikicommons_FetchAndAddTwoImages fedwikiPageArray, shortImageFile, pApiRoot
      end repeat
   else
      wikicommons_FetchAndAddTwoImages fedwikiPageArray, shortImageFile, pApiRoot
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


--> Wikicommons | Image
   
command wikicommons_MoveImage @fedwikiPageArray, pToItemNum
   -- moves image or media item
   -- fedwiki_MakeTextParagraphFirst fedwikiPageArray
   
   if pToItemNum is empty then put 2 into pToItemNum -- move image to item 2
   
   put fedwiki_FindFirstPicture (fedwikiPageArray) into foundItemNum
   fedwiki_MoveStoryItem fedwikiPageArray, foundItemNum, pToItemNum
   put the result into moveBoolean
   return moveBoolean
end wikicommons_MoveImage

function wikicommons_ConstructImageOrVideoHtml imageURL, pImageCaption, pDescriptionURL, pPosterImageFile
   set the itemdelimiter to "."
   if item -1 of imageURL is "webm" then
      put fedwiki_ConstructVideoHtml (imageURL, pImageCaption, pDescriptionURL, pPosterImageFile) into someHTML
   else
      put fedwiki_ConstructImageHtml (imageURL, pImageCaption, pDescriptionURL, false) into someHTML
   end if
   return someHTML
end wikicommons_ConstructImageOrVideoHtml

function wikicommons_FindImageTag wikiText
   -- put "[[Image:Scheme ant worker anatomy-en.svg|thumb|450px|left|Diagram of a worker ant (''Pachycondyla verenae'')]]" into wikiText
   
   _SetImageTagOffsets wikiText, tagStart, tagEnd
   if the result is true then
      put char tagStart to tagEnd of wikiText into imageTag
      return imageTag
   else
      return empty
   end if
end wikicommons_FindImageTag

function wikicommons_FindFileTag wikiText
   -- put "lafsjdl [[File:Bullant head detail.jpg|thumb|[[Bull ant]] showing the powerful mandibles and the relatively large compound eyes that provide excellent vision]] jlkj" into wikiText
   -- put "[[File:Thefalloftheberlinwall1989.JPG|thumb|left|The [[Berlin Wall#The Fall|fall of the Berlin Wall]] on 9 November 1989. On [[German Unity Day|3 October 1990]], the [[German reunification]] process was formally finished.]]" into wikiText
   
   _SetFileTagOffsets wikiText, tagStart, tagEnd
   if the result is true then
      put char tagStart to tagEnd of wikiText into fileTag
      return fileTag
   else
      return empty
   end if
end wikicommons_FindFileTag

command wikicomons_FetchImageUrls shortImageFile, @imageURL, @descriptionURL, @pImageCaption
   put wikicommons_FetchImageSandboxArray (shortImageFile) into sandboxArray
   --
   put sandboxArray ["query"]["pages"] into pagesArray
   put line 1 of the keys of pagesArray into pageID
   put pagesArray [pageID] into pageArray
   -- put wikicommons_ConstructImageHtml (pageArray, pImageCaption) into imageHTML
   wikicommons_DeconstructPageArray pageArray, pageTitle, imageURL, descriptionURL, pImageCaption
   return pageArray
end wikicomons_FetchImageUrls

command wikicommons_DeconstructFileWikiText imageWikiText, @shortImageFile, @captionBit
   -- [[File:Bullant head detail.jpg|thumb|[[Bull ant]] showing the powerful mandibles and the relatively large compound eyes that provide excellent vision]]
   -- [[File:Thefalloftheberlinwall1989.JPG|thumb|left|The [[Berlin Wall#The Fall|fall of the Berlin Wall]] on 9 November 1989. On [[German Unity Day|3 October 1990]], the [[German reunification]] process was formally finished.]]
   
   delete char 1 to 2 of imageWikiText
   delete char -2 to -1 of imageWikiText
   
   set the itemdelimiter to "|"
   put item -1 of imageWikiText into captionBit
   delete item -1 of imageWikiText
   
   put item 1 of imageWikiText into shortFileBit
   put item 2 of imageWikiText into thumbBit
   put item 3 of imageWikiText into directionBit
   
   set the itemdelimiter to ":"
   put item 2 of shortFileBit into shortImageFile
   
   -- hack
   replace space with "_" in shortImageFile
   --
   return shortFileBit & CR & thumbBit & CR & directionBit
end wikicommons_DeconstructFileWikiText

command wikicommons_DeconstructImageWikiText imageWikiText, @shortImageFile, @captionBit
   -- [[Image:Scheme ant worker anatomy-en.svg|thumb|450px|left|Diagram of a worker ant (''Pachycondyla verenae'')]]
   
   delete char 1 to 2 of imageWikiText
   delete char -2 to -1 of imageWikiText
   
   set the itemdelimiter to "|"
   put item -1 of imageWikiText into captionBit
   delete item -1 of imageWikiText
   
   put item 1 of imageWikiText into shortFileBit
   put item 2 of imageWikiText into thumbBit
   put item 3 of imageWikiText into imageWidth
   put item 4 of imageWikiText into directionBit
   
   set the itemdelimiter to ":"
   put item 2 of shortFileBit into shortImageFile
   
   -- hack
   replace space with "_" in shortImageFile
   --
   return shortFileBit & CR & thumbBit & CR & directionBit
end wikicommons_DeconstructImageWikiText

function wikicommons_FetchImageHtml shortImageFile, pImageCaption
   wikicomons_FetchImageUrls shortImageFile, imageURL, descriptionURL, pImageCaption
   put fedwiki_ConstructImageHtml (imageURL, pImageCaption, descriptionURL, false) into imageHTML
   return imageHTML
end wikicommons_FetchImageHtml

private command wikicommons_AddSandboxToPageArray @fedwikiPageArray, sandboxArray
   put sandboxArray ["query"]["pages"] into pagesArray
   put line 1 of keys (pagesArray) into pageID
   put pagesArray [pageID] into sandPageArray
   
   put sandPageArray ["imageinfo"]["1"]["mime"] into someMime
   wikicommons_AddMediaToPageArray fedwikiPageArray, sandPageArray
   return someMime
end wikicommons_AddSandboxToPageArray

command wikicommons_AddMediaToPageArray @fedwikiPageArray, sandPageArray
   set the itemdelimiter to slash
   switch item 1 of someMime
      case "video"
         wikicommons_AddVideoToPageArray fedwikiPageArray, sandPageArray
         break
      default
         wikicommons_AddImageToPageArray fedwikiPageArray, sandPageArray
   end switch
end wikicommons_AddMediaToPageArray

function wikicommons_ConstructVideoPageArray pageTitle, simplePageDescription, wikipediaUrl, shortImageFile, pSourceArray
   --need to add imagedescription
   put wikicommons_ConstructBasicSummaryPageArray (pageTitle, simplePageDescription, wikipediaUrl, pSourceArray) into fedwikiPageArray
   
   put urlencode (word 1 to -1 of shortImageFile) into shortImageFile
   put wikicommons_FetchImageSandboxArray (shortImageFile) into sandboxArray
   put sandboxArray ["query"]["pages"] into pagesArray
   put line 1 of keys (pagesArray) into pageID
   put pagesArray [pageID] into pageArray
   wikicommons_AddVideoToPageArray fedwikiPageArray, pageArray
   return fedwikiPageArray
end wikicommons_ConstructVideoPageArray

command wikicommons_AddVideoToPageArray @fedwikiPageArray, sandPageArray
   _DeconstructSandVideoArray sandPageArray, videoURL, videoCaption, descriptionURL, thumbURL
   --
   put fedwiki_ConstructVideoHtml (videoURL, videoCaption, descriptionURL, thumbURL) into videoHTML
   fedwiki_AddHtmlToPageArray fedwikiPageArray, videoHTML
end wikicommons_AddVideoToPageArray

command wikicommons_DeconstructPageArray sandPageArray, @imageTitle, @imageURL, @descriptionURL, @pImageCaption
   put pageArray ["title"] into imageTitle
   
   put sandPageArray ["imageinfo"]["1"] into imageInfoArray  -- if there is only one
   put imageInfoArray ["descriptionURL"] into descriptionURL
   put imageInfoArray ["width"] into imageWidth
   put imageInfoArray ["height"] into imageHeight
   put imageInfoArray ["url"] into imageURL
   put imageInfoArray ["mime"] into imageMime
   
   -- let's use thumbURL for embeding fedwiki images
   put imageInfoArray ["thumburl"] into thumbURL
   put imageInfoArray ["thumbwidth"] into thumbWidth
   -- put imageInfoArray ["thumbheight"] into thumbHeight
   -- put imageInfoArray ["thumbmime"] into thumbMime
   if thumbWidth > 400 and imageMime is not "video/webm" then
      put thumbURL into imageURL
   end if
   
   if pImageCaption is empty then
      put imageInfoArray ["extmetadata"]["imageDescription"]["value"] into pImageCaption
   end if
end wikicommons_DeconstructPageArray

function wikicommons_ConstructVideoCaption pageTitle, descriptionURL   
   put "<br></br>" into someHTML
   put html_ConstructRefLink (pageTitle, descriptionURL, "_blank") after someHTML 
   return someHTML
end wikicommons_ConstructVideoCaption


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


--> Fedwiki | Mediawiki | Image
-
function wikicommons_FetchImagePageJson shortImageFile
   -- just HTML version
   put wikicommons_FetchImagePageArray (shortImageFile, true) into pageArray
   put json_FromArray (pageArray) into pageJSON
   return pageJSON
end wikicommons_FetchImagePageJson

function wikicommons_FetchImagePageArray shortImageFile, pApiStem 
   put wikicommons_FetchImageSandboxArray (shortImageFile) into sandboxArray
   put wikicommons_ConstructImagePageArray (sandboxArray) into pageArray
   return pageArray
end wikicommons_FetchImagePageArray

private function wikicommons_ConstructImagePageArray sandboxArray, pPageTitle, pPageComment
   if pPageTitle is empty then put "Wikpedia Image Import" into pageTitle
   
   put sandboxArray ["query"]["pages"] into pagesArray
   put line 1 of keys (pagesArray) into pageID
   put pagesArray [pageID] into pageArray
   
   put pageArray ["imageinfo"]["1"]["mime"] into someMime
   set the itemdelimiter to slash
   switch item 1 of someMime
      case "video"
         if pPageComment is empty then put "Here is an video from Wikipedia ready to drag onto your page..." into pPageComment
         put fedwiki_ConstructNewPageArray (pageTitle, pPageComment) into fedwikiPageArray
         break
      default
         -- we assume it is an image
         if pPageComment is empty then put "Here is an image from Wikipedia ready to drag onto your page..." into pPageComment
         put fedwiki_ConstructNewPageArray (pageTitle, pPageComment) into fedwikiPageArray
   end switch
   
   wikicommons_AddSandboxToPageArray fedwikiPageArray, sandboxArray
   return fedwikiPageArray
end wikicommons_ConstructImagePageArray


--> Wiki Commons | Two Images
-
function wikicommons_FetchBasicTwoImagePageArray shortImageFile, pPageTitle, pSomeText, pApiRoot
   if pPageTitle is empty then put "Wikimedia Image" into pPageTitle
   if pSomeText is empty then put "Drag these images to your source page..." into pSomeText
   
   put fedwiki_ConstructPageArray (pPageTitle, pSomeText) into fedwikiPageArray   
   set the itemdelimiter to "."
   if item -1 of shortImageFile is "webm" then
      put wikicommons_ConstructVideoPageArray (pPageTitle, simplePageDescription, wikipediaUrl, shortImageFile, pSourceArray) into fedwikiPageArray
   else
      wikicommons_FetchAndAddTwoImages fedwikiPageArray, shortImageFile, pApiRoot
   end if
   fedwiki_StripJournalToCreate fedwikiPageArray
   return fedwikiPageArray
end wikicommons_FetchBasicTwoImagePageArray


--> WikiCommons | Media | PageArray
-
command wikicommons_AddImageToPageArray @fedwikiPageArray, sandPageArray
   put wikicommons_ConstructImageHtml (sandPageArray) into imageHTML
   fedwiki_AddHtmlToPageArray fedwikiPageArray, imageHTML
end wikicommons_AddImageToPageArray

function wikicommons_ConstructImageHtml pageArray, pImageCaption, pWikimediaLink
   wikicommons_DeconstructPageArray pageArray, pageTitle, imageURL, descriptionURL, pImageCaption
   put fedwiki_ConstructImageHtml (imageURL, pImageCaption, descriptionURL, false) into imageHTML
   return imageHTML
end wikicommons_ConstructImageHtml


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

private command _AddImageToPageArray @fedwikiPageArray, wikisectionLine
   put wikicommons_FindImageTag (wikisectionLine) into imageTag
   wikicommons_DeconstructImageWikiText imageTag, shortImageFile, captionBit
   
   _AddMediaToPageArray fedwikiPageArray, shortImageFile, captionBit
   return shortImageFile
end _AddImageToPageArray

private command _AddMediaToPageArray @fedwikiPageArray, shortImageFile, pCaptionBit
   wikicomons_FetchImageUrls shortImageFile, imageURL, descriptionURL, pCaptionBit
   put wikicommons_ConstructImageOrVideoHtml (imageURL, pCaptionBit, descriptionURL) into imageHTML
   fedwiki_AddHtmlToPageArray fedwikiPageArray, imageHTML
   return imageHTML
end _AddMediaToPageArray

private command _SetImageTagOffsets wikiText, @tagStart, @tagEnd
   put "(\[\[Image:.+\]\])" into someReg -- let's be greedy
   put matchchunk (wikiText, someReg, tagStart, tagEnd) into someBoolean
   return someBoolean
end _SetImageTagOffsets

private command _SetFileTagOffsets wikiText, @tagStart, @tagEnd
   put "(\[\[File:.+\]\])" into someReg -- let's be greedy
   put matchchunk (wikiText, someReg, tagStart, tagEnd) into someBoolean
   return someBoolean
end _SetFileTagOffsets

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

private command _DeconstructSandVideoArray sandPageArray, @videoURL, @videoCaption, @descriptionURL, @thumbURL
   put sandPageArray ["imageinfo"]["1"] into imageInfoArray  -- assume there is only one
   --
   put imageInfoArray ["mime"] into imageMime
   if imageMime is not "video/webm" then
      return false
   end if
   
   put imageInfoArray ["url"] into videoURL
   put imageInfoArray ["thumburl"] into thumbURL
   put imageInfoArray ["extmetadata"]["imageDescription"]["value"] into videoCaption
   
   put imageInfoArray ["descriptionURL"] into descriptionURL
   
   /*
   put imageInfoArray ["width"] into imageWidth
   put imageInfoArray ["height"] into imageHeight
   put imageInfoArray ["thumbwidth"] into thumbWidth
   put imageInfoArray ["thumbheight"] into thumbHeight
   put imageInfoArray ["thumbmime"] into thumbMime
   */
   return true
end _DeconstructSandVideoArray

function fedwiki_ConstructVideoHtml webmURL, videoCaption, pDescriptionURL, pPosterImageFile
   -- put "MP4 (HD),mp4,WEBM (HD),webm" into videoTypes
   if pDescriptionURL is empty then put webmURL into pDescriptionURL
   put html_ConstructVideoTag (webmURL, "webm", 420, true, pPosterImageFile) into videoHTML
   put wikicommons_ConstructVideoCaption (videoCaption, pDescriptionURL) after videoHTML
   return videoHTML
end fedwiki_ConstructVideoHtml

function html_ConstructVideoTag videoURL, pMediaType, pVideoWidth, pShowControls, pPosterImageFile, pFallbackHtml
   -- this is a single source video tag
   if pFallbackHtml is empty then put "This is fallback content to display for user agents that do not support the video tag." into pFallbackHtml
   
   put "<video" into someHTML
   put space & "src=" & quote & videoURL & quote after someHTML
   switch word 1 of pMediaType
      case "webm"
         put space & "type='video/webm'" after someHTML
         break
      case "mp4"
         put  space & "type='video/mp4'" after someHTML
   end switch
   
   if pVideoWidth is not empty then put space & "width=" & quote & pVideoWidth & quote after someHTML
   if pShowControls is not false then put space & "controls" after someHTML
   if pPosterImageFile is not empty then put space & "poster=" & quote & pPosterImageFile & quote after someHTML
   put ">" after someHTML
   
   put pFallbackHtml after someHTML
   put "</video>" after someHTML
   
   return someHTML
end html_ConstructVideoTag


--> Deps
-
function html_ConstructOpenVideoTag pVideoWidth, pShowControls, pPosterImageFile
   -- this constructs an opening video tag
   put "<video" into someHTML
   if pPosterImageFile is not empty then put space & "poster=" & quote & pPosterImageFile & quote after someHTML
   if pVideoWidth is not empty then put space & "width=" & quote & pVideoWidth & quote after someHTML
   if pShowControls is not false then put space & "controls" after someHTML
   put ">" after someHTML
   return someHTML
end html_ConstructOpenVideoTag

function html_ConstructVideoSourceTag videoURL, pMediaType
   -- multiple source video tag
   -- should enhance to extract pMediaType from file extension
   put "<source src=" & quote & videoURL & quote into someHTML
   switch pMediaType
      case "webm"
         put space & "type='video/webm" after someHTML
         break
      case "mp4"
         put  space & "type='video/mp4" after someHTML
   end switch
   -- maybe add codecs?
   put ">" after someHTML
   return someHTML
end html_ConstructVideoSourceTag
