script "lib_NodeJS"
--> MetaData
-
license: GPLv3
name: lib_NodeJS
type: library
version: 0.1

--> Working on
-

--> Node
-
function node_GetVersion
   -- should check if we are using nvm
   return nvm_GetNodeVersion()
end node_GetVersion

command node_OpenModulesFolder
   put node_GetModulesFolder() into someFolder
   if someFolder is empty then return empty
   
   finder_Reveal someFolder
   return someFolder
end node_OpenModulesFolder
