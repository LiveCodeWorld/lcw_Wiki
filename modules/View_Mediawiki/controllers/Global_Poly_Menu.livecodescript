script "Global | Poly | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Poly | Menu
type: controller
version: 0.2


--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_Controller
   return the long id of me
end menu_Controller

getprop menu_Target [tObject]
   if exists (tObject) is false then
      put the long id of cd 1 of stack "View|Mediawiki" into cObject
      put the menu_Target of cObject into mTarget
      return mTarget
   end if
   
   put the view_Object of tObject into dView
   if exists (dView) is false then
      breakpoint
      return tObject
   end if
   
   put the displayed_Object of dView into sObject
   if sObject is empty then
      return dView
   else
      put dView into LocalArray ["dView"]
      return sObject
   end if
end menu_Target

getprop menu_CheckTarget [dView]
   return exists (dView)
end menu_CheckTarget


--> Events
-
on display_TargetData dView, dArray
   put dArray ["text"] into dText
   
   put "https://www.one-tab.com/page/(.+)" into rExp
   if matchText (dText, rExp) then
      put oneTab_Parse (dText) into oneTabData
      display_Data oneTabData, "oneTab_Parse()"
   else
      put dText
   end if
end display_TargetData

on footer_HiliteChange dView, iName, iNum
   switch iNum
      case 1
         -- dispatch "toggle_Header" to dView
         put the view_RectOnCard of dView into oRect
         
         lock screen
         set the header_IsVisible of dView to true
         set the body_IsVisible of dView to true
         set the footer_IsVisible of dView to true
         --
         dispatch "LayoutControl" to dView with oRect
         unlock screen
         
         dispatch "LayoutCard" to dView
         break
      case 2
         set the poly_DataContent of dView to empty
         put the data_Height of dView into dHeight
         set data_Height of dView to dHeight
         break
      case 3
         set the poly_DataContent of dView to _FetchPolyData()
         put the data_Height of dView into dHeight
         set data_Height of dView to dHeight
         break
      case 4
         lock screen
         set the header_IsVisible of dView to false
         set the body_IsVisible of dView to false
         set the footer_IsVisible of dView to true
         unlock screen
         break
   end switch
end footer_HiliteChange


--> Private
-
private function _dView
   return LocalArray ["dView"]
end _dView

private function _FetchPolyData
   put _Slug() into wSlug
   put restbase_FetchMediaArray (wSlug) into mwData
   put _PolyData (mwData) into pData
   return pData
end _FetchPolyData

private function _PolyData mwData
   repeat for each key indexNum in mwData
      set the cursor to busy
      
      # Title
      get mwData [indexNum]["title"]
      replace "File:" with empty in it
      put it into mwData [indexNum]["title"]
      
      # Image
      get mwData [indexNum]["srcset"][1]["src"]
      put "https:" & it into imageURL
      put url imageURL into sImage
      put sImage into mwData [indexNum]["thumb"]
      -- delete variable mwData [indexNum]["srcset"]
      
      # Description
      get mwData [indexNum]["caption"]["text"]
      put it into mwData [indexNum]["description"]
      delete variable mwData [indexNum]["caption"]["text"]
      
      # Defaults
      put "ellipsis vertical" into mwData [indexNum]["action"]
      put "user" into mwData [indexNum]["icon"]
   end repeat
   return mwData
end _PolyData

private function _Slug
   put "Ant" into wSlug
   put "Greenwhich" into wSlug
   return wSlug
end _Slug


--> Menu | Props
-
getprop dragCommand_Param [dView]
   get the drop_Command of dView
   if it is empty then return "Empty"
   return it
end dragCommand_Param

getprop dragCommand_Params
   return "Empty,display_TargetData,-,Ask"
end dragCommand_Params

getprop cardMargin_Param [dView]
   return the card_Margin of dView
end cardMargin_Param

getprop cardMargin_Params
   return "0,4,8,24,-,Ask"
end cardMargin_Params

getprop checked_SystemWindow [dView]
   put the stack_Name of dView into sName
   return the systemwindow of stack sName
end checked_SystemWindow

getprop description_Params
   get the menu_CaseConditions ["menu_Description"] of me
   return it
   
   put the hkey_CaseConditions  of me
   return "mw_SummaryHtml,mw_SummaryText,mw_PageExtract"
end description_Params

getprop checked_ShowHeader [dView]
   put the header_IsVisible of dView into sBoolean
   return sBoolean
end checked_ShowHeader

getprop checked_ShowFooter [dView]
   put the footer_IsVisible of dView into sBoolean
   return sBoolean
end checked_ShowFooter

getprop restoreDataLayout_Params [dView]
   put _StoreData(dView) into storeData
   return keys (storeData)
end restoreDataLayout_Params

private function _StoreData dView
   set the customPropertySet of dView to "data_Store"
   put the customProperties of dView into storeData
   return storeData
end _StoreData


--> Global | Poly | Menu
-
on menu_RestoreDataLayout dView, sName
   put _StoreData(dView) into storeData
   put storeData [sName] into polyDataLayout
   --
   set the poly_DataLayout of dView to pData
end menu_RestoreDataLayout

on menu_SaveDataLayout dView
   put lcw_Ask ("Name for data layout?", "pDefault", dView) into sName
   
   put the poly_DataLayout of dView into pData
   set the data_Store [sName] of dView to pData
end menu_SaveDataLayout

on menu_SummaryArray dView
   put _Slug() into wSlug
   put mw_SummaryArray (wSlug) into sArray
   --
   display_Data sArray, wSlug
end menu_SummaryArray

on menu_Description dView, hName
   put _Slug() into wSlug
   --
   switch hName
      case "Markdown Toc"
         put mw_MarkdownTOC (wSlug, true)
         break
      case "mw_SummaryHtml"
         put mw_SummaryHtml (wSlug)
         break
      case "mw_SummaryText"
         put mw_SummaryText (wSlug)
         break
      case "-"
      case "mw_PageExtract"
         put mw_PageExtract (wSlug)
         break
      case "-"
      case "Cors Proxy Url"
         put mw_PageExtractUrl (wSlug) into mwURL
         put url_AddCorsProxy (mwURL) into corsURL
         put url corsURL
         break
   end switch
end menu_Description

on menu_MediaWikiImageData dView
   put _FetchPolyData() into pData
   set the poly_DataContent [wSlug] of dView to pData
end menu_MediaWikiImageData

private on _
end _

on menu_DisplayPolyData dView
   put the poly_DataContent of dView into pData
   put the name of dView into sTitle
   --
   display_Data pData, sTitle, "the poly_DataContent"
end menu_DisplayPolyData

on menu_DisplayDataLayout dView
   put the poly_DataLayout of dView into pData
   put the name of dView into sTitle
   --
   display_Data pData, sTitle, "the poly_DataLayout"
end menu_DisplayDataLayout

on menu_DragCommand dView, dCommand
   switch dCommand
      case "ask"
         put the drop_Command of dView into dCommand
         put "Set the drop_Command..." into sQuestion
         put lcw_Ask (sQuestion, dCommand, dView) into dCommand
         set the drop_Command of dView to dCommand
         break
      case "Empty"
         set the drop_Command of dView to empty
         break
      default
         set the drop_Command of dView to dCommand
   end switch
end menu_DragCommand

private on __
end __

on menu_CardMargin dView, sMargin
   if sMargin = "Ask" then
      put the card_Margin of dView into sMargin
      put "Set the card_Margin..." into sQuestion
      put lcw_Ask (sQuestion, sMargin, dView) into sMargin
   end if
   
   set the card_Margin of dView to sMargin
end menu_CardMargin

on menu_SystemWindow dView
   put the stack_Name of dView into sName
   --
   put the systemwindow of stack sName into sBoolean
   set the systemwindow of stack sName to (sBoolean is false)
end menu_SystemWindow

private on ___
end ___

on menu_ShowHeader dView
   put the header_IsVisible of dView into sBoolean
   set the header_IsVisible of dView to (sBoolean is false)
end menu_ShowHeader

on menu_ShowFooter dView
   put the footer_IsVisible of dView into sBoolean
   set the footer_IsVisible of dView to (sBoolean is false)
end menu_ShowFooter

on menu_EditBehavior dView
   put the behavior of dView into bObject
   edit the script of bObject
end menu_EditBehavior

on submenu_Dev
   return menu_DevTitle ("Global | Poly | Menu")
end submenu_Dev
