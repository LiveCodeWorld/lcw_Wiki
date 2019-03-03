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
*/

--> Working on
-
function fedwikipedia_FetchSandboxSectionText pageTitle, sectionNum
   put sandbox_FetchSectionArray (pageTitle, sectionNum) into sandboxArray
   put sandboxArray ["parse"] into parseArray
   put parseArray ["wikitext"]["*"] into sectionWikiText
   return sectionWikiText
end fedwikipedia_FetchSandboxSectionText


--> FedWikipedia | Section | Summary
-
function fedwikipedia_FetchSectionSummaryPageJson pageSlug, sectionNum, pSourceArray
   -- used also by transportAgain
   put fedwikipedia_FetchSectionSummaryPageArray (pageSlug, sectionNum, pSourceArray) into fedwikiPageArray
   put json_FromArray (fedwikiPageArray) into pageJSON
   return pageJSON
end fedwikipedia_FetchSectionSummaryPageJson

function fedwikipedia_FetchSectionSummaryPageArray pageSlug, sectionNum
   -- see also "fedwiki_FetchWikipediaSummaryPageArray"
   -- need to make a "query" call to get a nice clean text
   -- this will fetch all the nested text into sectionDescription which can be to long.
   local sectionTocArray, sectionTitle, lookUpArray, sectionTOC
   
   fedwikipedia_FetchAndDeconstructSectionQuery pageSlug, sectionNum, sectionDescription, pageTitle, shortImageFile, sectionArray, wikipediaRevisionID
   put the result into sandboxArray
   fedwikipedia_ConstructSectionTocArray sectionArray, sectionNum, sectionTocArray, sectionTitle
   --
   if sectionTitle = "See also" then
      /*
      ==See also==
      *[[Appointment (disambiguation)]]
      *[[Etienne Chouard]]
      */
      
      put fedwiki_ConstructPageArray (pageTitle) into fedwikiPageArray
      --
      fedwiki_AddMarkdownToPageArray fedwikiPageArray, "# See also"
      put sectionDescription into markdownSection
      delete line 1 of markdownSection
      replace "*[[" with "- [[" in markdownSection -- quick hack
      fedwiki_AddMarkdownToPageArray fedwikiPageArray, markdownSection
   else
      put sectionTocArray ["index"][sectionTitle]["dot_number"] into dotNum
      toc_LookupArrayFromDotNum sectionTocArray, dotNum, lookUpArray, sectionTOC
      --
      put wikipedia_ConstructUrl (pageSlug, sectionTitle) into wikipediaUrl
      put fedwikipedia_ConstructSourceArray (pageTitle, pageSlug, wikipediaUrl, wikipediaRevisionID, lookUpArray) into pSourceArray
      
      -- now let's construct the page
      put fedwikipedia_SplitSectionDescription (pageTitle, shortImageFile, sectionDescription, sectionTocArray) into sectionIntro
      put wikicommons_ConstructTwoImagePageArray (sectionTitle, sectionIntro, shortImageFile, wikipediaUrl, pSourceArray) into fedwikiPageArray
      
      if sectionTOC is not empty then
         put "# See also" into markdownSection
         -- put CR & sectionTOC after markdownSection
         put CR & sectionDescription after markdownSection
         fedwiki_AddMarkdownToPageArray fedwikiPageArray, markdownSection
      end if
   end if
   
   fedwiki_StripJournal fedwikiPageArray
   return fedwikiPageArray
end fedwikipedia_FetchSectionSummaryPageArray


--> FedWikipedia | TOC
-
command fedwikipedia_ConstructTocLookupArray tocArray, @lookUpArray, @markdownTOC
   delete variable tocArray ["index"]
   repeat with itemNum = (the number of lines of the keys of tocArray) down to 1
      put tocArray [itemNum]["meta"] into metaTocArray
      put metaTocArray ["title"] into sectionTitle
      delete variable metaTocArray ["title"]
      
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

private command fedwikipedia_FetchAndDeconstructSectionQuery pageSlug, sectionNum, @sectionDescription, @pageTitle, @shortImageFile, @sectionArray, @wikipediaRevisionID
   put sandbox_FetchSectionArray (pageSlug, sectionNum) into sandboxArray
   sandbox_DeconstructSectionArray sandboxArray, pageTitle, sectionDescription, imageArray, sectionArray, wikipediaRevisionID
   put mediawiki_ExtractFirstInterestingImage (imageArray) into shortImageFile
   return sandboxArray
end fedwikipedia_FetchAndDeconstructSectionQuery
