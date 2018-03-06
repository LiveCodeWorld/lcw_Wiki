script "lib_Citation"
--> MetaData
-
license: GPLv3
name: lib_Citation
type: library
version: 0.1

/*
This library contains handlers to interface with citation services.
*/


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
