﻿script "lib_OneTab"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_OneTab
type: library
version: 0.1

/*Some help*/

local MarkDownLinks


--> Working on
-


--> One | Tab
-
function oneTab_FetchPageArray oneTabUrl, pType
   put url oneTabUrl into someHtml
   --
   put "Below are a collection of links imported from [[OneTab]]. You can view these links here - [" & oneTabUrl && "one-tab.com]:" into headerBit
   _ParseOneTabHtml someHtml, headerBit, markDownLinks, divSection, tabTitle
   put the result into parseArray
   --
   put parseArray ["tabTitle"] into tabTitle
   put parseArray ["headerBit"] into headerBit
   put pageArray_Construct (tabTitle, headerBit) into pageArray
   --
   switch pType
      case "pretty"
         _AddPretty pageArray, tabTitle, divSection, parseArray
         break
      case "htmlParagraphs"
         _AddHtmlParagraphs pageArray, tabTitle, divSection, parseArray
         break
      case "htmlSection"
         _AddHtmlSection pageArray, tabTitle, headerBit, divSection
         break
      case "markdown"
         _AddMarkdownSection pageArray, tabTitle, markDownLinks
         break
      default
         put _ConstructOneTabPageArray (parseArray) into pageArray
   end switch
   pageArray_StripJournal pageArray
   return pageArray
end oneTab_FetchPageArray

command transport_Video @pageArray, videoURL, urlText
   /*
   put "https://rest.livecode.world/youtube/transport_Video" into restURL
   put transporter_ConstructDroppedJSON (videoURL) into dropJSON
   fedwiki_PostJSON dropJSON, restURL
   put the result into pageJSON
   put json_ToArray (pageJSON) into fetchedPageArray
   */
   
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
   
   pageArray_AddImage pageArray, imageURL, someCaption, refURL
   return pageArray
end transport_GoogleImage

command transport_Webpage @pageArray, linkUrl, urlText
   put _ConstructMarkDownLink (linkUrl, urlText) into markDownLink
   -- pageArray_AddMarkdown pageArray, markDownLink
   put markDownLink & CR after MarkDownLinks
   return empty
end transport_Webpage

command transport_Mediawiki @pageArray, linkUrl, urlText
   -- messy the way it add form-buttons
   put _ConstructMarkDownLink (linkUrl, urlText) into markDownLink
   put markDownLink & CR after MarkDownLinks
   --
   put "https://rest.livecode.world/mediawiki/form" into postURL
   put linkUrl into hiddenKeyValueArray ["url"]
   --
   pageArray_AddButton pageArray, urlText, postURL, hiddenKeyValueArray, "", "right"
   return empty
end transport_Mediawiki

function transport_ParseURL droppedURL
   switch
      -- https://www.ted.com/talks/alexander_betts_why_brexit_happened_and_what_to_do_next
      case droppedURL begins with "https://www.youtube.com/"
      case droppedURL begins with "https://vimeo.com/"
      case droppedURL begins with "https://www.ted.com/talks/"
         put "https://rest.livecode.world/youtube/transport_Video" into resultArray ["url"]
         put "transport_Video" into resultArray ["handler"]
         return resultArray
      case droppedURL begins with "https://audioboom.com/posts/"
         put "https://rest.livecode.world/audioboom" into resultArray ["url"]
         put "transport_AudioBoom" into resultArray ["handler"]
         return resultArray
      case droppedURL begins with "https://player.fm/series/"         
         put "https://rest.livecode.world/bbc/playerfm" into resultArray ["url"]
         put "transport_PlayerFM" into resultArray ["handler"]
         return resultArray
      case droppedURL begins with "http://www.radiolab.org/story/"
      case droppedURL begins with "http://www.bbc.co.uk/programmes/"
      case droppedURL begins with "https://www.theguardian.com/science/audio/" -- plenty of other podcast urls
         put "https://rest.livecode.world/bbc" into resultArray ["url"]
         put "transport_Podcast" into resultArray ["handler"]
         return resultArray
      case droppedURL begins with "http://www.openstreetmap.org/"
      case droppedURL begins with "https://www.openstreetmap.org/"
      case droppedURL begins with "https://www.google.co.uk/maps/place/"
      case droppedURL begins with "https://www.google.com/maps/place/"
      case matchtext (droppedURL, "^https://tools.wmflabs.org/geohack/geohack.php\?pagename=(.+)&params=(.+)", pageName, geoInfo)
         put "https://rest.livecode.world/map" into resultArray ["url"]
         put "transport_Map" into resultArray ["handler"]
         return resultArray
      case matchText (droppedURL, "https://www.one-tab.com/page/(.+)", oneTabID)
         put "https://rest.livecode.world/onetab" into resultArray ["url"]
         put "transport_OneTab" into resultArray ["handler"]
         return resultArray
      case matchText (droppedURL, "https://(.+).wikipedia.org/(.+)", lastBit)
         put "https://rest.livecode.world/mediawiki" into resultArray ["url"]
         put "transport_Mediawiki" into resultArray ["handler"]
         return resultArray
      case matchtext (droppedURL, "https://matrix.org/_matrix/media/v1/download/matrix.org/(.+)", matrixAssetID)
      case matchText (droppedURL, "http://britishlibrary.typepad.co.uk/.a/(.+)", assetID)
      case matchText (droppedURL, "https://static.+.squarespace.com/static/.+", photoID)
         put "http://home.c2.com:4010/image" into resultArray ["url"]
         put "transport_Photo" into resultArray ["handler"]
         return resultArray
      case matchText (droppedURL, "https://www.pinterest.com/pin/(.+)/|https://www.pinterest.co.uk/pin/(.+)/", photoID)
         put "" into resultArray ["url"]
         put "transport_Pinterest" into resultArray ["handler"]
         return resultArray
      case matchText (droppedURL, "https://www.flickr.com/photos/(.+)/(.+)/in/.+", userID, photoID)
         put "" into resultArray ["url"]
         put "transport_Flickr" into resultArray ["handler"]
         return resultArray
      case matchText (droppedURL, "https://twitter.com/.+/status/.+")
         put "" into resultArray ["url"]
         put "transport_Twitter" into resultArray ["handler"]
         return resultArray
      case droppedURL begins with "https://www.google.com/imgres?imgurl="
      case droppedURL begins with "https://www.google.co.uk/imgres?imgurl="
         put "" into resultArray ["url"]
         put "transport_GoogleImage" into resultArray ["handler"]
         return resultArray
      default
         put "" into resultArray ["url"]
         put "transport_Webpage" into resultArray ["handler"]
         return resultArray
   end switch
end transport_ParseURL


--> Private
-
private command _AddPretty @pageArray, tabTitle, divSection, parseArray
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
      put transport_ParseURL (linkURL) into resultArray
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
end _AddPretty

private function _ConstructOneTabPageArray oneTabUrl
   put url oneTabUrl into someHtml
   put "Below are a collection of links imported from [[OneTab]]. You can view these links here - [" & oneTabUrl && "one-tab.com]:" into headerBit
   _ParseOneTabHtml someHtml, headerBit, markDownLinks, divSection, tabTitle
   if tabTitle is empty then put "OneTab Links" into tabTitle
   put the result into parseArray
   put parseArray ["urls"] into urlArray
   --
   put pageArray_Construct (tabTitle, headerBit) into pageArray
   
   put item 2 of the extents of urlArray into maxItemNum
   repeat with itemNum = 1 to maxItemNum
      put empty into storyItemArray
      --
      put urlArray [itemNum] into itemArray
      put itemArray ["linkURL"] into linkURL
      --
      put transport_ParseURL (linkURL) into resultArray
      put resultArray ["url"] into restURL
      put resultArray ["handler"] into tHandler
      --
      switch
         case tHandler is empty and restURL is empty
            put _ConstructItemHtml (itemArray) into imageHTML
            pageArray_AddHtml pageArray, imageHTML
            break
         case tHandler is empty
            -- basic processing
            next repeat
            break
         case restURL is not empty
            -- let's fetch a pageArray
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
               
               -- add story to the end
               fedwiki_AddStoryArray pageArray, receivedStoryItemArray
            end if
            break
         default
            -- not bothering to serialise as json?
            dispatch tHandler with itemArray
            if it is "handled" then
               put the result into storyItemArray
               fedwiki_AddStoryArray pageArray, storyItemArray
            end if
      end switch
   end repeat
   --
   pageArray_StripJournal pageArray
   return pageArray
end _ConstructOneTabPageArray

private command _ParseOneTabHtml someHtml, headerBit, @markDownLinks, @divSection, @tabTitle
   html_Tidy someHtml
   put revXMLCreateTree (someHTML, false, true, false) into treeID
   --
   put revXMLRootNode (treeID) into rootNode
   put word 1 to -1 of revXMLNodeContents (treeID, "/html/head/title") into htmlTitle
   put word 1 to -1 of revXMLNodeContents (treeID, "/html/body/div[1]/div[6]") into tabTitle
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
   put revXMLChildNames (treeID, "/html/body/div[1]", CR, "div", true) into tNames
   repeat with divNum = 7 to (the number of lines of tNames - 1)
      put "/html/body/div[1]/div[" & divNum & "]" into divNode      
      put revXMLText (treeID, divNode) into linkHTML
      --
      put divNode & "/img" into imgNode
      put revXMLAttribute (treeID, imgNode, "src") into faviconURL
      put divNode & "/a" into aNode
      put revXMLAttribute (treeID, aNode, "href") into someTextURL
      put revXMLNodeContents (treeID, aNode) into someTextLink
      replace CR with space in someTextLink
      --
      put _GetTldBit (someTextURL) into tldBit
      
      -- construct markDownLinks
      put _ConstructMarkDownLink (someTextURL, someTextLink) into markDownLink
      put CR & markDownLink after markDownLinks
      
      -- construct divSection
      put merge (linkTemplate) into htmlLine
      put divStart & htmlLine & "</div>" into divBit
      put divBit & CR after divSection
      --
      put divNum - 6 into urlLineNum
      put someTextURL into parseArray ["urls"][urlLineNum]["linkURL"]
      put faviconURL into parseArray ["urls"][urlLineNum]["faviconURL"]
      put tldBit into parseArray ["urls"][urlLineNum]["tldBit"]
      put someTextLink into parseArray ["urls"][urlLineNum]["someTextLink"]
      put linkHTML into parseArray ["urls"][urlLineNum]["linkHTML"]
   end repeat
   --
   revDeleteXMLTree treeID
   return parseArray
end _ParseOneTabHtml

private function _GetTldBit someTextURL
   set the itemdelimiter to slash
   put item 3 of someTextURL into tldBit
   set the itemdelimiter to "."
   put item -2 to -1 of tldBit into tldBit
   set the itemdelimiter to ","
   return tldBit
end _GetTldBit

private function _ConstructMarkDownLink someTextURL, someTextLink
   put _GetTldBit (someTextURL) into tldBit
   --
   if the number of chars of someTextLink > 30 then
      get char 1 to 30 of someTextLink
      put word 1 to -2 of it into truncatedLink -- using token seems to break the encoding for json_FromArray???
      put "..." after truncatedLink
      put "-" && truncatedLink && "- [" & someTextURL && tldBit & "]" into markDownLink
   else
      put "-" && someTextLink && "- [" & someTextURL && tldBit & "]" into markDownLink
   end if
   return markDownLink
end _ConstructMarkDownLink

private command _AddHtmlParagraphs @pageArray, tabTitle, divSection, parseArray
   put "#" && tabTitle into someMarkDown
   pageArray_AddMarkdown pageArray, someMarkDown
   --
   put 1 into urlLineNum
   repeat for each line htmlLine in divSection
      put parseArray ["urls"][urlLineNum]["linkURL"] into linkURL
      put transport_ParseURL (linkURL) into resultArray
      put resultArray ["url"] into restURL
      put resultArray ["handler"] into tHandler
      --
      dispatch tHandler with pageArray, linkURL
      --
      add 1 to urlLineNum
   end repeat
end _AddHtmlParagraphs

private command _AddMarkdownSection @pageArray, tabTitle, markDownLinks
   put "#" && tabTitle & CR & markDownLinks into someMarkDown
   pageArray_AddMarkdown pageArray, someMarkdown
end _AddMarkdownSection

private command _AddHtmlSection @pageArray, tabTitle, headerBit, divSection
   put "<h3>" & tabTitle & "</h3>" & CR into divHeader
   put headerBit & "<p>" & CR after divHeader
   put divHeader before divSection
   pageArray_AddHtml pageArray, divSection
end _AddHtmlSection

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