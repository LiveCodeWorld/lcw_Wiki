script "Global | Hosts | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Hosts | Menu
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
   put the display_View of tObject into LocalArray ["dView"]
   put the displayed_Object of tObject into sObject
   return sObject
end menu_Target

private function _dView
   return LocalArray ["dView"]
end _dView

getprop menu_CheckTarget [dView]
   return exists (dView)
end menu_CheckTarget

command _AnswerSaveHosts hostsText, dView
   lcw_Answer "Backup and save the displayed text to /etc/hosts?", dView
   
   hosts_Backup
   hosts_Set hostsText
   --
   return hostsText
end _AnswerSaveHosts


--> Global | Hosts | Menu
-
on menu_MoveHostsFile dView
   hosts_MoveToBackup
   --
   display_EtcHosts
end menu_MoveHostsFile

getprop disabled_MoveHostsFile
   if there is a file "/etc/hosts" then
      return false
   else
      return "delete"
   end if
end disabled_MoveHostsFile

getprop disabled_MoveHostsFile
   if there is a file "/etc/hosts" then
      return false
   else
      return "delete"
   end if
end disabled_MoveHostsFile

on menu_RestoreHostsFile dView
   hosts_RestoreBackup
   --
   display_EtcHosts
end menu_RestoreHostsFile

getprop disabled_RestoreHostsFile
   if there is not a file "/etc/hosts" then
      if there is a file "/etc/hosts_backup" then
         return false
      else
         return true
      end if
   else
      return "delete"
   end if
end disabled_RestoreHostsFile

private on _
end _

on menu_DisplayEtcHosts
   display_EtcHosts
   if the shiftKey is "Down" then
      launch_EtcHosts
   end if
end menu_DisplayEtcHosts

on menu_EditEtcHosts
   code_OpenFile "/etc/hosts"
end menu_EditEtcHosts

private on __
end __

on menu_BasicEtcHosts dView
   put hosts_NewText ("rest.livecode.world") into hostsText
   --
   set the displayed_Index ["Basic /etc/hosts?"] of dView to hostsText
end menu_BasicEtcHosts

on menu_NewEtcHosts dView
   put wikiDomain_List() into wikiDomains
   put hosts_NewText (wikiDomains) into hostsText
   --
   set the displayed_Index ["New /etc/hosts?"] of dView to hostsText
   --
   -- _AnswerSaveHosts hostsText, dView
end menu_NewEtcHosts

on menu_UpdateEtcHosts dView
   put the displayed_Index of dView into localHosts
   filter localHosts with "*localhost" -- just in case
   --
   put hosts_AddLocalDomainsToText (localHosts) into hostsText
   -- display_Text hostsText, "Current", "/etc/hosts", dView
   set the displayed_Index ["New /etc/hosts?"] of dView to hostsText
   
   display_LocalWikis
   --
   _AnswerSaveHosts hostsText, dView
end menu_UpdateEtcHosts

private on ___
end ___

on menu_WriteDisplayed dView
   put the displayed_Index of dView into hostsText
   --
   lcw_Answer "Write the displayed text to /etc/hosts?", dView
   --
   hosts_Set hostsText
end menu_WriteDisplayed

on menu_BackupHostsFile
   hosts_Backup
end menu_BackupHostsFile

on submenu_Dev
   return menu_DevTitle ("Global | Hosts | Menu")
end submenu_Dev
