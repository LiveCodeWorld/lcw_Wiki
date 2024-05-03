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
   if exists (browserView) is false then
      put line 1 of display_List ("View|Obeya|Studio") into browserView
      if exists (browserView) is false then
         return empty
      end if
   end if
   --
   put the page_Titles of browserView into LocalArray ["pageTitles"]
   return browserView
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

getprop speak_Params [browserView]
   return LocalArray ["pageTitles"]
end speak_Params

getprop translateToGerman_Params [browserView]
   return LocalArray ["pageTitles"]
end translateToGerman_Params

getprop translateToIcelandic_Params [browserView]
   return LocalArray ["pageTitles"]
end translateToIcelandic_Params

getprop translateToWelsh_Params [browserView]
   return LocalArray ["pageTitles"]
end translateToWelsh_Params


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

on menu_CreateDomainList browserView, tldDomain
   -- put word -2 to -1 of wikidomain into tldDomain
   put wikiPage_FilteredDomainList (tldDomain) into pageArray
   set the ghost_PageArray of browserView to pageArray
end menu_CreateDomainList

private on _
end _

on menu_Speak browserView, pageTitle
   put _GetPageText (browserView, pageTitle) into pageText
   --
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put the wiki_Domain of browserView into wikiDomain
   --
   put pageSlug & ".mp3" into shortFile
   put wiki_ConstructAssetFile (shortFile, wikiDomain) into audioFile
   --
   openAI_TextToSpeech pageText, audioFile
   --
   finder_Reveal audioFile
end menu_Speak

private function _GetTranslation browserView, pageTitle, sLang, pModel
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put the wiki_Domain of browserView into wikiDomain
   --
   put _GetPageText (browserView, pageTitle) into pageText
   put wikiPage_FetchTranslation (pageText, sLang, pModel) into sTranslation
   put wikiPage_ConstructTranslation (sLang, sTranslation, wikiDomain, pageSlug, pageTitle, pageText) into tPageArray
   --
   return tPageArray
end _GetTranslation

private function _GetPageText browserView, pageTitle
   put the lineUp_Data  of browserView into lineUpData
   --
   put indexArray_Find (lineUpData, "title", pageTitle) into itemNum
   put lineUpData [itemNum] into pageArray
   --
   put pageArray_Text (pageArray) into pageText
   return pageText
end _GetPageText

on menu_TranslateToGerman browserView, pageTitle
   put _GetTranslation (browserView, pageTitle, "German") into pageArray
   set the ghost_PageArray of browserView to pageArray
end menu_TranslateToGerman

on menu_TranslateToIcelandic browserView, pageTitle
   put _GetTranslation (browserView, pageTitle, "Icelandic") into pageArray
   set the ghost_PageArray of browserView to pageArray
end menu_TranslateToIcelandic

on menu_TranslateToWelsh browserView, pageTitle
   put _GetTranslation (browserView, pageTitle, "Welsh") into pageArray
   set the ghost_PageArray of browserView to pageArray
end menu_TranslateToWelsh

private on __
end __

on menu_ShowTerminal browserView
   put "radar" into shortPluginName
   --
   put the other_Browser of browserView into oBrowser
   put "cd $(npm prefix -g); npm i wiki-plugin-" & shortPluginName into sShellCommand
   --
   display_Xterm oBrowser, sShellCommand
end menu_ShowTerminal

on menu_ShowChatGpt browserView
   put the other_Browser of browserView into oBrowser
   set the browser_URL of oBrowser to "https://auth0.openai.com/authorize?client_id=TdJIcbe16WoTHtN95nyywh5E4yOo6ItG&scope=openid%20email%20profile%20offline_access%20model.request%20model.read%20organization.read%20organization.write&response_type=code&redirect_uri=https%3A%2F%2Fchat.openai.com%2Fapi%2Fauth%2Fcallback%2Fauth0&audience=https%3A%2F%2Fapi.openai.com%2Fv1&state=TCb84sVofxommgO0nGSP6XeL_hIdIIvaeXtgt26fiD4&code_challenge=N28l-klMH55P8456l89bQgkMxADesMuYms3VYIyCECQ&code_challenge_method=S256"
end menu_ShowChatGpt

on menu_ShowAsana browserView
   put the other_Browser of browserView into oBrowser
   set the browser_URL of oBrowser to "https://app.asana.com/0/1206580415766932/1206580454304519"
end menu_ShowAsana

private on ___
end ___

on submenu_Dev
   return menu_DevTitle("Global | Obeya | Studio | Wiki | Menu")
end submenu_Dev

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

on menu_Today browserView
   put wikiPage_TodaysActivity() into pageArray
   set the ghost_PageArray of browserView to pageArray
end menu_Today

on menu_EmptyFolders browserView
   put wikiPage_EmptyLocalFolders() into pageArray
   set the ghost_PageArray of browserView to pageArray
end menu_EmptyFolders
