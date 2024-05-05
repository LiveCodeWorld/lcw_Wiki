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
   
   # Lineup URLs are faster than LineUp Data
   put the lineup_Urls of browserView into lineUpURLs
   put lineUpURLs into LocalArray ["lineUpURLs"]
   
   # PageTitles
   put _SlugsFromLineUpURLs (lineUpURLs) into LocalArray ["pageTitles"]
   
   return browserView
end menu_Target

private function _SlugsFromLineUpURLs lineUpURLs
   -- put the page_Titles of browserView into LocalArray ["pageTitles"]
   put 1 into indexNum
   repeat for each line sURL in lineUpURLs
      set the itemdelimiter to slash
      put item -1 of sURL into pageSlug
      set the itemdelimiter to "."
      delete item -1 of pageSlug
      
      if pageSlug is among the lines of pageSlugs then
         /*
         set the itemdelimiter to slash
         get item 1 of sURL 
         set the itemdelimiter to ":"
         put item -1 of it into wikiDomain
         put wikiDomain && pageSlug & CR after pageSlugs
         */
         put indexNum  & CR after pageSlugs 
      else
         put pageSlug & CR after pageSlugs
      end if
      add 1 to indexNum
   end repeat
   delete char -1 of pageSlugs
   return pageSlugs
end _SlugsFromLineUpURLs

private function _TranslatePageJson browserView, pageTitle, sLang, pModel, pIncludeOriginal
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put the wiki_Domain of browserView into wikiDomain
   --
   put _GetPageText (browserView, pageSlug) into pageText
   
   # Fetch ChatGPT translation
   set the cursor to watch
   put pageTitle & CR before pageText
   put wikiPage_FetchTranslation (pageText, sLang, pModel) into sTranslation
   put line 1 of sTranslation into utf8Title
   put textDecode (utf8Title, "UTF-8") into translatedTitle
   delete line 1 of pageText
   delete line 1 of sTranslation
   
   # Construct PageArray
   put _ConstructPageJson (sLang, sTranslation, wikiDomain, pageSlug, pageTitle, pageText, translatedTitle, pIncludeOriginal) into pageJSON
   return pageJSON
end _TranslatePageJson
   
function _ConstructPageJson sLang, sTranslation, wikiDomain, pageSlug, pageTitle, pageText, translatedTitle, pIncludeOriginal
   -- we use replaceText on JSON to avoid utf8 chat issues with json_FromArray
   put urlEncode (sTranslation) into encodedTranslation
   put "{{sTranslation}}" into curlyStub
   
   # Construct pageArray
   -- put sLang && "Translation" into translatedTitle
   
   put "The following is a first draft [[ChatGPT]] mediated translation of the [[{{pageTitle}}]] wiki-page into [[{{sLang}}]]:" into someMD
   curly_ReplaceText someMD, "pageTitle", pageTitle
   curly_ReplaceText someMD, "sLang", sLang
   put pageArray_Construct ("{{pageTitle}}", someMD, "markdown") into pageArray
   
   # Add Translation
   put "# Translation" into sTitle
   -- put "#" && translatedTitle into sTitle
   pageArray_AddMarkdown pageArray, sTitle
   pageArray_AddMarkdown pageArray, curlyStub
   
   # Add Text-to-Speech button
   put transport_ConstructHiddenArray (wikiDomain, pageSlug, pageTitle) into hiddenArray
   put sLang into hiddenArray ["sLang"]
   put encodedTranslation into hiddenArray ["eTranslation"]
   
   put "{{translatedTitle}}" into hiddenArray ["translatedTitle"]
   put "http://rest.livecode.world/augmented/add_Audio" into hiddenArray ["postURL"]
   
   pageArray_AddMarkdown pageArray, "# Speak"
   put wikiSnippet_CurlyGet ("text-to-speech-form", hiddenArray) into formHTML
   pageArray_AddHTML pageArray, formHTML
   
   pageArray_AddMarkdown pageArray, "To record audio for an edited version of this text, first save this page, then edit the translation and use the button below:"
   
   put empty into hiddenArray ["eTranslation"]
   put "http://rest.livecode.world/augmented/add_PageAudio" into hiddenArray ["postURL"]
   put wikiSnippet_CurlyGet ("text-to-speech-form", hiddenArray) into formHTML
   pageArray_AddHTML pageArray, formHTML
   
   if pIncludeOriginal is true then
      # Add pageText
      pageArray_AddMarkdown pageArray, "# Original"
      pageArray_AddMarkdown pageArray, pageText
   end if
   
   # Strip and Return
   pageArray_StripJournal pageArray
   pageArray_AddChatGptCred pageArray
   
   # Replace translated PageTitle and sTranslation
   put json_FromArray (pageArray) into pageJSON
   
   curly_ReplaceText pageJSON, "PageTitle", translatedTitle
   
   put textDecode (translatedTitle, "UTF-8") into utf8TranslatedTitle
   curly_ReplaceText pageJSON, "translatedTitle", utf8TranslatedTitle
   
   put textDecode (sTranslation, "UTF-8") into sTranslation
   replace CR with "\n" in sTranslation
   put replaceText (pageJSON, curlyStub, sTranslation) into pageJSON
   
   return pageJSON
end _ConstructPageJson

private function _GetPageText browserView, pageSlug
   -- put the lineUp_Data [pageSlug] of browserView into pageArray
   put the lineUp_PageArray [pageSlug] of browserView into pageArray
   put pageArray_Text (pageArray) into pageText
   return pageText
end _GetPageText

private function _BrowserView tObject
   if exists (tObject) then
      put the browser_View of testView into browserView
      return browserView
   else
      return empty
   end if
end _BrowserView

private function _ListToplevelDomains
   put wiki_ListTopLevelDomains() into wikiDomains
   url_SortDomainIndex wikiDomains
   return wikiDomains
end _ListToplevelDomains

getprop disabled_DisplayWiki [browserView]
   return exists (browserView) is false
end disabled_DisplayWiki

getprop displayDomain_Param [browserView]
   put the browser_Domain of browserView into wikiDomain
   return wikiDomain
end displayDomain_Param

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
   put wikiPage_SitesIndex (tldDomain) into pageArray
   set the ghost_PageArray of browserView to pageArray
end menu_CreateDomainList

private on _
end _

on menu_Speak browserView, pageSlug
   put fedwiki_ConstructTitle (pageSlug) into pageTitle
   --
   put _GetPageText (browserView, pageSlug) into pageText
   --
   -- put the wiki_Domain of browserView into wikiDomain
   put the lineUP_Domain [pageSlug] of browserView into wikiDomain
   --
   put pageSlug & ".mp3" into shortFile
   put wiki_ConstructAssetFile (shortFile, wikiDomain) into audioFile
   --
   openAI_TextToSpeech pageText, audioFile
   --
   finder_Reveal audioFile
end menu_Speak

on menu_TranslateToGerman browserView, pageSlug
   put fedwiki_ConstructTitle (pageSlug) into pageTitle
   --
   put _TranslatePageJson (browserView, pageTitle, "German") into pageJSON
   set the ghost_JSON of browserView to pageJSON
end menu_TranslateToGerman

on menu_TranslateToIcelandic browserView, pageSlug
   put fedwiki_ConstructTitle (pageSlug) into pageTitle
   --
   put _TranslatePageJson (browserView, pageTitle, "Icelandic") into pageJSON
   set the ghost_JSON of browserView to pageJSON
end menu_TranslateToIcelandic

on menu_TranslateToWelsh browserView, pageSlug
   put fedwiki_ConstructTitle (pageSlug) into pageTitle
   --
   put _TranslatePageJson (browserView, pageTitle, "Welsh") into pageJSON
   set the ghost_JSON of browserView to pageJSON
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

on menu_SaveBrowser browserView
   put the stack_Name of browserView into stackName
   save stack stackName
   --
   put "Saved stack" && kwote (stackName) into sComment
   lcw_Notify sComment
end menu_SaveBrowser

-- on submenu_Dev
   return menu_DevTitle("Global | Obeya | Studio | Wiki | Menu")
end submenu_Dev
