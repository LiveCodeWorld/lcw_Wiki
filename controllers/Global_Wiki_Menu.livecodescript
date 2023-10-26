script "Global | Wiki | Menu"
--> MetaData
-
license: GPLv3
name: Global | Wiki | Menu
type: controller
version: 0.4

/*This menu is used to control a Livecode wiki browser.*/


--> Menu | Props
-
local LocalArray

getprop menu_Target [tObject]
   put wiki_Started() into LocalArray ["wikiStarted"]
   return the display_View of tObject
end menu_Target

getprop dream_Domains
   put "Jelly Fish" & CR after topDomains
   put "-" & CR after topDomains
   put "david.icotopia.io" & CR after topDomains
   put "trevor.icotopia.io" & CR after topDomains
   put "video.icotopia.io" & CR after topDomains
   put "david.culturecollective.cc" & CR after topDomains
   --
   delete char -1 of topDomains
   return topDomains
end dream_Domains

getprop top_Domains
   put "Jelly Fish" & CR after topDomains
   put "Worldscape" & CR after topDomains
   put "-" & CR after topDomains
   put "outlandish.academy" & CR after topDomains
   put "david.outlandish.academy" & CR after topDomains
   put "nina.outlandish.academy" & CR after topDomains
   put "trevor.outlandish.academy" & CR after topDomains
   --
   delete char -1 of topDomains
   return topDomains
end top_Domains

getprop show_HiddenFiles
   put finder_GetShowInvisibleFiles() into someBoolean
   return someBoolean
end show_HiddenFiles

getprop disabled_StartWiki
   return LocalArray ["wikiStarted"] is true
end disabled_StartWiki

getprop disabled_StopWiki
   return LocalArray ["wikiStarted"] is false
end disabled_StopWiki

function _GetWikiView mTarget
   -- "browser_View" is on card script of stack "Fedwiki Editor"
   put the wiki_View of cd 1 of stack "Fedwiki Editor" into wikiView
   return wikiView
end _GetWikiView

private function _GetDomain
   return empty
end _GetDomain


--> Global | Wiki | Menu
-
on menu_StartWiki
   wiki_Start
end menu_StartWiki

on menu_StopWiki
   wiki_Stop
end menu_StopWiki

private on ____
end ____

on menu_WikiBrowser
   get "http://localhost:3000/view/welcome-visitors/view/livecode-managed-wiki/view/polyglot-authoring-experience/view/obeya-studio/view/complex-problems/view/cynefin-template/view/cynefin/view/sense-maker#"
   display_Browser it, empty, true
end menu_WikiBrowser

on menu_MatrixChat
   display_Browser "https://app.element.io/#/room/#fedwiki:matrix.org"
end menu_MatrixChat

private on ___
end ___

on menu_IplayerDownloadsFolder
   put _GetDomain() into wikiDomain
   put fedwiki_LocalAssetsFolder (wikiDomain) into assetsFolder
   --
   answer folder "Iplayer downloads..." with assetsFolder
   put it into dFolder
   --
   iplayer_SetDefaultOutupFolder dFolder
end menu_IplayerDownloadsFolder

on menu_AssetsFolder
   put _GetDomain() into wikiDomain
   put fedwiki_LocalAssetsFolder (wikiDomain) into assetsFolder
   finder_Reveal assetsFolder
end menu_AssetsFolder

on menu_WikiRootFolder
   put fedwiki_GetLocalWikiRoot() into wikiRootFolder
   finder_Reveal wikiRootFolder
end menu_WikiRootFolder

private on ____
end ____

on menu_ImageSearch
   -- https://commons.wikimedia.org/w/api.php?action=query&generator=images&prop=imageinfo&gimlimit=500&redirects=1&titles=Cat&iiprop=timestamp|user|userid|comment|canonicaltitle|url|size|dimensions|sha1|mime|thumbmime|mediatype|bitdepth
   -- /w/api.php?action=query&format=json&origin=*&titles=North%20Africa&generator=allimages
   put lcw_Ask ("What do you want to search for", "Cat") into someTitle
   put urlencode (someTitle) into encodedTitle
   -- replace "+" with "%20" in encodedTitle
   --
   put "https://commons.wikimedia.org" into restURL
   put "/w/api.php?action=query&generator=images&prop=imageinfo" after restURL
   put "&gimlimit=100"  after restURL
   put "&redirects=1"  after restURL
   
   -- put "/w/api.php?action=query&format=json&origin=*&generator=allimages" after restURL
   put "&titles=" & encodedTitle after restURL
   put "&iiprop=timestamp|user|userid|comment|canonicaltitle|url|size|dimensions|sha1|mime|thumbmime|mediatype|bitdepth" after restURL
   put "&format=json" after restURL
   
   put url restURL into someJSON
   display_JSON  someJSON
end menu_ImageSearch

on _
end _

on submenu_Medium
   return "Global | Medium | Menu"
end submenu_Medium

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Menu")
end submenu_Dev
