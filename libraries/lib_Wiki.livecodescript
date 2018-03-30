script "lib_Wiki"
--> MetaData
-
license: GPLv3
name: lib_Wiki
type: library
version: 0.1

/*
This is a library for working with Fedwiki.
*/



--> Display
-
command display_FedwikiPageJson pageJson
   put json_ToArray (pageJson) into pageArray
   display_FedwikiPageArray pageArray
   put the result into arrayView
   return arrayView
end display_FedwikiPageJson
   
command display_FedwikiPageArray pageArray
   display_Array pageArray, "Fedwiki Page JSON"
   put the result into arrayView
   return arrayView
end display_FedwikiPageArray

command display_WikiPageArray fedwikiDomain, pageSlug
   put fedwiki_FetchPageArray (fedwikiDomain, pageSlug) into pageArray
   put pageSlug,fedwikiDomain into someTitle
   display_Array pageArray, someTitle
end display_WikiPageArray

function fedwiki_GitHubReadmePageJson githubProjectName
   -- put fedwiki_GitHubReadmePageJson ("lcw_Menus") into readmeJSON
   put github_FetchReadmeMD (githubProjectName) into readmeMarkdown
   --
   put "Project" && githubProjectName into pageTitle
   put wiki_Merge ("On this page we describe the [[Github]] project {{githubProjectName}}.") into firstPara
   --
   put fedwiki_ConstructNewPageArray (pageTitle, firstPara) into pageArray
   fedwiki_AddMarkdownToPageArray pageArray, readmeMarkdown
   fedwiki_AddMarkdownToPageArray pageArray, "# See also"
   fedwiki_AddMarkdownToPageArray pageArray, "- [[Github]]"
   --
   fedwiki_CleanJournalArray pageArray
   put json_FromArray (pageArray) into readmeJSON
   return readmeJSON
end fedwiki_GitHubReadmePageJson

function wiki_Merge someText
   replace "[" with "{{{" in someText
   replace "]" with "}}}" in someText
   put merge (someText) into mergedText
   replace "{{{" with "[" in mergedText
   replace "}}}" with "]" in mergedText
   return mergedText
end wiki_Merge


--> Wiki
-
function wiki_GetSiteFolder
   put $HOME & "/.wiki/" into wikiSiteFolder
   return wikiSiteFolder
end wiki_GetSiteFolder

function wiki_GetWikiClientFolder
   put wiki_GetModulesFolder() & "wiki-client/" into wikiClientFolder
   return wikiClientFolder
end wiki_GetWikiClientFolder

function wiki_GetModulesFolder
   return "/usr/local/lib/node_modules/wiki"
end wiki_GetModulesFolder


--> Javascript
-
function javascript_ConstructInternalLink pageTitle
   put merge ("wiki.doInternalLink('[[pageTitle]]')") into someJavascript
   return someJavascript
end javascript_ConstructInternalLink

function javascript_ConstructFooterHeight pSomeHeight
   -- if pSomeHeight is empty then put 18 into pSomeHeight
   if pSomeHeight is empty then put 60 into pSomeHeight
   put merge ("document.querySelector('section.main').style.bottom='[[pSomeHeight]]px'") into someJavascript
   return someJavascript
end javascript_ConstructFooterHeight

function javascript_ConstructHideSiteOwner
   put "document.getElementById('site-owner').style.visibility = 'hidden'" into someJavascript
   return someJavascript
end javascript_ConstructHideSiteOwner

function javascript_ConstructFooterVisibility someBoolean
   -- put "document.getElementById('site-owner').style.visibility = 'hidden'" into someJavascript
   -- put "var myElement = document.querySelector('footer');myElement.style.visibility = 'hidden'" into someJavascript
   -- put "var myElement = document.querySelector('footer');myElement.style.visibility = 'visible'" into someJavascript
   
   if someBoolean is true then
      put "document.querySelector('footer').style.visibility = 'hidden'" into someJavascript
   else
      put "document.querySelector('footer').style.visibility = 'visible'" into someJavascript
   end if
   return someJavascript
end javascript_ConstructFooterVisibility
