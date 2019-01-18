script "lib_NodeJS"
--> MetaData
-
license: GPLv3
name: lib_NodeJS
type: library
version: 0.1


--> Node
-
command node_OpenModulesFolder
   put node_GetModulesFolder() into someFolder
   if someFolder is empty then return empty
   
   finder_Reveal someFolder
   return someFolder
end node_OpenModulesFolder

function node_GetModulesFolder
   put line 1 of shell ("npm root -g") & "/" into nodeModulesFolder
   if there is not a folder nodeModulesFolder then return empty
   return nodeModulesFolder
end node_GetModulesFolder

function node_GetNodeBinaryPath
   return line 1 of shell ("npm bin -g") & "/npm"
end node_GetNodeBinaryPath
