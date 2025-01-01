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
function wikiPage_ForkDomains wikiDomain, pForkDomains
   put url_GetTLD (wikiDomain) into forkDomains
   put CR & "fedwiki.org" after forkDomains
   if pForkDomains is not empty then
      replace comma with CR in pForkDomains
      put CR & pForkDomains after forkDomains
   end if
   return forkDomains
end wikiPage_ForkDomains

function wikiPage_EditOrCreate wikiDomain, pageSlug, pPageTitle
   if pPageTitle is empty then
      put fedwiki_ConstructTitle (pageSlug) into pPageTitle
   end if
   
   put wikiFile_Construct (wikiDomain, pageSlug) into pageJsonFile
   --
   if there is a file pageJsonFile then
      put "Edit Page" && kwote (pPageTitle, "'") into editTitle
      put wikiPage_EditPage (pageSlug, wikiDomain, editTitle) into pageArray
   else
      put wikiDialogue_CurlyData (wikiDomain, pageSlug) into curlyData
      put curlyData ["all"]["Wikipedia Title"] into mwTitle
      if mwTitle is not empty then
         put "Create Page" && kwote (mwTitle, "'") into createTitle
      else
         put "Create Page" && kwote (pPageTitle, "'") into createTitle
      end if
      
      -- put wikiDialogue_Get (pageSlug, wikiDomain, "create-page-dialogue", createTitle) into pageArray
      -- put wikiPage_MergeDialogue (pageArray, wikiDomain, pageSlug) into pageArray
      put pageArray_GetDialogue ("create-page-dialogue", createTitle, wikiDomain) into pageArray
      curly_MergePageArray pageArray, curlyData
      pageArray_CleanJournal pageArray
   end if
   return pageArray
end wikiPage_EditOrCreate

function wikiPageEditImages pageArray
   /*
   "size": "wide",
   "text": "We can [[drag-and-drop]] an image from [[Photos]] while working on [[localhost]].",
   "width": "420",
   "location": {
   "latitude": "51.509413888888886",
   "longitude": "-0.12234166666666667"
   },
   "id": "771a82a9ee369a96",
   "height": "315",
   "url": "/assets/plugins/image/0bc52c9aeab76ab47feb3e72d7965ca5.jpg",
   "type": "image"
   */
   
   put pageArray ["story"] into storyArray
   put "thumbnail" into sSize
   
   put "Images for you to fix..." into mdText
   put pageArray_Construct ("Edit Images", mdText, "tool") into pageArray
   --
   put 1 into newItemNum
   repeat with itemNum = 1 to item 2 of the extents of storyArray
      put storyArray [itemNum] into itemArray
      if itemArray ["type"] = "image" then
         --
         put itemArray into hiddenArray
         put colour_GetRandom() into rgbColour
         put colour_RgbToHex (rgbColour) into bColour
         --
         put itemArray ["url"] into imageURL
         put itemArray ["text"] into cText
         delete variable hiddenArray ["text"]
         --
         put empty into linkURL
         put empty into sLat
         put empty into sLong
         put "wide" into sSize
         pageArray_AddImage pageArray, imageURL, cText, linkURL, sLat, sLong, sSize
         --
         put platform_RestUrl ("echo") into restURL
         pageArray_AddForm pageArray, "Edit Image", restURL, sSize, "size", bColour, "Images", 22, hiddenArray
         pageArray_AddPageFold pageArray, "-"
         --
         add 1 to newItemNum
      end if
   end repeat
   --
   if newItemNum > 1 then
      return pageArray
   else
      return empty
   end if
end wikiPageEditImages

function wikiPage_EditPage pageSlug, wikiDomain, pPageArrayTitle
   # Get Curly Template
   put wikiDialogue_Get (pageSlug, wikiDomain, "edit-page-dialogue", pPageArrayTitle) into pageArray
   -- put pageArray_GetDialogue ("edit-page-dialogue", pPageArrayTitle, wikiDomain) into pageArray
   -- put wikiPage_MergeDialogue (pageArray, wikiDomain, pageSlug) into pageArray
   
   # Add Create Section
   wikiPage_AddCreateButtons pageArray, wikiDomain, pageSlug
   
   # Add Transporter Section
   wikiPage_AddTransporters pageArray
   
   return pageArray
end wikiPage_EditPage

function wikiPage_Help subDomain, curlyData, pScriptHelp, pForkDomains
   -- subDomain = scriptType
   put curlyData ["title"] into pageTitle
   put help_ConstructDomain (subDomain) into wikiDomain
   
   # Fetch Template
   put wikiTemplate_GetHelp (subDomain) into pageArray
   if pageArray ["plugin"] = "Error" then return pageArray -- could use "title"
   if pageArray_Check (pageArray) is false then return pageArray_Construct  ("Error", "Some error with wikiTemplate_GetHelp()", "Error")
   
   # Rename
   help_RenameTemplate pageArray, pageTitle, wikiDomain
   
   # Curly Merge
   curly_MergePageArray pageArray, curlyData
   if pScriptHelp is not empty then
      put pageArray ["story"][1]["text"] into oText
      put pScriptHelp & CR&CR & oText into newFirstPara
      put newFirstPara into pageArray ["story"][1]["text"]
   end if
   
   # Add Fork
   pageArray_StripJournal pageArray
   put wikiPage_ForkDomains (wikiDomain, pForkDomains) into forkDomains
   pageArray_AddFork pageArray, forkDomains
   --
   return pageArray
end wikiPage_Help

function wikiPage_WelcomeVisitors wikiDomain
   put url_GetTLD (wikiDomain) into tldDomain
   put tldDomain into pageTitle
   replace "." with space in pageTitle
   put text_InitialCaps (pageTitle) into pageTitle
   
   put url_GetTLD (wikiDomain) into tldDomain
   put wikiPage_DomainStem (tldDomain) into pageTitle   
   --
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put wikiDialogue_Get (pageSlug, tldDomain, "welcome-visitors-dialogue", "Welcome Visitors") into pageArray
   
   # Add Fork
   put tldDomain &CR& "fedwiki.org" into tldDomains
   pageArray_AddFork pageArray, tldDomains
   --
   delete variable pageArray ["plugin"]
   return pageArray
end wikiPage_WelcomeVisitors

function wikiPage_EmptyDomains wikiDomain
   put "Empty Domains" into pageTitle
   put "Empty wiki-folder for domain" && wikiDomain into someMarkdown
   put wikiDomain_ListEmptyFolders (wikiDomain, true) into emptyDomains
   --
   put _SitesIndex (emptyDomains, pageTitle, wikiDomain, pageTitle, someMarkdown) into pageArray
   
   # Clean and Return
   pageArray_StripJournal pageArray
   return pageArray
end wikiPage_EmptyDomains

function wikiPage_GardenIndex gardenName, wikiDomain, pSinceWhen
   put gardenName && "Garden Index" into pageTitle
   put "This [[garden]] contains the following domains:" into someMarkdown
   --
   put pageTitle into rosterTitle
   put "Sites" into word -1 of rosterTitle
   --
   put "NEIGHBORHOOD no" &CR& "CONVERSATION" into moreActivityText
   put CR & "SORT titles" after moreActivityText
   --
   put _Activity (pageTitle, rosterTitle, wikiDomain, pSinceWhen, moreActivityText, someMarkdown) into pageArray
   
   # Clean and Return
   pageArray_StripJournal pageArray
   return pageArray
end wikiPage_GardenIndex

function wikiPage_GardenActivity gardenName, wikiDomain, pSinceWhen
   put gardenName && "Garden Activity" into pageTitle
   put "This [[garden]] contains the following domains:" into someMarkdown
   --
   put pageTitle into rosterTitle
   put "Sites" into word -1 of rosterTitle
   --
   put "NEIGHBORHOOD no" &CR& "CONVERSATION" into moreActivityText
   --
   put _Activity (pageTitle, rosterTitle, wikiDomain, pSinceWhen, moreActivityText, someMarkdown) into pageArray
   
   # Clean and Return
   pageArray_StripJournal pageArray
   return pageArray
end wikiPage_GardenActivity

function wikiPage_GardenSites gardenName, wikiDomain
   put gardenName && "Garden Sites" into pageTitle
   -- put "This [[garden]] contains the following domains:" into someMarkdown
   put empty into someMarkdown
   
   put wikiGarden_ListDomains (gardenName) into wikiDomains  
   put _SitesIndex (wikiDomains, pageTitle, wikiDomain, pageTitle, someMarkdown) into pageArray
   
   # Clean and Return
   pageArray_StripJournal pageArray
   return pageArray
end wikiPage_GardenSites

function wikiPage_LocalActivity
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

function roster_ConstructActivityPage wikiDomain, rosterDomains, templatePageArray
   set the itemdelimiter to "."
   put text_InitialCaps (item 1 of wikiDomain) into rosterTitle   
   put markdown_LinkedBullets (rosterDomains) into curlyArray ["rosterIndex"]
   
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
   put wikiPage_DomainStem (wikidomain) && pWord into domainTitle
   return domainTitle
end wikiPage_DomainTitle

function wikiPage_DomainStem wikidomain
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
   put text_InitialCaps (wikiDomain) into pageTitle
   return pageTitle
end wikiPage_DomainStem

function wikiPage_FilteredDomainList tldDomain, pPageTitle, pFirstPara
   -- might be renamed / same as some other handler?
   if pPageTitle is empty then
      put wikiPage_DomainTitle (tldDomain, "Sites") into pPageTitle
   end if
   put pPageTitle into pageTitle
   
   # WikiFolders
   put "*" & tldDomain & "*" into sFilter
   put wikiDomain_List (sFilter) into wikiFolders
   
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
   
   if pPageTitle is empty then
      put wikiPage_DomainTitle (tldDomain, "Sites") into pageTitle
   else
      put pPageTitle into pageTitle
      -- put "Sites" into word -1 of sitesTitle
   end if
   put pageTitle into sitesTitle
   
   # WikiFolders
   put wikiDomain_List (tldDomain) into wikiDomains
   
   # PageArray
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
command wikiPage_AddCreateButtons @editPageArray, wikiDomain, pageSlug
   # ValueArray
   put pageSlug into valueArray ["pageSlug"]
   put wikiDomain into valueArray ["wikiDomain"]
   
   # Find Code Items
   put pageArray_Get (wikiDomain, pageSlug) into pageArray
   put pageArray ["story"] into storyArray
   put item 2 of the extents of storyArray into maxNum
   put 1 into imageNum
   put platform_RestUrl ("augmented/create_Image") into postURL
   
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
   
   put "POST" && platform_RestUrl ("mediawiki/summary") into postBit
   pageArray_AddTransport pageArray, postBit
   --
   put "POST" && platform_RestUrl ("fedwiki/compact_Refs") into postBit
   pageArray_AddTransport pageArray, postBit
   --
   put "POST" && platform_RestUrl ("fedwiki/addFedwiki") into postBit
   pageArray_AddTransport pageArray, postBit
   --
   put "POST" && platform_RestUrl ("fedwiki/fork_Cleaner") into postBit
   pageArray_AddTransport pageArray, postBit
   --
   put "POST" && platform_RestUrl ("echo") into postBit
   pageArray_AddTransport pageArray, postBit
   --
   put "POST" && platform_RestUrl ("fedwiki/add_GreenBorder") into postBit
   pageArray_AddTransport pageArray, postBit
   --
   put "POST" && platform_RestUrl ("fedwiki/remove_GreenBorder") into postBit
   pageArray_AddTransport pageArray, postBit
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
   --
   put platform_RestUrl ("mediawiki/gallery") into restURL
   pageArray_AddForm pageArray, "Find Images", restURL, pageTitle, "title", "lightpink", "Mediawiki", 22
   --
   put platform_RestUrl("mediawiki/related") into restURL
   pageArray_AddForm pageArray, "Pages", restURL, pageTitle, "title", "lightgreen", "Find Related", 24
   --
   put platform_RestUrl ("openverse") into restURL
   pageArray_AddForm pageArray, "Openverse", restURL, pageTitle, "search_Term", "orange", "Find Image", 24
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

private function _ActivityPageArray tldDomain, moreActivityText, titleWord, sinceWhen, pPageTitle, pFirstPara
   if pPageTitle is empty then
      put wikiPage_DomainTitle (tldDomain, titleWord) into pageTitle
      put wikiPage_DomainTitle (tldDomain, "Sites") into sitesTitle
   else
      put pPageTitle into pageTitle
      if word -1 of pageTitle = "Sites" then
         put titleWord into word -1 of pageTitle
      end if
      put pageTitle into sitesTitle
      put "Sites" into word -1 of sitesTitle
   end if
   --
   put _Activity (pageTitle, sitesTitle, tldDomain, sinceWhen, moreActivityText, pFirstPara) into  pageArray
   return pageArray
end _ActivityPageArray

private function _Activity pageTitle, sitesTitle, tldDomain, sinceWhen, moreActivityText, pFirstPara
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
end _Activity

private command _AddMissingSites wikiDomains, @pageArray
   put wikiDomain_List() into existingDomains
   set the wholematches to true
   put platform_RestUrl("fedwiki/create_Wiki")  into postURL
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
