script "lib_WikiVideo"
--> MetaData
-
license: GPLv3
name: lib_WikiVideo
type: library
version: 0.1

/*
Here we start to organise and collect handlers that work with video in wiki. 
We start with video on commons.wikimedia.org
*/


--> PageArray
-
command pageArray_AddMedia @pageArray, imageURL, pImageCaption, pDescriptionURL
   set the itemdelimiter to "."
   if item -1 of imageURL is "webm" then
      wikicommons_AddVideoToPageArray pageArray, shortMediaFile
   else
      put fedwiki_ConstructImageHtml (imageURL, pCaption, pCaptionLinkURL, pLinkToImage) into imageHTML
      pageArray_AddHtml pageArray, imageHTML
   end if
   return someHTML
end pageArray_AddMedia


--> Wikicommons | Meida | Construct
-
function wikicommons_ConstructImageHtml sandPageArray, pImageCaption, pWikimediaLink
   _DeconstructSandMediaArray sandPageArray, pageTitle, mediaURL, pImageCaption, descriptionURL, thumbURL
   put fedwiki_ConstructImageHtml (mediaURL, pImageCaption, descriptionURL, false) into imageHTML
   return imageHTML
end wikicommons_ConstructImageHtml

function wikicommons_ConstructVideoPageArray pageTitle, simplePageDescription, wikipediaUrl, shortVideoFile, pSourceArray
   put wikicommons_ConstructBasicSummaryPageArray (pageTitle, simplePageDescription, wikipediaUrl, pSourceArray) into pageArray
   wikicommons_AddVideoToPageArray pageArray, shortVideoFile
   pageArray_CleanJournal pageArray
   return pageArray
end wikicommons_ConstructVideoPageArray

function wikicommons_ConstructAudioPageArray pageTitle, simplePageDescription, wikipediaUrl, shortAudioFile, pSourceArray
   put wikicommons_ConstructBasicSummaryPageArray (pageTitle, simplePageDescription, wikipediaUrl, pSourceArray) into pageArray
   wikicommons_AddAudioToPageArray pageArray, shortAudioFile
   put the result into audioCaption
   pageArray_AddMarkdown pageArray, audioCaption
   pageArray_CleanJournal pageArray
   return pageArray
end wikicommons_ConstructAudioPageArray


--> Wikicommons | Add
-
command wikicommons_AddAudioToPageArray @pageArray, shortAudioFile, pMediaCaption, pApiStem
   local pageTitle, mediaURL, descriptionURL, thumbURL
   --
   put wikicommons_FetchImageSandboxArray (shortAudioFile, pApiStem) into sandboxArray
   put _GetSandPageArray (sandboxArray) into sandPageArray
   _DeconstructSandMediaArray sandPageArray, pageTitle, mediaURL, pMediaCaption, descriptionURL, thumbURL
   put word 1 of the result into someCodec
   if someCodec = "ogg" then
      fedwiki_AddExternalLink pMediaCaption, descriptionURL
      pageArray_AddAudio pageArray, mediaURL, pMediaCaption
      return pMediaCaption
   else
      return empty
   end if
end wikicommons_AddAudioToPageArray

command wikicommons_AddVideoToPageArray @pageArray, shortVideoFile, pMediaCaption, pApiStem
   local pageTitle, mediaURL, descriptionURL, thumbURL
   --
   put wikicommons_FetchImageSandboxArray (shortVideoFile, pApiStem) into sandboxArray
   put _GetSandPageArray (sandboxArray) into sandPageArray
   _DeconstructSandMediaArray sandPageArray, pageTitle, mediaURL, pMediaCaption, descriptionURL, thumbURL
   put the result into videoLine
   --
   fedwiki_AddExternalLink pMediaCaption, descriptionURL
   pageArray_AddVideo pageArray, videoLine, "HTML5", pMediaCaption
   return sandPageArray
end wikicommons_AddVideoToPageArray

command wikicommons_AddImageToPageArray @pageArray, sandPageArray
   put wikicommons_ConstructImageHtml (sandPageArray) into imageHTML
   pageArray_AddHtml pageArray, imageHTML
end wikicommons_AddImageToPageArray

command wikicommons_AddMediaToPageArray @pageArray, shortMediaFile, pMediaCaption, pApiStem
   put wikicommons_FetchImageSandboxArray (shortMediaFile, pApiStem) into sandboxArray
   put _GetSandPageArray (sandboxArray) into sandPageArray
   put sandPageArray ["imageinfo"]["1"]["mime"] into someMime
   --
   set the itemdelimiter to slash
   switch item 1 of someMime
      case "video"
         wikicommons_AddVideoToPageArray pageArray, shortMediaFile, pMediaCaption, pApiStem
         break
      default
         -- we assume it is an image
         _DeconstructSandMediaArray sandPageArray, pageTitle, mediaURL, pMediaCaption, descriptionURL, thumbURL
         put fedwiki_ConstructImageHtml (mediaURL, pMediaCaption, descriptionURL) into imageHTML
         pageArray_AddHtml pageArray, imageHTML
   end switch
end wikicommons_AddMediaToPageArray


--> Wikicommons | Media | Fetch
-
function wikicommons_FetchImageHtml shortImageFile, pImageCaption, pApiStem
   put wikicommons_FetchImageSandboxArray (shortImageFile, pApiStem) into sandboxArray
   _DeconstructSandMediaArray sandPageArray, pageTitle, mediaURL, pImageCaption, descriptionURL, thumbURL
   put fedwiki_ConstructImageHtml (mediaURL, pImageCaption, descriptionURL, false) into imageHTML
   return imageHTML
end wikicommons_FetchImageHtml

function wikicommons_FetchImagePageJson shortImageFile, pPageTitle, pPageComment, pApiStem
   put wikicommons_FetchImagePageArray (shortImageFile, pPageTitle, pPageComment, pApiStem) into pageArray
   put json_FromArray (pageArray) into pageJSON
   return pageJSON
end wikicommons_FetchImagePageJson

function wikicommons_FetchImagePageArray shortImageFile, pPageTitle, pPageComment, pApiStem
   if pPageTitle is empty then put "Wikpedia Image Import" into pageTitle
   --
   put wikicommons_FetchImageSandboxArray (shortImageFile, pApiStem) into sandboxArray
   put sandboxArray ["query"]["pages"] into queryPagesArray
   put line 1 of keys (queryPagesArray) into pageID
   put queryPagesArray [pageID] into sandPageArray
   put sandPageArray ["imageinfo"]["1"]["mime"] into someMime
   
   set the itemdelimiter to slash
   switch item 1 of someMime
      case "video"
         if pPageComment is empty then put "Here is an video from Wikipedia ready to drag onto your page..." into pPageComment
         put fedwiki_ConstructNewPageArray (pageTitle, pPageComment) into pageArray
         --
         _DeconstructSandMediaArray sandPageArray, pageTitle, mediaURL, mediaCaption, descriptionURL, thumbURL
         put the result into videoLine
         fedwiki_AddExternalLink mediaCaption, descriptionURL
         pageArray_AddVideo pageArray, videoLine, "HTML5", mediaCaption
         break
      default
         if pPageComment is empty then put "Here is an image from Wikipedia ready to drag onto your page..." into pPageComment
         put fedwiki_ConstructNewPageArray (pageTitle, pPageComment) into pageArray
         wikicommons_AddImageToPageArray pageArray, sandPageArray
   end switch
   return pageArray
end wikicommons_FetchImagePageArray

command wikicommons_AddSectionToPageArray @pageArray, wikiText, pFirstSectionOnly, pApiStem
   -- ugly and complicated. Refactor!
   local firstSection, addedImages,markDownBulletSection
   --
   fedwikipedia_CleanWikiText wikiText
   put 0 into lineNum
   set the wholematches to true
   repeat for each line wikisectionLine in wikiText
      add 1 to lineNum
      put word 1 to - 1 of wikisectionLine into wikisectionLine
      switch
         case wikisectionLine is empty
            next repeat
         case char 1 to 8 of wikisectionLine = "[[Image:"
            put _FindImageTag (wikisectionLine) into imageTag
            wikicommons_DeconstructImageWikiText imageTag, shortImageFile, captionBit
            if shortImageFile is not among the lines of addedImages then
               wikicommons_AddMediaToPageArray pageArray, shortImageFile, captionBit, pApiStem
               put shortImageFile & CR after addedImages
            end if
            break
         case char 1 to 7 of wikisectionLine = "[[File:"
            put _FindFileTag (wikisectionLine) into fileTag
            wikicommons_DeconstructFileWikiText fileTag, shortMediaFile, captionBit
            if shortMediaFile is not among the lines of addedImages then
               wikicommons_AddMediaToPageArray pageArray, shortMediaFile, captionBit, pApiStem
               put shortMediaFile & CR after addedImages
            end if
            break
         case char 1 to 2 of wikisectionLine = "* "
            put "-" into char 1 of wikisectionLine
            put wikisectionLine & CR after markDownBulletSection
            next repeat
         case markDownBulletSection is not empty
            delete char -1 of markDownBulletSection
            pageArray_AddMarkdown pageArray, markDownBulletSection
            put empty into markDownBulletSection
            break
         case char 1 of wikisectionLine = "<"
            fedwikipedia_CleanInternalLinks wikiSectionLine
            pageArray_AddHtml pageArray, wikisectionLine
            break
         case char 1 of wikisectionLine = "=" and char -1 of wikisectionLine = "="
            if pFirstSectionOnly is true then
               exit repeat
            end if
            mediawiki_ConvertSectionTitle wikisectionLine
            pageArray_AddMarkdown pageArray, wikisectionLine
            break
         default
            -- we use markdown now instead of text
            fedwikipedia_CleanInternalLinks wikiSectionLine
            pageArray_AddMarkdown pageArray, wikisectionLine
            break
      end switch
   end repeat
   
   if markDownBulletSection is not empty then
      -- exitted without adding markDownBulletSection
      delete char -1 of markDownBulletSection
      pageArray_AddMarkdown pageArray, markDownBulletSection
   end if
   
   delete char -1 of addedImages
   return addedImages
end wikicommons_AddSectionToPageArray


--> Private
-
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

private function _FindImageTag wikiText
   -- put "[[Image:Scheme ant worker anatomy-en.svg|thumb|450px|left|Diagram of a worker ant (''Pachycondyla verenae'')]]" into wikiText
   
   _SetImageTagOffsets wikiText, tagStart, tagEnd
   if the result is true then
      put char tagStart to tagEnd of wikiText into imageTag
      return imageTag
   else
      return empty
   end if
end _FindImageTag

private function _FindFileTag wikiText
   -- put "lafsjdl [[File:Bullant head detail.jpg|thumb|[[Bull ant]] showing the powerful mandibles and the relatively large compound eyes that provide excellent vision]] jlkj" into wikiText
   -- put "[[File:Thefalloftheberlinwall1989.JPG|thumb|left|The [[Berlin Wall#The Fall|fall of the Berlin Wall]] on 9 November 1989. On [[German Unity Day|3 October 1990]], the [[German reunification]] process was formally finished.]]" into wikiText
   
   _SetFileTagOffsets wikiText, tagStart, tagEnd
   if the result is true then
      put char tagStart to tagEnd of wikiText into fileTag
      return fileTag
   else
      return empty
   end if
end _FindFileTag

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

private function _GetSandPageArray sandboxArray
   put sandboxArray ["query"]["pages"] into pagesArray
   put line 1 of keys (pagesArray) into pageID
   put pagesArray [pageID] into sandPageArray
   return sandPageArray
end _GetSandPageArray

private command _DeconstructSandMediaArray sandPageArray, @pageTitle, @mediaURL, @mediaCaption, @descriptionURL, @thumbURL
   -- take first value
   put sandPageArray ["title"] into pageTitle
   put sandPageArray ["imageinfo"]["1"] into imageInfoArray
   put imageInfoArray ["mime"] into imageMime
   --
   /*
   put imageInfoArray ["width"] into imageWidth
   put imageInfoArray ["height"] into imageHeight
   put imageInfoArray ["thumbwidth"] into thumbWidth
   put imageInfoArray ["thumbheight"] into thumbHeight
   put imageInfoArray ["thumbmime"] into thumbMime
   */
   put imageInfoArray ["descriptionURL"] into descriptionURL
   put imageInfoArray ["width"] into imageWidth
   put imageInfoArray ["height"] into imageHeight
   put imageInfoArray ["url"] into mediaURL
   
   put imageInfoArray ["mime"] into someMime
   --
   if mediaCaption is empty then
      put imageInfoArray ["comment"] into someComment
      if someMime = "application/ogg" then
         put someComment into mediaCaption
      else
         put imageInfoArray ["extmetadata"]["imageDescription"]["value"] into mediaCaptionHtml
         put word 1 to -1 of replacetext (mediaCaptionHtml, "(<(.|\n)+?>)", empty) into mediaCaption
      end if
   end if
   --
   switch someMime
      case "application/ogg"
      case "video/webm"
         if descriptionURL is empty then put mediaURL into descriptionURL
         set the itemdelimiter to slash
         put item 2 of someMime into videoCodec
         put videoCodec && mediaURL into videoLine
         return videoLine
      default
         -- assume it is an image
         put imageInfoArray ["thumburl"] into thumbURL
         put imageInfoArray ["thumbwidth"] into thumbWidth 
         if thumbWidth > 400 and imageMime is not "video/webm" then
            put thumbURL into mediaURL
         end if
         return empty
   end switch
end _DeconstructSandMediaArray


--> Deps
-
