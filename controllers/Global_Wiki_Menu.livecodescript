script "Global | Wiki | Menu"
--> MetaData
-
license: GPLv3
name: Global | Wiki | Menu
type: controller
version: 0.5


--> Menu | Props
-
local LocalArray

getprop menu_Target [tObject]   
   put the browser_View of tObject into browserView
   if exists (browserView) then
      return browserView
   else
      put line 1 of display_List ("View|Obeya|Studio") into browserView
      if exists (browserView) then return browserView
      return empty
   end if
end menu_Target

getprop menu_CheckTarget [browserView]
   try
      put wiki_NodeServerIsRunning() into LocalArray ["wikiStarted"]
      return exists (browserView)
   catch e
      return false
   end try
end menu_CheckTarget

getprop checked_StartWiki
   return LocalArray ["wikiStarted"] is true
end checked_StartWiki

getprop disabled_WikiBrowser
   return LocalArray ["wikiStarted"] is false
end disabled_WikiBrowser

getprop localWiki_Params
   put wikiGarden_ListAllDomains ("*astralship*") into wikiFolders
   return wikiFolders
end localWiki_Params


--> Global | Wiki | Menu
-
on menu_LocalWiki wikiView, wikiDomain
   if the shiftkey is "down" then
      set the page_Title [wikiDomain] of wikiView to "welcome-visitors"
   else
      set the wiki_Domain of wikiView to wikiDomain
   end if
end menu_LocalWiki

on menu_ListLocalWikis
   display_LocalWikis
end menu_ListLocalWikis

on menu_CreateLocalWiki wikiView
   put lcw_Ask ("Add new wiki domain to /etchosts?", "", "Local Wiki Domain") into wikiDomain
   --
   wikiServer_Create wikiDomain
   display_LocalWikis
   --
   put wiki_Browser() into browserView
   display_Wiki wikiDomain, browserView
end menu_CreateLocalWiki

private on _
end _

on menu_StartWiki wikiView
   if wiki_NodeServerIsRunning() is true then
      wikiServer_StopNode
   else
      -- wikiServer_StartNode -- display_Wiki starts wiki if needed
      display_Wiki "fedwiki.org", wikiView
   end if
end menu_StartWiki

on menu_UseNodeServer wikiView
   put LocalArray ["wikiStarted"] into sBoolean
   put sBoolean is false into LocalArray ["wikiStarted"]
end menu_UseNodeServer

on menu_RestLivecodeWorld
   put system_GetAdminPassword() into systemPassword
   hosts_Add "rest.livecode.world", systemPassword
end menu_RestLivecodeWorld

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Menu")
end submenu_Dev
