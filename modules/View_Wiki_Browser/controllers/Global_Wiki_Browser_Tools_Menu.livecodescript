script "Global | Wiki | Browser | Tools | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Browser | Tools | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray


--> Menu | Props
-
getprop menu_CheckTarget [wikiView]
   put the lineup_Titles of wikiView into pageTitles
   put pageTitles into LocalArray ["pageTitles"]
   return true
end menu_CheckTarget

getprop checked_FlagEvent [wikiView]
    get the flag_Handler of wikiView
   if it = "default" then
      return true
   else
      return true
   end if
end checked_FlagEvent

getprop compactRefs_Params [wikiView]
   return LocalArray ["pageTitles"]
end compactRefs_Params

getprop checked_ScriptDebugMode
   -- put revIDEGetPreference("cREVScriptDebugMode") into gREVRestore["scriptdebugmode"]
   -- revIDESetPreference "cREVScriptDebugMode",false
   return revIDEGetPreference("cREVScriptDebugMode")
end checked_ScriptDebugMode

getprop checked_SuppressMessages
   global gRevSuppressMessages
   return gRevSuppressMessages
end checked_SuppressMessages

getprop checked_SupressErrors
   global gRevSuppressErrors
   return gRevSuppressErrors
end checked_SupressErrors

private function _GetPageArray wikiView, pageTitle
   -- could get directly form live HTML using "lineup_Data"
   put the wiki_Domain of wikiView into wikiDomain
   --
   if pageTitle is empty then
      put the last_PageSlug of wikiView into pSlug
      put lcw_Ask ("Choose a wiki page-slug for this domain...", pSlug, wikiDomain, wikiView) into pSlug
   else
      put fedwiki_ConstructSlug (pageTitle) into pageSlug
   end if
   --
   put pageArray_Get (wikiDomain, pageSlug) into pageArray
   return pageArray
end _GetPageArray


--> Global | Wiki | Browser | Tools | Menu
-
on menu_CompactRefs wikiView, pageTitle
   put _GetPageArray (wikiView, pageTitle) into pageArray
   --
   pageArray_CompactRefs pageArray
   --
   set the ghost_PageArray of wikiView to pageArray
end menu_CompactRefs

on menu_StripJournal wikiView, pageTitle
   put _GetPageArray (wikiView, pageTitle) into pageArray
   --
   pageArray_StripJournal pageArray
   --
   set the ghost_PageArray of wikiView to pageArray
end menu_StripJournal

getprop stripJournal_Params [wikiView]
   return LocalArray ["pageTitles"]
end stripJournal_Params

on menu_AddForks wikiView
   put _GetPageArray (wikiView) into pageArray
   --
   put "livecode.world" into wikiDomains
   if the shiftKey is "Down" then
      pageArray_StripJournal pageArray
   end if
   pageArray_AddFork pageArray, wikiDomains
   --
   set the ghost_PageArray of wikiView to pageArray
end menu_AddForks

on menu_FixPageJson wikiView
   put _GetPageArray (wikiView) into pageArray
   --
   pageArray_StripJournal pageArray
   --
   set the ghost_PageArray of wikiView to pageArray
end menu_FixPageJson

on menu_FixText wikiView, pageTitle
   put _GetPageArray (wikiView) into pageArray
   --
   put pageArray ["story"] into storyArray
   repeat with itemNum = 1 to item 2 of the extents of storyArray
      put storyArray [itemNum]["text"] into itemText
      wikipedia_FixText itemText
      put itemText into storyArray [itemNum]["text"]
   end repeat
   put storyArray into pageArray ["story"]
   --   
   set the ghost_PageArray of wikiView to pageArray
end menu_FixText

getprop fixText_Params [wikiView]
   return LocalArray ["pageTitles"]
end fixText_Params


private on _
end _

on menu_SearchOpenverse wikiView
   put lcw_Ask ("Enter search terms...", "cat|dog", "Openverse", dView) into searchBit
   --
   put openverse_Search (searchBit) into sData
   put wikiPage_OpenVerseThumbNails (sData) into pageArray
   --
   set the ghost_PageArray of wikiView to pageArray
end menu_SearchOpenverse

private on __
end __

on menu_RevealEmptyFolder wikiView
   
end menu_RevealEmptyFolder

on menu_TrashEmptyFolders
   
end menu_TrashEmptyFolders

private on ___
end ___

on menu_ScriptDebugMode
   revIDEToggle "Script Debug Mode"
end menu_ScriptDebugMode

-- on menu_SuppressMessages
   revIDEToggle "Suppress Messages"
end menu_SuppressMessages

on menu_SupressErrors wikiView
   revIDEToggle "Suppress Errors"
end menu_SupressErrors

on menu_MessageWatcher.M wikiView
   revIDEOpenPalette "message watcher"
end menu_MessageWatcher.M

on menu_SuspendDevelopmentTools wikiView
   revIDESuspendDevelopmentTools
end menu_SuspendDevelopmentTools

private on ____
end ____

on menu_RevealWikiFolder wikiView
   put the wiki_Domain of wikiView into wikiDomain
   --
   put wikiFolder_Get (wikiDomain) into wikiFolder
   if there is a folder wikiFolder then
      finder_Reveal wikiFolder
   else
      lcw_AnswerWarning "Cannot locate wiki-folder for domain [[wikiDomain]]", wikiView, wikiDomain
   end if
end menu_RevealWikiFolder

on menu_LayoutCard wikiView
   dispatch "LayoutCard" to wikiView
end menu_LayoutCard

on menu_SaveStack wikiView
   put the stack_Name of wikiView into stackName
   save stack stackName
end menu_SaveStack

private on _____
end _____

on menu_FlagEvent wikiView
   set the flag_Handler of wikiView to "default"
end menu_FlagEvent

on menu_EditPlatform
   edit the script of stack "lib_Platform'"
end menu_EditPlatform

on submenu_Dev
   return "Global | Wiki | Browser | Tools | Dev | Menu"
end submenu_Dev

