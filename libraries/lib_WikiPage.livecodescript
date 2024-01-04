script "lib_WikiPage"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_WikiPage
type: library
version: 0.2

/*
This library is about handlers that constuct specific crafted wiki pages.

The functions all return pageArrays, which can then be used to create wiki-pages or ghost-pages.
*/


--> Working on
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


--> Wiki | Page
-
function wikiPage_FilteredDomainList filterWord
   put "*" & filterWord & "*" into sFilter
   put wiki_ListLocalShortAll (sFilter) into wikiFolders
   --
   put text_InitialCaps (filterWord) && "Sites" into pageTitle
   put "Here is a list of" && pageTitle & ":" into firstPara
   put wikiPage_ConstructDomainList (pageTitle, wikiFolders, firstPara) into pageArray
   return pageArray
end wikiPage_FilteredDomainList

function wikiPage_ConstructDomainList pageTitle, wikiDomains, pFirstPara
   if pFirstPara is empty then
      put "Here is a list of wikidomains:" into pFirstPara
   end if
   --
   put pageArray_Construct (pageTitle, pFirstPara) into pageArray
   put markdown_LinkedBullets (wikiDomains) into mdDomains
   pageArray_AddMarkdown pageArray, mdDomains
   --
   pageArray_AddMarkdown pageArray, "# Roster"
   put pageTitle & CR&CR & wikiDomains into rosterText
   pageArray_AddRoster pageArray, rosterText
   --
   pageArray_AddMarkdown pageArray, "# Activity"
   pageArray_AddActivity pageArray, pageTitle, "1 week", "CONVERSATION"
   --
   pageArray_AddReferenceIndex pageArray, wikiDomains
   --
   pageArray_StripJournal pageArray
   return pageArray
end wikiPage_ConstructDomainList

function wikiPage_TodaysActivity pFirstPara
   put "Todays Activity" into pageTitle
   put ward_ListRecentDomains ("today") into wikiDomains
   if pFirstPara is empty then
      put "Here is the activity across [[the federation]] today:" into pFirstPara
   end if
   --
   put pageArray_Construct (pageTitle, pFirstPara) into pageArray
   pageArray_AddMarkdown pageArray, "# Roster"
   put pageTitle & CR&CR & wikiDomains into rosterText
   pageArray_AddRoster pageArray, rosterText
   --
   pageArray_AddMarkdown pageArray, "# Activity"
   pageArray_AddActivity pageArray, pageTitle, "1 day", "CONVERSATION"
   --
   pageArray_StripJournal pageArray
   return pageArray
end wikiPage_TodaysActivity

function wikiPage_EmptyLocalFolders
   put "Empty Folders" into pageTitle
   --
   put wiki_ListEmptyLocalFolders (true) into emptyFolders
   if emptyFolders is empty then
      put "There are no local wikis with empty page folders!" into firstPara
      put pageArray_Construct (pageTitle, firstPara) into pageArray
      --
      pageArray_AddMarkdown pageArray, "# Tools"
      _AddRefreshEmpty pageArray
   else
      put "Here is a list of local wikis with empty page folders:" into firstPara
      put pageArray_Construct (pageTitle, pFirstPara) into pageArray
      
      # Add bullet domain list
      put markdown_LinkedBullets (wikiDomains) into mdDomains
      pageArray_AddMarkdown pageArray, mdDomains
      --
      pageArray_AddMarkdown pageArray, "# Tools"
      _AddRefreshEmpty pageArray
      _AddDeleteEmpty pageArray
   end if
   --
   pageArray_StripJournal pageArray
   --
   return pageArray
end wikiPage_EmptyLocalFolders


--> Private
-
command _SetEndScript @htmlTemplate, pageTitle, pOwnedBy, pIsAuthenticated, pIsClaimed, pIsOwner, pSeedNeighbors, pUser
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

private command _AddDeleteEmpty @pageArray
   put "This tools wil safely delete all empty folders if finds. It checks first that the folder has no pages:" into sMarkdown
   put CR & "- [http://tools.platform.earth/deleteEmptyWikis Delete Empty Folders]" after sMarkdown
   --
   pageArray_AddMarkdown pageArray, sMarkdown
   return sMarkdown
end _AddDeleteEmpty

private command _AddRefreshEmpty @pageArray
   put "Check that this page is up-to-date:" into sMarkdown
   put CR & "- [http://tools.platform.earth/RefreshEmptyWikis Refresh Empty Folders]" after sMarkdown
   --
   pageArray_AddMarkdown pageArray, sMarkdown
   return sMarkdown
end _AddRefreshEmpty
