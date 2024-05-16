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
getprop menu_Target [tObject]
   put the browser_View of tObject into wikiView
   --
   put the card_Object of tObject into arrayObject
   put the displayed_RectDataNum [true] of arrayObject into LocalArray ["dRectDataNum"]
   put the displayed_ObjectNames of arrayObject into LocalArray ["objectNames"]
   --
   return wikiView
end menu_Target

getprop checked_FlagEvent [wikiView]
   get the flag_Handler of wikiView
   if it = "default" then
      return true
   else
      return true
   end if
end checked_FlagEvent

getprop checked_AnimationEngine [wikiView]
   return "animationEngine" is among the lines of the stacksinuse
end checked_AnimationEngine

getprop checked_Footer [wikiView]
   return LocalArray ["footer_IsVisible"]
end checked_Footer

getprop checked_BrowserVisible [wikiView]
   put the visible of wikiView into isVisible
   return isVisible
end checked_BrowserVisible

getprop scale_Params
   return "0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,-,1,-,1.5"
end scale_Params

getprop compactRefs_Params [wikiView]
   put the lineup_Data of wikiView into lineupData
   put the lineup_Titles of wikiView into pageTitles
   return pageTitles
end compactRefs_Params

getprop shrink_Params [wikiView]
   return the page_Slugs of wikiView
end shrink_Params

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

private command _RefreshMenu wikiView
   put the menubar_View of wikiView into mGroup
   --
   put the live_Menu of mGroup into isLive
   if isLive is false then
      set the menuButton_Refresh of mGroup to "Tools"
   end if
end _RefreshMenu


--> Global | Wiki | Browser | Tools | Menu
-
on menu_FixPageJson wikiView
   put the wiki_Domain of wikiView into wikiDomain
   put the last_PageSlug of wikiView into pSlug
   put lcw_Ask ("Choose a wiki page-slug for this domain...", pSlug, wikiDomain, wikiView) into pSlug
   --
   put pageJson_Get (wikiDomain, pSlug) into pageJson
   put JSONToArray (pageJson) into pageArray
end menu_FixPageJson

on menu_SearchOpenverse wikiView
   put lcw_Ask ("Enter search terms...", "cat|dog", "Openverse", dView) into searchBit
   --
   put openverse_Search (searchBit) into sData
   put wikiPage_OpenVerseThumbNails (sData) into pageArray
   --
   set the ghost_PageArray of wikiView to pageArray
end menu_SearchOpenverse

on menu_CompactRefs wikiView, pageTitle
   put the lineup_Data of wikiView into lineupData
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put pageArray_Get (wikiDomain, pageSlug)
   pageArray_CompactRefs pageArray
end menu_CompactRefs

private on _
end _

on menu_FlagEvent wikiView
   set the flag_Handler of wikiView to "default"
   --
   _RefreshMenu wikiView
end menu_FlagEvent

private on __
end __

on menu_Shrink wikiView, pageSlug
   -- put the page_Rect ["welcome-visitors"] of wikiView into sRect
   -- 204,364,302,542
   
   set the page_Scale [pageSlug] of wikiView to 0.2
   put the page_Rect [pageSlug] of wikiView into sRect
   --
   rect_Translate sRect, 400, 200
   --
   set the page_Rect [pageSlug] of wikiView to sRect
end menu_Shrink

on menu_Scale wikiView, sSale
   -- put wikijs_SetPageScale (sSale) into sJavascript
   -- set the browser_Javascript of wikiView to sJavascript
   set the wiki_Scale of wikiView to sSale
   -- set the page_Scale of wikiView to sScale
end menu_Scale

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
   --
   _RefreshMenu wikiView
end menu_SupressErrors

on menu_MessageWatcher wikiView
   revIDEOpenPalette "message watcher"
   --
   _RefreshMenu wikiView
end menu_MessageWatcher

on menu_SuspendDevelopmentTools wikiView
   revIDESuspendDevelopmentTools
   --
   _RefreshMenu wikiView
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

on menu_SaveStack wikiView
   put the stack_Name of wikiView into stackName
   save stack stackName
end menu_SaveStack

on submenu_Dev
   return "Global | Wiki | Browser | Tools | Dev | Menu"
end submenu_Dev
