script "Global_Wiki_Tree_Line_Menu"
--> MetaData
-
license: GPLv3
name: Global_Wiki_Tree_Line_Menu
type: controller
version: 0.1


--> Global | Wiki | Tree | Line | Menu
-
on menu_UploadPageJson arrayView, dreamDomain
   put the title_Text of arrayView into fedwikiDomain
   put the top_Array of arrayView into itemArray
   put itemArray ["slug"] into pageSlug
   
   put pageJson_Fetch (fedwikiDomain, pageSlug) into pageJSON
   dreamfactory_StoreWikiPage pageSlug, dreamDomain, pageJSON
   put merge ("http://hosting.permanent.wiki/view/welcome-visitors/[[dreamDomain]]/[[pageSlug]]") into pageURL
   launch url pageURL
end menu_UploadPageJson

on menu_DisplayPageArray arrayView
   put the title_Text of arrayView into fedwikiDomain
   put the top_Array of arrayView into itemArray
   put itemArray ["slug"] into pageSlug
   
   display_WikiPageArray
end menu_DisplayPageArray



--> Global | Wiki | Tree | Line | Menu | Props
-

--> Global | Wiki | Tree | Line | Menu | Disabled
-
