script "lib_Openverse"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_Openverse
type: library
version: 0.1

/*Some help*/


--> Working on
-
function openverse_Search searchBit
   /*
   # Example 0: Search for images using single query parameter
   ?q=test"
   
   # Example 1: Search for images using multiple query parameters
   ?q=test&license=pdm,by&categories=illustration&page_size=1&page=1"
   
   # Example 2: Search for images that are an exact match of Claude Monet
   ?q=%22Claude%20Monet%22"
   
   # Example 3: Search for images related to both dog and cat
   ?q=dog+cat"
   
   # Example 4: Search for images related to dog or cat, but not necessarily both
   ?q=dog|cat"
   
   # Example 5: Search for images related to dog but won't include results related to 'pug'
   ?q=dog -pug"
   
   # Example 6: Search for images matching anything with the prefix ‘net’
   ?q=net*"
   
   # Example 7: Search for images matching dogs that are either corgis or labrador
   ?q=dogs + (corgis | labrador)"
   
   # Example 8: Search for images matching strings close to the term theaterwith a difference of one character
   ?q=theatre~1"
   */
   
   put "q=" & urlencode (searchBit) into pQueryBit
   put openverse_FetchArray ("/v1/images/", pQueryBit) into rArray
   return rArray
end openverse_Search


--> Openverse
-
function openverse_ImageDetail imageID
   put "/v1/images/" & imageID & slash into restBit
   put openverse_FetchArray (restBit) into rArray
   return rArray
end openverse_ImageDetail

function openverse_KeyInfo
   put openverse_FetchArray ("/v1/rate_limit/") into rArray
   return rArray
end openverse_KeyInfo

function openverse_RestUrl restBit, pQueryBit
   if char 1 of restBit is not slash then put slash before restBit
   text_AddTrailing restBit, slash
   put "https://api.openverse.engineering" & restBit into restURL
   --
   if pQueryBit is not empty then
      put "?" & pQueryBit after restURL
   end if
   --
   return restURL
end openverse_RestUrl

function openverse_FetchArray restBit, pQueryBit
   put openverse_RestUrl (restBit, pQueryBit) into restURL
   put openverse_GetAccessToken() into accessToken
   put jsonrpc_GetArray (restURL, accessToken) into rArray
   return rArray
end openverse_FetchArray

function openverse_GetAccessToken
   put secret_Get ("access_token", "openverse") into accessToken
   return accessToken
end openverse_GetAccessToken

function openverse_FetchAndStoreNewAccessToken
   put "https://api.openverse.engineering/v1/auth_tokens/token/" into restURL
   --
   put openverse_GetClientID() into clientID
   put openverse_GetClientSecret() into clientSecret
   --
   put _PostForm (clientID, clientSecret, "client_credentials") into accessArray
   --
   if accessArray ["error"] is not empty then
      breakpoint
      exit to top
   end if
   --
   openverse_AddSecretArray accessArray
   --
   return accessArray ["access_token"]
end openverse_FetchAndStoreNewAccessToken

private function _PostForm clientID, clientSecret, grantType
   put libURLFormData ("client_id", clientID, "client_secret", clientSecret, "grant_type", grantType) into formData
   --
   set the httpHeaders to "Content-Type: application/x-www-form-urlencoded"
   post formData to url "https://api.openverse.engineering/v1/auth_tokens/token/"
   put it into rJSON
   --
   put json_ToArray (rJSON) into accessArray
   return accessArray
end _PostForm

command openverse_Register userEmail, projectName, sDescription
   put "https://api.openverse.engineering/v1/auth_tokens/register/" into restURL
   --
   put projectName into postData ["name"]
   put sDescription into postData ["description"]
   put userEmail into postData ["email"]
   --
   put jsonrpc_PostArray (postData, restUrl) into registerArray
   --
   openverse_StoreSecrets registerArray
   put the result into registerMessage
   --
   return registerArray
end openverse_Register

function openverse_GetClientID
   put secret_Get ("client_id", "openverse") into clientID
   return clientID
end openverse_GetClientID

function openverse_GetClientSecret
   put secret_Get ("client_secret", "openverse") into clientSecret
   return clientSecret
end openverse_GetClientSecret

function openverse_GetProjectName
   put secret_Get ("name", "openverse") into projectName
   return projectName
end openverse_GetProjectName

command openverse_AddSecretArray accessArray
   secret_AddArray accessArray, "openverse"
   put the result into modelFile
   return modelFile
end openverse_AddSecretArray

command openverse_StoreSecrets registerArray
   put registerArray ["name"] into projectName
   put registerArray ["client_id"] into clientID
   put registerArray ["client_secret"] into clientSecret
   
   secret_Set "client_id", clientID, "openverse"
   secret_Set "client_secret", clientSecret, "openverse"
   secret_Set "name", projectName, "openverse"
   --
   put registerArray ["message"] into registerMessage
   return registerMessage
end openverse_StoreSecrets
