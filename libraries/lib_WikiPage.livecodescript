script "lib_WikiPage"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_WikiPage
type: library
version: 0.3

/*
This library is about handlers that constuct specific crafted wiki pages.

The functions all return pageArrays, which can then be used to create wiki-pages or ghost-pages.
*/

--> Working on
-
function wikiPage_GardenActivity gardenName, wikiDomain
   put gardenName && "Garden Sites" into pageTitle
   -- put "This [[garden]] contains the following domains:" into someMarkdown
   put empty into someMarkdown
   
   put wikiGarden_ListDomains (gardenName) into wikiDomains  
   put _SitesIndex (wikiDomains, pageTitle, wikiDomain, pageTitle, someMarkdown) into pageArray
   
   # Clean and Return
   pageArray_StripJournal pageArray
   return pageArray
end wikiPage_GardenActivity

function wikiPage_LocalActivity
   -- put wikiGarden_ListAllDomains() into wikiDomains
   put wikiGarden_GetDomainData() into gardenDomainData
   repeat for each key wikiDomain in gardenDomainData
      set the cursor to busy
      put gardenDomainData [wikiDomain]["folder"] into wikiFolder
      put wikiFolder_HasNoPages (wikiFolder) into noPages
      if nPages is true then
         put wikiFolder & CR after emptyFolders
      else
         put wikiDomain & CR after wikiDomains
         put wikiFolder & CR after wikiFolders
      end if
   end repeat
   delete char -1 of emptyFolders
   delete char -1 of wikiDomains
   delete char -1 of wikiFolders
   --
   url_SortDomainIndex wikiDomains
   
   if emptyFolders is not empty then
      put emptyFolders
   end if
   --
   put "Local Activity" into pageTitle
   
   put "This site index lists all [[local activity]] from all the garden domains on your local machine:" into someMarkdown
   put pageArray_Construct (pageTitle, someMarkdown) into pageArray
   
   # Roster
   pageArray_AddMarkdown pageArray, "# Roster"
   put roster_ConstructText (wikiDomains, pageTitle) into rosterText
   pageArray_AddRoster pageArray, rosterText
   
   # Activity
   pageArray_AddMarkdown pageArray, "# Activity"
   put "NEIGHBORHOOD no" &CR& "CONVERSATION" into moreActivityText
   pageArray_AddActivity pageArray, pageTitle, "1 week", moreActivityText   
   
   # Clean and Return
   pageArray_StripJournal pageArray
   return pageArray
end wikiPage_LocalActivity

private function _SitesIndex wikiDomains, sitesTitle, tldDomain, pageTitle, pFirstPara
   # Construct PageArray
   if pFirstPara is empty then
      put pageTitle into shortTitle
      delete word -1 of shortTitle
      put "Here we list sites related to [[{{shortTitle}} Activity]]. See [[{{shortTitle}} Index]] for a chronological view of all contributions." into pFirstPara
      curly_ReplaceText pFirstPara, "shortTitle", shortTitle
   end if
   put pageArray_Construct (pageTitle, pFirstPara) into pageArray
   
   # Roster
   pageArray_AddMarkdown pageArray, "# Roster"
   put roster_ConstructReferenceText (tldDomain, sitesTitle) into rosterText
   pageArray_AddRoster pageArray, rosterText
   
   # Activity
   pageArray_AddMarkdown pageArray, "# Activity"
   put "NEIGHBORHOOD no" &CR& "CONVERSATION" into moreActivityText
   pageArray_AddActivity pageArray, pageTitle, "1 week", moreActivityText
   
   # Reference Links
   pageArray_AddMarkdown pageArray, "# Reference Links"
   pageArray_AddReferenceIndex pageArray, wikiDomains
   
   # Domain List
   pageArray_AddMarkdown pageArray, "# Domains"
   put markdown_LinkedBullets (wikiDomains) into mdDomains
   pageArray_AddMarkdown pageArray, mdDomains
   
   return pageArray
end _SitesIndex

function roster_ConstructActivityPage wikiDomain, rosterDomains, templatePageArray
   set the itemdelimiter to "."
   put text_InitialCaps (item 1 of wikiDomain) into rosterTitle   
   put fedwiki_MarkdownIndex (rosterDomains) into curlyArray ["rosterIndex"]
   
   put rosterTitle into curlyArray ["rosterTitle"]
   put wikiDomain into curlyArray ["wikiDomain"]
   put rosterDomains into curlyArray ["rosterText"]
   --
   put curlyArray into curlyData ["all"]
   curly_MergeAll pageArray, curlyData
   --
   put rosterTitle && "Activity" into pageTitle
   put pageTitle into pageArray ["title"]
   --
   return pageArray
end roster_ConstructActivityPage

function wikiPage_DomainTitle wikidomain, pWord
   if pWord is empty then put "Sites" into pWord
   
   set the itemdelimiter to "."
   switch item -1 of wikidomain
      case "academy"
      case "world"
      case "wiki"
      case "org"
      case "com"
      case "net"
         delete item -1 of wikidomain
         break
      default
   end switch
   replace "." with space in wikiDomain
   --
   put text_InitialCaps (wikiDomain) && pWord into pageTitle
   return pageTitle
end wikiPage_DomainTitle

function wikiPage_FilteredDomainList tldDomain, pPageTitle, pFirstPara
   -- might be renamed / same as some other handler?
   if pPageTitle is empty then
      put wikiPage_DomainTitle (tldDomain, "Sites") into pPageTitle
   end if
   put pPageTitle into pageTitle
   
   # WikiFolders
   put "*" & tldDomain & "*" into sFilter
   put wikiGarden_ListAllDomains (sFilter) into wikiFolders
   
   # Construct PageArray
   if pFirstPara is empty then
      # Construct first paragraph
      put pageTitle into shortTitle
      delete word -1 of shortTitle
      put "Here we list current sites related to [[{{shortTitle}} Sites]]. See [[{{shortTitle}} Activity]] for a chronological view of all contributions." into pFirstPara
      curly_ReplaceText pFirstPara, "shortTitle", shortTitle
   end if
   put pageArray_Construct (pageTitle, pFirstPara) into pageArray
   
   # Roster
   pageArray_AddMarkdown pageArray, "# Roster"
   put wikiPage_DomainTitle (tldDomain, "Sites") into sitesTitle
   put roster_ConstructReferenceText (tldDomain, sitesTitle) into rosterText
   pageArray_AddRoster pageArray, rosterText
   
   # Activity
   pageArray_AddMarkdown pageArray, "# Activity"
   pageArray_AddActivity pageArray, pageTitle, "1 week", "CONVERSATION"
   
   # Reference Links
   pageArray_AddMarkdown pageArray, "# Reference Links"
   pageArray_AddReferenceIndex pageArray, wikiDomains
   
   # Domain List
   pageArray_AddMarkdown pageArray, "# Domains"
   put markdown_LinkedBullets (wikiDomains) into mdDomains
   pageArray_AddMarkdown pageArray, mdDomains
   
   # Clean and Return
   pageArray_StripJournal pageArray
   return pageArray
end wikiPage_FilteredDomainList


--> WikiPage | Activity
-
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


--> WikiPage | Index
-
function wikiPage_ActivityIndex someDomain, pPageTitle, pFirstPara
   put url_GetTLD (someDomain) into tldDomain
   put "NEIGHBORHOOD no" &CR& "CONVERSATION" into moreActivityText
   put CR & "SORT titles" after moreActivityText
   put _ActivityPageArray (tldDomain, moreActivityText, "Index", "", pPageTitle, pFirstPara) into pageArray
   return pageArray
end wikiPage_ActivityIndex

function wikiPage_SitesActivity someDomain, pPageTitle, pFirstPara
   put url_GetTLD (someDomain) into tldDomain
   put "NEIGHBORHOOD no" &CR& "CONVERSATION" into moreActivityText
   put _ActivityPageArray (tldDomain, moreActivityText, "Activity", "", pPageTitle, pFirstPara) into pageArray
   return pageArray
end wikiPage_SitesActivity

function wikiPage_SitesIndex someDomain, pPageTitle, pFirstPara
   put url_GetTLD (someDomain) into tldDomain
   if pPageTitle is empty then
      put wikiPage_DomainTitle (tldDomain, "Sites") into pPageTitle
   end if
   put pPageTitle into pageTitle
   
   # WikiFolders
   put wikiGarden_ListAllDomains (tldDomain) into wikiDomains
   put wikiPage_DomainTitle (tldDomain, "Sites") into sitesTitle
   
   put _SitesIndex (wikiDomains, sitesTitle, tldDomain, pageTitle, pFirstPara) into pageArray
   
   # Clean and Return
   pageArray_StripJournal pageArray
   return pageArray
end wikiPage_SitesIndex


--> WikiPage | Missing
-
function wikiPage_CreateMissingSites pageTitle, wikiDomains, pFirstPara
   if pFirstPara is empty then
      put "Here is a list of wikidomains:" into pFirstPara
   end if
   --
   put pageArray_Construct (pageTitle, pFirstPara) into pageArray
   
   # Missing Section
   pageArray_AddMarkdown pageArray, "# Missing"
   _AddMissingSites wikiDomains, pageArray
   put the result into foundWikiFolders
   
   # Found Section
   pageArray_AddMarkdown pageArray, "# Found"
   put markdown_LinkedBullets (foundWikiFolders) into mdDomains
   pageArray_AddMarkdown pageArray, mdDomains
   --
   pageArray_AddMarkdown pageArray, "# Roster"
   put pageTitle & CR&CR & foundWikiFolders into rosterText
   pageArray_AddRoster pageArray, rosterText
   --
   pageArray_AddMarkdown pageArray, "# Activity"
   pageArray_AddActivity pageArray, pageTitle, "1 week", "CONVERSATION"
   --
   pageArray_AddMarkdown pageArray, "# Sites"
   pageArray_AddReferenceIndex pageArray, foundWikiFolders
   --
   pageArray_StripJournal pageArray
   return pageArray
end wikiPage_CreateMissingSites


--> WikiPage | Edit
-
function wikiPage_EditPage pageSlug, wikiDomain, pPageArrayTitle
   # Get Curly Template
   put wikiDialogue_Get (pageSlug, wikiDomain, "edit-page-dialogue", pPageArrayTitle) into editPageArray
   
   # Add Create Section
   wikiPage_AddCreateButtons editPageArray, wikiDomain, pageSlug
   
   # Add Transporter Section
   wikiPage_AddTransporters editPageArray
   
   return editPageArray
end wikiPage_EditPage

command wikiPage_AddCreateButtons @editPageArray, wikiDomain, pageSlug
   # ValueArray
   put pageSlug into valueArray ["pageSlug"]
   put wikiDomain into valueArray ["wikiDomain"]
   
   # Find Code Items
   put pageArray_Get (wikiDomain, pageSlug) into pageArray
   put pageArray ["story"] into storyArray
   put item 2 of the extents of storyArray into maxNum
   put 1 into imageNum
   put "http://rest.livecode.world/augmented/create_Image" into postURL
   
   set the itemdelimiter to ":"
   repeat with indexNum = 1 to maxNum
      put storyArray [indexNum]["type"] into itemType
      if itemType is not "code" then next repeat
      
      put storyArray [indexNum]["text"] into itemText
      switch item 1 of itemText
         case "Image Prompt"
            put item 2 to -1 of itemText into imagePrompt
            put imagePrompt into valueArray ["imagePrompt"]
            
            # Add Image Prompt
            pageArray_AddMarkdown editPageArray, imagePrompt
            
            # Add Button
            put "Create Image" && imageNum into buttonName
            pageArray_AddButton editPageArray, buttonName, postURL, valueArray, "", "right"
            add 1 to imageNum
            break
         default
            next repeat
      end switch 
   end repeat
end wikiPage_AddCreateButtons

command wikiPage_AddTransporters @pageArray
   pageArray_AddMarkdown pageArray, "# Transporters"
   
   pageArray_AddTransport pageArray, "POST http://rest.livecode.world/mediawiki/summary"
   pageArray_AddTransport pageArray, "POST http://rest.livecode.world/fedwiki/compact_Refs"
   
   pageArray_AddTransport pageArray, "POST http://rest.livecode.world/fedwiki/addFedwiki"
   pageArray_AddTransport pageArray, "POST http://rest.livecode.world/fedwiki/fork_Cleaner"
   pageArray_AddTransport pageArray, "POST http://rest.livecode.world/echo"
   
   pageArray_AddTransport pageArray, "POST http://rest.livecode.world/fedwiki/add_GreenBorder"
   pageArray_AddTransport pageArray, "POST http://rest.livecode.world/fedwiki/remove_GreenBorder"
end wikiPage_AddTransporters


--> WikiPage | Gallery
-
function wikiPage_Image imageURL, pPageTitle, pPageDescription, pImageCaption, pImageSourceUrl, iWidth, iHeight, iSize, pLat, pLong
   put pageArray_ConstructImageCaption (pImageCaption, pImageSourceUrl, imageURL) into sCaption
   --
   put itemArray_ConstructImage (imageURL, pImageSourceUrl, iWidth, iHeight, iSize, sCaption, pLat, pLong) into itemArray
   put _ConstructImagePageArray (pPageTitle, pPageDescription) into pageArray
   itemArray_Add itemArray, pageArray
   --
   return pageArray
end wikiPage_Image

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


function wikiPage_FiveConcepts wikiDomain, pageSlug, pModel
   return openAI_GetChatResponse ("five-concepts", wikiDomain, pageSlug, pModel)
end wikiPage_FiveConcepts

function wikiPage_ConceptGraph wikiDomain, pageSlug, pModel
   return openAI_GetChatResponse ("extract-concept-graph", wikiDomain, pageSlug, pModel)
end wikiPage_ConceptGraph

function wikiPage_Keywords wikiDomain, pageSlug, pModel
   put platform_GetPrompt ("extract-keywords") into sPrompt
   put wikiPage_GetText (wikiDomain, pageSlug) into userText
   
   # Get ChatGPT reply
   put openAI_FetchChatData (userText, sPrompt, pModel) into rData
   if rData is not an array then
      display_Data rData, "Received Data"
      return empty
   else
      put rData ["choices"][1]["message"]["content"] into sText
      return sText
   end if
end wikiPage_Keywords


--> WikiPage | Elements
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


--> PageArray | Image
-
function wikiPage_ImageEditor imageURL, imageAttributeArray, pAddMetaData
   html_DeconstructImageArray imageAttributeArray, srcURL, imageCaption, imageWidth, imageHeight, imageClass
   if imageCaption is empty then put "This is a full width image" into imageCaption
   --
   put pageArray_GetTemplate ("fedwiki.org", "edit-image-template", "Edit Image Tool", "fedwiki.org") into pageArray
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


--> WikiPage | Filter
-
function wikiPage_EmptyLocalFolders
   put "Empty Folders" into pageTitle
   --
   put wikiFarm_ListEmptyFolders (true) into emptyFolders
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

private function _ActivityPageArray tldDomain, moreActivityText, titleWord, sinceWhen, pPageTitle, pFirstPara
   if pPageTitle is empty then
      put wikiPage_DomainTitle (tldDomain, titleWord) into pPageTitle
   end if
   put pPageTitle into pageTitle
   put wikiPage_DomainTitle (tldDomain, "Sites") into sitesTitle
   
   # Construct PageArray
   if pFirstPara is empty then
      put "View all activity from [[{{sitesTitle}}]] listed in the roster below:" into pFirstPara
      curly_ReplaceText pFirstPara, "sitesTitle", sitesTitle
   end if
   put pageArray_Construct (pageTitle, pFirstPara) into pageArray
   
   # Roster
   pageArray_AddMarkdown pageArray, "# Roster"
   put roster_ConstructReferenceText (tldDomain, sitesTitle) into rosterText
   pageArray_AddRoster pageArray, rosterText
   
   # Activity
   pageArray_AddMarkdown pageArray, "# Activity"
   pageArray_AddActivity pageArray, sitesTitle, sinceWhen, moreActivityText
   
   # Clean and Return
   pageArray_StripJournal pageArray
   return pageArray
end _ActivityPageArray

private command _AddMissingSites wikiDomains, @pageArray
   put wikiGarden_ListAllDomains() into existingDomains
   set the wholematches to true
   put "http://rest.livecode.world/fedwiki/create_Wiki" into postURL
   repeat for each line wikiDomain in wikiDomains
      if wikiDomain is among the lines of existingDomains then
         put wikiDomain & CR after foundWikiFolders
      else
         put wikiDomain into valueArray ["wikiDomain"]
         pageArray_AddButton pageArray, wikiDomain, postURL, valueArray
      end if
   end repeat
   delete char -1 of foundWikiFolders
   return foundWikiFolders
end _AddMissingSites

