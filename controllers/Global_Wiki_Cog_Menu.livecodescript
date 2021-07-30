script "Global | Wiki | Cog | Menu"
--> MetaData
-
license: GPLv3
name: Global | Wiki | Cog | Menu
type: controller
version: 0.3


--> Events
-
on script_Compile
   -- put the long id of me into mController
   put the wiki_View of cd 1 of stack "Fedwiki Editor" into wikiView
   put the menu_Array ["Global | Wiki | Cog | Menu"] of wikiView into mArray
   --
   set the left_MenuArray of wikiView to mArray
   --
   put mArray_ToText (mArray) into mText
   put the card_Object of wikiView into cardObject
   set the text of button "PopUP Menu" of cardObject to mText
end script_Compile 


--> Menu | Props
-
getprop menu_Target [tObject]
   if exists (tObject) is false then
      breakpoint
      pass menu_Target
   end if
   put the wiki_View of tObject into wikiView
   return wikiView
end menu_Target

getprop setUrl_Params [wikiView]
   -- put atopia_FetchDomains () into wikiDoamins
   put the wiki_Domains of wikiView into wikiDomains
   return wikiDomains
end setUrl_Params

getprop setUrl_Param
   return "livecode.world"
end setUrl_Param


--> Global | Wiki | Cog | Menu
-
on menu_EditController
   edit the script of me
end menu_EditController

on menu_EditWikiView wikiView
   edit the script of wikiView
end menu_EditWikiView

on menu_EditFooterView wikiView
   put the footer_View of wikiView into footerView
   edit the script of footerView
end menu_EditFooterView

on _
end _

on submenu_Palette
   return "PaletteActions | Menu"
end submenu_Palette

on _
end _

on menu_SetUrl wikiView, wikiDomain
   set the wiki_Domain of wikiView to wikiDomain
end menu_SetUrl


--> PaletteActions | Menu | Props
-
command test mTarget
   put the target into tObject
   get tObject & CR & mTarget
   return it
end test

getprop setActionKey_Params [wikiView]
   put the card_Object of wikiView into cardObject
   put the handler_Names ["M wiki_*"] of cardObject into hNames
   return hNames
end setActionKey_Params


--> PaletteActions | Menu
-
on menu_SetDefaultFederationHome
   put "welcome-visitors" into pageSlug
   put pageArray_Fetch ("proto.institute", pageSlug) into pageArray
   pageArray_StripJournal pageArray
   pageArray_AddFork pageArray, "proto.institute,fedwiki.org,orientation.fedwiki.org"
   --
   pageArray_StoreDefault pageSlug, pageArray
end menu_SetDefaultFederationHome

on menu_EditActionMenu
   menu_Edit "Global | PaletteActions | Menu"
end menu_EditActionMenu

on _
end _

on menu_SetActionKey wikiView, hName
   put the card_Object of wikiView into cardObject
   --
   set the footer_Action [2] of wikiView to the action_Key [hName] of cardObject
   -- set the footer_ActionIcon [2] of wikiView to "bullseye"
   set the footer_Action [3] of wikiView to the action_Key ["wiki_ToggleVisible"] of cardObject
   --
end menu_SetActionKey

on menu_DisplayActionData wikiView
   put the footer_ActionData of wikiView into aData
   display_Array aData
end menu_DisplayActionData

on menu_ResetFooterArray wikiView
   lcw_Answer "Clear the navData of this views footer?", wikiView
   --
   set the footer_NavData of wikiView to empty
end menu_ResetFooterArray

on _
end _

on menu_ActionInspector wikiView
   put the footer_View of wikiView into footerView
   put the action_Widget of footerView into actionWidget
   --
   display_ObjectProperties actionWidget
end menu_ActionInspector

on menu_RightIconInspector wikiView
   put the footer_View of wikiView into footerView
   put the right_Icon of footerView into rightIcon
   --
   display_ObjectProperties rightIcon
end menu_RightIconInspector

on _
end _

on menu_LeftMenuArray wikiView
   put the left_MenuArray of wikiView into menuArray
   --
   put "Global | PaletteActions | Menu" into mTitle
   display_Array menuArray, "the left_MenuArray", mTitle
   put the result into arrayView
end menu_LeftMenuArray

on _
end _

on menu_AddMenuItem wikiView
   put the left_MenuArray of wikiView into menuArray
   actionPalette_AddMenuItemArray menuArray, "lcw", "Livecode World", true
   set the left_MenuArray of wikiView to menuArray
end menu_AddMenuItem


--> Working on
-
command actionPalette_SetMenuItemArray @menuArray, newItemNum, itemName, pItemLabel, pChecked
   put actionPalette_ConstructMenuItemArray (itemName, pItemLabel, pChecked) into menuItemArray
   put menuItemArray into menuArray [newItemNum]
end actionPalette_SetMenuItemArray

command actionPalette_AddMenuItemArray @menuArray, itemName, pItemLabel, pChecked
   put item 2 of the extents of menuArray into newItemNum
   add 1 to newItemNum
   put actionPalette_ConstructMenuItemArray (itemName, pItemLabel, pChecked) into menuItemArray
   put menuItemArray into menuArray [newItemNum]
end actionPalette_AddMenuItemArray

function actionPalette_ConstructMenuItemArray itemName, pItemLabel, pChecked
   if pItemLabel is empty then
      put itemName into pItemLabel
   end if
   put itemName into menuItemArray ["name"]
   put pItemLabel into menuItemArray ["label"]
   if pChecked is not empty then
      put pChecked into menuItemArray ["checked"]
   end if
   return menuItemArray
end actionPalette_ConstructMenuItemArray
