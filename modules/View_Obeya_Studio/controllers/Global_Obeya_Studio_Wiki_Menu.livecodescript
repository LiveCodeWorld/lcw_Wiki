script "Global | Obeya | Studio | Wiki | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Obeya | Studio | Wiki | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_Target [tObject]
   -- return _BrowserView(tObject)
   put the browser_View of tObject into browserView
   if exists (browserView) then
      return browserView
   else
      put line 1 of display_List ("View|Obeya|Studio") into browserView
      if exists (browserView) then return browserView
      return empty
   end if
end menu_Target

private function _BrowserView tObject
   if exists (tObject) then
      put the browser_View of testView into browserView
      return browserView
   else
      return empty
   end if
end _BrowserView

getprop disabled_DisplayWiki [browserView]
   return exists (browserView) is false
end disabled_DisplayWiki

getprop displayDomain_Param [browserView]
   put the browser_Domain of browserView into wikiDomain
   return wikiDomain
end displayDomain_Param

private function _ListToplevelDomains
   put wiki_ListTopLevelDomains() into wikiDomains
   url_SortDomainIndex wikiDomains
   return wikiDomains
end _ListToplevelDomains

getprop displayDomain_Params
   put _ListToplevelDomains() into wikiDomains
   --
   if wikiDomains is empty then
      return "ChatGPT,Localhost"
   else
      return wikiDomains & ",-,ChatGPT,Localhost"
   end if
end displayDomain_Params

getprop createDomainList_Params
   put _ListToplevelDomains() into wikiDomains
   return wikiDomains
end createDomainList_Params


--> Global | Obeya | Studio | Wiki | Menu
-
on menu_DisplayDomain browserView, wikiDomain   
   if the shiftKey is "down" then put empty into browserView
   switch wikiDomain
      case "ChatGPT"
         display_WikiBrowser "https://chat.openai.com/", browserView
         break
      default
         -- display_LocalWiki wikiDomain, browserView
         display_Wiki wikiDomain, browserView
   end switch
end menu_DisplayDomain

on menu_CreateDomainList browserView, wikiDomain
   set the itemdelimiter to "."
   put item 1 of wikiDomain into tldWord
   --
   put wikiPage_FilteredDomainList (tldWord) into pageArray
   set the ghost_PageArray of browserView to pageArray
end menu_CreateDomainList

private on _
end _

getprop speak_Params [browserView]
   return the page_Titles of browserView
end speak_Params

on menu_Speak browserView, pageTitle
   put the wiki_Domain of browserView into wikiDomain
   put the lineUp_Data  of browserView into lineUpData
   put indexArray_Find (lineUpData, "title", pageTitle) into itemNum
   put lineUpData [itemNum] into pageArray
   --
   put pageArray_Text (pageArray) into pageText
   --
   put pageSlug & ".mp3" into shortFile
   put wiki_ConstructAssetFile (shortFile, wikiDomain) into audioFile
   openAI_TextToSpeech pageText, audioFile
   --
   finder_Reveal audioFile
end menu_Speak

on menu_Today browserView
   put wikiPage_TodaysActivity() into pageArray
   set the ghost_PageArray of browserView to pageArray
end menu_Today

on menu_EmptyFolders browserView
   put wikiPage_EmptyLocalFolders() into pageArray
   set the ghost_PageArray of browserView to pageArray
end menu_EmptyFolders

private on __
end __

on menu_ListLocalWikis
   display_LocalWikis
end menu_ListLocalWikis

on menu_ListDynadotDomains
   display_Dynadot
end menu_ListDynadotDomains

on menu_ListDynadotWikis displayView
   put lcw_Ask ("Which domain...", "outlandish.academy", "Dynadot Domain", displayView) into domainName
   display_DynadotWikis domainName, displayView, ""
end menu_ListDynadotWikis

private on ___
end ___

on menu_ObeyaStudioTools browserView
   put the view_Name of browserView into viewName
   display_ModuleTools viewName
end menu_ObeyaStudioTools

on menu_MenuGroupTools
   put the stack_Folder of stack "View|Menu|Group" into moduleFolder
   put project_PathFromFolder (moduleFolder) into stackPath
   display_ModuleTools stackPath
end menu_MenuGroupTools
