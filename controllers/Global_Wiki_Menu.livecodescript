script "Global | Wiki | Menu"
--> MetaData
-
license: GPLv3
name: Global | Wiki | Menu
type: controller
version: 0.4

/*This menu is used to control a Livecode wiki browser.*/


--> Menu | Props
-
local LocalArray

getprop menu_Target [tObject]
   put wiki_Started() into LocalArray ["wikiStarted"]
   return display_MenuTarget (tObject)
   -- return the display_View of tObject
end menu_Target

getprop dream_Domains
   put "Jelly Fish" & CR after topDomains
   put "-" & CR after topDomains
   put "david.icotopia.io" & CR after topDomains
   put "trevor.icotopia.io" & CR after topDomains
   put "video.icotopia.io" & CR after topDomains
   put "david.culturecollective.cc" & CR after topDomains
   --
   delete char -1 of topDomains
   return topDomains
end dream_Domains

getprop top_Domains
   put "Jelly Fish" & CR after topDomains
   put "Worldscape" & CR after topDomains
   put "-" & CR after topDomains
   put "outlandish.academy" & CR after topDomains
   put "david.outlandish.academy" & CR after topDomains
   put "nina.outlandish.academy" & CR after topDomains
   put "trevor.outlandish.academy" & CR after topDomains
   --
   delete char -1 of topDomains
   return topDomains
end top_Domains

getprop show_HiddenFiles
   put finder_GetShowInvisibleFiles() into someBoolean
   return someBoolean
end show_HiddenFiles

getprop disabled_StartWiki
   return LocalArray ["wikiStarted"] is true
end disabled_StartWiki

getprop disabled_StopWiki
   return LocalArray ["wikiStarted"] is false
end disabled_StopWiki

getprop disabled_WikiBrowser
   return LocalArray ["wikiStarted"] is false
end disabled_WikiBrowser

getprop checked_Ngrok
   return ngrok_ListProcessIds() is not empty
end checked_Ngrok

function _GetWikiView mTarget
   -- "browser_View" is on card script of stack "Fedwiki Editor"
   put the wiki_View of cd 1 of stack "Fedwiki Editor" into wikiView
   return wikiView
end _GetWikiView

private function _GetDomain
   return empty
end _GetDomain


--> Global | Wiki | Menu
-
on menu_TestFaasd
   post "Hello world" to url "https://faasd.platform.earth/function/activity"
   put it
end menu_TestFaasd

on menu_WikiBrowser
   display_WikiBrowser
end menu_WikiBrowser

on menu_ListLocalWikis
  display_LocalWikis
end menu_ListLocalWikis

on submenu_ObeyaStudio
   return "Global | Obeya | Studio | Menu"
end submenu_ObeyaStudio

private on _
end _

on menu_StartWiki
   wiki_Start
end menu_StartWiki

on menu_StopWiki
   wiki_Stop
end menu_StopWiki

private on __
end __

on menu_Xterm
   display_Xterm true
end menu_Xterm

on menu_XtermClear browserView
   put line 1 of xterm_ListBrowsers() into xtermView
   if exists (xtermView) is false then
      display_Xterm true
      put the result into xtermView
   end if
   --
   ttyd_Execute "clear", xtermView
end menu_XtermClear

private on ____
end ____

on submenu_Tunnel
   return "Global | Tunnel | Menu"
end submenu_Tunnel

on submenu_InstallWiki
   return "Global | Wiki | Install | Menu"
end submenu_InstallWiki

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Menu")
end submenu_Dev
