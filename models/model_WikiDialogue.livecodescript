script "model_WikiDialogue"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_WikiDialogue
type: model
version: 0.1


--> Working on
-
function wikiTemplate_Get templateTitle, newPageTitle, curlyData, pForkDomains, pTemplateDomain
   if pDialogueDomain is empty then put "dialogue.fedwiki.org" into pDialogueDomain
   if pForkDomains is empty then put "fedwiki.org,server.fedwiki.org" into pForkDomains
   --
   put pageArray_GetTemplate (pDialogueDomain, templateTitle, newPageTitle, pForkDomains) into pageArray
   curly_MergePageArray pageArray, curlyData
   --
   return pageArray
end wikiTemplate_Get

function wikiDialogue_Get pageSlug, wikiDomain, dialogueSlug, pPageArrayTitle, pTemplateDomain
   put pageArray_GetDialogue (dialogueSlug, pPageArrayTitle, pTemplateDomain) into pageArray
   put wikiPage_MergeDialogue (pageArray, wikiDomain, pageSlug) into pageArray
   return pageArray
end wikiDialogue_Get

function wikiPage_MergeDialogue pageArray, wikiDomain, pageSlug
   put wikiDialogue_CurlyData (wikiDomain, pageSlug) into curlyData
   curly_MergePageArray pageArray, curlyData
   pageArray_CleanJournal pageArray
   return pageArray
end wikiPage_MergeDialogue

function wikiDialogue_CurlyData wikiDomain, pageSlug
   put wikiDomain into curlyData ["all"]["wikiDomain"]
   --
   put pageSlug into curlyData ["all"]["originalSlug"]
   put fedwiki_ConstructTitle (pageSlug) into pageTitle
   put pageTitle into curlyData ["all"]["New Page Title"]
   put urlEncode (pageTitle) into curlyData ["all"]["URLEncodedTitle"]
      
   # Check Wikipedia for Title
   mediawiki_NormaliseTitle pageSlug, mediaWikiTitle, pageID
   if mediaWikiTitle is not empty then
      put mediaWikiTitle into curlyData ["all"]["Wikipedia Title"]
      -- put pageTitle into curlyData ["all"]["originalTitle"]
   end if
   
   return curlyData
end wikiDialogue_CurlyData


--> PageArray
-
function pageArray_GetDialogue dialogueSlug, pPageTitle, pDialogueDomain, 
   if pPageTitle is empty then
      put fedwiki_ConstructTitle (dialogueSlug) into pPageTitle
   end if
   
   # Fetch Dialogue
   if pDialogueDomain is empty then
      put pageArray_GetTemplate ("dialogue.fedwiki.org", dialogueSlug, pPageTitle) into pageArray
   else
      put pageArray_GetTemplate (pDialogueDomain, dialogueSlug, pPageTitle) into pageArray
   end if
   put "html" into pageArray ["plugin"]
   pageArray_CleanJournal pageArray
   --
   return pageArray
end pageArray_GetDialogue

function pageArray_GetTemplate wikiDomain, templateTitle, newTitle, pForkDomains
   if pForkDomains is empty then put "fedwiki.org,server.fedwiki.org" into pForkDomains
   
   put fedwiki_ConstructSlug (templateTitle) into pageSlug
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   --
   if pageArray is not an array then
      put pageArray_Fetch ("dialogue.fedwiki.org", pageSlug) into pageArray
   end if
   -- if pageArray is not an array then put pageArray_Fetch ("template.fedwiki.org", pageSlug) into pageArray
   --
   pageArray_Rename pageArray, newTitle
   pageArray_CleanFork pageArray, pForkDomains
   --
   return pageArray
end pageArray_GetTemplate
