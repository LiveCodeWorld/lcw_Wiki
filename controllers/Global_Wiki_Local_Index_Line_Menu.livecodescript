script "Global | Wiki | Local | Index | Line | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Local | Index | Line | Menu
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
   -- return display_MenuTarget(tObject)
   return the display_View of tObject
end menu_Target

getprop menu_CheckTarget [cameraView]
   return exists (cameraView)
end menu_CheckTarget

private function _AskAstral sDomain, pTitle
   if sDomain ends with "astralship.wiki" is false then
      set the itemdelimiter to "."
      put "astralship.wiki" into item -1 of sDomain
   end if
   put lcw_Ask ("Create wild card tunnel...", sDomain, pTitle) into sDomain
   return sDomain
end _AskAstral

private function _SelectedFolder dView
   _SetSelected dView, shortFolder, sFolder
   return sFolder
end _SelectedFolder

private command _SetSelected dView, @shortFolder, @sFolder
   put the selected_Line of dView into shortFolder
   put _DisplayedFolder (shortFolder) into sFolder
end _SetSelected

private function _DisplayedFolder shortFolder
   put wikiFarm_GetFolder() into wikiFolder
   put wikiFolder & shortFolder into sFolder
   text_AddTrailing sFolder, slash
   return sFolder
end _DisplayedFolder

private command _SelectedAstralFolders dView, @wikiFolder, @localFolder
   put the selected_Line of dView into folderName
   set the itemdelimiter to "."
   put item 1 to -3 of folderName & ".localhost" into localHostName
   --
   put wikiFarm_GetFolder() into wikiFolder
   set the defaultfolder to wikiFolder
   put wikiFolder & localHostName into localFolder
   text_AddTrailing localFolder, slash
   --
   put wikiFolder & folderName into wikiFolder
   text_AddTrailing wikiFolder, slash
end _SelectedAstralFolders

private function _FolderIsNonAndAstral dView
   _SelectedAstralFolders dView, wikiFolder, localFolder
   --
   if wikiFolder ends with "astalship.wiki" then
      return _GoodToLocalSymLink (wikiFolder, localFolder)
   else
      return false
   end if
end _FolderIsNonAndAstral

getprop disabled_DisplayPages [dView]
   if the shiftKey is "down" then return false
   put _SelectedFolder (dView) into sFolder
   --
   return wiki_FolderHasNoPages (sFolder) is false
end disabled_DisplayPages

getprop disabled_TrashFolder [dView]
   if the shiftKey is "down" then return false
   _SelectedAstralFolders dView, astralFolder, localFolder
   --
   return wiki_FolderHasNoPages (astralFolder) is false
end disabled_TrashFolder

getprop disabled_SymLinkLocal [dView]
   put the selected_Line of dView into localFolder
   return localFolder ends with "astralship.wiki"
end disabled_SymLinkLocal

getprop disabled_ConvertAstralToLocal [displayView]
   put _FolderIsNonAndAstral (displayView) into isNonAndAstral
   return isNonAndAstral is false 
   
   if the title_Text of displayView is "Non-Symlinked Astral" then
      put _FolderIsNonAndAstral (displayView) into isNonAndAstral
      return isNonAndAstral is false 
   else
      return true
   end if
end disabled_ConvertAstralToLocal


--> Global | Wiki | Local | Index | Line | Menu
-
on menu_SymLinkLocal displayView
   put the selected_Line of displayView into localFolder
   set the itemdelimiter to "."
   -- put item 1 to -2 of shortFolder & ".localhost" into symFolder
   put localFolder into destFolder
   -- put "astralship.wiki" into item -1 of destFolder
   put "locahost" into item -1 of destFolder
   --
   put lcw_Ask("Name the localhost folder:", destFolder, "Sym Link", displayView) into destFolder
   --
   put wikiFarm_GetFolder() into wikiFolder
   set the defaultfolder to wikiFolder
   put wikiFolder & localFolder into longLocalFolder
   put wikiFolder & destFolder into longDestFolder
   --
   switch
      case there is not a folder longLocalFolder
         breakpoint
         break
      case there is a folder longDestFolder
         breakpoint
         break
      default
         symlink_CreateFolder longLocalFolder, longDestFolder --, "paste"
         --
         display_LocalWikis displayView
   end switch
end menu_SymLinkLocal

getprop disabled_ConvertToLocal [dView]
   if the shiftKey is "down" then return false
   put _SelectedFolder (dView) into sFolder
   --
   put folder_IsSymLink (sFolder) into isSymLinked
   return isSymLinked
end disabled_ConvertToLocal

private function _GoodToLocalSymLink wikiFolder, localFolder
   if there is not a folder wikiFolder then return true
   if there is a folder localFolder then return true
   
   put folder_IsSymLink (sFolder) into isSymLinked
   return isSymLinked is false 
end _GoodToLocalSymLink

on menu_ConvertToLocal dView
   _SetSelected dView, shortFolder, sFolder
   --
   set the itemdelimiter to "."
   put sFolder into sFilter
   put "*" into item 1 of sFilter
   --
   put shortFolder into shortLocalHostFolder
   put "localhost" into item -2 to -1 of shortLocalHostFolder
   --
   put lcw_Ask ("Create localhost folder...", shortLocalHostFolder, "Create Symlink", dView) into shortLocalHostFolder
   put _DisplayedFolder (shortLocalHostFolder) into localhostFolder
   if there is a folder localhostFolder then
      finder_Reveal localhostFolder
      lcw_AnswerWarning "Folder already exists!", dView
      exit to top
   end if
   
   revMoveFolder sFolder, localhostFolder
   if there is a folder localhostFolder then
      symlink_CreateFolder localhostFolder, sFolder
   end if
   --
   display_NonSymLinked dView, sFilter
end menu_ConvertToLocal

on menu_AddAstralSubdomain dView
   put the selected_Line of dView into sDomain
   put _AskAstral (sDomain, "Dynadot") into domainName
   set the itemdelimiter to "."
   put item 1 to -3 of domainName into subDomainName
   --
   astral_AddSubdomain "astralship.wiki", subDomainName
   put the result into dnsData
   --
   display_LocalAstralWikis dView, true
end menu_AddAstralSubdomain

private on _
end _

on menu_DisplayPages dView
   put the selected_Line of dView into sDomain
   --
   display_WikiSitePageArray sDomain
end menu_DisplayPages

private on __
end __

on menu_TrashFolder dView
   _SelectedAstralFolders dView, astralFolder, localFolder
   --
   revDeleteFolder astralFolder
   --
   _Refresh dView
end menu_TrashFolder

private command _Refresh dView
   breakpoint
   --
   put the title_Text of dView into sTitle
   put the wiki_Filter of dView into wikiFilter
   display_LocalWikis dView, sTitle, wikiFilter
end _Refresh

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Local | Index | Line | Menu")
end submenu_Dev

