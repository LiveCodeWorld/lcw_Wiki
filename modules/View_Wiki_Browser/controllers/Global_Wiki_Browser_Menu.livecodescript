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
   put wikiServer_NodeIsRunning() into nodeIsRunning
   put nodeIsRunning into LocalArray ["nodeIsRunning"]
   --
   put url_GetTLD (wikiDomain) into tldDomain
   put tldDomain into LocalArray ["tldDomain"]
   --
   return wikiView
end menu_Target

getprop displayDomain_Param [wikiView]
   return LocalArray ["tldDomain"]
end displayDomain_Param

getprop displayDomain_Params
   if LocalArray ["nodeIsRunning"] then
      put wikiFarm_ListDomains() into wikiDomains
      put url_ListTopLevelDomains (wikiDomains) into wikiDomains
   else
      put wikiFolder_ListTopLevel() into wikiDomains
   end if
   return "Ask,-" &CR& wikiDomains &CR& "-,ChatGPT"
end displayDomain_Params

getprop subdomain_Params [wikiView]
   return LocalArray ["subDomains"]
end subdomain_Params

getprop disabled_Subdomain [wikiView] 
   put LocalArray ["wikiDomain"] into wikiDomain
   switch
      case wikiDomain = "localhost"
         return "delete"
      default
         if LocalArray ["nodeIsRunning"] then
            put LocalArray ["tldDomain"] into tldDomain
            put wikiFarm_ListSubdomains (tldDomain) into subDomains
         else
            put wikiDomain_ListTop() into subDomains
            url_FilterDomains subDomains, wikiDomain
         end if
         put subDomains into LocalArray ["subDomains"]
         if subDomains is empty then
            return "delete"
         else
            return false
         end if
   end switch
end disabled_Subdomain


--> Global | Wiki | Browser | Menu
-
on menu_DisplayDomain wikiView, wikiDomain
   switch wikiDomain
      case "Ask"
         put the wiki_Domain of wikiView into wikiDomain
         put lcw_Ask ("Display wiki '[[var]]'...", wikiDomain, wikiView, wikiDomain) into wikiDomain
         --
         put wikiFolder_FromDomain (wikiDomain) into gardenFolder
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
         if the shiftKey is "Down" then
            if the controlKey is "Down" then
               display_Wiki wikiDomain
            else
               set the wiki_Domain of wikiView to wikiDomain
            end if
         else
            set the page_Title [wikiDomain] of wikiView to "Welcome Visitors"
         end if
   end switch
end menu_DisplayDomain

on menu_Subdomain wikiView, subDomain
   if the shiftKey is "Down" then
      if the controlKey is "Down" then
         display_Wiki subDomain
      else
         set the wiki_Domain of wikiView to subDomain
      end if 
   else
      set the page_Title [subDomain] of wikiView to "Welcome Visitors"
   end if
end menu_Subdomain

private on _
end _

on menu_Fedwiki.1 wikiView
   display_Wiki "fedwiki.org", wikiView
end menu_Fedwiki.1

on menu_Livecode.2 wikiView
   display_Wiki "livecode.world", wikiView
end menu_Livecode.2

on menu_Thought.3 wikiView
   -- set the page_Title ["thought.garden"] of wikiView to "Welcome Visitors"
   display_Wiki "thought.garden", wikiView
end menu_Thought.3

private on __
end __

on menu_ViewInBrowser.8 wikiView
   put the lineUp_URL of wikiView into lineUpURL
   --
   launch url lineUpURL
end menu_ViewInBrowser.8

on menu_Localhost.9 wikiView
   display_Wiki "localhost", wikiView
end menu_Localhost.9

on menu_ResetDomain.0 wikiView
   put the wiki_Domain of wikiView into wikiDomain
   --
   -- put url_GetTLD (wikiDomain) into tldDomain
   display_Wiki wikiDomain, wikiView
end menu_ResetDomain.0

private on ___
end ___

on menu_Keypass wikiView
   -- display_Template
   display_ModuleInstance "View|Keepass"
   if item 1 of the result = "Error" then
      lcw_AnswerWarning "Cannot open stack View|Keepass! [[var]]", wikiView, the result
   else
      put the result into dView
      return dView
   end if
end menu_Keypass

on menu_DomainTools wikiView
   put the wiki_Domain of wikiView into wikiDomain
   --
   put the siteMap_Array of wikiView into sArray
   display_Tool sArray, wikiDomain, "Wiki Domain", "lcw_Wiki"
   put the result into dView
   set the displayed_Object of dView to wikiView
   return dView
end menu_DomainTools

on menu_SaveStack wikiView
   put the stack_Name of wikiView into sName
   ide_SaveStack sName
end menu_SaveStack

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Browser | Menu")
end submenu_Dev
