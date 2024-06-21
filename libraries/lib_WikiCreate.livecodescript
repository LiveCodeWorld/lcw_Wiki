script "lib_WikiCreate"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_WikiCreate
type: library
version: 0.1

/*
This library is for creating {{wiki-site}}s, which are app-with integrated wikis.
*/


--> Working on
-
command ask_CreateWikiSite wikiView, pComment
   if pComment is empty then
      put "Create a new wiki..." into pComment
   end if
   
   put the wiki_Domain of wikiView into wikiDomain
   put lcw_Ask (pComment, wikiDomain, wikiView) into wikiDomain
   --
   wikiSite_Create wikiDomain
   if item 1 of the result is "Error" then
      put the result into sMarkdown
      put pageArray_Construct ("Error", sMarkdown) into pageArray
   else
      put the result into wikiFolder
      --
      put merge ("Created new local wiki '[[wikiDomain]]'. Use these tools to create some initial content.") into sMarkdown
      put pageArray_Construct ("Site Construction", sMarkdown) into pageArray
      pageArray_AddReferenceIndex pageArray, wikiDomain
   end if
   --
   set the ghost_PageArray of wikiView to pageArray
end ask_CreateWikiSite


--> WikiSite
-


--> WikiSite | Create
-
command wikiSite_Create wikiDomain
   # Create folders in wikiFolder of default farm
   put wikiFolder_ConstructFromFarm (wikiDomain) into wikiFolder
   if there is a folder wikiFolder then
      return "Error, a folder for this domain already exists:" && wikiFolder
   end if
   --
   repeat for each item shortFolder in "pages,recycle,status"
      put wikiFolder & shortFolder & slash into sFolder
      folder_CreateNested sFolder
   end repeat
   
   # Create Image and Assets folders
   put wikiFolder & "assets/plugins/image" & slash into sFolder
   folder_CreateNested sFolder
   
   # Add domain to /etc/hosts
   put system_GetAdminPassword() into systemPassword
   hosts_Add wikiDomain, systemPassword
   
   # Create files
   put wikiPage_WelcomeVisitors (wikiDomain) into pageArray
   pageArray_Set wikiDomain, "welcome-visitors", pageArray
   
   # Set Favicon
   put wikiServer_GetFavicon() into pngData
   wikiServer_SetFavicon wikiDomain, pngData
   
   # Add owner.json
   wikiServer_SetFriendlyData wikiDomain
   --
   return wikiFolder
end wikiSite_Create


--> Deps
-
