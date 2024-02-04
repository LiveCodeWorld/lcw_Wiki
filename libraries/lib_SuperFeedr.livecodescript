script "lib_SuperFeedr"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: lib_SuperFeedr
type: library
version: 0.1

/*
This library interfaces with the superfeedr.com api
*/


--> Working on
-


--> SuperFeedr
-
function superfeedr_ListSubscriptions
   put "https://push.superfeedr.com" into restURL
   put "list" into restParamArray ["hub.mode"]
   --
   put superfeedr_FetchData (restURL, restParamArray) into responseArray
   -- 
   -- display_Data responseArray, "superfeedr_ListSubscriptions", "Superfeedr"
   repeat for each key itemNum in responseArray
      put responseArray [itemNum]["subscription"]["endpoint"] into webhookURL
      put responseArray [itemNum]["subscription"]["feed"]["title"] into subscriptionTitle
      put responseArray [itemNum]["subscription"]["feed"]["url"] into subscriptionURL
      --
      put subscriptionTitle & CR after subscriptionTitles
   end repeat
   delete char -1 of subscriptionTitles
   --
   return subscriptionTitles
end superfeedr_ListSubscriptions

command superfeedr_RemoveFeed feedURL
   /*
   -X POST
   -d'hub.topic=http://push-pub.appspot.com/feed'
   -d'hub.callback=http://mycallback.tld/ok'
   */
   
   put "https://push.superfeedr.com" into restURL
   --
   put "unsubscribe" into restParamArray ["hub.mode"]
   put feedURL into restParamArray ["hub.topic"]
   --
   put libURLFormData ("hub.mode", "unsubscribe", "hub.topic", feedURL, "hub.callback") into postData
   _SetAuthHeaders
   post postData to url restURL
   put it into someResponse
   put the result into someError
   --
   if someResponse is empty then
      return empty
   else
      put json_ToArray (someResponse) into responseArray
      display_data responseArray, feedURL, "SuperFeedr"
      return responseArray
   end if
end superfeedr_RemoveFeed

command superfeedr_AddFeed feedURL, pWebHookURL
   /*
   -d'hub.mode=subscribe'
   -d'hub.topic=http://push-pub.appspot.com/feed'
   -d'hub.callback=http://mycallback.tld/ok'
   */
   if pWebHookURL is empty then put "http://rest.livecode.world/echo" into pWebHookURL
   
   put "https://push.superfeedr.com" into restURL
   --
   -- put "subscribe" into postArray ["hub.mode"]
   -- put feedURL into postArray ["hub.topic"]
   -- put pWebHookURL into postArray ["hub.callback"]
   -- put "atom" into postArray ["format"]
   -- put the milliseconds into postArray ["hub.secret"]
   --
   put libURLFormData ("hub.mode", "subscribe", "hub.topic", feedURL, "hub.callback", pWebHookURL, "format", "json") into postData
   _SetAuthHeaders
   post postData to url restURL
   put it into someResponse
   put the result into someError
   --
   if someResponse is empty then
      return empty
   else
      put json_ToArray (someResponse) into responseArray
      display_data responseArray, feedURL, "SuperFeedr"
      return responseArray
   end if
end superfeedr_AddFeed


--> SuperFeedr | REST
-
function superfeedr_FetchData restURL, pRestParamArray
   put superfeedr_Fetch (restURL, pRestParamArray) into responseJSON
   put json_ToArray (responseJSON) into responseArray
   return responseArray
end superfeedr_FetchData

function superfeedr_Fetch restURL, pRestParamArray
   _SetAuthHeaders
   if pRestParamArray is an array then
      combine pRestParamArray by "&" and "="
      put "?" & pRestParamArray after restURL
   end if
   
   put url restURL into someResponse
   return someResponse
end superfeedr_Fetch

private command _SetAuthHeaders
   put superfeedr_GetBasicAuth() into authToken
   put superfeedr_GetUser() into someUser
   http_SetBasicAuthentication someUser, authToken
end _SetAuthHeaders

function superfeedr_GetUser
   return "opn"
end superfeedr_GetUser

function superfeedr_GetBasicAuth
   put secret_Get ("SuperFeedrBasicAuth") into basicAuthToken
   return basicAuthToken 
end superfeedr_GetBasicAuth

command superfeedr_SetBasicAuth basicAuthToken
   secret_Set "SuperFeedrBasicAuth", basicAuthToken
   put the result into modelDataFile
   return modelDataFile
end superfeedr_SetBasicAuth
