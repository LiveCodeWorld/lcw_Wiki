script "lib_Citation"
--> MetaData
-
license: GPLv3
name: lib_Citation
type: library
version: 0.2

/*
This library contains handlers to interface with citation services.

https://www.zotero.org/support/dev/start
*/

--> Varaibles
-
constant ZoteroBaseURL = "https://api.zotero.org"


--> DOI
-
function doi_FetchCitation droppedURL
   put zotero_FetchCitationArray (droppedURL) into arrayResult
   put arrayResult [1]["DOI"] into someDOI
   if someDOI is empty then return empty
   
   -- Shao, X., Sheng, X., Wu, M., Wu, H., & Ning, X. (2017). Methane production potential and emission at different water levels in the restored reed wetland of Hangzhou Bay. PLOS ONE, 12(10), e0185709. https://doi.org/10.1371/journal.pone.0185709
   put zotero_CrossCite (someDOI) into someCitation
   put word - 1 of someCitation into doiLink
   delete word -1 of someCitation
   put space & "- [" & doiLink && "doi]" into char -1 of someCitation
   return someCitation   
end doi_FetchCitation


--> Zotero
-
function zotero_ListItems
   -- https://api.zotero.org/users/475425/collections?v=3
   -- https://api.zotero.org/users/475425/collections/9KH9TNSJ/items/top?v=3
   -- https://api.zotero.org/users/475425/collections/9KH9TNSJ/items?format=bib
   -- put ZoteroBaseURL & <userOrGroupPrefix> & "/items" into restURL
   
   put "/users/475425/collections" into restPath
   put zotero_FetchJSON (restPath) into someJSON
   return someJSON
end zotero_ListItems


--> Zotero | Cite
-
function zotero_CrossCite someDOI
   -- web service from crosssite.org
   put "https://citation.crosscite.org/format?doi=" & someDOI & "&style=apa&lang=en-GB" into someURL
   put url someURL into citationText
   return citationText
end zotero_CrossCite

function zotero_FetchCitationArray droppedURL
   -- zotero web service from wikipedia
   put "https://en.wikipedia.org/api/rest_v1/data/citation/mediawiki/" into restURL
   put urlEncode (droppedURL) after restURL
   put jsonrpc_GetArray (restURL) into arrayResult
   return arrayResult
end zotero_FetchCitationArray


--> Zotero | REST
-
-- function zotero_PostJSON restPath, someJSON
put merge ("https://app.asana.com/api/[[ApiVersionNum]]/") & restPath into restURL
put asana_GetAuthenticationToken() into oAuthToken
put jsonrpc_POST (someJSON, restUrl, oAuthToken) into someJSON
return someJSON
end zotero_PostJSON

function zotero_FetchJSON restPath
   put ZoteroBaseURL & restPath into restURL
   put "?v=3" after restURL
   --
   put zotero_GetAuthenticationToken() into oAuthToken
   put jsonrpc_GET (restURL, oAuthToken) into someJSON
   return someJSON
end zotero_FetchJSON

function zotero_GetAuthenticationToken
   put secret_Get ("ZoteroAuthenticationToken", "zotero") into oAuthToken
   return oAuthToken
end zotero_GetAuthenticationToken

command zotero_SetAuthenticationToken oAuthToken
   secret_Set "ZoteroAuthenticationToken", oAuthToken, "zotero"
   put the result into modelDataFile
   return modelDataFile
end zotero_SetAuthenticationToken


--> Deps
-
function secret_Get secretName
   -- for server use only
   if the environment is not "server" then pass "secret_Get"
   --
   put rigFetchConfigItem (secretName) into someSecret
   return someSecret
end secret_Get
