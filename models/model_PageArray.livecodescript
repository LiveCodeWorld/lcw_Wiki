script "model_PageArray"
--> MetaData
-
license: GPLv3
name: model_PageArray
type: model
version: 0.5

/*
Should use "textDecode" every time we fetch text?

This is a model for fetching, storing Fedwiki page-array structures derived from the page-json schema.
It also provides hanlders to to CRUD operations of page-json files.

See also "model_WikiPage", "model_AtopiaFiles", "lib_PageArray" and "lib_FedwikiCreate"

We also provide wrappers for specific types of page-array, such as LCW hander-array's.
We can use these handlers to fetch json and arrays from anywhere in the federation,
but naturally we can only write to wiki-domains that we have permission to write to.
For now this means domains on the Atopia server.

"location": {"latitude": "52.20755","longitude": "0.11588"
*/


--> Working on
- 
function graph_Extract sText
   put "(digraph \{(?:.|\n|\r)*?\})" into sRegExp
   if matchText (sText, sRegExp, dotText) is true then
      return dotText
   else
      return empty
   end if
end graph_Extract

function accreditation_ChatGpt
   put snippet_Get ("chatgpt-accreditation") into mdCred
   return mdCred
end accreditation_ChatGpt

function accreditation_WikiPedia mwTitle, mwSlug
   put snippet_Get ("wikipedia-accreditation") into mdCred
   -- put scaffold_Get ("Wikipedia Accreditation") into mdCred
   curly_ReplaceText mdCred, "mwSlug", mwSlug
   curly_ReplaceText mdCred, "mwTitle", mwTitle
   return mdCred
end accreditation_WikiPedia


--> PageArray | File | Model
-
function pageArray_Fetch wikiDomain, pSlug, pPort
   put pageJson_Fetch (wikiDomain, pSlug, pPort) into pageJson
   --
   if pageJson is empty then return empty
   put json_ToArray (pageJson) into pageArray
   return pageArray
end pageArray_Fetch

function pageArray_Get wikiDomain, pageSlug
   put wikiFile_Construct (wikiDomain, pageSlug) into wikiFile
   if there is a file wikiFile then
      put jsonArray_FromFile (wikiFile) into pageArray
      return pageArray
   else
      return empty
   end if
end pageArray_Get

command pageArray_Set wikiDomain, pageSlug, pageArray, pDeleteSiteMap
   put wikiFile_Construct (wikiDomain, pageSlug) into wikiFile
   jsonArray_ToFile wikiFile, pageArray
   --
   if pDeleteSiteMap is not false then
      wikiSiteMap_DeleteFile wikiDomain
   end if
   return wikiFile
end pageArray_Set

command pageArray_Delete wikiDomain, pageSlug
   pageJson_Delete wikiDomain, pageSlug
   put the result into shellResult
   if shellResult is not empty then return shellResult
   --
   wikiSiteMap_DeleteFile wikiDomain
   return empty
end pageArray_Delete


--> PageArray | Cred
-
command pageArray_AddChatGptCred @pageArray
   put accreditation_ChatGpt() into mdCred
   put mdCred into pageArray ["journal"][1]["provenance"]
   delete variable pageArray ["plugin"]
end pageArray_AddChatGptCred

command pageArray_AddWikipediaCred @pageArray, mwTitle, mwSlug
   put accreditation_WikiPedia (mwTitle, mwSlug) into mdCred
   put mdCred into pageArray ["journal"][1]["provenance"]
   delete variable pageArray ["plugin"]
end pageArray_AddWikipediaCred


--> PageArray | Add
-
command pageArray_AddRssButton @pageArray, podcastRSS, pTitle, pWikiDomain, pRssLastUpdated, pDisplayStyle
   if pTitle is empty then
      put "Import RSS" into buttonName
   else
      put pTitle into buttonName
   end if
   --
   put podcastRSS into hiddenKeyValueArray ["rssURL"]
   if pTitle is not empty then put pTitle into hiddenKeyValueArray ["pageTitle"]
   if pWikiDomain is not empty then put pWikiDomain into hiddenKeyValueArray ["wikiDomain"]
   if pRssLastUpdated is not empty then put pRssLastUpdated into hiddenKeyValueArray ["rssLastUpdated"]
   if pDisplayStyle is not empty then put pDisplayStyle into hiddenKeyValueArray ["displayStyle"]
   --
   put LcwRestUrl & "/podcast/rss" into postURL
   pageArray_AddButton pageArray, buttonName, postURL, hiddenKeyValueArray
end pageArray_AddRssButton

command pageArray_AddAssets @pageArray, sText, pID
   put itemArray_ConstructAssets (sText, pID) into itemArray
   itemArray_Add itemArray, pageArray
   return the result
end pageArray_AddAssets

command pageArray_AddGraphviz @pageArray, sText, pDot, pSVG, pID
   put itemArray_ConstructGraphviz (sText, pDot, pSVG, pID) into itemArray
   itemArray_Add itemArray, pageArray
   return the result
end pageArray_AddGraphviz

command pageArray_StripJournal @pageArray, pSourceArray, pMilliseconds
   put pageArray ["title"] into pageTitle
   put pageArray ["story"] into storyArray
   --
   put journalArray_Construct (pageTitle, pSourceArray, pMilliseconds, storyArray) into journalArray
   put journalArray into pageArray ["journal"]
end pageArray_StripJournal


--> PageArray | Image
- 
command pageArray_AddImage @pageArray, imageURL, pCaptionText, pLinkURL, pLat, pLong, pSize, pWidth, pHeight, pID
   -- put pageArray_ConstructImageCaption (pImageCaption, pImageSourceUrl, imageURL) into sCaption
   if pageArray is not an array then return false
   if imageURL is  empty then return false
   if pCaptionText is empty then put "This is an image" into pCaptionText
   --
   put itemArray_ConstructImage (imageURL, pLinkURL, pWidth, pHeight, pSize, pCaptionText, pLat, pLong) into itemArray
   itemArray_Add itemArray, pageArray
   return itemArray
end pageArray_AddImage

command pageArray_AddThumbnail @pageArray, imageURL, pImageCaption, pLinkURL
   if pageArray is not an array then return false
   if imageURL is empty then return false
   _SetImageDescription pImageCaption, pLinkURL, imageURL
   --
   put fedwiki_ConstructThumbHtml (imageURL, pImageCaption, pLinkURL) into imageHTML
   pageArray_AddHtml pageArray, imageHTML
   return true
end pageArray_AddThumbnail

command pageArray_AddEmbeddedImage @pageArray, someImage, pImageCaption, pImageType
   if pImageType is empty then put image_DetectType (someImage) into pImageType
   --
   put fedwiki_ConstructEncodedImageArray (someImage, pImageType, pImageCaption) into imageArray
   itemArray_Add imageArray, pageArray
end pageArray_AddEmbeddedImage


--> PageArray | Add | Form
-
command pageArray_AddForm @pageArray, submitName, postURL, pInputValue, pInputName, pBgColor, pLabel, pInputSize, pHiddenArray, pAlign, pID
   if pInputName is empty then put "title" into pInputName
   if pInputSize is empty then put 32 into pInputSize
   --
   put pInputName into inputArray ["inputVarName"]
   put pInputValue into inputArray ["inputDefault"]
   put pInputSize into inputArray ["inputSize"]
   --
   put fedwiki_ConstructForm (submitName, postURL, pHiddenArray, inputArray, pLabel, pAlign, pBgColor) into formHTML
   pageArray_AddHTML pageArray, formHTML, pID
   return formHTML
end pageArray_AddForm

command pageArray_AddButton @pageArray, buttonName, postURL, pHiddenKeyValueArray, pLabel, pAlign, pBgColor, pID
   put fedwiki_ConstructButtonForm (buttonName, postURL, pHiddenKeyValueArray, pLabel, pAlign, pBgColor) into formHTML
   pageArray_AddHTML pageArray, formHTML, pID
   return formHTML
end pageArray_AddButton


--> PageArray
-
command pageArray_AddReferenceIndex @pageArray, wikiDomains, pCaps
   put -3 into pItemNum
   set the itemDelimiter to "."
   repeat for each line wikiDomain in wikiDomains
      put item 1 to pItemNum of wikiDomain into someText
      if someText is empty then put wikiDomain into someText
      --
      if pCaps is true then
         replace "." with space in someText
         put text_InitialCaps (someText) into someText
      end if
      pageArray_AddReference pageArray, "Welcome Visitors", wikiDomain, someText, "welcome-visitors"
   end repeat
   delete char -1 of sMarkdown
   return sMarkdown
end pageArray_AddReferenceIndex

command pageArray_AddReference @pageArray, pageTitle, wikiDomain, refText, pPageSlug, pID
   if pPageSlug is empty then put fedwiki_ConstructSlug (pageTitle) into pPageSlug
   put itemArray_ConstructReference (pPageSlug, wikiDomain, refText, pageTitle, pID) into itemArray
   itemArray_Add itemArray, pageArray
   return the result
end pageArray_AddReference


--> PageArray | Construct
-
function pageArray_ConstructImageCaption pImageCaption, pImageSourceUrl, pImageURL
   if pImageCaption is empty then put "This is a [[full width image]]" into pImageCaption
   _SetImageDescription pImageCaption, pImageSourceUrl, pImageURL
   return pImageCaption
end pageArray_ConstructImageCaption

function pageArray_ConstructHtmlImage imageURL, pPageTitle, pPageDescription, pLinkURL, pImageCaption
   put _ConstructImagePageArray (pPageTitle, pPageDescription) into pageArray
   --
   if pImageCaption is empty then put "This is a [[full width image]]" into pImageCaption
   pageArray_AddImage pageArray, imageURL, pImageCaption
   --
   return pageArray
end pageArray_ConstructHtmlImage

command pageArray_AddActivity @pageArray, rosterTitle, pSinceWhen, pConversationItem, pID
   put itemArray_ConstructActivity (rosterTitle, pSinceWhen, pConversationItem, pID) into itemArray
   itemArray_Add itemArray, pageArray
   return the result
end pageArray_AddActivity

command pageArray_AddJsonArray @pageArray, jsonArray, pDescription, pID
   put pageArray_FindItemType ("json", pageArray) into itemNum
   if itemNum = 0 then
      get the extents of pageArray ["story"]
      put item 2 of it + 1 into itemNum
      --
      put "json" into pageArray ["story"][itemNum]["type"]
      put uuid () into pageArray ["story"][itemNum]["id"]
      --
      if pDescription is empty then
         put line 1 of the keys of jsonArray into pDescription
      end if
      put pDescription into pageArray ["story"][itemNum]["text"]
   else
      if pDescription is empty then
         put pageArray ["story"][itemNum]["text"] into pDescription
         if pDescription is empty then
            put line 1 of the keys of jsonArray into pDescription
            put pDescription into pageArray ["story"][itemNum]["text"]
         end if
      else
         put pDescription into pageArray ["story"][itemNum]["text"]
      end if
   end if
   --
   put jsonArray into pageArray ["story"][itemNum]["resource"]
   --
   put "Livecode" into pageArray ["story"][itemNum]["writer"] -- "writer": "goaljam"
   --
   put pageArray ["Title"] into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pSlug
   put pSlug into pageArray ["story"][itemNum]["slug"] -- "slug": "junk",
   --
   -- "interval": 115324
   put the milliseconds  into milliNow
   put pageArray ["story"][itemNum]["written"] into lastWritten
   if lastWritten is a number then
      put milliNow - lastWritten into pageArray ["story"][itemNum]["interval"]
   else
      put 0 into pageArray ["story"][itemNum]["interval"]    
   end if
   put milliNow into pageArray ["story"][itemNum]["written"] -- "written": 1620833478309,
   --
   put pageArray ["story"][itemNum]["writes"] into lastWriteNum
   if lastWriteNum is a number then
      put lastWriteNum + 1 into pageArray ["story"][itemNum]["writes"]
   else
      put 1 into pageArray ["story"][itemNum]["writes"]
   end if
   --
   return the result
end pageArray_AddJsonArray


--> PageArray | Construct
-
function pageArray_Construct pageTitle, someMarkdown, pPlugin
   -- was "fedwiki_ConstructSimplePageArray"
   put pageTitle into pageArray ["title"]
   pageArray_AddMarkdown pageArray, someMarkdown
   put journalArray_Construct (pageTitle) into pageArray ["journal"]
   --
   if pPlugin is not empty then
      put pPlugin into pageArray ["plugin"]
   end if
   return pageArray
end pageArray_Construct


--> PageArray | LastUpdated
-
function pageArray_FetchLastUpdated wikiDomain, pSlug
   put pageArray_Fetch (wikiDomain, pSlug) into pageArray
   --
   get pageArray_GetFirstItem (pageArray, "code")
   set the itemdelimiter to ":"
   delete item 1 of it
   put word 1 to -1 of it into lastUpDate
   --
   convert lastUpDate from internet date to seconds
   return lastUpDate
end pageArray_FetchLastUpdated

command pageArray_StoreLastUpdated wikiDomain, pSlug, pDateInSeconds
   if pDateInSeconds is empty then put the seconds into pDateInSeconds
   --
   convert pDateInSeconds from seconds to internet date
   put "Last updated:" && pDateInSeconds into lastUpDate
   --
   put pageArray_Fetch (wikiDomain, pSlug) into pageArray
   pageArray_SetFirstItem pageArray, "code", lastUpDate
   --
   pageArray_Set wikiDomain, pSlug, pageArray, true
   return the result
end pageArray_StoreLastUpdated


--> PageArray | Roster
-
command pageArray_AddToRoster @pageArray, newDomain
   put pageArray_FindItemType ("roster", pageArray) into itemNum
   if itemNum = 0 then return 0
   --
   put pageArray ["story"][itemNum]["text"] into rosterText
   roster_AddDomain rosterText, newDomain
   put rosterText into pageArray ["story"][itemNum]["text"]
   return itemNum
end pageArray_AddToRoster

command pageArray_SetRoster @pageArray, rosterDomains, rosterTitle
   put pageArray_FindItemType ("roster", pageArray) into firstRosterItemNum
   if firstRosterItemNum > 0 then
      put word 1 to -1 of (rosterTitle & CR & CR & rosterDomains) into rosterText
      put rosterText into pageArray ["story"][firstRosterItemNum]["text"]
   end if
end pageArray_SetRoster

command pageArray_AddRoster @pageArray, rosterText, pID
   if rosterText is empty then return false
   put itemArray_Construct ("roster", pID, rosterText) into itemArray
   itemArray_Add itemArray, pageArray
   return true
end pageArray_AddRoster


--> PageArray | Set
-
command pageArray_SetTitle @pageArray, someTitle, pID
   if someTitle is  empty then return false
   put "#" && someTitle into someMarkdown
   pageArray_AddMarkdown pageArray, someMarkdown, pID
   put the result into itemNum
   --
   put pageArray ["story"][itemNum] into newItemArray
   pageArray_AddEditAction pageArray, itemNum
   return true
end pageArray_SetTitle

command pageArray_EditItem @pageArray, sText, itemNum, pMilliseconds
   put sText into pageArray ["story"][itemNum]["text"]
   pageArray_AddedEditAction pageArray, itemNum, pMilliseconds
   put the result into actionArray
   return actionArray
end pageArray_EditItem

command pageArray_AddedEditAction @pageArray, itemNum, pMilliseconds
   if pMilliseconds is empty then put the milliseconds into pMilliseconds
   put pageArray ["story"][itemNum] into newItemArray
   put newItemArray ["id"] into itemID
   pageArray_AddEditAction pageArray, newItemArray, itemID, pMilliseconds
   put the result into actionArray
   return actionArray
end pageArray_AddedEditAction


--> PageArray | Actions
-
command pageArray_AddEditAction @pageArray, newItemArray, itemID, pMilliseconds
   if pMilliseconds is empty then put the milliseconds into pMilliseconds
   put pageArray ["journal"] into journalArray
   --
   put "edit" into actionArray ["type"]
   put pMilliseconds into actionArray ["date"]
   put itemID into actionArray ["id"]
   put newItemArray into actionArray ["item"]
   --
   itemArray_AddToEnd actionArray, journalArray
   put journalArray into pageArray ["journal"]
   return actionArray
end pageArray_AddEditAction

command pageArray_AddAddAction @pageArray, itemArray, afterID, pMilliseconds
   if pMilliseconds is empty then put the milliseconds into pMilliseconds
   put pageArray ["journal"] into journalArray
   --
   put "add" into actionArray ["type"]
   put afterID into actionArray ["after"]
   put itemArray into actionArray ["item"]
   put itemArray ["id"] into actionArray ["id"]
   put pMilliseconds into actionArray ["date"]
   --
   itemArray_AddToEnd actionArray, journalArray
   put journalArray into pageArray ["journal"]
   return actionArray
end pageArray_AddAddAction

command pageArray_AddDeleteAction @pageArray, deletedItemID, pMilliseconds
   if pMilliseconds is empty then put the milliseconds into pMilliseconds
   put pageArray ["journal"] into journalArray
   --
   put "remove" into actionArray ["type"]
   put pMilliseconds into actionArray ["date"]
   put deletedItemID into actionArray ["id"]
   --
   itemArray_AddToEnd actionArray, journalArray
   put journalArray into pageArray ["journal"]
end pageArray_AddDeleteAction


--> PageArray | Add
-
command pageArray_AddMarkdown @pageArray, someMarkdown, pID
   if someMarkdown is empty then return 0
   put itemArray_Construct ("markdown", pID, someMarkdown) into itemArray
   itemArray_Add itemArray, pageArray
   return the result
end pageArray_AddMarkdown

command pageArray_AddText @pageArray, someText, pID
   if someText is  empty then return 0
   put word 1 to -1 of someText into someText
   put itemArray_Construct ("paragraph", pID, someText) into itemArray
   itemArray_Add itemArray, pageArray
   return the result
end pageArray_AddText

command pageArray_AddHtml @pageArray, someHtml, pID
   if someCode is  empty then return 0
   put itemArray_Construct ("html", pID, someHtml) into itemArray
   itemArray_Add itemArray, pageArray
   return the result
end pageArray_AddHtml

command pageArray_AddFactory @pageArray, pID
   put itemArray_ConstructFactory (pID) into itemArray
   itemArray_Add itemArray, pageArray
   return the result
end pageArray_AddFactory

command pageArray_AddPagefold @pageArray, someText, pID
   if someText is  empty then return 0
   put word 1 to -1 of someText into someText
   put itemArray_Construct ("pagefold", pID, someText) into itemArray
   itemArray_Add itemArray, pageArray
   return the result
end pageArray_AddPagefold

command pageArray_AddCode @pageArray, someCode, pID
   if someCode is  empty then return false
   put itemArray_Construct ("code", pID, someCode) into itemArray
   itemArray_Add itemArray, pageArray
   return true
end pageArray_AddCode

command pageArray_AddVideo @pageArray, videoID, videoType, videoDescription, pID
   -- videoID can be "webm http://xxx"
   if videoID is empty then return 0
   put itemArray_ConstructVideo (videoID, videoType, videoDescription, pID) into itemArray
   itemArray_Add itemArray, pageArray
   return the result
end pageArray_AddVideo

command pageArray_AddAudio @pageArray, audioUrl, someText, pID
   if audioUrl is  empty then return false
   put itemArray_ConstructAudio (audioUrl, someText, pID) into itemArray
   itemArray_Add itemArray, pageArray
   return true
end pageArray_AddAudio

command pageArray_AddTransport @pageArray, pTransportLine, pID
   if pTransportLine is  empty then return 0
   if pTransportLine is empty then
      put "POST https://rest.livecode.world/imagine" into pTransportLine
   end if
   put itemArray_ConstructTransport (pTransportLine, pID) into itemArray
   itemArray_Add itemArray, pageArray
   return the result
end pageArray_AddTransport


--> JournalArray
-
function journalArray_Construct pageTitle, pSourceArray, pMilliseconds, pStoryArray
   if pMilliseconds is not a number then put the milliseconds into pMilliseconds
   --
   put "create" into createArray ["type"]
   put pMilliseconds into createArray ["date"]
   put pageTitle into createArray ["item"]["title"]
   if pStoryArray is an array then put pStoryArray into createArray ["item"]["story"]
   if pSourceArray is an array then put pSourceArray into createArray ["source"]
   --
   put createArray into journalArray [1]
   return journalArray
end journalArray_Construct

function fedwiki_ConstructSearchForm buttonName, postURL, inputVarName, pInputSize, pInputDefault, pAlign, pHiddenKeyValueArray, pBgColor
   put inputVarName into pInputArray ["inputVarName"]
   put pInputSize into pInputArray ["inputSize"]
   put pInputDefault into pInputArray ["inputDefault"]
   --
   put fedwiki_ConstructForm (buttonName, postURL, pHiddenKeyValueArray, pInputArray, empty, pAlign, pBgColor) into formHTML
   return formHTML
end fedwiki_ConstructSearchForm

function fedwiki_ConstructButtonForm buttonName, postURL, pHiddenKeyValueArray, pLabel, pAlign, pBgColor, pInline
   put empty into pInput -- a button is a form without an input field
   put fedwiki_ConstructForm (buttonName, postURL, pHiddenKeyValueArray, pInput, pLabel, pAlign, pBgColor, pInline) into formHTML
   return formHTML
end fedwiki_ConstructButtonForm

function fedwiki_ConstructForm buttonName, postURL, inputKeyValueArray, pInput, pLabel, pAlign, pBgColor, pInline
   if pAlign is empty then put "center" into pAlign
   if pBgColor is empty then
      put "<div align=[[pAlign]]>" & CR into htmlTemplate
   else
      put "<div align=[[pAlign]] style='background-color:[[pBgColor]];color:black;padding:12px'>" & CR after htmlTemplate
   end if
   put _GetHiddenInput (inputKeyValueArray) into hiddenTemplateBit
   --
   if pInline then
      put "<form action='[[postURL]]' style='display:inline'>" & CR after htmlTemplate
   else
      put "<form action='[[postURL]]'>" & CR after htmlTemplate
   end if
   --
   if pLabel is not empty then
      put "[[pLabel]]: &nbsp;&nbsp;" & CR after htmlTemplate
   end if
   --
   if pInput is not empty then
      if pInput is an array then
         put pInput ["inputVarName"] into inputVarName
         put pInput ["inputSize"] into inputSize
         put pInput ["inputDefault"] into inputDefault
      else
         put pInput into inputVarName
         put empty into inputDefault
      end if
      if inputSize is empty then put 32 into inputSize
      --
      put "<input name=[[inputVarName]] value='[[inputDefault]]' size=[[inputSize]]>" & CR after htmlTemplate
   end if
   --
   if hiddenTemplateBit is not empty then
      put "[[hiddenTemplateBit]]"  & CR after htmlTemplate
   end if
   put "<button type='submit'>[[buttonName]]</button>" & CR after htmlTemplate
   put "</form></div>" after htmlTemplate
   --
   replace "'" with quote in htmlTemplate
   put merge (htmlTemplate) into someHTML
   return someHTML
end fedwiki_ConstructForm


--> Private
-
private function _GetHiddenInput inputKeyValueArray
   repeat for each key inputKey in inputKeyValueArray
      put inputKeyValueArray [inputKey] into inputValue
      if inputValue is not empty then
         put _ConstructHiddenBit (inputKey, inputValue) & CR after hiddenTemplateBit
      end if
   end repeat
   delete char -1 of hiddenTemplateBit
   return hiddenTemplateBit
end _GetHiddenInput

private function _ConstructHiddenBit inputKey, inputValue
   put "<input name='[[inputKey]]'" & space into hiddenBit
   put "value='[[inputValue]]'" & space after hiddenBit
   put "type='hidden'>" after hiddenBit
   replace "'" with quote in hiddenBit
   return merge (hiddenBit)
end _ConstructHiddenBit

private command _SetImageDescription @pImageCaption, @pLinkURL, imageURL
   if pImageCaption is empty then put "This is an image" into pImageCaption
   if pLinkURL is empty then
      if imageURL begins with "data:image/" then
         put empty into pLinkURL
      else
         put imageURL into pLinkURL
      end if
   end if
end _SetImageDescription

private function _ConstructImagePageArray pPageTitle, pPageDescription
   local pageArray
   if pPageTitle is empty then put "Imported Image" into pPageTitle
   if pPageDescription is empty then
      put "This [[ghost-page]] has not been saved yet. Drag the map off this page if you want to keep it." into pPageDescription
   end if
   --
   put pPageTitle into pageArray ["title"]
   put journalArray_Construct (pPageTitle) into pageArray ["journal"] 
   pageArray_AddMarkdown pageArray, pPageDescription
   --
   return pageArray
end _ConstructImagePageArray


--> Deps
-
command line_AddToNameArray @nameArray, someIndex
   replace comma with CR in someIndex
   repeat for each line someLine in someIndex
      put word 1 to -1 of someLine into someLine
      if someLine is empty then next repeat
      put empty into nameArray [someLine]
   end repeat
end line_AddToNameArray
