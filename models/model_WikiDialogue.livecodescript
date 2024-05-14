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
   mediawiki_NormaliseTitle pageSlug, mediaWikiTitle, pageID
   put fedwiki_ConstructTitle (pageSlug) into pageTitle
   --
   put urlEncode (pageTitle) into curlyData ["all"]["URLEncodedTitle"]
   put pageTitle into curlyData ["all"]["New Page Title"]
   put mediaWikiTitle into curlyData ["all"]["Wikipedia Title"]
   put pageSlug into curlyData ["all"]["originalSlug"]
   put wikiDomain into curlyData ["all"]["wikiDomain"]
   --
   put pageArray_GetDialogue (dialogueSlug, pPageArrayTitle, pTemplateDomain) into pageArray
   curly_MergePageArray pageArray, curlyData
   --
   pageArray_CleanJournal pageArray
   return pageArray
end wikiDialogue_Get


--> PageArray
-
function pageArray_GetTemplate wikiDomain, templateTitle, newTitle, pForkDomains
   if pForkDomains is empty then put "fedwiki.org,server.fedwiki.org" into pForkDomains
   
   put fedwiki_ConstructSlug (templateTitle) into pageSlug
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   --
   pageArray_Rename pageArray, newTitle
   pageArray_CleanFork pageArray, pForkDomains
   --
   return pageArray
end pageArray_GetTemplate

function pageArray_GetDialogue dialogueSlug, pPageTitle, pDialogueDomain, 
   if pDialogueDomain is empty then put "dialogue.fedwiki.org" into pDialogueDomain
   if pPageTitle is empty then
      put fedwiki_ConstructTitle (dialogueSlug) into pPageTitle
   end if
   
   # Fetch Dialogue
   put pageArray_GetTemplate (pDialogueDomain, dialogueSlug, pPageTitle) into pageArray
   put "html" into pageArray ["plugin"]
   pageArray_CleanJournal pageArray
   --
   return pageArray
end pageArray_GetDialogue
