script "lib_WikiPage"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_WikiPage
type: library
version: 0.1

/*
This library is about handlers that constuct specific crafted wiki pages.

The functions all return pageArrays, which can then be used to create wiki-pages or ghost-pages.
*/


--> Working on
-
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

command pageArray_AddReferenceIndex @pageArray, wikiDomains
   repeat for each line wikiDomain in wikiDomains
      pageArray_AddReference pageArray, wikiDomain, wikiDomain, wikiDomain, "welcome-visitors"
      -- pageArray_AddReference pageArray, pageTitle, wikiDomain, refText, pPageSlug, pID
   end repeat
   delete char -1 of sMarkdown
   return sMarkdown
end pageArray_AddReferenceIndex
