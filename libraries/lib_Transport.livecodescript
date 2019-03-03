script "lib_Transport"
--> MetaData
-
license: GPLv3
name: lib_Transport
type: library
version: 0.1

/*
This library is for creating and manipulating Transporter wiki pages.
*/


--> Transport
-
command transport_UpdatePageGraph @pageArray, hKey
   put hkey_DotFile (hKey) into dotFile
   put url ("file:" & dotFile) into dotText
   --
   put fedwiki_FindItemType ("graphviz", pageArray) into itemNum
   if itemNum > 0 then
      put dotText into pageArray ["story"][itemNum]["text"]
   end if
end transport_UpdatePageGraph


--> Tranport | Help
-
command transport_CreateHelp hKey, pScriptHelp
   _SetTransportInfo hKey, wikiDomain, pageTitle, pageSlug, hObject
   put help_CurlyObjectData (hObject) into curlyData
   --
   help_Create pageTitle, "transport", pageSlug, wikiDomain, curlyData, pScriptHelp
   put the result into shellResult
   return shellResult
end transport_CreateHelp

function transport_HelpURL hKey, pCheckURL
   _SetTransportInfo hKey, wikiDomain, pageTitle, pageSlug, hObject
   --
   if pCheckURL is true then
      put fedwiki_IsWikiPage (wikiDomain, pageSlug) into isWiki
      if isWiki is false then
         return empty
      end if
   end if
   --
   put fedwiki_PageUrl (wikiDomain, pageSlug) into someURL
   return someURL
end transport_HelpURL

function transport_IndexHkey hObject
   put hKeyLine_FromTripple ("index", "c", hObject) into hKey
   return hKey
end transport_IndexHkey

function transport_IndexDotText hObject
   put transport_IndexHkey (hObject) into hKey
   put hkey_GetDotText (hKey) into dotText
   return dotText   
end transport_IndexDotText

function transport_ConstructHelpPageTitle stackName
   set the itemdelimiter to "."
   put text_InitialCaps (item 1 of stackName) && "Transport" after pageTitle
   return pageTitle
end transport_ConstructHelpPageTitle


--> Transport | Model
-
function transport_FetchPageArray hKey
   _SetTransportInfo hKey, wikiDomain, pageTitle, pageSlug, hObject
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   return pageArray
end transport_FetchPageArray

command transport_StorePageArray hKey, pageArray
   _SetTransportInfo hKey, wikiDomain, pageTitle, pageSlug, hObject
   atopia_StoreWikiPageArray wikiDomain, pageSlug, pageArray
   put the result into shellResult
   return shellResult
end transport_StorePageArray


--> Private
-
command _SetTransportInfo hKey, @wikiDomain, @pageTitle, @pageSlug, @hObject
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   put the stack_Name of hObject into stackName
   --
   if hName = "index" then
      put "transport.fedwiki.org" into wikiDomain
      put transport_ConstructHelpPageTitle (stackName) into pageTitle
   else
      set the itemdelimiter to "."
      put hName into pageTitle
      put item 1 of stackName into subdomain
      put tolower (subdomain) & ".transport.fedwiki.org" into wikiDomain
   end if
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
end _SetTransportInfo


