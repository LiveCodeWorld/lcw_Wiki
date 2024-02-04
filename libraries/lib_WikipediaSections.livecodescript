script "lib_WikipediaSections"
--> MetaData
-
license: GPLv3
name: lib_WikipediaSections
type: library
version: 0.1

/*
Used by importSection.

This is the old way of doing things.

function fedwikipedia_FetchSandboxSectionText pageTitle, sectionNum
   -- not used
   put sandbox_FetchSectionArray (pageTitle, sectionNum) into sandboxArray
   put sandboxArray ["parse"] into parseArray
   put parseArray ["wikitext"]["*"] into sectionWikiText
   return sectionWikiText
end fedwikipedia_FetchSandboxSectionText
*/

--> Working on
-
command _AddTocFromSectionTitle @pageArray, pageSlug, sectionTitle, subSectionArray, sectionNum
   if subSectionArray is not an array then return false
   put item 2 of the extents of subsectionArray into maxNum
   if maxNum < 2 then return false
   
   pageArray_AddMarkdown pageArray, "# Sections"
   -- _AddTocToPageArray pageArray, pageSlug, subsectionArray, tocArray
   repeat with indexNum = 2 to maxNum
      put subsectionArray [indexNum]["line"] into sectionTitle
      replace "<i>" with empty in sectionTitle
      replace "</i>" with empty in sectionTitle
      --
      put sectionNum + subsectionArray [indexNum]["index"] - 1 into subSectionNum
      put wikicommons_ConstructSectionForm (pageSlug, subSectionNum, sectionTitle) into formHTML
      pageArray_AddHtml pageArray, formHTML
   end repeat
end _AddTocFromSectionTitle


--> wikicommons | SectionPageArray
-
function wikicommons_ConstructSectionPageArray pageSlug, sectionNum, pApiStem, pNewSectionTitle, pFirstSectionOnly, pSourceArray
   put pFirstSectionOnly is not false into pFirstSectionOnly
   if pApiStem is empty then put "https://en.wikipedia.org" into pApiStem
   
   # Info
   put sandbox_FetchSectionArray (pageSlug, sectionNum, pApiStem) into sandboxArray
   put sandboxArray ["parse"] into parseArray
   put parseArray ["title"] into pageTitle
   put parseArray ["wikitext"]["*"] into sectionWikiText
   
   # Original section titleo
   put parseArray ["sections"][1] into sectionInfoArray
   put sectionInfoArray ["line"] into sectionTitle
   -- replace "<i>" with empty in sectionTitle
   -- replace "</i>" with empty in sectionTitle
   
   # Construct wikipediaURL section link
   put _ConstructWikipediaURL (pageSlug, sectionTitle, pApiStem) into wikipediaURL
   
   # What images are in section 
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
   
   # Start constructing pageArray
   put sectionTitle into pageArray ["title"]
   put journalArray_Construct (sectionTitle, pSourceArray) into pageArray ["journal"]
   
   # Remove section title and put it at the end in case needed
   delete line 1 of sectionWikiText -- == sectionTitle ==
   
   wikicommons_AddSectionToPageArray pageArray, sectionWikiText, pFirstSectionOnly
   
   # Add some utility tools
   put pageTitle && sectionTitle into seachWords
   fedwiki_AddTools pageArray, seachWords
   
   # Add "# Sections"
   put parseArray ["sections"] into sectionArray
   _AddTocFromSectionTitle pageArray, pageSlug, sectionTitle, sectionArray, sectionNum
   
   -- add draggable markDownTitles
   if pNewSectionTitle is empty then
      put sectionTitle into pNewSectionTitle
   end if
   put "#" && pNewSectionTitle into markDownTitle
   pageArray_AddMarkdown pageArray, markDownTitle
   put "- [[" & pNewSectionTitle & "]]" into markDownTitle
   pageArray_AddMarkdown pageArray, markDownTitle
   
   # Move first image to second paragraph
   fedwiki_MakeTextParagraphFirst pageArray -- in case image is first
   wikicommons_MoveImage pageArray, 2
   
   # Add link back to wikipedia
   fedwiki_AddExternalLinkToFirstSection pageArray, wikipediaURL
   
   # Strip journal
   pageArray_StripJournal pageArray
   return pageArray
end wikicommons_ConstructSectionPageArray

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

function wikicommons_ConstructSectionForm pageSlug, sectionNum, sectionTitle, pSize
   if pSize is empty then put 42 into pSize
   --
   put merge ("<form action='http://rest.livecode.world/mediawiki/importSection'><input name=section_title size=[[pSize]] value='[[sectionTitle]]'>") into formTemplate
   put CR & "<input name=url type=hidden value='https://en.wikipedia.org/w/index.php?title=[[pageSlug]]&action=edit&section=[[sectionNum]]'>" after formTemplate
   put CR & "<input type=submit value=create></form>" after formTemplate
   replace "'" with quote in formTemplate
   --
   put merge (formTemplate) into formHTML
   return formHTML
end wikicommons_ConstructSectionForm

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

function wikicommons_FetchSubSectionMarkdown sectionTitle, pageSlug
   local subsectionInfoArray, subsectionArray
   wikicommons_ConstructSubSectionArrays sectionTitle, tocArray, subsectionInfoArray, subsectionArray
   
   put item 2 of the extents of subsectionArray into maxNum
   repeat with indexNum = 1 to maxNum
      put subsectionArray [indexNum]["info"]["html"] into subSectionTitle
      put "- [[" & subSectionTitle & "]]" & CR after tocSectionMarkdown
   end repeat
   delete char -1 of tocSectionMarkdown
   return tocSectionMarkdown
end wikicommons_FetchSubSectionMarkdown

function wikicommons_FetchSubSectionTitles sectionTitle, pageTitle
   local subsectionInfoArray, subsectionArray
   wikicommons_ConstructSubSectionArrays sectionTitle, tocArray, subsectionInfoArray, subsectionArray
   
   put item 2 of the extents of subsectionArray into maxNum
   repeat with indexNum = 1 to maxNum
      put subsectionArray [indexNum]["info"]["html"] into subSectionTitle
      put subSectionTitle & CR after subSectionTitles
   end repeat
   delete char -1 of subSectionTitles
   return subSectionTitles
end wikicommons_FetchSubSectionTitles



--> FedWikipedia | Section | Summary
-
function fedwikipedia_FetchSectionSummaryPageJson pageSlug, sectionNum, pSourceArray
   -- used also by transportAgain
   put fedwikipedia_FetchSectionSummaryPageArray (pageSlug, sectionNum, pSourceArray) into pageArray
   put json_FromArray (pageArray) into pageJSON
   return pageJSON
end fedwikipedia_FetchSectionSummaryPageJson

function fedwikipedia_FetchSectionSummaryPageArray pageSlug, sectionNum
   -- see also "fedwiki_FetchWikipediaSummaryPageArray"
   -- need to make a "query" call to get a nice clean text
   -- this will fetch all the nested text into sectionDescription which can be to long.
   local sectionTocArray, sectionTitle, lookUpArray, sectionTOC
   
   _FetchAndDeconstructSectionQuery pageSlug, sectionNum, sectionDescription, pageTitle, shortImageFile, sectionArray, wikipediaRevisionID
   put the result into sandboxArray
   fedwikipedia_ConstructSectionTocArray sectionArray, sectionNum, sectionTocArray, sectionTitle
   --
   if sectionTitle = "See also" then
      /*
      ==See also==
      *[[Appointment (disambiguation)]]
      *[[Etienne Chouard]]
      */
      
      put pageArray_Construct (pageTitle) into pageArray
      --
      pageArray_AddMarkdown pageArray, "# See also"
      put sectionDescription into markdownSection
      delete line 1 of markdownSection
      replace "*[[" with "- [[" in markdownSection -- quick hack
      pageArray_AddMarkdown pageArray, markdownSection
   else
      put sectionTocArray ["index"][sectionTitle]["dot_number"] into dotNum
      toc_LookupArrayFromDotNum sectionTocArray, dotNum, lookUpArray, sectionTOC
      --
      put wikipedia_ConstructUrl (pageSlug, sectionTitle) into wikipediaUrl
      put fedwikipedia_ConstructSourceArray (pageTitle, pageSlug, wikipediaUrl, wikipediaRevisionID, lookUpArray) into pSourceArray
      
      # Construct the page
      put fedwikipedia_SplitSectionDescription (pageTitle, shortImageFile, sectionDescription, sectionTocArray) into sectionIntro
      put wikicommons_ConstructTwoImagePageArray (sectionTitle, sectionIntro, shortImageFile, wikipediaUrl, pSourceArray) into pageArray
      
      if sectionTOC is not empty then
         put "# See also" into markdownSection
         -- put CR & sectionTOC after markdownSection
         put CR & sectionDescription after markdownSection
         pageArray_AddMarkdown pageArray, markdownSection
      end if
   end if
   
   pageArray_StripJournal pageArray
   return pageArray
end fedwikipedia_FetchSectionSummaryPageArray


--> FedWikipedia | TOC
-
function mediawiki_FetchMarkdownTOC pageSlug
   mediawiki_FetchPageParseInfo pageSlug, pageDescription, pageTitle, shortImageFile, infoBoxArray
   put the result into sandboxArray
   put fedwikipedia_ConstructPageTocArray (sandboxArray) into tocArray
   fedwikipedia_ConstructTocLookupArray tocArray, lookUpArray, markdownTOC
   return markdownTOC
end mediawiki_FetchMarkdownTOC

command fedwikipedia_ConstructTocLookupArray tocArray, @lookUpArray, @markdownTOC, pAddAll
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
end fedwikipedia_ConstructTocLookupArray


--> Private
-
private command toc_LookupArrayFromDotNum tocArray, dotNum, @lookUpArray, @markdownTOC
   -- used by "fedwikipedia_FetchSectionSummaryPageArray"
   split dotNum by "."
   put tocArray [dotNum] into sectionTocArray
   delete variable sectionTocArray ["meta"]
   fedwikipedia_ConstructTocLookupArray sectionTocArray, lookUpArray, markdownTOC
end toc_LookupArrayFromDotNum

private command fedwikipedia_ConstructSectionTocArray sectionArray, sectionNum, @sectionTocArray, @sectionTitle
   -- see similar "fedwikipedia_ConstructPageTocArray"
   put sectionArray [1]["fromTitle"] into tocTitle
   put sectionArray [1]["line"] into sectionTitle
   
   put item 2 of the extents of sectionArray into maxNum
   set the itemdelimiter to "."
   repeat with itemNum = 2 to maxNum
      put sectionArray [itemNum]["line"] into tocLine
      put sectionArray [itemNum]["number"] into tocNumber
      put sectionArray [itemNum]["level"] into tocLevel
      
      delete item 1 of tocNumber
      put itemNum - 1 + sectionNum into tocNum
      
      put tocNumber into sectionTocArray ["index"][tocLine]["dot_number"]
      put tocNum into sectionTocArray ["index"][tocLine]["section_number"]
      put tocLevel into sectionTocArray ["index"][tocLine]["section_level"]
      
      put tocNumber into dotKeyArray
      split dotKeyArray by "."
      put tocLine into sectionTocArray [dotKeyArray]["meta"]["title"]
      put tocNumber into sectionTocArray [dotKeyArray]["meta"]["dot_number"]
      put tocNum into sectionTocArray [dotKeyArray]["meta"]["section_number"]
      put tocLevel into sectionTocArray [dotKeyArray]["meta"]["section_level"]
   end repeat
   return sectionTocArray
end fedwikipedia_ConstructSectionTocArray

private function fedwikipedia_SplitSectionDescription pageTitle, shortImageFile, sectionDescription, sectionTocArray
   -- strip the top bit including sectionTitle and intro image
   
   put sectionTocArray [1]["meta"]["title"] into firstSectionTitle
   
   if firstSectionTitle is empty then
      -- should not be???
      
      put word 1 to -1 of sectionDescription into sectionIntro
      
      /*
      ==See also==
      *[[Appointment (disambiguation)]]
      *[[Etienne Chouard]]
      */
      replace "*[[" with "- [[" in sectionIntro -- quick hack
   else
      put sectionTocArray [1]["meta"]["section_level"] into toclevel
      repeat toclevel
         put "=" after titleBit
      end repeat
      put titleBit & firstSectionTitle & titleBit into testLine
      -- return testLine & CR & sectionDescription
      
      -- set the wholematches to true -- bug in server (seems not to match CR)
      put lineOffset (testLine, sectionDescription) into lineNum
      -- return lineNum
      
      if lineNum = 0 then
         put sectionDescription into sectionIntro
      else
         put line 1 to (lineNum - 1) of sectionDescription into sectionIntro
      end if
   end if
   
   replace "_" with space in shortImageFile -- why is it encoded like this?
   repeat -- let's just strip all templates and headers until we get normal text?
      switch
         case char 1 of sectionIntro is among the chars of "{="
            delete line 1 of sectionIntro
            break
         case line 1 of sectionIntro begins with ("[[File:" & shortImageFile)
            delete line 1 of sectionIntro
            break
         case sectionIntro is empty
            put "No section text, so add your own here..." into sectionIntro
            exit repeat
            break
         case line 1 of sectionIntro is empty
            delete line 1 of sectionIntro
            break
         default
            exit repeat
      end switch
   end repeat
   
   return sectionIntro
end fedwikipedia_SplitSectionDescription


--> Private
-
command _AddTocToPageArray @pageArray, pageSlug, subsectionArray, tocArray
   put item 2 of the extents of subsectionArray into maxNum
   repeat with indexNum = 1 to maxNum
      put subsectionArray [indexNum]["info"] into sectionInfoArray
      _DeconstructSectionInfoArray sectionInfoArray, sectionTitle, sectionSlug, sectionNum, dotNumber, sectionLevel
      
      put wikicommons_ConstructSectionForm (pageSlug, sectionNum, sectionTitle) into formHTML
      pageArray_AddHtml pageArray, formHTML
   end repeat
end _AddTocToPageArray

private command _FetchAndDeconstructSectionQuery pageSlug, sectionNum, @sectionDescription, @pageTitle, @shortImageFile, @sectionArray, @wikipediaRevisionID
   put sandbox_FetchSectionArray (pageSlug, sectionNum) into sandboxArray
   sandbox_DeconstructSectionArray sandboxArray, pageTitle, sectionDescription, imageArray, sectionArray, wikipediaRevisionID
   put mediawiki_ExtractFirstInterestingImage (imageArray) into shortImageFile
   return sandboxArray
end _FetchAndDeconstructSectionQuery

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

command _DeconstructSectionInfoArray sectionInfoArray, @sectionTitle, @pageSlug, @sectionNum, @dotNumber, @sectionLevel
   put sectionInfoArray ["html"] into sectionTitle
   put sectionInfoArray ["anchor"] into pageSlug
   
   put sectionInfoArray ["section"] into sectionNum
   put sectionInfoArray ["number"] into dotNumber
   put sectionInfoArray ["level"] into sectionLevel
end _DeconstructSectionInfoArray
