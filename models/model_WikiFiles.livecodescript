script "model_WikiFiles"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_WikiFiles
type: model
version: 0.1


--> Working on
-
function wiki_RootFolder pUseDefault
   if pUseDefault is true then
      put $HOME & "/.wiki/" into wikiRootFolder
      return wikiRootFolder
   else
      set the itemdelimiter to slash
      put env_GetRepoFolder() into wikiRootFolder
      put "Earth" into item -1 of wikiRootFolder
      --
      if there is a folder wikiRootFolder then
         return wikiRootFolder
      else
         return empty
      end if
   end if
end wiki_RootFolder

function gitwiki_RootFolder
   put env_GetRepoFolder() into repoFolder
   put repoFolder & "wiki/" into gitWikiFolder
   return gitWikiFolder
end gitwiki_RootFolder


--> Symlink | Create
-
command gitwiki_CreateSymLink gitWikiDomain, pSymLinkDomain
   if pSymLinkDomain is empty then
      put gitWikiDomain into pSymLinkDomain
   end if
   --
   put gitwiki_GetFolder (gitWikiDomain) into gitWikiFolder
   put wiki_ConstructFolder (pSymLinkDomain) into symWikiFolder
   --
   symlink_CreateFolder gitWikiFolder, symWikiFolder
   --
   if the result is empty then
      return pSymLinkDomain
   else
      breakpoint
      return "Error," && the result
   end if
end gitwiki_CreateSymLink

command wiki_CreateSymLink wikiDomain, pSymLinkDomain
   if pSymLinkDomain is empty then put wikiDomain into pSymLinkDomain
   --
   put wiki_GetFolder (wikiDomain) into wikiFolder
   put wiki_ConstructFolder (pSymLinkDomain) into symWikiFolder
   --
   symlink_CreateFolder wikiFolder, symWikiFolder
   return the result
end wiki_CreateSymLink


--> Wiki | config
-
function wiki_GetConfigFile
   -- see "lib_AtopiaDomainOwnership"
   put wiki_ConstructConfigFile() into wikiConfigFile
   if there is a file wikiConfigFile then
      return wikiConfigFile
   else
      return empty
   end if
end wiki_GetConfigFile

function wiki_ConstructConfigFile
   put wiki_RootFolder() into wikiRootFolder
   put wikiRootFolder & "config.json" into wikiConfigFile
   return wikiConfigFile
end wiki_ConstructConfigFile


--> Gitwiki | Folders
-
function gitwiki_GetFolder sDomain
   put gitwiki_RootFolder() into gitWikiFolder
   put gitWikiFolder & sDomain into folderPath 
   if there is a folder folderPath then
      return folderPath
   else
      return empty
   end if
end gitwiki_GetFolder


--> Gitwiki | List
-
function gitwiki_ListFolders pListshort
   put gitwiki_RootFolder() into rootFolder
   put "fedwiki_owners,dead.anarchive.earth" into notThese
   --
   if pListshort is true then
      put wiki_ListShortFolders (rootFolder, notThese) into gitWikiFolders
   else
      put wiki_ListFolders (rootFolder, notThese) into gitWikiFolders
   end if
   return gitWikiFolders
end gitwiki_ListFolders

function gitwiki_ListEmptyFolders pListShort
   put gitwiki_RootFolder() into rootFolder
   put wiki_ListEmptyFolders (rootFolder, pListShort, ".git,fedwiki_owners,dead.anarchive.earth") into emptyFolders
   return emptyFolders
end gitwiki_ListEmptyFolders


--> Paths
-
function node_WikiModulesFolder
   put node_GetModulesFolder() & "wiki/node_modules/" into wikiModulesFolder
   return wikiModulesFolder
end node_WikiModulesFolder

function node_GetModulesFolder pUseNpm
   # Node version
   if pUseNpm is true then
      put line 1 of shell ("npm root -g") & "/" into nodeModulesFolder
      return nodeModulesFolder
   end if
   
   # NVM version
   set the itemdelimiter to slash
   put nvm_GetBin() into nodeModulesFolder
   put "lib/node_modules/" into item -1 of nodeModulesFolder
   
   if there is not a folder nodeModulesFolder then return empty
   return nodeModulesFolder
end node_GetModulesFolder

function node_GetNodeBinaryPath
   return line 1 of shell ("npm bin -g") & "/npm"
end node_GetNodeBinaryPath


--> Wiki | ModulesFolder
-
function wiki_ModulesFolder
   -- it's inside the node modules /wiki/node-modules" folder
   put node_GetModulesFolder() into nodeModulesFolder
   if there is not a folder nodeModulesFolder then  return empty
   
   put nodeModulesFolder & "wiki/node_modules/" into fedwikiModulesFolder
   if there is not a folder fedwikiModulesFolder then  return empty
   
   return fedwikiModulesFolder
end wiki_ModulesFolder


--> Wiki | Folder
-
function wiki_ConstructFolder sDomain
   put wiki_RootFolder() into wikiRoot
   put wikiRoot & sDomain into folderPath 
   return folderPath
end wiki_ConstructFolder

function wiki_GetFolder sDomain
   put wiki_ConstructFolder (sDomain) into folderPath 
   if there is a folder folderPath then
      return folderPath
   else
      return empty
   end if
end wiki_GetFolder

function wiki_GetWikiClientFolder
   put wiki_ModulesFolder() & "wiki-client/" into wikiClientFolder
   return wikiClientFolder
end wiki_GetWikiClientFolder


--> Fedwiki | Local | Paths
-
function wiki_DefaultPagePath pageSlug
   put wiki_DefaultPagesFolder() & pageSlug into wikiPagePath
   return wikiPagePath
end wiki_DefaultPagePath


--> Fedwiki | Local | Folders
-
function wiki_DefaultPagesFolder
   put node_WikiModulesFolder() & "wiki-server/default-data/pages/" into wikiDefaultPagesFolder
   if there is a folder wikiDefaultPagesFolder then
      return wikiDefaultPagesFolder
   else
      return empty
   end if
   
   put fedwiki_GetNodeVersion() into nodeVersion
   return merge ("/root/.nvm/versions/node/[[nodeVersion]]/lib/node_modules/wiki/node_modules/wiki-server/default-data/pages/")
end wiki_DefaultPagesFolder


--> Nvm
-
function nvm_Directory
   return shell ("source ~/.zshrc; echo $NVM_DIR")
end nvm_Directory

function nvm_GetBin
   -- put "/Users/david/.nvm/versions/node/v21.0.0/bin/" before wikiBinFile
   get shell ("source ~/.zshrc; echo $NVM_BIN")
   return word 1 to -1 of line 1 of it
end nvm_GetBin

