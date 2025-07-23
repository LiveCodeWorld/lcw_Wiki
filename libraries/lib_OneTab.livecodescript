script "lib_OneTab"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_OneTab
type: library
version: 0.2

/*
*/

local MarkDownLinks


--> Working on
-
function oneTab_Parse oneTabURL
   local markDownIndex, divSection, tabTitle
   put url oneTabURL into someHTML
   _ParseOneTabHtml someHtml, empty, markDownIndex, divSection, tabTitle
   put the result into parseArray
   return parseArray
end oneTab_Parse

private function _BasicMarkDownLink someTextURL, someTextLink
   put _GetTldBit (someTextURL) into tldBit
   --
   put "-" && someTextLink && "- [" & someTextURL && tldBit & "]" into markDownLink
   return markDownLink
end _BasicMarkDownLink

private function _TrimmedMarkDownLink someTextURL, someTextLink
   put _GetTldBit (someTextURL) into tldBit
   --
   get char 1 to 30 of someTextLink
   put word 1 to -2 of it into truncatedLink -- using token seems to break the encoding for json_FromArray???
   put "..." after truncatedLink
   put "-" && truncatedLink && "- [" & someTextURL && tldBit & "]" into markDownLink
   --
   return markDownLink
end _TrimmedMarkDownLink

private function _ConstructMarkDownLink someTextURL, someTextLink
   if the number of chars of someTextLink > 30 then
      put _TrimmedMarkDownLink (someTextURL, someTextLink) into markDownLink
   else
      put _BasicMarkDownLink (someTextURL, someTextLink) into markDownLink
   end if
   return markDownLink
end _ConstructMarkDownLink

on drop_OneTab dView, droppedURL
   put the displayed_Object of dView into browserView
   --
   switch
      case droppedURL begins with "https://www.one-tab.com"
         put url droppedURL into someHTML
         put oneTab_ConstructPageArray (someHtml, "pretty") into pageArray
         break
      default
         put "Not a [[OneTab]] web page. Visit OneTab to start collaborative bookmarking - [https://www.one-tab.com/ one-tab.com]" into someInfo
         put pageArray_Construct ("Error", someInfo) into pageArray
   end switch
   --
   set the ghost_PageArray of browserView to pageArray
end drop_OneTab

private command _ParseOneTabHtml someHtml, headerBit, @markDownIndex, @divSection, @tabTitle
   html_Tidy someHtml
   put revXMLCreateTree (someHTML, false, true, false) into treeID
   --
   put revXMLRootNode (treeID) into rootNode
   put word 1 to -1 of revXMLNodeContents (treeID, "/html/head/title") into htmlTitle
   
   put revXMLMatchingNode (treeID, "/html/body", "div", "class", "tabGroupLabel", -1) into tabGroupLabelDiv
   put word 1 to -1 of revXMLNodeContents (treeID, tabGroupLabelDiv) into tabTitle
   --
   put htmlTitle into parseArray ["htmlTitle"]
   put tabTitle into parseArray ["tabTitle"]
   put headerBit into parseArray ["headerBit"]
   --
   put "vertical-align: middle; width:16px; height:16px" into faviconStyle
   put "vertical-align: middle; padding-left: 10px; padding-right: 12px; text-decoration: none;" into someLinkstyle
   put "<img src='[[faviconURL]]' style='[[faviconStyle]]' /><a target=_blank style='[[someLinkstyle]]' href='[[someTextURL]]'>[[someTextLink]]</a>" into linkTemplate
   put "<div style='padding-left: 24px; padding-top: 8px; position: relative; font-size: 13px;'>" into divStart
   --
   put revXMLMatchingNode (treeID, "/html/body/div", "div", "class", "tabGroup", 1) into tabGroupDiv 
   put revXMLChildNames (treeID, tabGroupDiv, CR, "div", true) into tNames
   
   put 1 into urlLineNum
   repeat for each line tName in tNames -- with divNum = 2 to maxNum
      put tabGroupDiv & slash & tName into divNode
      if divNode = tabGroupLabelDiv then next repeat
      --      
      put divNode & "/img" into imgNode
      put revXMLAttribute (treeID, imgNode, "src") into faviconURL
      put divNode & "/a" into aNode
      put revXMLAttribute (treeID, aNode, "href") into someTextURL
      put revXMLNodeContents (treeID, aNode) into someTextLink
      replace CR with space in someTextLink
      --
      put revXMLText (treeID, divNode) into linkHTML
      put _GetTldBit (someTextURL) into tldBit
      
      -- construct markDownIndex
      put _ConstructMarkDownLink (someTextURL, someTextLink) into markDownLine
      put CR & markDownLine after markDownIndex
      
      -- construct divSection
      put merge (linkTemplate) into htmlLine
      put divStart & htmlLine & "</div>" into divBit
      put divBit & CR after divSection
      --
      put someTextURL into parseArray ["urls"][urlLineNum]["linkURL"]
      put faviconURL into parseArray ["urls"][urlLineNum]["faviconURL"]
      put tldBit into parseArray ["urls"][urlLineNum]["tldBit"]
      put someTextLink into parseArray ["urls"][urlLineNum]["someTextLink"]
      put linkHTML into parseArray ["urls"][urlLineNum]["linkHTML"]
      add 1 to urlLineNum
   end repeat
   --
   revDeleteXMLTree treeID
   return parseArray
end _ParseOneTabHtml


--> One | Tab
-
function oneTab_FetchPageArray oneTabUrl, pType, pHeaderBit
   if pHeaderBit is empty then
      put "Below are a collection of links imported from [[OneTab]]. You can view these links here - [" & oneTabUrl && "one-tab.com]:" into pHeaderBit
   end if
   --
   put url oneTabUrl into someHtml
   put oneTab_ConstructPageArray (someHtml, pType, pHeaderBit) into pageArray
   return pageArray
end oneTab_FetchPageArray

function oneTab_ConstructPageArray someHtml, pType, pHeaderBit
   switch pType
      case "pretty"
         put oneTab_ConstructPrettyPageArray (someHtml, pHeaderBit) into pageArray
         break
      case "htmlParagraphs"
         put oneTab_ConstructHtmlParagraphArray (someHtml, pHeaderBit) into pageArray
         break
      case "htmlSection"
         put oneTab_ConstructHtmlSectionPageArray (someHtml, pHeaderBit) into pageArray
         break
         /*
      case "markdown"
         put oneTab_ConstructMarkdwonPageArray (someHtml, pHeaderBit) into pageArray
         break
         */
      default
         put oneTab_ConstructBasicPageArray (someHtml, pHeaderBit) into pageArray
   end switch
   pageArray_StripJournal pageArray
   return pageArray
end oneTab_ConstructPageArray

-- function oneTab_ConstructMarkdwonPageArray someHtml, markDownLinks
_SetPageArrayHeader pageArray, someHtml, pHeaderBit
put the result into parseArray
put parseArray ["tabTitle"] into tabTitle

put "#" && tabTitle & CR & markDownLinks into someMarkDown
pageArray_AddMarkdown pageArray, someMarkdown
return markDownLinks
end oneTab_ConstructMarkdwonPageArray

function oneTab_ConstructHtmlSectionPageArray someHtml, pHeaderBit
   _SetPageArrayHeader pageArray, someHtml, pHeaderBit
   put the result into parseArray
   put parseArray ["tabTitle"] into tabTitle
   
   put "<h3>" & tabTitle & "</h3>" & CR into divHeader
   put headerBit & "<p>" & CR after divHeader
   put divHeader before divSection
   pageArray_AddHtml pageArray, divSection
   --
   return pageArray
end oneTab_ConstructHtmlSectionPageArray

function oneTab_ConstructHtmlParagraphArray someHtml, pHeaderBit
   _SetPageArrayHeader pageArray, someHtml, pHeaderBit
   put the result into parseArray
   put parseArray ["tabTitle"] into tabTitle
   
   put "#" && tabTitle into someMarkDown
   pageArray_AddMarkdown pageArray, someMarkDown
   --
   put 1 into urlLineNum
   repeat for each line htmlLine in divSection
      put parseArray ["urls"][urlLineNum]["linkURL"] into linkURL
      put imagine_ConstructDroppedURLArray (linkURL) into resultArray
      put resultArray ["url"] into restURL
      put resultArray ["handler"] into tHandler
      --
      dispatch tHandler with pageArray, linkURL
      --
      add 1 to urlLineNum
   end repeat
   --
   return pageArray
end oneTab_ConstructHtmlParagraphArray

private command _SetPageArrayHeader @pageArray, someHtml, pHeaderBit
   _ParseOneTabHtml someHtml, pHeaderBit, markDownIndex, divSection, tabTitle
   put the result into parseArray
   --
   put parseArray ["tabTitle"] into tabTitle
   put pageArray_Construct (tabTitle, pHeaderBit) into pageArray
   return parseArray
end _SetPageArrayHeader

function oneTab_ConstructPrettyPageArray someHtml, pHeaderBit
   _SetPageArrayHeader pageArray, someHtml, pHeaderBit
   put the result into parseArray
   put parseArray ["tabTitle"] into tabTitle
   
   put empty into MarkDownLinks
   --
   put "#" && tabTitle into someMarkDown
   pageArray_AddMarkdown pageArray, someMarkDown
   --
   put parseArray ["urls"] into urlArray
   put item 2 of the extents of urlArray into maxNum
   repeat with urlLineNum = 1 to maxNum
      put urlArray [urlLineNum]["someTextLink"] into urlText
      put urlArray [urlLineNum]["linkURL"] into linkURL
      --
      put imagine_ConstructDroppedURLArray (linkURL) into resultArray
      put resultArray ["url"] into restURL
      put resultArray ["handler"] into tHandler
      --
      dispatch tHandler with pageArray, linkURL, urlText
      if it is "unhandled" then
         transport_Webpage pageArray, linkUrl, urlText
      end if
   end repeat
   
   put word 1 to -1 of MarkDownLinks into MarkDownLinks
   pageArray_AddMarkdown pageArray, MarkDownLinks
   --
   return pageArray
end oneTab_ConstructPrettyPageArray

function oneTab_ConstructBasicPageArray someHtml, pHeaderBit
   _SetPageArrayHeader pageArray, someHtml, pHeaderBit
   put the result into parseArray
   --
   put parseArray ["urls"] into urlArray
   
   # Loop through each of the OneTab Items in urlArray
   put item 2 of the extents of urlArray into maxItemNum
   repeat with itemNum = 1 to maxItemNum
      put empty into storyItemArray
      --
      put urlArray [itemNum] into oneTabItemArray
      put oneTabItemArray ["linkURL"] into linkURL
      put oneTabItemArray ["someTextLink"] into someTextLink
      
      # Use imagine array to construct specific resultArray
      put imagine_ConstructDroppedURLArray (linkURL) into imagineItemArray
      put imagineItemArray ["url"] into restURL
      put imagineItemArray ["handler"] into tHandler
      
      # Depending on the handler associated with oneTabUrl
      switch tHandler
         case "transport_Mediawiki"
            transport_Mediawiki pageArray, linkUrl, someTextLink
            break
         case "transport_Video"
            transport_Video pageArray, linkURL, someTextLink
            break
         case "transport_Webpage"
         default       
            -- put _ConstructMarkDownLink (linkUrl, someTextLink) into mdText
            put _BasicMarkDownLink (linkUrl, someTextLink) into mdText
            pageArray_AddMarkdown pageArray, mdText
      end switch
   end repeat
   --
   return pageArray
end oneTab_ConstructBasicPageArray

command transport_Webpage @pageArray, linkUrl, urlText
   put _ConstructMarkDownLink (linkUrl, urlText) into markDownLink
   put markDownLink & CR after MarkDownLinks
   return empty
end transport_Webpage

function oneTab_AddHtmlpageArray @pageArray, oneTabItemArray
   put _ConstructItemHtml (oneTabItemArray) into imageHTML
   pageArray_AddHtml pageArray, imageHTML
end oneTab_AddHtmlpageArray

function transport_FetchFromControllerUrl linkURL
   put fedwiki_EncodePost (linkURL) into postJSON
   fedwiki_PostJSON postJSON, restURL
   put the result into returnedJSON
   
   put json_ToArray (returnedJSON) into receivedPageArray
   put receivedPageArray ["title"] into receivedTitle
   put receivedPageArray ["story"] into receivedStoryItemArray
   --
   if receivedStoryItemArray is an array then
      put "#" && receivedTitle into someMarkDown
      pageArray_AddMarkdown pageArray, someMarkDown
      
      # Add story to the end
      pageArray_AddStory pageArray, receivedStoryItemArray
   end if
   return pageArray
end transport_FetchFromControllerUrl

command transport_Video @pageArray, videoURL, urlText
   switch
      case matchText (videoURL, "https\://www\.youtube\.com/watch\?v\=(.+)", videoIDBit)
         put youtube_GetVideoID (videoURL) into videoID
         put "[" & videoURL && "youtube]" into word -1 of urlText
         pageArray_AddVideo pageArray, videoID, "YOUTUBE", urlText
         break
      case matchText (videoURL, "https\://www\.ted\.com/talks/(.+)", tedID)
         -- put ted_ConstructPageArray (tedID) into fedwikiPageArray
         put "[" & videoURL && "ted]" into word -1 of urlText
         pageArray_AddVideo pageArray, tedID, "TED", urlText
         break
      case matchText (videoURL, "https\://vimeo\.com/(.+)", vimeoID)
         -- put vimeo_ConstructPageArray (vimeoID) into fedwikiPageArray
         put "[" & videoURL && "vimeo]" into word -1 of urlText
         pageArray_AddVideo pageArray, vimeoID, "VIMEO", urlText
         break
      default
         -- do nothing
   end switch
end transport_Video

command transport_GoogleImage @pageArray, linkURL, urlText
   _DeconstructGoogleImageUrl linkURL, imageURL, refURL, searchTerms, w, h
   put "Google Image Result for" && kwote (searchTerms) into someCaption
   
   pageArray_AddHtmlImage pageArray, imageURL, someCaption, refURL
   return pageArray
end transport_GoogleImage

command transport_Mediawiki @pageArray, linkUrl, urlText
   -- messy the way it add form-buttons
   put _ConstructMarkDownLink (linkUrl, urlText) into markDownLink
   put markDownLink & CR after MarkDownLinks
   --
   put platform_RestUrl ("mediawiki/form") into postURL
   put linkUrl into hiddenKeyValueArray ["url"]
   --
   pageArray_AddButton pageArray, urlText, postURL, hiddenKeyValueArray, "", "right"
   return empty
end transport_Mediawiki


--> Private
-
private function _GetTldBit someTextURL
   set the itemdelimiter to slash
   put item 3 of someTextURL into tldBit
   set the itemdelimiter to "."
   put item -2 to -1 of tldBit into tldBit
   set the itemdelimiter to ","
   return tldBit
end _GetTldBit

private command _AddImageSection parseArray, @pageArray
   -- this is not needed now that we are replacing html links with images in the html section?
   put parseArray ["urls"] into urlArray
   repeat for each key urlLineNum in urlArray
      put urlArray [urlLineNum] into itemArray
      put _ConstructItemHtml (itemArray) into imageHTML
      if imageHTML is not empty then
         pageArray_AddHtml pageArray, imageHTML
      end if
   end repeat
end _AddImageSection

private function _ConstructItemHtml itemArray
   put itemArray ["linkURL"] into linkURL
   put itemArray ["faviconURL"] into faviconURL
   put itemArray ["tldBit"] into tldBit
   put itemArray ["someTextLink"] into gSearchTextLink
   --
   _DeconstructGoogleImageUrl linkURL, imageURL, refURL, searchTerms, w, h
   if the result is false then return empty
   --
   put "Google Image Result for" && kwote (searchTerms) into someCaption
   put fedwiki_ConstructImageHtml (imageURL, someCaption, linkURL) into imageHTML
   --
   return imageHTML
end _ConstructItemHtml

private command _DeconstructGoogleImageUrl someTextURL, @imageURL, @refURL, @searchTerms, @w, @h
   put urldecode (someTextURL) into someURL
   set the itemdelimiter to "?"
   -- if matchtext() then
   if someTextURL begins with "https://www.google.co.uk/imgres?" then
      delete item 1 of someURL
      --
      put someURL into someArray
      split someArray with "&" and "="
      put someArray ["imgurl"] into imageURL
      put someArray ["imgrefurl"] into refURL
      put someArray ["q"] into searchTerms
      put someArray ["w"] into w
      put someArray ["h"] into h
      --
      return true
   else
      put empty into imageURL
      put empty into refURL
      put empty into searchTerms
      put 0 into w
      put 0 into h
      return false
   end if
end _DeconstructGoogleImageUrl


--> Deps
-
command html_Tidy @someHtml
   put the tempname & ".html" into inputFile
   put someHtml into url ("file:" & inputFile)
   
   put "tidy --show-info false --show-warnings false --force-output true --char-encoding utf8 --input-encoding utf8 --output-encoding utf8 --output-xml true -asxml -m" && inputFile into someShell
   -- put "tidy -q -utf8 -asxml -m" && inputFile into someShell
   put shell (someShell) into shellResult
   put url ("file:" & inputFile) into someHtml
end html_Tidy

function youtube_GetVideoID someURL
   set the itemdelimiter to "/"
   put item 3 of someURL into youtubeBit
   put item 4 of someURL into firstPathBit
   
   if youtubeBit ends with "youtube.com" is false then
      put "Not a link that I can parse:" && droppedURL into errorText
      return "error," && errorText
   end if
   
   set the itemdelimiter to "?"
   delete item 1 of firstPathBit
   --
   split firstPathBit with "&" and "="
   put firstPathBit ["v"] into videoID
   --
   return videoID
end youtube_GetVideoID
