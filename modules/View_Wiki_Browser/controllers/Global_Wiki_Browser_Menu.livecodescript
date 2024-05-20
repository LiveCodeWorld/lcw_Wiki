script "Global | Wiki | Browser | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Browser | Menu
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
   put the browser_View of tObject into wikiView
   if exists (wikiView) is false then
      put the display_View of tObject into dView
      put the displayed_Object of dView into wikiView
      if exists (wikiView) is false then
         return empty
      end if
   end if
   
   put the wiki_Domain of wikiView into wikiDomain
   put wikiDomain into LocalArray ["wikiDomain"]
   --
   put _ListSubdomains(wikiDomain) into LocalArray ["subDomains"]
   return wikiView
end menu_Target

private function _ListSubdomains wikiDomain
   put wikiGarden_ListAllDomains (wikiDomain) into wikiDomains
   --
   put url_GetTLD (wikiDomain) into tldDomain
   line_Delete tldDomain, wikiDomains
   --
   return wikiDomains
end _ListSubdomains

getprop displayDomain_Param [wikiView]
   put the browser_Domain of wikiView into wikiDomain
   return wikiDomain
end displayDomain_Param

getprop displayDomain_Params
   put wikiFolder_ListTopLevel() into wikiDomains
   --
   if wikiDomains is empty then
      return "ChatGPT,Localhost,-,Ask"
   else
      return "Ask,-" &CR& wikiDomains &CR& "-,ChatGPT"
   end if
end displayDomain_Params

getprop subdomain_Params [wikiView]
   return LocalArray ["subDomains"]
end subdomain_Params

getprop disabled_Subdomain [wikiView] 
   put LocalArray ["wikiDomain"] into wikiDomain
   
   switch
      case wikiDomain = "localhost"
         return "delete"
      case LocalArray ["subDomains"] is empty
         return "delete"
      default
         return false
   end switch
end disabled_Subdomain


--> Global | Wiki | Browser | Menu
-
on menu_DisplayDomain wikiView, wikiDomain   
   if the shiftKey is "down" then put empty into wikiView
   switch wikiDomain
      case "Ask"
         put the wiki_Domain of wikiView into wikiDomain
         put lcw_Ask ("Display wiki '[[var]]'...", wikiDomain, wikiView, wikiDomain) into wikiDomain
         --
         put wikiGarden_Folder (wikiDomain) into gardenFolder
         if gardenFolder is not empty then
            put wikiGarden_Name (wikiDomain) into gardenName
            wikiServer_StartNodeGarden gardenName
         end if
         --
         display_WikiBrowser wikiDomain, wikiView
         break
      case "ChatGPT"
         display_WikiBrowser "https://chat.openai.com/", wikiView
         break
      default
         display_Wiki wikiDomain, wikiView
   end switch
end menu_DisplayDomain

on menu_Subdomain wikiView, subDomain
   if the shiftKey is "Down" then
      display_Wiki subDomain
   else
      set the page_Title [subDomain] of wikiView to "Welcome Visitors"
   end if
end menu_Subdomain

private on _
end _

on menu_Fedwiki.1 wikiView
   display_WikiDomain "fedwiki.org"
end menu_Fedwiki.1

on menu_Livecode.2 wikiView
   -- set the page_Title ["livecode.world"] of wikiView to "Welcome Visitors"
   display_WikiDomain "livecode.world"
end menu_Livecode.2

on menu_Thought.3 wikiView
   set the page_Title ["thought.garden"] of wikiView to "Welcome Visitors"
end menu_Thought.3

private on __
end __

on menu_Localhost.9 wikiView
   display_WikiBrowser "localhost", wikiView
end menu_Localhost.9

on menu_ResetDomain.0 wikiView
   put the wiki_Domain of wikiView into wikiDomain
   --
   -- put url_GetTLD (wikiDomain) into tldDomain
   display_Wiki wikiDomain, wikiView
end menu_ResetDomain.0

private on ___
end ___

on menu_SaveStack wikiView
   put the stack_Name of wikiView into sName
   save stack sName
   --
   lcw_Notify "Saved stack!", sName
end menu_SaveStack

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Browser | Menu")
end submenu_Dev
