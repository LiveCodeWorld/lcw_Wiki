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
   if exists (browserView) then
      return browserView
   else
      put line 1 of display_List ("View|Obeya|Studio") into browserView
      if exists (browserView) then return browserView
      return empty
   end if
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

getprop displayDomain_Params
   put wiki_ListTopLevelDomains() into wikiDomains
   url_SortDomainIndex wikiDomains
   --
   if wikiDomains is empty then
      return "ChatGPT,Localhost"
   else
      return wikiDomains & ",-,ChatGPT,Localhost"
   end if
end displayDomain_Params


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

private on _
end _

on menu_Fedwiki browserView
   put wikiPage_FilteredDomainList ("Fedwiki") into pageArray
   set the ghost_PageArray of browserView to pageArray
end menu_Fedwiki

on menu_Livecode browserView
   put wikiPage_FilteredDomainList ("Livecode") into pageArray
   set the ghost_PageArray of browserView to pageArray
end menu_Livecode

on menu_Thought browserView
   put wikiPage_FilteredDomainList ("Thought") into pageArray
   set the ghost_PageArray of browserView to pageArray
end menu_Thought

on menu_Platform browserView
   put wikiPage_FilteredDomainList ("Platform") into pageArray
   set the ghost_PageArray of browserView to pageArray
end menu_Platform

on menu_Astral browserView
   put wikiPage_FilteredDomainList ("Astral") into pageArray
   set the ghost_PageArray of browserView to pageArray
end menu_Astral

private on __
end __

on menu_Today browserView
   put wikiPage_TodaysActivity() into pageArray
   set the ghost_PageArray of browserView to pageArray
end menu_Today

on menu_EmptyFolders browserView
   put wikiPage_EmptyLocalFolders() into pageArray
   set the ghost_PageArray of browserView to pageArray
end menu_EmptyFolders

private on ___
end ___

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

on menu_ObeyaStudioTools browserView
   put the view_Name of browserView into viewName
   display_ModuleTools viewName
end menu_ObeyaStudioTools

on menu_MenuGroupTools
   put the stack_Folder of stack "View|Menu|Group" into moduleFolder
   put project_PathFromFolder (moduleFolder) into stackPath
   display_ModuleTools stackPath
end menu_MenuGroupTools
