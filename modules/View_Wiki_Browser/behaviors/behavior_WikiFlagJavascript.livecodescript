script "behavior_WikiFlagJavascript"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_WikiFlagJavascript
type: behavior
version: 0.1


--> Working on
-
getprop wiki_Garden
   put _WikiDomain() into wikiDomain
   put wikiGarden_Name (wikiDomain) into gardenName
   return gardenName
end wiki_Garden

getprop performative_Dictionary
   put _WikiDomain() into wikiDomain
   --
   put pageArray_Get (wikiDomain, "performative-dictionary") into pageArray
   put handlerWiki_Array() into wikiArray
   put pageArray_ReferenceDictionary (pageArray, wikiArray) into pDict
   return pDict
end performative_Dictionary

setprop wikipedia_Page pageTitle
   put mediawiki_GetPageArrayFromSlug (pageTitle) into pageArray
   set the ghost_PageArray of me to pageArray
   return pageArray
end wikipedia_Page

getprop page_Text [titleOrNum]
   put the page_Array [titleOrNum] of me into pageArray
   put pageArray_ToText (pageArray) into pageText
   return pageText
end page_Text


--> Flag
-
on flag_Event flagYaml
   -- called by wiki-client Livecode javascript
   split flagYaml using comma and ":"
   --
   put flagYaml ["target"] into wikiDomain
   put flagYaml ["href"] into urlPath
   put flagYaml ["pageTitle"] into pageTitle
   
   # Store Yaml
   set the clicked_FlagArray of me to flagYaml
   
   if char 1 to 2 of urlPath = "//" then
      # Open nwiki in new tab
      display_Wiki wikiDomain, "New"
      put the result into wikiView
   else
      _DisplayToolsPage pageTitle, wikiDomain, urlPath
   end if
end flag_Event

on wikiClick_HamburgerMenu
   set the page_Title of me to "tools"
end wikiClick_HamburgerMenu



--> Private | Flag
-
private command _DisplayToolsPage pageTitle, wikiDomain, urlPath
   # Open tools
   set the itemdelimiter to slash
   put item -1 of urlPath into pageSlug
   --
   put the page_Class [pageSlug] of me into pageClass
   switch
      /*
      case the optionkey is "Down"
         set the page_Title of me to "Tools"
         break
      case the shiftkey is "Down"
         */
      case pageClass contains "ghost"
         set the wikipedia_Page of me to pageSlug
         break
      default 
         put wikiFile_Construct (wikiDomain, pageSlug) into jsonFile
         if there is a file jsonFile then
            put wikiPage_EditPage (pageSlug, wikiDomain) into pageArray
         else
            put wikiDialogue_Get (pageSlug, wikiDomain, "create-page-dialogue", "Create Page") into pageArray
         end if
         set the ghost_PageArray of me to pageArray
         --
         -- _CheckPageArray pageArray, pageSlug, wikiDomain
   end switch
end _DisplayToolsPage
