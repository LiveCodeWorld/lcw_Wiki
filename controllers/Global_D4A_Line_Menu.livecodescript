script "Global_D4A_Line_Menu"
--> MetaData
-
license: GPLv3
name: Global_D4A_Line_Menu
type: controller
version: 0.1

command _CheckExists pageTitle
   put dropbox_MediaWikiImageFolder (pageTitle) into someFolder
   if there is a folder someFolder then
      lcw_WarnAndExit merge ("There is already an image folder for the wiki page '[[pageTitle]]'?"), true
   end if
end _CheckExists

/*
lcw_WarnAndExit merge ("There are no images for the wiki page '[[pageTitle]]'?"), true
end if
lcw_Answer merge ("Download all the images for the wiki page '[[pageTitle]]'?")
*/

--> Global | D4A | Line | Menu
-
on menu_DownloadImages displayView
   put the selected_Line of displayView into pageTitle   
   _CheckExists pageTitle
   --
   wikipedia_DownloadImages pageTitle
   put the result into imageUrls
   
   put the number of lines of imageUrls into iNum
   lcw_Answer merge ("Downloaded [[iNum]] images for the wiki page '[[pageTitle]]'?")
end menu_DownloadImages

on _
end _

on menu_RevealImageFolder displayView
   put dropbox_MediaWikiImageFolder (pageTitle) into someFolder
   finder_Reveal someFolder
end menu_RevealImageFolder


--> Global | D4A | Line | Menu | Disabled
-
getprop disabled_RevealImageFolder [displayView]
   put the selected_Line of displayView into pageTitle   
   --
   put dropbox_MediaWikiImageFolder (pageTitle) into someFolder
   put there is a folder someFolder into folderExists
   return folderExists
end disabled_RevealImageFolder
