script "model_PageJson"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_PageJson
type: model
version: 0.1

/*
This model is for wiki json files. PageJson and other json files.
It is not for fetching them by http or url's, but reading and writing to the local disk.
*/

--> Working on
-

--> JsonArray
-
function jsonArray_FromFile sFile, pUseMerge
   if there is not a file sFile then return "Error, json file does not exist." && sFile
   
   if pUseMerge is not false then
      return _GetMergJsonArray (sFile)
   else
      return _GetJsonArray (sFile) -- uses "textDecode"
   end if
end jsonArray_FromFile

command jsonArray_ToFile sFile, jsonArray, pCreateFolder, pUseMerge
   if pUseMerge is not false then
      _SetMergJsonArray sFile, jsonArray, pCreateFolder
   else
      _SetJsonArray sFile, jsonArray, pCreateFolder -- uses "textEncode"
   end if
   return the result
end jsonArray_ToFile


--> PageJson | Fetch
-
function pageJson_Fetch wikiDomain, pSlug, pPort, pDecode
   put pageJson_ConstructUrl (wikiDomain, pSlug, pPort) into someUrl
   put url someUrl into sJSON
   --
   if pDecode is true then
      put textDecode (sJSON, "UTF-8") into sJSON
   end if
   --
   return sJSON
end pageJson_Fetch

function pageJson_ConstructUrl wikiDomain, pSlug, pPort, pProtocol
   -- http://film.thought.garden:3000/welcome-visitors.json
   
   if pProtocol is empty then put "http" into pProtocol
   if pSlug is empty then put "welcome-visitors" into pSlug
   put tolower (pSlug) into pSlug -- just in case
   
   # Base URL
   put pProtocol & "://" & wikiDomain into wikiURL
   
   # Add Port
   if pPort is a number then
      put ":" & pPort after wikiURL
   end if
   
   # Add Slug
   put "/" & pSlug & ".json" after wikiURL
   
   # For Caching
   put "?random=" & the milliseconds after wikiURL
   return wikiURL
end pageJson_ConstructUrl


--> PageJson | Get
-
function pageJson_GetRecycled wikiDomain, pageSlug
   put wikiFile_ConstructRecycled (wikiDomain, pageSlug) into recycledPagePath
   put _GetJson (recycledPagePath) into pageJSON
   return pageJSON
end pageJson_GetRecycled

function pageJson_Get wikiDomain, pageSlug
   put wikiFile_Construct (wikiDomain, pageSlug) into wikiPagePath
   put _GetJson (wikiPagePath) into pageJSON
   return pageJSON
end pageJson_Get

command pageJson_Set wikiDomain, pageSlug, pageJSON, pDeleteSiteMap
   put wikiFile_Construct (wikiDomain, pageSlug) into wikiPagePath
   _SetJson wikiPagePath, pageJSON
   --
   if pDeleteSiteMap is not false then
      wikiSiteMap_DeleteFile wikiDomain
   end if
   return wikiPagePath
end pageJson_Set

command pageJson_Trash wikiDomain, pageSlug
   put wikiFile_Construct (wikiDomain, pageSlug) into wikiPagePath
   if there is not a file wikiPagePath then
      return "Error, no such file to trash:" && wikiPagePath
   end if
   
   # Create Recycled folder
   put wikiFolder_ConstructRecycled (wikiDomain) into wikiRecycleFolder
   folder_CreateNested wikiRecycleFolder -- if necessary
   
   -- put wikiFile_ConstructRecycled (wikiDomain, pageSlug) into recycledPagePath
   put wikiRecycleFolder & pageSlug into recycledPagePath
   
   # Move
   rename wikiPagePath to recycledPagePath
   return the result
end pageJson_Trash

command pageJson_Delete wikiDomain, pageSlug
   put wikiFile_Construct (wikiDomain, pageSlug) into wikiPagePath
   revDeleteFile wikiPagePath
   return the result
end pageJson_Delete


--> Private
-
private function _GetMergJsonArray sFile
   put url ("binfile:" & sFile) into binaryJSON
   if binaryJSON is empty then return empty
   
   try
      # Use binary and not textDecode with JSONToArray
      put JSONToArray (binaryJSON) into jsonArray
      -- put json_ToArray (binaryJSON) into jsonArray
      if jsonArray is an array then
         return jsonArray
      else
         return "Error, json file cannot be turned into an array." && sFile
      end if
   catch e
      return "Error, json file cannot be turned into an array." && sFile
   end try
end _GetMergJsonArray

private command _SetMergJsonArray sFile, jsonArray, pCreateFolder
   /* Use of ArrayToJSON and mergJsonEncode creates correct json.
   But accepts binary json and not result of textencode/decode.*/
   
   try
      # Use binary and not textEncode with JSONToArray
      put ArrayToJSON (jsonArray) into binaryJSON
      -- put json_FromArray (jsonArray) into binaryJSON
      --
      put binaryJSON into url ("binfile:" & sFile)
      put the result into writeResult
      return writeResult
   catch e
      return "Error, encoding jsonArray with _SetMergJsonArray."
   end try
end _SetMergJsonArray

private function _GetJsonArray sFile
   -- put _GetMergJsonArray (sFile) into jsonArray
   put _GetJson (sFile) into sJSON
   try
      # More tolerant and uses textDecode with _GetJson
      -- but numbers indexed arrays differently to mergeJSON
      put jsonImport (sJSON) into jsonArray
      if jsonArray is an array then
         return jsonArray
      else
         return "Error, json file cannot be turned into an array." && sFile
      end if
   catch e
      breakpoint
      return "Error, json file cannot be turned into an array." && sFile
   end try
end _GetJsonArray

private command _SetJsonArray sFile, jsonArray, pCreateFolder
   /* Use of jsonExport does not create correct json.
   Temporarily using ArrayToJSON and mergJson.*/
   
   try
      # More tolerant and uses textEncode with _SetJson
      put jsonExport (jsonArray) into sJSON
      _SetJson sFile, sJSON, pCreateFolder
      put the result into writeResult
      return writeResult
   catch e
      return "Error, problem decoding array to json for:" && sFile & CR & e
   end try
end _SetJsonArray

private function _GetJson sFile
   if there is not a file sFile then return empty
   put url ("binfile:" & sFile) into binaryJSON
   put textDecode (binaryJSON, "UTF-8") into sJSON
   return sJSON
end _GetJson

private command _SetJson sFile, sJSON, pCreateFolder
   if pCreateFolder is true then
      put sFile into sFolder
      set the itemdelimiter to slash
      put empty into item -1 of sFolder
      folder_CreateNested sFolder
   end if
   --
   put word 1 to -1 of sJSON into sJSON
   put textEncode (sJSON, "UTF-8") into binaryJSON
   put binaryJSON into url ("binfile:" & sFile)
   put the result into writeResult
   return writeResult
end _SetJson
