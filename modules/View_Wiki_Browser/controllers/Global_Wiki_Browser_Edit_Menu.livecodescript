script "Global | Wiki | Browser | Edit | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Browser | Edit | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_CheckTarget [wikiView]
   -- put the footer_IsVisible of wikiView into LocalArray ["footer_IsVisible"]
   put the lineup_Titles of wikiView into pageTitles
   put pageTitles into LocalArray ["pageTitles"]
   return true
end menu_CheckTarget


--> Global | Wiki | Browser | Edit | Menu
-
on menu_WikiBehavior wikiView
   put the behavior of wikiView into bObject
   edit the script of bObject
end menu_WikiBehavior

on menu_MenuGroupBehavior wikiView
   put the menuBar_View of wikiView into mGroup
   put the behavior of mGroup into bObject
   edit the script of bObject
end menu_MenuGroupBehavior

private on _
end _

on insert_Edit
   return "Global | Menu | Group | Edit | Menu"
end insert_Edit

private on __
end __

getprop fixText_Params [wikiView]
   return LocalArray ["pageTitles"]
end fixText_Params

on menu_FixText wikiView, pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put the wiki_Domain [pageTitle] of wikiView into wikiDomain
   --
   put pageArray_Get (wikiDomain, pageSlug) into pageArray
   put pageArray ["story"] into storyArray
   repeat with itemNum = 1 to item 2 of the extents of storyArray
      put storyArray [itemNum]["text"] into itemText
      wikipedia_FixText itemText
      put itemText into storyArray [itemNum]["text"]
   end repeat
   put storyArray into pageArray ["story"]
   
   -- put the page_Text [pageTitle] of wikiView into pageText
   -- wikipedia_FixText pageText
   -- display_Text pageText
   
   set the ghost_PageArray of wikiView to pageArray
end menu_FixText

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Browser | Edit | Menu")
end submenu_Dev
