script "lib_Hypothesis"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: lib_Hypothesis
type: library
version: 0.1

/*Some help*/


--> Variables
-
local LocalGroupsData


--> Working on
-
function hyp_SearchAnnotations
   put "https://api.hypothes.is/api/search"
end hyp_SearchAnnotations

function hyp_GetMyID
   return "acct:opn@hypothes.is"
end hyp_GetMyID

command hyp_SetMyID userName
   
end hyp_SetMyID

command display_Hypothesis someData
   set the itemdelimiter to slash
   put item 5 of restURL into someTitle
   put "Test" into someTitle
   --
   display_Data someData, someTitle, "Hypothes.is"
end display_Hypothesis


--> Hypothesis | Search
-
function hyp_ListGroupAnnotationData gName
   put hyp_GetGroupID (gName) into gID
   put "https://api.hypothes.is/api/search?" into restURL
   put "group=" & gID after restURL
   --
   put hyp_FetchData (restURL) into someData
   return someData
end hyp_ListGroupAnnotationData

function hyp_ListMyAnnotationData
   put hyp_GetMyID() into myID
   put "https://api.hypothes.is/api/search?" into restURL
   put "user=" & myID after restURL
   --
   put hyp_FetchData (restURL) into someData
   return someData
end hyp_ListMyAnnotationData


--> Hypothesis | Groups
-
function hyp_GetGroupID gName
   put hyp_GetGroupArray (gName) into gArray
   put gArray ["id"] into gID
   return gID
end hyp_GetGroupID

function hyp_GetGroupArray gName
   put hyp_GetLocalGroupsData() into gData
   repeat for each key itemNum in gData
      if gName = gData [itemNum]["name"] then
         return gData [itemNum]
      end if
   end repeat
   return empty
end hyp_GetGroupArray

function hyp_ListGroupNames
   put hyp_GetLocalGroupsData() into gData
   repeat for each key itemNum in gData
      put gData [itemNum]["name"] into gName
      put gName & CR after gNames
   end repeat
   delete char -1 of gNames
   return gNames
end hyp_ListGroupNames

function hyp_GetLocalGroupsData
   if LocalGroupsData is not an array then hyp_ResetGroupsData
   return LocalGroupsData
end hyp_GetLocalGroupsData

command hyp_ResetGroupsData
   put hyp_FetchLocalGroupsData() into LocalGroupsData
end hyp_ResetGroupsData

function hyp_FetchLocalGroupsData
   put "https://api.hypothes.is/api/groups?" into restURL
   --
   put hyp_FetchData (restURL) into profileData
   return profileData
end hyp_FetchLocalGroupsData


--> Hypothesis | User
-
function hyp_FetchUserArray userID
   -- do not understand authrosation
   -- userID is of the form acct:opn@hypothes.is
   put "https://api.hypothes.is/api/users/" into restURL
   put userID after restURL
   --
   put hyp_FetchData (restURL) into userArray
   return userArray
end hyp_FetchUserArray

command hyp_CreateUser userName, userEmail, pDisplayName
   put "https://api.hypothes.is/api/users" into restURL
   --
   put "hypothes.is" into postArray ["authority"]
   put userName into postArray ["username"]
   put userEmail into postArray ["email"]
   if pDisplayName is not empty then
      put pDisplayName into postArray ["display_name"]
   end if
   --
   put hyp_PostData (restURL, postArray) into responseArray
   --
   display_Data responseArray, word 1 of the params, "Hypothes.is"
   --
   return responseArray
end hyp_CreateUser

function hyp_FetchProfileArray
   put "https://api.hypothes.is/api/profile" into restURL
   put hyp_FetchData (restURL) into profileArray
   return profileArray
end hyp_FetchProfileArray


--> Hypothesis
-
function hyp_GetServiceData
   put "https://api.hypothes.is/api/" into  restURL
   put hyp_FetchData (restURL) into profileData
   return profileData
end hyp_GetServiceData


--> Hypothesis | REST
-
function hyp_FetchData restURL
   put hyp_GetApikey() into authToken
   put jsonrpc_GetArray (restURL, authToken, empty, "Accept: application/vnd.hypothesis.v1+json") into responseArray
   return responseArray
end hyp_FetchData

function hyp_PostData restURL, postArray
   put hyp_GetApikey() into authToken
   put jsonrpc_PostArray (postArray, restURL, authToken, "Accept: application/vnd.hypothesis.v1+json") into responseArray
   return responseArray
end hyp_PostData

function hyp_GetApikey
   put secret_Get ("HypothesisApiKey") into oAuthToken
   return oAuthToken 
end hyp_GetApikey

command hyp_SetApikey apiKey
   secret_Set "HypothesisApiKey", apiKey
   put the result into modelDataFile
   return modelDataFile
end hyp_SetApikey
