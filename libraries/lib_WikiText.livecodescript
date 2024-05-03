script "lib_WikiText"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_WikiText
type: library
version: 0.1

/* Library for processing wiki-text and wiki-links.
*/


--> Working on
-
function wikiSnippet_CurlyGet pageSlug, hiddenArray
   put wikiSnippet_Get (pageSlug) into sHTML
   curly_Merge sHTML, hiddenArray
   return sHTML
end wikiSnippet_CurlyGet

function wikiSnippet_Get pageSlug
   put pageArray_Get ("css.fedwiki.org", pageSlug) into pageArray
   put pageArray_GetFirstHtml (pageArray) into sHTML
   return sHTML
end wikiSnippet_Get


--> PageArray | Image
-
command pageArray_AddHtmlImage @pageArray, imageURL, pCaptionText, pLinkURL
   if pageArray is not an array then return false
   if imageURL is  empty then return false
   if pCaptionText is empty then put "This is an image" into pCaptionText
   --
   -- put fedwiki_ConstructImageCaption (pCaptionText, pLinkURL, imageURL) into pCaptionText
   put _ConstructImageHtml (imageURL, pCaptionText, pLinkURL) into imageHTML
   pageArray_AddHtml pageArray, imageHTML
   return true
end pageArray_AddHtmlImage

function fedwiki_ConstructImageHtml encodedSrcURL, pCaption, pCaptionLinkURL, pEncodedImageLink
   put fedwiki_ConstructImageCaption (pCaption, pCaptionLinkURL, encodedSrcURL) into pCaptionText
   put _ConstructImageHtml (encodedSrcURL, pCaptionText, pEncodedImageLink) into imageHTML
   return imageHTML
end fedwiki_ConstructImageHtml

function fedwiki_ConstructThumbHtml encodedSrcURL, pCaption, pCaptionLinkURL, pEncodedImageLink
   put fedwiki_ConstructImageCaption (pCaption, pCaptionLinkURL, encodedSrcURL) into pCaptionText
   --
   put "class='item image ui-sortable-handle'" into divClassBit
   put "class='thumbnail' data-imagestyle='thumbwiki'" into imgStyleBit
   put _ConstructImageHtml (encodedSrcURL, pCaptionText, pEncodedImageLink, divClassBit, imgStyleBit) into someHTML
   return someHTML
end fedwiki_ConstructThumbHtml

function fedwiki_ConstructImageCaption pCaption, pCaptionLinkURL
   if pCaption is empty then
      put "This is an image" into pCaption
   else if the number of words of pCaption > 35 then
      put word 1 to 35 of pCaption & "..." into pCaption
   else
      put word 1 to -1 of pCaption into pCaption
   end if
   html_TopAndTailParagraphTags pCaption
   --
   if pCaptionLinkURL is empty then return pCaption
   if char -1 of pCaption = "." then delete char -1 of pCaption
   --
   put fedwiki_ExternalLink (pCaptionLinkURL) into externalLink
   put pCaption && "-" && externalLink into imageCaption
   --
   return imageCaption
end fedwiki_ConstructImageCaption

function fedwiki_InternalLink pageTitle
   return "[[" & word 1 to -1 of pageTitle & "]]"
end fedwiki_InternalLink

function fedwiki_ExternalLink linkURL, pLinkTag
   if pLinkTag is empty then
      put fedwiki_ConstructLinkTag (linkURL) into pLinkTag
   end if
   put "[" & linkURL && pLinkTag & "]" into externalLink
   return externalLink
end fedwiki_ExternalLink

command fedwiki_AddExternalLink @someText, pExtLinkURL, pHackHtml
   if char -1 of someText = "." then delete char -1 of someText
   --
   put md_ConstructExternalLinkLine (pExtLinkURL) into mdLinkLine
   --
   if pHackHtml is true then
      -- ...<p>It's only preliminary, folks.</p><img src="http://feeds.feedburner.com/~r/sciencealert-latestnews/~4/Bj-Ay6aCDOg" height="1" width="1" alt=""/>
      put "</p>" into ePara
      set the itemdelimiter to ePara
      if char -4 to -1 of someText = "</p>" then
         delete char -4 to -1 of someText
         _TrimFullStop someText, mdLinkLine
         put ePara after someText
      else if the number of items of someText > 1 then
         put item -1 of someText into lastBit
         delete item -1 of someText
         _TrimFullStop someText, mdLinkLine
         put ePara & lastBit after someText
      else
         _TrimFullStop someText, mdLinkLine
      end if
   else
      _TrimFullStop someText, mdLinkLine
   end if
   return linkTag
end fedwiki_AddExternalLink

function fedwiki_ConstructLinkTag someURL
   switch
      case someURL contains "twitter.com"
         return "twitter"
      case someURL contains "facebook.com"
         return "facebook"
      case someURL contains "bbc.co.uk"
         return "bbc"
      case someURL contains "listennotes.com"
         return "listen"
      case someURL contains "wikipedia.org"
         return "wikipedia"
      case someURL contains "wikimedia.org"
         return "wikimedia"
      default
         put html_ExtractTLD (someURL, true) into linkTag
         return linkTag
   end switch
end fedwiki_ConstructLinkTag


--> Private
-
private function _ConstructImageHtml encodedSrcURL, pCaptionText, pEncodedImageLink, pImgStyleBit, pDivClassBit
   if pDivClassBit is empty then put "style='padding: 12px; background:#eee; width:96%; align=centered;'" into pDivClassBit
   if pImgStyleBit is empty then put "data-imagestyle='fullwiki'; style='display:block; margin:auto; width:100%;'" into pImgStyleBit
   
   # Div header
   put "<div [[pDivClassBit]]>" & CR into htmlTemplate
   
   -- maybe add a link to the image
   if pImageLink is not empty then put "<a href='[[pEncodedImageLink]]' target='_blank'>" after htmlTemplate
   
   # Add image source
   put "<img [[pImgStyleBit]] src='[[encodedSrcURL]]'>" & CR after htmlTemplate
   
   # End imageLink
   if pImageLink is not empty then put "</a>" & CR after htmlTemplate
   
   # Add caption
   put "<p class=caption>" & CR&CR after htmlTemplate
   put "[[pCaptionText]]" & CR&CR after htmlTemplate
   
   # Add ending
   put "</p></div>" after htmlTemplate
   
   # Merge and return
   put merge (htmlTemplate) into someHTML
   return someHTML
end _ConstructImageHtml

private command _TrimFullStop @someText, linkBit
   put word 1 to -1 of someText into someText
   switch
      case char -3 to -1 of someText is "..."
      case char -2 to -1 of someText is ".."
         break
      case char -1 of someText is "."
         delete char -1 of someText
         break
   end switch
   put linkBit after someText
end _TrimFullStop
