script "model_WikiLocal"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_WikiLocal
type: model
version: 0.2

--> Variable
-
local LocalArray


--> Working on
-

--> Wiki | Construct
-
function wiki_ConstructLocalHostDomain wikidomain
   set the itemdelimiter to "."
   if the number of items of wikidomain = 2 then
      put "wiki." & item 1 of wikidomain & ".localhost" into wikidomain
   else
      put "localhost" into item -1 of wikidomain
   end if
   return wikidomain
end wiki_ConstructLocalHostDomain

function wiki_AstralFromLocalhost localhostDomain
   if localhostDomain = "localhost" then return "localhost"
   if localhostDomain = "astralship.localhost" then return "astralship.wiki"
   --
   set the itemdelimiter to "."
   if item -1 of localhostDomain = "localhost" then
      put "astralship.wiki" into item -1 of localhostDomain
   end if
   return localhostDomain
end wiki_AstralFromLocalhost


--> Wiki | Port
-
command wiki_AddPortToDomain @wikiDomain, pPort
   if pPort is empty then put wiki_GetPort() into pPort
   if pPort is not empty then
      put ":" & pPort after wikiDomain
   end if
end wiki_AddPortToDomain

command wiki_NormailzePort @sPort
   if sPort is empty then
      put wiki_GetPort() into sPort
   end if
end wiki_NormailzePort

function wiki_GetPort
   put LocalArray ["sPort"] into sPort
   if sPort is empty then put 80 into sPort
   --
   return sPort
end wiki_GetPort

command wiki_SetPort sPort
   put sPort into LocalArray ["sPort"]
end wiki_SetPort


--> Wiki | Url
-
function wiki_ConstructUrl wikiDomain, pPort, pProtocol
   if wikiDomain is empty then return empty
   if pPort is empty then put wiki_GetPort() into pPort
   return url_Construct (wikiDomain, pPort, pProtocol)
end wiki_ConstructUrl

function wiki_LocalhostUrl pWikiDomain
   if pWikiDomain is empty then put "localhost" into pWikiDomain
   put wiki_ConstructLocalHostDomain (pWikiDomain) into localhostDomain
   put wiki_ConstructUrl (localhostDomain) into localhostURL
   return localhostURL
end wiki_LocalhostUrl

function wiki_DefaultLocalUrl
   put "http://localhost:3000" into wikiURL
   return wikiURL
end wiki_DefaultLocalUrl


--> Wiki | Pages
-
function wiki_FolderHasNoPages wikiFolder, pNum
   if pNum is not a number then put 1 into pNum
   put wiki_NumberOfpages (wikiFolder) into numOfPages
   if numOfPages is empty then return empty -- not a wiki
   return numOfPages < pNum
end wiki_FolderHasNoPages

function wiki_NumberOfpages wikiFolder, pUseSymLinked
   if pUseSymLinked is true then
      put symlink_Destination (wikiFolder) into destFolder
      if destFolder is empty then
         put _NumberOfpages (wikiFolder) into numOfPages
      else
         put _NumberOfpages (destFolder) into numOfPages
      end if
   else
      put _NumberOfpages (wikiFolder) into numOfPages
   end if
   return numOfPages
end wiki_NumberOfpages


--> Fedwiki | Local | Folders
-
command fedwiki_SetLocalWikiRoot localWikiRoot
   folder_Format localWikiRoot
   put fedwiki_GetLocalData() into localWikiData
   put localWikiRoot into localWikiData ["localWikiRoot"]
   fedwiki_SetLocalData localWikiData
end fedwiki_SetLocalWikiRoot

function fedwiki_GetLocalWikiRoot
   put fedwiki_GetLocalData() into localWikiData
   put localWikiData ["localWikiRoot"] into localWikiRoot
   --
   if localWikiRoot is empty then
      put "~/.wiki/" into localWikiRoot -- this is the default root for a wiki-node server on OSX and Linux
   end if
   return localWikiRoot
end fedwiki_GetLocalWikiRoot


--> Fedwiki | Local | Model
-
function fedwiki_GetLocalData
   put the model_Data of me into localWikiData
   return localWikiData
end fedwiki_GetLocalData

command fedwiki_SetLocalData localWikiData
   set the model_Data of me to localWikiData
   put the result into modelFile
   return modelFile
end fedwiki_SetLocalData


--> Private
-
private function _NumberOfpages wikiFolder
   if there is not a folder wikiFolder then return empty
   
   # Check pages
   text_AddTrailing wikiFolder, slash
   put wikiFolder & "pages/" into pageFolder
   if there is not a folder pageFolder then
      return empty -- not a wiki
   end if
   
   # List wiki-pages and count
   put files (pageFolder) into pageFiles
   if pageFiles is empty then return 0
   put the number of lines of pageFiles - 1 into numOfPages
   return numOfPages
end _NumberOfpages
