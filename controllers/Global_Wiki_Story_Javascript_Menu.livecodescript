﻿script "Global | Wiki | Story | Javascript | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Story | Javascript | Menu
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
   -- called once for each menu
   return the display_View of tObject
end menu_Target

getprop footer_Array
   return the footer_Array of me
end footer_Array

setprop footer_Array footerArray
   set the footer_Array of me to footerArray
end footer_Array

-- getprop visibleBody_Param [mTarget]
   put the wiki_View of mTarget into wikiView
   put the body_View of mTarget into bodyView
   put the visible_Name of bodyView into visBodyName
   return visBodyName
end visibleBody_Param

-- getprop visibleBody_Params [mTarget]
   put the wiki_View of mTarget into wikiView
   put the body_View of mTarget into bodyView
   put the visible_Names of bodyView into visBodyNames
   return visBodyNames
end visibleBody_Params


--> Global | Wiki | Story | Javascript | Menu
-
on menu_DisplayNeighborhood mTarget
   put _WikiView() into wikiView
   --
   -- put "$('.header H1 > a').click(function() { alert('done') });" into someJavascript
   put "wiki.neighborhood" into someJavascript
   set the browser_Javascript of wikiView to someJavascript
   put the result into someThing
   --
   put the result
end menu_DisplayNeighborhood

on menu_TryAndDisableClicks mTarget
   put _WikiView() into wikiView
   --
   put "$( 'a' ).click(function( event ) {event.preventDefault(); alert ('Hello wolrd');return false;});" into someJavascript
   --
   set the browser_Javascript of wikiView to someJavascript
   put someJavascript
end menu_TryAndDisableClicks

private on _
end _

-- on menu_VisibleBody mTarget, visBodyName
   put the wiki_View of mTarget into wikiView
   put the body_View of wikiView into bodyView
   
   set the visible_Name of bodyView to visBodyName
end menu_VisibleBody

on menu_SaveFooterArray mTarget
   put the wiki_View of mTarget into wikiView
   put the footer_View of mTarget into footerView
   put the itemArray of footerView into oArray
   
   put oArray into footerArray ["itemArray"]
   set the footer_Array of me to footerArray
end menu_SaveFooterArray

private on __
end __

on menu_ReplaceFooter mTarget
   put the wiki_View of mTarget into wikiView
   put the footer_View of mTarget into footerView
   
   put the footer_Array of me into footerArray
   put footerArray ["itemArray"] into footerItemArray
   
   lock screen   
   set the control_Type of footerView to "navbar"  
   
   set the itemArray of footerView to footerItemArray
   set the backgroundcolor of footerView to "white"
   set the showborder of footerView to false
   set the itemstyle of footerView to "icons"
   unlock screen
   
   put the script of footerView
end menu_ReplaceFooter

on menu_ResetFooter mTarget
   put the wiki_View of mTarget into wikiView
   put the footer_View of mTarget into footerView
   set the control_Type of footerView to "placeholder"  
end menu_ResetFooter

private on ___
end ___

on menu_ReplaceBody mTarget
   put the wiki_View of mTarget into wikiView
   put the body_View of mTarget into bodyView
   
   set the control_Type of bodyView to "View|Layout|Group"  
end menu_ReplaceBody

on menu_ResetBody mTarget
   put the wiki_View of mTarget into wikiView
   put the body_View of mTarget into bodyView
   
   set the control_Type of bodyView to "placeholder"  
end menu_ResetBody

on menu_EditBodyBehavior mTarget
   put the wiki_View of mTarget into wikiView
   put the body_View of mTarget into bodyView
   
   put the behavior of bodyView into bObject
   edit the script of bObject
end menu_EditBodyBehavior

private on ____
end ____

on menu_TestGeometry mTarget
   put the wiki_View of mTarget into wikiView
   dispatch "LayoutControl" to wikiView
end menu_TestGeometry

on menu_EditBehavior mTarget, whichBehavior
   switch whichBehavior
      case "Header"
         break
      case "Body"
         break
      case "Footer"
         break
   end switch
end menu_EditBehavior

on _
end _

on menu_TestJson mTarget
   put url "http://livecode.viral.academy/svg.json?random=079fed55" into someJSON
   put json_ToArray (someJSON) into someArray
   display_Array someArray
end menu_TestJson

on menu_FetchLastPage dgView
   put the browser_Url of dgView into someUrl
   
   -- url_Deconstruct someUrl, someProtocol, fedwikiDomain, urlPath, shortName, fileExtension, uName, pWord
   set the itemdelimiter to "/"
   put item 3 of someUrl into fedwikiDomain
   put item 4 to -1 of someUrl into urlPath
   
   put fedwiki_ExtractPageSlugsFromPath (urlPath) into pageSlugs
   put line -1 of pageSlugs into pageSlug
   put pageArray_Fetch (fedwikiDomain, pageSlug) into someArray
   
   display_Array someArray, "pageArray_Fetch()"
end menu_FetchLastPage

on menu_WikiSiteMap dgView
   put the browser_Url of dgView into someUrl
   url_Deconstruct someUrl, someProtocol, fedwikiDomain, urlPath, shortName, fileExtension, uName, pWord
   put fedwiki_FetchSiteExport (fedwikiDomain) into siteJSON
end menu_WikiSiteMap

private on _____
end _____)

on menu_FindSites mTarget
   put "tigrutigru" into nameStem
   put "https://www.google.se/?gfe_rd=cr&ei=ihuFVb6rFaar8wfVj4GoBA" into someURL
   put merge ("&gws_rd=ssl#q=%22Welcome+visitors%22+%22site+owned+by+[[nameStem]]%22") after someURL
   
   put the browser_Widget of mTarget into browserWidget
   set the url of browserWidget to someURL
end menu_FindSites

on _
end _

on menu_CreatePage mTarget
   put the tree_Array of mTarget into jsonArray
   
   if jsonArray is an array then
      put the tree_Field of mTarget into treeField
      put the fedwiki_Domain of treeField into fedwikiDomain
      put jsonArray ["Title"] into oldTitle
   else  
      put the textDisplay_View of mTarget into textDisplayView
      put the fedwiki_Domain of textDisplayView into fedwikiDomain
      put the view_Text of textDisplayView into someJson
      put json_ToArray (someJson) into jsonArray
      put jsonArray ["Title"] into oldTitle
   end if
   
   put opn_Ask ("Give the page a new title...", oldTitle) into newTitle
   put newTitle into jsonArray ["Title"]
   
   put json_FromArray (jsonArray) into someJson
   -- put someJson
   
   put tolower (newTitle) into wikiPageSlug
   replace space with "-" in wikiPageSlug
   
   breakpoint
   -- dispatch "pageJson_Store" to stack "Wiki Crawl" with wikiPageSlug, fedwikiDomain, someJson
   pageJson_Store
   put the result into someResult
   
   put someResult
end menu_CreatePage

on _
end _

on menu_DisplaySites
   -- scp –P 40050 Desktop/url.txt yatri@192.168.1.50:~/Desktop/url.txt
end menu_DisplaySites

on menu_DoubleJson mTarget
   -- put url "http://wiki.viral.academy/teachers.json?random=22d425f7" into someJSON
   -- put url "http://wiki.viral.academy/welcome-visitors.json?random=6fcfffef" into someJSON
   put url "http://wiki.viral.academy/welcome-visitors.json" into someJSON
   -- put url "http://wiki.viral.academy/view/welcome-visitors/view/teachers" into someJSON
   put json_ToArray (someJSON) into someArray
   display_Array someArray
end menu_DoubleJson
