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
   put the openprocesses into oProcesses
   if "wiki" is among the lines of oProcesses then
      return "delete"
   else
      return false
   end if
end disabled_StartWiki

getprop disabled_StopWiki
   put the openprocesses into oProcesses
   if "wiki" is among the lines of oProcesses then
      return false
   else
      return "delete"
   end if
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
on menu_WikiBrowser
   get "http://localhost:3000/view/welcome-visitors/view/livecode-managed-wiki/view/polyglot-authoring-experience/view/obeya-studio/view/complex-problems/view/cynefin-template/view/cynefin/view/sense-maker#"
   display_Browser it, empty, true
end menu_WikiBrowser

on menu_MatrixChat
   display_Browser "https://app.element.io/#/room/#fedwiki:matrix.org"
end menu_MatrixChat

private on ___
end ___

on menu_StartWiki
   set the cursor to watch
   open process wiki for update
   -- Federated Wiki server listening on 3000 in mode: development
   read from process wiki until "Federated Wiki server listening on 3000 in mode: development"
   put it into wikiInfoToParse
   
   put "http://localhost:3000" into localWikiURL
   launch url localWikiURL
end menu_StartWiki

on menu_StopWiki
   if the platform = "MacOS" then
      kill process wiki
   else
      close process wiki
   end if
   -- put the openprocesses
end menu_StopWiki

private on ____
end ____

on menu_DownloadIplayer
   put iplayer_GetDefaultOutupFolder()
end menu_DownloadIplayer

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
