﻿script "lib_WikiRender"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_WikiRender
type: library
version: 0.1

/*
This linrary is the start of a native Livecode rendering of federated wiki-json.
*/


--> Working on
-
function wikiText_GetLinkArray sText
   local sNum, eNum, linkArray
   
   put "(?i)\[(http|https|ftp):\/\/([^ ]+?)\s+(.*?)\]" into sRegex
   put 1 into indexNum
   repeat while matchChunk (sText, sRegex, sProt, eProt, sHref, eHref, sLink, eLink) is true
      # Log Text
      put char sProt to eProt of sText into linkArray [indexNum]["protocol"]
      put char sHref to eHref of sText into linkArray [indexNum]["link"]
      put char sLink to eLink of sText into linkArray [indexNum]["text"]
      
      # Delete and Repeat
      put sProt -2 into sChunk
      put eLink + 2 into eChunk
      delete char sChunk to eChunk of sText
      
      # log Offsets
      put sChunk into linkArray [indexNum]["sChunk"]
      put eChunk into linkArray [indexNum]["eChunk"]
      
      add 1 to indexNum
   end repeat
   return linkArray
end wikiText_GetLinkArray

function text_TempReplaceQuoted someText, @offsetArray
   -- was "temptext_StripQuoted"
   -- version original,18/9/01
   
   put "(" & quote & "[^" & quote & "]*" & quote & ")" into someReg
   put 1 into dummyNum
   repeat
      if matchchunk(someText, someReg, startChar, endChar) then
         put char startChar to endChar of someText into quotedText
         put "<dummy id=" & dummyNum & "/>" into safeReplaceMent
         put safeReplaceMent into char startChar to endChar of someText
         put quotedText into offsetArray[safeReplaceMent]
         add 1 to dummyNum
      else
         return someText
      end if
   end repeat
end text_TempReplaceQuoted

function fedwiki_GetLinks wikiText
   local sNum, eNum
   
   put "[^\]]+" into notBracket
   put "\[\[(" & notBracket & ")\]\]" into someReg
   repeat
      get matchchunk (wikiText, someReg, sNum, eNum) 
      if it is true then
         put char sNum to eNum of wikiText into pageTitle
         put pageTitle & CR after pageTitles
         --
         delete char 1 to eNum of wikiText
      else 
         exit repeat
      end if
   end repeat
   delete char -1 of pageTitles
   return pageTitles
end fedwiki_GetLinks

command fedwiki_ReplaceExternalLinks @wikiText
   -- in public - [https://upload.wikimedia.org/wikipedia/commons/9/9c/Open_Science_-_Prinzipien.png wikimedia.org]
   put "(\[http.+\])" into someReg
   
   local refStart, refEnd
   put 0 into indexNum
   repeat
      get matchchunk (wikiText, someReg, sNum, eNum) 
      if it is true then
         add 1 to indexNum
         put char sNum to eNum of wikiText into extLinkText
         delete char - 1 of extLinkText
         delete char 1 of extLinkText
         put word 1 of extLinkText into extLinkURL
         put word 2 to -1 of extLinkText into extLinkText
         --
         -- - [wikimedia.org](https://upload.wikimedia.org/wikipedia/commons/9/9c/Open_Science_-_Prinzipien.png)
         put "[" & extLinkText & "](" & extLinkURL & ")" into markdownLink
         put markdownLink into char sNum to eNum of wikiText
      else
         exit repeat
      end if
   end repeat
   return indexNum
end fedwiki_ReplaceExternalLinks

function fedwiki_ConstructLink someText, pExternalURL
   put word 1 to -1 of line 1 of someText into someText
   if pExternalURL is empty then
      return "[[" & someText & "]]"
   else
      put word 1 to -1 of pExternalURL into pExternalURL
      return "[" & pExternalURL && someText & "]"
   end if
end fedwiki_ConstructLink

function _StripInternal sText
   put "(?i)(\[\[[^\]]+\]\])" into sRegex
   repeat while matchchunk (sText, sRegex, startChar, endChar) is true
      put char startChar to endChar of sText into fLink
      put char 3 to -3 of fLink into pageTitle
      put pageTitle into char startChar to endChar of sText
   end repeat
   return sText
end _StripInternal

function _StripExternal sText
   put "(?i)\[(http|https|ftp):\/\/([^ ]+?)\s+(.*?)\]" into sRegex
   --   --
   repeat while matchChunk (sText, sRegex, sProt, eProt, sHref, eHref, sLink, eLink) is true
      put char sLink to eLink of sText into sLinkText
      --
      put sProt -2 into sChunk
      put eLink + 2 into eChunk
      --
      put sLinkText into char sChunk to eChunk of sText
   end repeat
   return sText
end _StripExternal


--> PageArray
-
function pageArray_FetchText wikiDomain, pSlug, pPort
   put pageArray_Fetch (wikiDomain, pSlug, pPort) into pageArray
   put pageArray_Text (pageArray) into pageText
   return pageText
end pageArray_FetchText

function pageArray_Text pageArray, pIncludeNotes, pBreak
   if pBreak is empty then put CR&CR into pBreak
   --
   put pageArray ["story"] into storyArray
   repeat with itemNum = 1 to item 2 of the extents of storyArray
      put storyArray [itemNum] into itemArray
      put itemArray ["text"] into itemText
      switch itemArray ["type"]
         case "pageFold"
            if pIncludeNotes is not false then
               exit repeat
            end if
         case "paragraph"
         case "markdown"
            if itemText = "# See also" and pIncludeNotes is not false then
               exit repeat
            end if
            
            -- pageArray_CleanText itemText
            put markdown_ToText (itemText) into sText
            put sText & pBreak after pageText
         case "html"
            break
         default
            next repeat
      end switch
   end repeat
   return word 1 to -1 of pageText
end pageArray_Text


--> Wiki | Tag
-
command wiki_SetTagOffsets sHTML, tagName, @startCharNum, @endCharNum
   put merge ("{{#[[tagName]]}}") into startTag
   put merge ("{{/[[tagName]]}}") into endTag
   --
   put offset (startTag, sHTML) into startCharNum
   if startCharNum = 0 then
      put 0 into endCharNum
      return empty
   else
      get offset (endTag, sHTML, startCharNum)
      if it = 0 then
         put 0 into endCharNum
         return empty
      end if
      put it + startCharNum - 1 into endInnerCharNum
      put endInnerCharNum + the number of chars of endTag into endCharNum
      --
      put startCharNum + the number of chars of startTag into startInnerCharNum
      put char startInnerCharNum to endInnerCharNum of sHTML into innerHtml
      return innerHtml
   end if
end wiki_SetTagOffsets


--> Wiki | Render
-
function wiki_RenderHtml htmlTemplate, wikiDomain, pPageSlug, pOwnedBy
   if pPageSlug is empty then put "welcome-visitors" into pPageSlug
   --
   put pageArray_Get (wikiDomain, pPageSlug) into pageArray
   put wiki_RenderPageArray (pageArray, htmlTemplate, wikiDomain) into sHTML
   return sHTML
end wiki_RenderHtml

function wiki_RenderPageArray pageArray, htmlTemplate, wikiDomain, pOwnedBy, pTabChars
   if pTabChars is empty then put "  " into pTabChars
   put pageArray ["title"] into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   
   # Construct rendered page div
   put _ConstructRenderedPageDiv (wikiDomain, pageSlug, pageTitle, storyArray) into pageDiv
   
   # Set end script login and ownership params
   _SetEndScript htmlTemplate, pageTitle, pOwnedBy
   
   # Set "pages" div
   put pageArray ["story"] into storyArray
   wiki_SetTagOffsets htmlTemplate, "pages", startCharNum, endCharNum
   put the result into innerHTML
   if innerHTML is not empty then
      put pageDiv into char startCharNum to endCharNum of htmlTemplate
   end if
   
   return htmlTemplate
end wiki_RenderPageArray

function wiki_RenderStoryDiv storyArray
   repeat with itemNum = 1 to item 2 of the extents of storyArray
      put storyArray [itemNum] into itemArray
      --
      put itemArray ["id"] into pID
      put itemArray ["text"] into sText
      --
      put itemArray ["type"] into itemType
      switch itemType
         case "paragraph"
            put wiki_RenderTextDiv (sText, pID) into newDiv
            break
         case "markdown"
            put wiki_ConstructMarkdownDiv (sText, pID) into newDiv
            break
         case "HTML"
            put wiki_ConstructHtmlDiv (sText, pID) into newDiv
            break
         case "factory"
            put wiki_RenderFactoryDiv (pID) into newDiv
            break
         case "roster"
            put wiki_ConstructRosterDiv (sText, pID) into newDiv
            break
         default
            -- breakpoint
      end switch
      --
      put newDiv & CR after storyDiv
   end repeat
   delete char -1 of storyDiv
   return storyDiv
end wiki_RenderStoryDiv

function wiki_ConstructRosterDiv rosterText, pID, pMyDomain
   put roster_EvaluateText (rosterText) into allDomains
   --
   put "  " & roster_GetTitle (rosterText) into rosterTitle
   put the number of lines of allDomains into rosterNum
   put _RosterImageLines (allDomains, pMyDomain) into rosterImages
   put allDomains into rosterSites
   replace CR with comma in rosterSites
   --
   put scaffold_Get ("wiki-roster") into htmlTemplate
   put merge (htmlTemplate) into sHTML
   return sHTML
end wiki_ConstructRosterDiv

function wiki_ConstructHtmlDiv sText, pID
   return wiki_RenderTextDiv (sText, pID)
end wiki_ConstructHtmlDiv

function wiki_ConstructMarkdownDiv sText, pID
   return wiki_RenderTextDiv (sText, pID)
end wiki_ConstructMarkdownDiv

function wiki_RenderLinks sText
   get _ReplaceExternal (sText)
   put _ReplaceInternal (it) into sHTML
   return sHTML
end wiki_RenderLinks

function wiki_RenderTextDiv sText, pID
   itemArray_NormalizeID pID
   put xml_Enclose (sText, "p") into sText
   put _ReplaceInternal (sText) into sPara
   put html_ConstructDiv (sPara, "item paragraph", pID) into textDiv
   return textDiv
end wiki_RenderTextDiv

function wiki_RenderFactoryDiv pID, pHelpText
   itemArray_NormalizeID pID
   if pHelpText is empty then
      put "Double-Click to Edit<br>Drop Text or Image to Insert<br>Or Choose a Plugin" into pHelpText
   end if
   
   put scaffold_Get ("wiki-factory") into htmlTemplate
   put merge (htmlTemplate) into factoryDiv
   return factoryDiv
end wiki_RenderFactoryDiv

function wiki_ConstructFooter wikiDomain, pageSlug
   put scaffold_Get ("wiki-footer") into footerFragment
   return footerFragment
end wiki_ConstructFooter


--> Private
-
private function _ConstructRenderedPageDiv wikiDomain, pageSlug, pageTitle, storyArray, pTabChars   
   # Construct pageDivContents
   put _RenderPageDivContents (wikiDomain, pageSlug, pageTitle, storyArray) into pageDivContents
   
   # Indent and wrap with "page" and "paper"
   put html_ConstructDiv (pageDivContents, "paper") into paperDiv
   line_Indent paperDiv, pTabChars
   put html_ConstructDiv (paperDiv, "page", pageSlug, "tabindex='-1'") into pageDiv
   --
   return pageDiv
end _ConstructRenderedPageDiv

private function _RenderPageDivContents wikiDomain, pageSlug, pageTitle, storyArray
   put _MergeScaffold ("wiki-handle-parent", wikiDomain, pageSlug, pageTitle) & CR after pageDivContents
   put _MergeScaffold ("wiki-twins", wikiDomain, pageSlug, pageTitle) & CR after pageDivContents
   put _MergeScaffold ("wiki-header", wikiDomain, pageSlug, pageTitle) & CR after pageDivContents
   --
   put wiki_RenderStoryDiv (storyArray) & CR after pageDivContents
   --
   put _MergeScaffold ("wiki-backlinks", wikiDomain, pageSlug, pageTitle) & CR after pageDivContents
   put wiki_ConstructFooter (wikiDomain, pageSlug) after pageDivContents
   --
   return pageDivContents
end _RenderPageDivContents

private function _MergeScaffold tName, wikiDomain, pageSlug, pageTitle
   put scaffold_Get (tName) into htmlTemplate
   put merge (htmlTemplate) into htmlFragment
   return htmlFragment
end _MergeScaffold

private function _RosterImageLines allDomains, pMyDomain, pWhiteSpace
   /*
   <img class="remote" src="//builder.livecode.world/favicon.png" title="builder.livecode.world" data-site="builder.livecode.world" data-slug="welcome-visitors">
   */
   
   if pWhiteSpace is empty then put "  " into pWhiteSpace
   repeat for each line wikiDomain in allDomains
      if wikiDomain = pMyDomain then
         get "<img class='remote' src='/favicon.png' title='[[wikiDomain]]' data-site='[[wikiDomain]]' data-slug='pageSlug'>"
      else
         get "<img class='remote' src='//[[wikiDomain]]/favicon.png' title='[[wikiDomain]]' data-site='[[wikiDomain]]' data-slug='pageSlug'>"
      end if
      put merge (it) into imageLine
      put pWhiteSpace & imageLine & CR after imageLines
   end repeat
   delete char -1 of imageLines
   return imageLines
end _RosterImageLines

function _ReplaceInternal sText
   put "(?i)(\[\[[^\]]+\]\])" into sRegex
   --
   repeat while matchchunk (sText, sRegex, startChar, endChar) is true
      put char startChar to endChar of sText into fLink
      --
      put char 3 to -3 of fLink into pageTitle
      put _RenderLink (pageTitle) into hFragment
      put hFragment into char startChar to endChar of sText
   end repeat
   return sText
end _ReplaceInternal

function _RenderLink pageTitle, pSlug
   put "view" into wikiDomain
   if pSlug is empty then
      put fedwiki_ConstructSlug (pageTitle) into pSlug
   end if
   put "<a class='internal' href='/[[pSlug]].html' data-page-name='[[pSlug]]' title='[[wikiDomain]]'>[[pageTitle]]</a>" into hTemplate
   return merge (hTemplate)
end _RenderLink

function _ReplaceExternal sText
   put "(?i)\[(http|https|ftp):\/\/([^ ]+?)\s+(.*?)\]" into sRegex
   --   --
   repeat while matchChunk (sText, sRegex, sProt, eProt, sHref, eHref, sLink, eLink) is true
      put char sProt to eProt of sText into sProtocol
      put sProtocol & "://" & char sHref to eHref of sText into hRef
      put char sLink to eLink of sText into sLinkText
      --
      put sProt -2 into sChunk
      put eLink + 2 into eChunk
      --
      put _RenderExternal (hRef, sLinkText) into hFragment
      put hFragment into char sChunk to eChunk of sText
   end repeat
   return sText
end _ReplaceExternal

function _RenderExternal href, pLinkText
   if pLinkText is empty then
      set the itemdelimiter to slash
      put item 3 of pLinkText into pLinkText -- domain
   end if
   put "<a class='external' target='_blank' href='[[href]]' title='[[href]]' rel='nofollow'>" into hTemplate
   put pLinkText after hTemplate
   put "<img src='/images/external-link-ltr-icon.png'></a>" after hTemplate
   --
   return merge (hTemplate)
end _RenderExternal

private command _SetEndScript @htmlTemplate, pageTitle, pOwnedBy, pIsAuthenticated, pIsClaimed, pIsOwner, pSeedNeighbors, pUser
   if pOwnedBy is empty then put "David Bovill" into pOwnedBy
   --
   replace "{{title}}" with pageTitle in htmlTemplate
   --
   wiki_SetTagOffsets htmlTemplate, "owned", startCharNum, endCharNum
   put the result into innerHTML
   if htmlTemplate is not empty then
      curly_ReplaceText innerHTML, "ownedBy", pOwnedBy
      put innerHTML into char startCharNum to endCharNum of htmlTemplate
   end if
   --
   put pIsAuthenticated is true into pIsAuthenticated
   curly_ReplaceText htmlTemplate, "authenticated", pIsAuthenticated
   --
   put pIsClaimed is true into pIsClaimed
   curly_ReplaceText htmlTemplate, "owned", pIsClaimed
   --
   put pIsOwner is not false into pIsOwner
   curly_ReplaceText htmlTemplate, "isOwner", pIsOwner
   --
   curly_ReplaceText htmlTemplate, "ownedBy", pOwnedBy
   --
   curly_ReplaceText htmlTemplate, "seedNeighbors", pSeedNeighbors
   --
   curly_ReplaceText htmlTemplate, "user", pUser
end _SetEndScript
