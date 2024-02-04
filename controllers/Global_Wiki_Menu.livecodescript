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

getprop checked_UseNodeServer
   put LocalArray ["wikiStarted"] into sBoolean
   return sBoolean is true
end checked_UseNodeServer

getprop checked_StartWiki
   return LocalArray ["wikiStarted"] is true
end checked_StartWiki

getprop checked_StartWikiWithXterm
   return LocalArray ["wikiStarted"] is true
end checked_StartWikiWithXterm

getprop disabled_WikiBrowser
   return LocalArray ["wikiStarted"] is false
end disabled_WikiBrowser

getprop port_Param
   put wiki_GetPort() into sPort
   if sPort is empty then
      return 80
   else
      return sPort
   end if
end port_Param

getprop port_Params
   return "3000,8080,9090,-,80"
end port_Params

getprop localWiki_Params
   put wiki_ListLocalShortAll ("*astralship*") into wikiFolders
   return wikiFolders
end localWiki_Params

getprop securityType_Params
   return "friends,cookie,passport,-,legacy"
end securityType_Params

getprop securityType_Param [wikiView]
   return wiki_GetSecurityType()
end securityType_Param


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
      wiki_StopNodeServer
   else
      -- wiki_StartNodeServer -- display_Wiki starts wiki if needed
      display_Wiki "fedwiki.org", wikiView
   end if
end menu_StartWiki

on menu_UseNodeServer wikiView
   put LocalArray ["wikiStarted"] into sBoolean
   put sBoolean is false into LocalArray ["wikiStarted"]
end menu_UseNodeServer

on menu_SecurityType wikiView, securityType
   wiki_SetSecurityType securityType
end menu_SecurityType

on menu_Port wikiView, sPort
   wiki_SetPort sPort
end menu_Port

on menu_RestLivecodeWorld
   put system_GetAdminPassword() into systemPassword
   hosts_Add "rest.livecode.world", systemPassword
end menu_RestLivecodeWorld

private on __
end __

on menu_LaunchEtcHosts
   launch_EtcHosts
   if the shiftKey is "Down" then
      display_EtcHosts
   end if
end menu_LaunchEtcHosts

on menu_UpdateEtcHosts dView
   display_LocalWikis dView
   --
   put the displayed_Index of dView into localHosts
   --
   breakpoint
   put hosts_NewText (localHosts) into hostsText
   -- hosts_Set hostsText
   display_Text hostsText
end menu_UpdateEtcHosts

private on ____
end ____

on menu_SearchOpenverse dView
   put lcw_Ask ("Enter search terms...", "cat|dog", "Openverse", dView) into searchBit
   --
   put openverse_Search (searchBit) into sData
   -- display_Data sData, searchBit, "Openverse"
   
   put wikiPage_OpenVerseThumbNails (sData) into pageArray
   display_PageArray pageArray
end menu_SearchOpenverse

on menu_StartWikiWithXterm
   wiki_StartWithXterm
end menu_StartWikiWithXterm

on submenu_InstallWiki
   return "Global | Wiki | Install | Menu"
end submenu_InstallWiki

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Menu")
end submenu_Dev
