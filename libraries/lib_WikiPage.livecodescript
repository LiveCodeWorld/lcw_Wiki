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

function wikiPage_Tools pageSlug, wikiDomain, pPageTitle
   put wikiPage_Future (pageSlug, wikiDomain, pPageTitle) into pageArray
   return pageArray
end wikiPage_Tools


--> Working on
-
function wikiPage_TocButtons pageTitle, pFirstPara
   if pFirstPara is empty then
      put fedwiki_InternalLink (pageTitle) into linkedTitle
      put "Here is a table of contents for the Wikipedia Page" && linkedTitle into pFirstPara
   end if
   put pageArray_Construct ("Table of Contents", pFirstPara) into pageArray
   
   put mediaWiki_ConstructSlug (pageTitle) into pageSlug
   --
   mediawiki_FetchPageParseInfo pageSlug, pageDescription, pageTitle, shortImageFile, infoBoxArray
   put the result into sandboxArray
   put fedwikipedia_ConstructPageTocArray (sandboxArray) into tocArray
   
   delete variable tocArray ["index"]
   repeat with itemNum = 1 to item 2 of the extents of tocArray
      put tocArray [itemNum]["meta"] into metaTocArray
      --
      put metaTocArray ["title"] into sectionTitle
      if _SkipSection (sectionTitle, pAddAll) then next repeat
      --
      put metaTocArray [section_number]  into sectionNum
      
      put wikicommons_ConstructSectionForm (pageSlug, sectionNum, sectionTitle) into formHTML
      pageArray_AddHtml pageArray, formHTML
   end repeat
   --
   pageArray_AddMarkdown pageArray, "# Media"
   pageArray_AddForm pageArray, "Find Images", "http://rest.livecode.world/mediawiki/gallery", pageTitle, "title", "lightpink", "Mediawiki", 22
   pageArray_AddForm pageArray, "Pages", "http://rest.livecode.world/mediawiki/related", pageTitle, "title", "lightgreen", "Find Related", 24
   pageArray_AddForm pageArray, "Openverse", "http://rest.livecode.world/openverse", pageTitle, "search_Term", "orange", "Find Image", 24
   --
   fedwikipedia_ConstructTocLookupArray tocArray, lookUpArray, markdownTOC
   put "# See also" && CR&CR before markdownTOC
   pageArray_AddMarkdown pageArray, markdownTOC
   --
   pageArray_StripJournal pageArray
   return pageArray
end wikiPage_TocButtons

function wikiPage_GalleryPedia pageTitle, pFirstPara, pLang
   if pFirstPara is empty then
      put fedwiki_InternalLink (pageTitle) into linkedTitle
      put "Images found on Wikipedia page:" && linkedTitle into pFirstPara
   end if
   put pageArray_Construct (pageTitle, pFirstPara) into pageArray
   
   # Fetch page media
   put restbase_FetchMediaArray (pageTitle, pLang) into mediaIndexArray
   --
   repeat with itemNum = 1 to item 2 of the extents of mediaIndexArray
      put mediaIndexArray [itemNum]["type"] into shortImageFile
      put mediaIndexArray [itemNum]["title"] into shortImageFile
      -- put textDecode (shortImageFile, "UTF-8") into shortImageFile
      put mediaIndexArray [itemNum]["srcSet"][1]["src"] into imageURL
      put mediaIndexArray [itemNum]["srcSet"][1]["scale"] into srcScale
      --
      pageArray_AddImage pageArray, imageURL, shortImageFile
   end repeat
   delete char -1 of pinText
   --
   put "PAGE" & CR into mapText
   put "Map of" && pPageTitle & CR after mapText
   put pinText after mapText
   --
   pageArray_AddMap pageArray, mapText
   --
   pageArray_StripJournal pageArray
   return pageArray
end wikiPage_GalleryPedia

function wikiPage_RelatedWikipedia searchTitle, pPageTitle, pFirstPara, pLang
   if pFirstPara is empty then
      put fedwiki_InternalLink (searchTitle) into linkedTitle
      put "Search results for related pages of:" && linkedTitle into pFirstPara
   end if
   put pageArray_Construct (pPageTitle, pFirstPara) into pageArray
   
   # Fetch pageArray
   put restbase_FetchRelated (searchTitle, pLang) into pageIndexArray
   
   put item 2 of the extents of pageIndexArray into maxNum
   repeat with itemNum = 1 to maxNum
      put pageIndexArray [itemNum] into itemArray
      
      # Get Titles
      put itemArray ["title"] into imageSlug
      put itemArray ["titles"]["normalized"] into imageTitle
      
      # Get Metadata
      put itemArray ["revision"] into revisionID
      put itemArray ["pageid"] into pageID
      
      # Get Links
      put itemArray ["content_urls"]["desktop"]["page"] into linkURL
      put itemArray ["content_urls"]["mobile"]["page"] into mobileLinkURL
      
      # Get Description
      put line 1 of itemArray ["description"] into shortDescription
      put itemArray ["extract"] into imageDescription
      put itemArray ["extract_Html"] into htmlDescription
      -- put textDecode (htmlDescription, "UTF-8") into htmlDescription
      
      # Get Image
      put itemArray ["originalimage"]["source"] into imageURL
      put itemArray ["originalimage"]["height"] into imageHeight
      put itemArray ["originalimage"]["width"] into imageWidth
      
      # Get Thumbnail
      put itemArray ["thumbnail"]["source"] into thumbURL
      put itemArray ["thumbnail"]["height"] into thumbHeight
      put itemArray ["thumbnail"]["width"] into thumbWidth
      
      # Construct image caption
      -- put imageTitle & "." && sAttribution into imageCaption
      if char 1 to 3 of htmlDescription = "<p>" then delete char 1 to 3 of htmlDescription
      if char -4 to -1 of htmlDescription = "</p>" then delete char -4 to -1 of htmlDescription
      repeat while char -1 of htmlDescription = "."
         delete char -1 of htmlDescription
      end repeat
      --
      put fedwiki_InternalLink (imageTitle) into linkedTitle
      put linkedTitle & "." && imageDescription & " - [" & linkURL && "wikimedia]" into imageCaption
      
      # Add Coordinates
      put itemArray ["coordinates"]["lat"] into iLat
      put itemArray ["coordinates"]["lon"] into iLong
      if iLat is not empty then
         put imageTitle & "." && shortDescription into pinDescription
         put iLat & comma && iLong && pinDescription & CR after pinText
      end if
      
      # Add Image
      pageArray_AddImage pageArray, imageURL, imageCaption, linkURL, iLat, iLong, "wide"
   end repeat
   delete char -1 of pinText
   --
   if pinText is not empty then
      put "PAGE" & CR into mapText
      put "Map of" && pPageTitle & CR after mapText
      put pinText after mapText
      --
      pageArray_AddMap pageArray, mapText
   end if
   --
   pageArray_CleanJournal pageArray, false
   return pageArray
end wikiPage_RelatedWikipedia

command pageArray_AddImage @pageArray, imageURL, pCaptionText, pLinkURL, pLat, pLong, pSize, pWidth, pHeight, pID
   -- put pageArray_ConstructImageCaption (pImageCaption, pImageSourceUrl, imageURL) into sCaption
   if pageArray is not an array then return false
   if imageURL is  empty then return false
   if pCaptionText is empty then put "This is an image" into pCaptionText
   --
   put _ConstructImageItemArray (imageURL, pLinkURL, pWidth, pHeight, pSize, pCaptionText, pLat, pLong) into itemArray
   itemArray_Add itemArray, pageArray
   return itemArray
end pageArray_AddImage

private function _ConstructImageItemArray imageURL, iSource, pWidth, pHeight, pSize, pCaption, pLat, pLong, pID
   if pSize is empty then
      put "wide" into pSize
   end if
   itemArray_NormalizeID pID
   put pID into itemArray ["id"]
   
   put "image" into itemArray ["type"]
   --
   put imageURL into itemArray ["url"]
   put iSource into itemArray ["source"]
   put pCaption into itemArray ["text"]
   --
   put pSize into itemArray ["size"]
   if pWidth is not empty then
      put pWidth into itemArray ["width"]
   end if
   if pHeight is not empty then
      put pHeight into itemArray ["height"]
   end if
   
   # Add Geo
   if pLat is not empty then
      put pLat into itemArray ["location"]["latitude"]
      put pLong into itemArray ["location"]["longitude"]
   end if
   return itemArray
end _ConstructImageItemArray

command pageArray_AddHtmlImage @pageArray, imageURL, pCaptionText, pLinkURL
   if pageArray is not an array then return false
   if imageURL is  empty then return false
   if pCaptionText is empty then put "This is an image" into pCaptionText
   --
   -- put fedwiki_ConstructImageCaption (pCaptionText, pLinkURL, imageURL) into pCaptionText
   put _ConstructImageHtml (imageURL, pCaptionText, pLinkURL) into imageHTML
   pageArray_AddHtml pageArray, imageHTML
   return true
end pageArray_AddHtmlImage

function fedwiki_ConstructImageHtml encodedSrcURL, pCaption, pCaptionLinkURL, pEncodedImageLink
   put fedwiki_ConstructImageCaption (pCaption, pCaptionLinkURL, encodedSrcURL) into pCaptionText
   put _ConstructImageHtml (encodedSrcURL, pCaptionText, pEncodedImageLink) into imageHTML
   return imageHTML
end fedwiki_ConstructImageHtml

function fedwiki_ConstructThumbHtml encodedSrcURL, pCaption, pCaptionLinkURL, pEncodedImageLink
   put fedwiki_ConstructImageCaption (pCaption, pCaptionLinkURL, encodedSrcURL) into pCaptionText
   --
   put "class='item image ui-sortable-handle'" into divClassBit
   put "class='thumbnail' data-imagestyle='thumbwiki'" into imgStyleBit
   put _ConstructImageHtml (encodedSrcURL, pCaptionText, pEncodedImageLink, divClassBit, imgStyleBit) into someHTML
   return someHTML
end fedwiki_ConstructThumbHtml

function fedwiki_ConstructImageCaption pCaption, pCaptionLinkURL
   if pCaption is empty then
      put "This is an image" into pCaption
   else if the number of words of pCaption > 35 then
      put word 1 to 35 of pCaption & "..." into pCaption
   else
      put word 1 to -1 of pCaption into pCaption
   end if
   html_TopAndTailParagraphTags pCaption
   --
   if pCaptionLinkURL is empty then return pCaption
   if char -1 of pCaption = "." then delete char -1 of pCaption
   --
   put fedwiki_ExternalLink (pCaptionLinkURL) into externalLink
   put pCaption && "-" && externalLink into imageCaption
   --
   return imageCaption
end fedwiki_ConstructImageCaption

function fedwiki_InternalLink pageTitle
   return "[[" & word 1 to -1 of pageTitle & "]]"
end fedwiki_InternalLink

function fedwiki_ExternalLink linkURL, pLinkTag
   if pLinkTag is empty then
      put fedwiki_ConstructLinkTag (linkURL) into pLinkTag
   end if
   put "[" & linkURL && pLinkTag & "]" into externalLink
   return externalLink
end fedwiki_ExternalLink

command fedwiki_AddExternalLink @someText, pExtLinkURL, pHackHtml
   if char -1 of someText = "." then delete char -1 of someText
   --
   put md_ConstructExternalLinkLine (pExtLinkURL) into mdLinkLine
   --
   if pHackHtml is true then
      -- ...<p>It's only preliminary, folks.</p><img src="http://feeds.feedburner.com/~r/sciencealert-latestnews/~4/Bj-Ay6aCDOg" height="1" width="1" alt=""/>
      put "</p>" into ePara
      set the itemdelimiter to ePara
      if char -4 to -1 of someText = "</p>" then
         delete char -4 to -1 of someText
         _TrimFullStop someText, mdLinkLine
         put ePara after someText
      else if the number of items of someText > 1 then
         put item -1 of someText into lastBit
         delete item -1 of someText
         _TrimFullStop someText, mdLinkLine
         put ePara & lastBit after someText
      else
         _TrimFullStop someText, mdLinkLine
      end if
   else
      _TrimFullStop someText, mdLinkLine
   end if
   return linkTag
end fedwiki_AddExternalLink

function fedwiki_ConstructLinkTag someURL
   switch
      case someURL contains "twitter.com"
         return "twitter"
      case someURL contains "facebook.com"
         return "facebook"
      case someURL contains "bbc.co.uk"
         return "bbc"
      case someURL contains "listennotes.com"
         return "listen"
      case someURL contains "wikipedia.org"
         return "wikipedia"
      case someURL contains "wikimedia.org"
         return "wikimedia"
      default
         put html_ExtractTLD (someURL, true) into linkTag
         return linkTag
   end switch
end fedwiki_ConstructLinkTag

private command _SetImageDescription @pImageCaption, @pLinkURL, imageURL
   if pImageCaption is empty then put "This is an image" into pImageCaption
   if pLinkURL is empty then
      if imageURL begins with "data:image/" then
         put empty into pLinkURL
      else
         put imageURL into pLinkURL
      end if
   end if
end _SetImageDescription

function _ConstructImageHtml encodedSrcURL, pCaptionText, pEncodedImageLink, pImgStyleBit, pDivClassBit
   if pDivClassBit is empty then put "style='padding: 12px; background:#eee; width:96%; align=centered;'" into pDivClassBit
   if pImgStyleBit is empty then put "data-imagestyle='fullwiki'; style='display:block; margin:auto; width:100%;'" into pImgStyleBit
   
   # Div header
   put "<div [[pDivClassBit]]>" & CR into htmlTemplate
   
   -- maybe add a link to the image
   if pImageLink is not empty then put "<a href='[[pEncodedImageLink]]' target='_blank'>" after htmlTemplate
   
   # Add image source
   put "<img [[pImgStyleBit]] src='[[encodedSrcURL]]'>" & CR after htmlTemplate
   
   # End imageLink
   if pImageLink is not empty then put "</a>" & CR after htmlTemplate
   
   # Add caption
   put "<p class=caption>" & CR&CR after htmlTemplate
   put "[[pCaptionText]]" & CR&CR after htmlTemplate
   
   # Add ending
   put "</p></div>" after htmlTemplate
   
   # Merge and return
   put merge (htmlTemplate) into someHTML
   return someHTML
end _ConstructImageHtml

private command _TrimFullStop @someText, linkBit
   put word 1 to -1 of someText into someText
   switch
      case char -3 to -1 of someText is "..."
      case char -2 to -1 of someText is ".."
         break
      case char -1 of someText is "."
         delete char -1 of someText
         break
   end switch
   put linkBit after someText
end _TrimFullStop


--> WikiPage | Gallery
-
function wikiPage_Image imageURL, pPageTitle, pPageDescription, pImageCaption, pImageSourceUrl, iWidth, iHeight, iSize, pLat, pLong
   put pageArray_ConstructImageCaption (pImageCaption, pImageSourceUrl, imageURL) into sCaption
   --
   put _ConstructImageItemArray (imageURL, pImageSourceUrl, iWidth, iHeight, iSize, sCaption, pLat, pLong) into itemArray
   put _ConstructImagePageArray (pPageTitle, pPageDescription) into pageArray
   itemArray_Add itemArray, pageArray
   --
   return pageArray
end wikiPage_Image

function wikiPage_OpenVerseThumbNails sData, pPageTitle, pFirstPara, pSearchBit
   if pPageTitle is empty then
      put "Openverse Thumbnails" into pPageTitle
   end if
   if pFirstPara is empty then
      put "Search results for:" && pSearchBit into pFirstPara
   end if
   --
   put pageArray_Construct (pPageTitle, pFirstPara) into pageArray
   
   put sData ["results"] into indexArray
   put item 2 of the extents of indexArray into maxNum
   repeat with itemNum = 1 to maxNum
      put indexArray [itemNum] into itemArray
      --
      put itemArray ["thumbnail"] into thumbURL
      put itemArray ["url"] into imageURL
      put itemArray ["related_url"] into relatedURL
      put itemArray ["detail_url"] into detailURL
      put itemArray ["foreign_landing_url"] into linkURL
      
      --
      put itemArray ["title"] into imageTitle
      put itemArray ["attribution"] into sAttribution
      --
      put imageTitle & "." && sAttribution into imageCaption
      pageArray_AddThumbnail pageArray, thumbURL, imageCaption, linkURL
   end repeat
   return pageArray
end wikiPage_OpenVerseThumbNails


--> WikiPage | Dialogue
-
function wikiPage_Dialogue pageSlug, wikiDomain, dialogueSlug, pPageArrayTitle, pTemplateDomain
   mediawiki_NormaliseTitle pageSlug, mediaWikiTitle, pageID
   put fedwiki_ConstructTitle (pageSlug) into pageTitle
   put urlEncode (pageTitle) into curlyData ["all"]["URLEncodedTitle"]
   put pageTitle into curlyData ["all"]["New Page Title"]
   put mediaWikiTitle into curlyData ["all"]["Wikipedia Title"]
   put pageSlug into curlyData ["all"]["originalSlug"]
   put wikiDomain into curlyData ["all"]["wikiDomain"]
   --
   put wikiPage_CurlyDialogue (curlyData, dialogueSlug, pPageArrayTitle, pTemplateDomain) into pageArray
   return pageArray
end wikiPage_Dialogue

function wikiPage_CurlyDialogue curlyData, dialogueSlug, pPageArrayTitle, pTemplateDomain
   if pTemplateDomain is empty then put "dialogue.fedwiki.org" into pTemplateDomain
   if pPageArrayTitle is empty then put "Edit Wiki Page" into pPageArrayTitle
   --
   put pageArray_FetchTemplate (pTemplateDomain, dialogueSlug, pPageArrayTitle) into pageArray
   curly_MergePageArray pageArray, curlyData
   --
   put "html" into pageArray ["plugin"]
   pageArray_CleanJournal pageArray
   --
   return pageArray
end wikiPage_CurlyDialogue

function wikiPage_EditPage pageSlug, wikiDomain, pPageArrayTitle
   put wikiPage_Dialogue (pageSlug, wikiDomain, "edit-page-dialogue", pPageArrayTitle) into pageArray
   return pageArray
end wikiPage_EditPage

function wikiPage_CreatePage pageSlug, wikiDomain, pPageArrayTitle
   put wikiPage_Dialogue (pageSlug, wikiDomain, "create-page-dialogue", pPageArrayTitle) into pageArray
   return pageArray
end wikiPage_CreatePage

function wikiPage_Future pageSlug, wikiDomain, pPageArrayTitle
   put wikiPage_Dialogue (pageSlug, wikiDomain, "future-dialogue-template", pPageArrayTitle) into pageArray
   return pageArray
end wikiPage_Future


--> PageArray | Image
-
function wikiPage_ImageEditor imageURL, imageAttributeArray, pAddMetaData
   html_DeconstructImageArray imageAttributeArray, srcURL, imageCaption, imageWidth, imageHeight, imageClass
   if imageCaption is empty then put "This is a full width image" into imageCaption
   --
   put pageArray_FetchTemplate ("fedwiki.org", "edit-image-template", "Edit Image Tool", "fedwiki.org") into pageArray
   --
   curly_ReplacePageArray pageArray, "ImageURL", imageURL
   --
   put fedwiki_ExternalLink (imageURL) into imageLink
   curly_ReplacePageArray pageArray, "ImageLink", imageLink
   --
   curly_ReplacePageArray pageArray, "ImageCaption", imageCaption
    
   if pAddMetaData is not false then
      -- this fetches the image a second time with curl
      pageArray_AddImageMetadata pageArray, imageURL
   end if
   --
   return pageArray
end wikiPage_ImageEditor

function wikiPage_GoogleImage imageURL, imageAttributeArray
   html_DeconstructImageArray imageAttributeArray, srcURL, imageCaption, imageWidth, imageHeight, imageClass
   --
   put "Your Dropped Image" into pageTitle
   put "Here is a simple image you dropped on to wiki. From here you can do several things." into pageText
   put " Below is a simple [[full width image]], that uses the [[about html plugin]] to display the image using html." after pageText
   put pageArray_Construct (pageTitle, pageText) into pageArray
   put empty into linkURL
   --
   put srcURL into dataURL
   --
   if imageCaption is empty then put "This is an [[full width image]]" into imageCaption
   pageArray_AddHtmlImage pageArray, dataURL, imageCaption
   --
   if imageCaption is empty then put "This is an [[full thumbnail image]]" into imageCaption
   pageArray_AddThumbnail pageArray, dataURL, imageCaption
   --
   return pageArray
end wikiPage_GoogleImage


--> WikiPage
-
function wikiServer_GuessLastSlug sReferer
   set the itemdelimiter to slash
   put item -1 of sReferer into lastPageSlug
   if lastPageSlug = "tools" then
      put item -3 of sReferer into lastPageSlug
   end if
   return lastPageSlug
end wikiServer_GuessLastSlug


--> WikiPage | Filter
-
function wikiPage_FilteredDomainList filterWord, pPageTitle
   if pPageTitle is empty then
      put text_InitialCaps (filterWord) && "Sites" into pPageTitle
   end if
   
   put "*" & filterWord & "*" into sFilter
   put wiki_ListLocalShortAll (sFilter) into wikiFolders
   --
   put "Here is a list of" && pageTitle & ":" into firstPara
   put wikiPage_ConstructDomainList (pPageTitle, wikiFolders, firstPara) into pageArray
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

function wikiPage_TwoWeeksActivity pFirstPara
   return wikiPage_FederationActivity ("", pFirstPara)
end wikiPage_TwoWeeksActivity

function wikiPage_TodaysActivity pFirstPara
   return wikiPage_FederationActivity ("today", pFirstPara)
end wikiPage_TodaysActivity

function wikiPage_FederationActivity pDayName, pFirstPara
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
end wikiPage_FederationActivity

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
private function _SkipSection sectionTitle, pAddAll
   put pAddAll is not true AND sectionTitle is among the items of "See also,Notes,Further Reading,References,Sources,External links" into sBoolean
   return sBoolean
end _SkipSection

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
