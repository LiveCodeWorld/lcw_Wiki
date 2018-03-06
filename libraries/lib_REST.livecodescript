script "lib_REST"
--> MetaData
-
license: GPLv3
name: lib_REST
type: library
version: 0.1


--> JSON RPC
-
function jsonrpc_GET restURL, pOAuthToken, pVersionNum
   rest_SetJsonHeaders pOAuthToken, pVersionNum
   put url restURL into someJson
   return someJson
end jsonrpc_GET

function jsonrpc_GetArray restURL, pOAuthToken, pVersionNum
   put jsonrpc_GET (restURL, pOAuthToken, pVersionNum) into someJson
   put json_ToArray (someJson) into someArray
   return someArray
end jsonrpc_GetArray

function jsonrpc_POST someJSON, restUrl, pOAuthToken, pVersionNum
   rest_SetJsonHeaders pOAuthToken, pVersionNum
   post someJSON to url restUrl
   put it into jsonResult
   return jsonResult
end jsonrpc_POST


--> JSON RPC | Old
-
function rest_POST someJSON, restUrl, pOAuthToken, pVersionNum
   -- assuming we are using json rpc
   breakpoint
   jsonrpc_POST someJSON, restUrl, pOAuthToken, pVersionNum
   return the result
end rest_POST

function rest_GET someUrl, pOAuthToken, pVersionNum
   -- assuming we are using json rpc
   breakpoint
   return jsonrpc_GET (someUrl, pOAuthToken, pVersionNum)
end rest_GET


--> Audioboom | Post
-
function rest_PostArray someArray, restUrl, pOAuthToken, pVersionNum
   put rest_ConstructFormArray (someArray) into formArray
   put libURLMultipartFormData (formData, formArray) into tError
   if tError is not empty then return tError
   
   post formData to url restUrl
   put it into jsonResult
   return jsonResult
end rest_PostArray

function rest_ConstructFormArray someArray
   /*
   You can also pass in an array instead of pairs of parameters. 
   This could be useful if there are many parts to a form. 
   The array must be numerically indexed, and each element should contain the part name and part value, separated by a comma. 
   */
   put 1 into indexNum
   repeat for each key someKey in someArray
      put someArray [someKey] into someValue
      put someKey,someValue into formArray [indexNum]
      add 1 to indexNum
   end repeat
   return formArray
end rest_ConstructFormArray

function rest_PostJson jsonOrArray, restUrl, pOAuthToken, pVersionNum
   if jsonOrArray is an array then
      put json_FromArray (jsonOrArray) into someJSON
   else
      -- could error check here
      put jsonOrArray into someJSON
   end if
   put rest_POST (someJSON, restUrl, pOAuthToken, pVersionNum) into jsonResult
   return jsonResult
end rest_PostJson

command rest_SetJsonHeaders pOAuthToken, pVersionNum
   put "Content-type: application/json" into someHeader
   put CR & "Accept: application/json" after someHeader
   put CR & "Accept-Charset: utf-8" after someHeader
   --
   if pVersionNum is not empty then
      put "; version=" & pVersionNum after someHeader
   end if
   if pOAuthToken is not empty then
      put CR & "Authorization: Bearer" && pOAuthToken after someHeader
   end if
   set the httpHeaders to someHeader
   return someHeader
end rest_SetJsonHeaders

