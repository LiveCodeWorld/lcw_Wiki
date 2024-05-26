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


--> Global | Wiki | Browser | Tools | Menu
-
on menu_SearchOpenverse wikiView
   put lcw_Ask ("Enter search terms...", "cat|dog", "Openverse", dView) into searchBit
   --
   put openverse_Search (searchBit) into sData
   put wikiPage_OpenVerseThumbNails (sData) into pageArray
   --
   set the ghost_PageArray of wikiView to pageArray
end menu_SearchOpenverse

on menu_CompactRefs wikiView, pageTitle
   put the wiki_Domain of wikiView into wikiDomain
   --
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put pageArray_Get (wikiDomain, pageSlug) into pageArray
   -- put the lineup_Data of wikiView into lineupData
   pageArray_CompactRefs pageArray
   --
   set the ghost_PageArray of wikiView to pageArray
end menu_CompactRefs

getprop cleanJournal_Params [wikiView]
   return LocalArray ["pageTitles"]
end cleanJournal_Params

on menu_CleanJournal wikiView, pageTitle
   
end menu_CleanJournal

private on _
end _

on menu_FlagEvent wikiView
   set the flag_Handler of wikiView to "default"
end menu_FlagEvent

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

on menu_MessageWatcher wikiView
   revIDEOpenPalette "message watcher"
end menu_MessageWatcher

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

on menu_FixPageJson wikiView
   put the wiki_Domain of wikiView into wikiDomain
   put the last_PageSlug of wikiView into pSlug
   put lcw_Ask ("Choose a wiki page-slug for this domain...", pSlug, wikiDomain, wikiView) into pSlug
   --
   put pageArray_Get (wikiDomain, pSlug) into pageArray
   pageArray_StripJournal pageArray
   set the ghost_PageArray of wikiView to pageArray
   
   -- put pageJson_Get (wikiDomain, pSlug) into pageJson
   -- put wikiFile_Construct (wikiDomain, pSlug) into wikiPagePath
   -- get jsonArray_FromFile (wikiPagePath, false)
   --
   -- display_PageArray pageArray
end menu_FixPageJson

on submenu_Dev
   return "Global | Wiki | Browser | Tools | Dev | Menu"
end submenu_Dev
