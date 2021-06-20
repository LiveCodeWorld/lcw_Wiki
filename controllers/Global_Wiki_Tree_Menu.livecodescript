script "Global | Wiki | Tree | Menu"
--> MetaData
-
license: GPLv3
name: Global | Wiki | Tree | Menu
type: controller
version: 0.1


--> Global | Wiki | Tree | Menu
-
on menu_DisplayWikiBrowser displayView
   go to stack "Fedwiki Editor"
end menu_DisplayWikiBrowser

on menu_RevealStackFolder
   -- just for fun
   -- lcw_Wiki/stacks/Fedwiki Editor.livecode
   put the project_Folder ["stacks"] of stack "lcw_Wiki" into projectStackFolder
   put projectStackFolder & "Fedwiki Editor.livecode" into stackPath
end menu_RevealStackFolder

on _
end _

on menu_DisplayWiki arrayView, dreamDomain
   put fedwiki_FetchPageListArray (dreamDomain) into pageListArray
   
   display_Array pageListArray, dreamDomain, "Global | Wiki | Tree | Menu", "Global | Wiki | Tree | Line | Menu"
   
   -- put fedwiki_ListPageSlugs (dreamDomain)
end menu_DisplayWiki




--> Global | Wiki | Tree | Menu | Props
-

--> Global | Wiki | Tree | Menu | Disabled
-
