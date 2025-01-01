script "model_WikiClient"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_WikiClient
type: model
version: 0.2

/*
This model is for all the files and folders in the wiki-client npm moule of federated wiki.
It is used by the Livecode wiki server to serve the core files required by the wiki-client.
*/

--> Variables
-
local Wiki_FactoriesJson


--> Working on
-

--> WikiClient | Factories
-
function wikiClient_GetFactoriesJson pForceUpdate
   if Wiki_FactoriesJson is empty or pForceUpdate is true then
      put wikiClient_ConstructFactoriesJson() into Wiki_FactoriesJson
   end if
   return Wiki_FactoriesJson
end wikiClient_GetFactoriesJson

function wikiClient_ConstructFactoriesJson
   put wikiPlugin_List() into shortPluginFolders
   put node_WikiModulesFolder() into wikiModulesFolder
   put 1 into indexNum
   repeat for each line shortPluginFolder in shortPluginFolders
      put wikiModulesFolder & shortPluginFolder & "/factory.json" into factoryFile
      if there is a file factoryFile then
         put text_Get (factoryFile) into sJSON
         put json_ToArray (sJSON) into sArray
         put sArray into factoryData [indexNum]
         add 1 to indexNum
      end if
   end repeat
   put json_FromArray (factoryData) into factoriesJSON
   return factoriesJSON
end wikiClient_ConstructFactoriesJson


--> WikiClient | Html
-
function wikiClient_GetStaticHtml
   put wikiFolder_Client ("views/") into clientViewFolder
   put clientViewFolder & "static.html" into clientViewPath
   put text_Get (clientViewPath) into someHTML
   return someHTML
end wikiClient_GetStaticHtml
