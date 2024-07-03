script "Global | Wiki | Browser | Tools | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Browser | Tools | Menu
type: controller
version: 0.2

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray


--> Menu | Props
-
getprop menu_Target [tObject]
   put the displayed_Object of tObject into wikiView
   return wikiView
end menu_Target

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

private function _GetLastPageArray wikiView
   put the wiki_Domain of wikiView into wikiDomain
   put the last_PageSlug of wikiView into pageSlug
   put pageArray_Get (wikiDomain, pageSlug) into pageArray
   return pageArray
end _GetLastPageArray

private function _GetPageArray wikiView, pageTitle
   -- could get directly form live HTML using "lineup_Data"
   put the wiki_Domain of wikiView into wikiDomain
   --
   if pageTitle is empty then
      put the last_PageSlug of wikiView into pageSlug
      put lcw_Ask ("Choose a wiki page-slug for this domain...", pageSlug, wikiDomain, wikiView) into pageSlug
   else
      put fedwiki_ConstructSlug (pageTitle) into pageSlug
   end if
   --
   put pageArray_Get (wikiDomain, pageSlug) into pageArray
   return pageArray
end _GetPageArray


--> Global | Wiki | Browser | Tools | Menu
-
on menu_AddBookmarks wikiView
   put the bookmark_Data of wikiView into bookmarkData
   wikiBookmark_SetData bookmarkData
end menu_AddBookmarks

on menu_DisplayBookmarks wikiView
   put wikiBookmark_GetData() into bookmarkData
   --
   set the bookmark_Data of wikiView to bookmarkData
   --
   display_Data bookmarkData, "bookmarkData"
end menu_DisplayBookmarks

on menu_DeleteBookmark wikiView, pageSlug
   wikiBookmark_Delete pageSlug
end menu_DeleteBookmark

getprop deleteBookmark_Params
   put wikiBookmark_GetData() into bookmarkData
   put wikiBookMark_ListSlugs (bookmarkData) into pageSlugs
   return pageSlugs
end deleteBookmark_Params

on menu_ClearBookmarks
   wikiBookmark_SetData empty
end menu_ClearBookmarks

private on _
end _

on menu_AddOwnerJson wikiView
   put the wiki_Domain of wikiView into wikiDomain
   --
   if wikiServer_OwnerExists (wikiDomain) then
      display_WikiOwner wikiDomain
   else
      wikiServer_SetFriendlyData wikiDomain
   end if
end menu_AddOwnerJson

on menu_DisplayOwnerJson wikiView
   put the wiki_Domain of wikiView into wikiDomain
   --
   display_WikiOwner wikiDomain
end menu_DisplayOwnerJson

getprop checked_AddOwnerJson [wikiView]
   put the wiki_Domain of wikiView into wikiDomain
   return wikiServer_OwnerExists (wikiDomain)
end checked_AddOwnerJson

getprop disabled_AddOwnerJson [wikiView]
   put the wiki_Domain of wikiView into wikiDomain
   switch wikiDomain
      case "localhost"
         return "delete"
      default
         return false
   end switch
end disabled_AddOwnerJson

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
   if the shiftkey is "Down" then
      breakpoint
      pageArray_StripJournal pageArray
   else
      pageArray_StripJournal pageArray
   end if
   --
   set the ghost_PageArray of wikiView to pageArray
end menu_StripJournal

getprop stripJournal_Params [wikiView]
   return LocalArray ["pageTitles"]
end stripJournal_Params

private on __
end __

on menu_EditLast.E wikiView
   put the wiki_Domain of wikiView into wikiDomain
   put the last_PageSlug of wikiView into pageSlug
   put the lineup_Title [pageSlug] of wikiView into pageTitle
   
   # Create Page Dialogue
   put wikiPage_EditOrCreate (wikiDomain, pageSlug, pageTitle) into pageArray
   set the ghost_PageArray of wikiView to pageArray
   
   # Images
   put _GetLastPageArray (wikiView) into pageArray
   put wikiPageEditImages (pageArray) into pageArray
   if pageArray is an array then
      set the ghost_PageArray of wikiView to pageArray
   end if
end menu_EditLast.E

on menu_EditGhosts.G wikiView
   put the wiki_Domain of wikiView into wikiDomain
   --
   put the ghost_Slugs of wikiView into ghostSlugs
   repeat for each line ghostSlug in ghostSlugs
      if ghostSlug is among the items of "create-page,edit-page" then next repeat
      --
      put the lineup_Title [ghostSlug] of wikiView into pageTitle
      put wikiPage_EditOrCreate (wikiDomain, ghostSlug, pageTitle) into pageArray
      set the ghost_PageArray of wikiView to pageArray
   end repeat
end menu_EditGhosts.G

-- on menu_LastImages.I wikiView
put _GetLastPageArray (wikiView) into pageArray
put wikiPageEditImages (pageArray) into pageArray
set the ghost_PageArray of wikiView to pageArray
end menu_LastImages.I

on menu_LastForks wikiView
   put _GetLastPageArray (wikiView) into pageArray
   --
   put "livecode.world" into wikiDomains
   if the shiftKey is "Down" then
      pageArray_StripJournal pageArray
   end if
   pageArray_AddFork pageArray, wikiDomains
   --
   set the ghost_PageArray of wikiView to pageArray
end menu_LastForks

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

private on ___
end ___

on menu_MenuGroupTools mGroup
   display_ModuleTools "View|Menu|Group"
end menu_MenuGroupTools

on menu_MenuControllerTools
   display_Project "lcw_Controllers"
end menu_MenuControllerTools

on menu_WikiBrowserTools mGroup
   display_ModuleTools "View|Wiki|Browser"
end menu_WikiBrowserTools

on menu_WikiFutureTools mGroup
   display_ModuleTools "View|Wiki|Future"
end menu_WikiFutureTools

on menu_WikiServerTools mGroup
   display_ModuleTools "View|Wiki|Server"
end menu_WikiServerTools

private on ____
end ____

on menu_Deps
   put "behavior_MenuGroupDev" into sName
   put view_GetTemplateObject ("View|Menu|Group") into mGroup
   --
   if the behavior_InHierarchy [sName] of mGroup is true then
      set the behavior_Remove of mGroup to sName
      lcw_Notify "Removed behavior!"
   else
      set the behavior_Add of mGroup to sName
      lcw_Notify "Added behavior!"
   end if
end menu_Deps

getprop checked_Deps
   put "behavior_MenuGroupDev" into sName
   put view_GetTemplateObject ("View|Menu|Group") into mGroup
   --
   return the behavior_InHierarchy [sName] of mGroup
end checked_Deps

on menu_ScriptDebugMode
   revIDEToggle "Script Debug Mode"
end menu_ScriptDebugMode

-- on menu_SuppressMessages
revIDEToggle "Suppress Messages"
end menu_SuppressMessages

-- getprop checked_SuppressMessages
global gRevSuppressMessages
return gRevSuppressMessages
end checked_SuppressMessages

on menu_SupressErrors wikiView
   revIDEToggle "Suppress Errors"
   --
   global gRevSuppressErrors
   if gRevSuppressErrors is true then
      lcw_Notify "Error messages are now suppressed!"
   else
      lcw_Notify "Error messages are now back on."
   end if
end menu_SupressErrors

getprop checked_SupressErrors
   global gRevSuppressErrors
   return gRevSuppressErrors
end checked_SupressErrors

on menu_MessageWatcher wikiView
   revIDEOpenPalette "message watcher"
end menu_MessageWatcher

on menu_SuspendDevelopmentTools wikiView
   revIDESuspendDevelopmentTools
end menu_SuspendDevelopmentTools

private on _____
end _____

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

private on ______
end ______

on menu_FlagEvent wikiView
   set the flag_Handler of wikiView to "default"
end menu_FlagEvent

on menu_EditPlatform
   edit the script of stack "lib_Platform'"
end menu_EditPlatform

on submenu_Dev
   return "Global | Wiki | Browser | Tools | Dev | Menu"
end submenu_Dev
