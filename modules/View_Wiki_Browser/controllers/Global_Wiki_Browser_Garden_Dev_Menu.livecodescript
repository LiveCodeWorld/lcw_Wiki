script "Global | Wiki | Browser | Garden | Dev | Menu"
--> MetaData
-
license: GPLv3
name: Global | Wiki | Browser | Garden | Dev | Menu
type: controller
author: David Bovill
version: 0.1

/*
Here you can describe this developer menu.
Full help text should be provided on the linked wiki.

Consider improving by creating with same menu_Target as no-developer menu is is based on.
*/

--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_CheckTarget [mTarget]
   return exists (mTarget)
end menu_CheckTarget

getprop moveToGarden_Params
   return LocalArray ["gardenNames"]
end moveToGarden_Params

getprop moveSubDomains_Params
   return LocalArray ["gardenNames"]
end moveSubDomains_Params


--> Global | Wiki | Browser | Garden | Dev | Menu
-
on menu_MoveToGarden wikiView, gardenName
   put the wiki_Domain of wikiView into wikiDomain
   put wikiFolder_FromRouter (wikiDomain) into oldWikiFolder
   put wikiGarden_FindGardenFolder (gardenName) into newGardenFolder
   
   # Old Wiki Folder
   put newGardenFolder & wikiDomain & slash into newWikiFolder
   
   # Move
   revMoveFolder oldWikiFolder, newWikiFolder
   wikiGarden_Init true
end menu_MoveToGarden

on menu_MoveSubDomains wikiView, gardenName
   # Domains to Move
   put the wiki_Domain of wikiView into wikiDomain
   put url_GetTLD (wikiDomain) into tldDomain
   --
   put lcw_Ask ("Move all domains and subdomains to garden '[[var]]", tldDomain, wikiView, gardenName) into tldDomain
   
   breakpoint
   put wikiGarden_ListAllDomains (tldDomain) into domainsToMove
   put wikiGarden_FindGardenFolder (gardenName) into toGarden
   repeat for each line wikiDomain in domainsToMove
      put toGarden & wikiDomain & slash into toFolder
      put wikiFolder_FromRouter (wikiDomain) into fromFolder
      --
      if there is not a folder fromFolder then next repeat
      if fromFolder = toFolder then next repeat
      if there is a folder toFolder then next repeat
      
      revMoveFolder fromFolder, toFolder
   end repeat
   
   wikiGarden_Init true
end menu_MoveSubDomains

private on _
end _

on menu_MenuEdit displayView
   menu_Edit "Global | Wiki | Browser | Garden | Dev | Menu"
end menu_MenuEdit
