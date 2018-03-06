script "Global_Splash_Menu"
--> MetaData
-
license: GPLv3
name: Global_Splash_Menu
type: controller
version: 0.2


--> Deps
-
command splash_WriteHtmlAndUpdateGit newHTML
   return empty
   
   put newHTML into url ("file:" & newHtmlFile)
   pullMe
   commitAll
   pushMe
end splash_WriteHtmlAndUpdateGit

function feast_Merge templateHTML, mergeArray
   return templateHTML
end feast_Merge

function _getTemplateHTML
   /*
   put "/var/www/html/system/application/rest.livecode.world/" into gAPPPATH
   put gAPPPATH & "controllers/feast/full_image_index_template.html" into templateFile
   put url ("file:" & templateFile) into templateHTML
   */
   put url "https://raw.githubusercontent.com/feastfm/feast-website/master/index-3.html" into someHTML
   return someHTML
end _getTemplateHTML

command fedwiki_ReturnJSON someJSON
   put json_ToArray (someJSON) into pageArray
   display_Array pageArray
end fedwiki_ReturnJSON

function _checkDroppedURL droppedURL
   if droppedURL is among the items of "http://david.feast.fm/view/welcome-visitors/view/feast,http://david.feast.fm/feast.html,http://david.feast.fm/feast.json" then
      return true
   else
      return false
   end if
end _checkDroppedURL

function _checkAuthoringStatus
   -- for security let's check a page only I can author
   put url "http://david.feast.fm/feast.json" into someJSON
   put json_ToArray (someJSON) into pageArray
   put fedwiki_ItemChecked (pageArray, "Allow website update") into checkedBoolean
   return checkedBoolean
end _checkAuthoringStatus

command _convertDroppedURL @droppedURL
   set the itemdelimiter to "."
   if item -1 of droppedURL is among the items of "json.html" then
      delete item -1 of droppedURL
   end if
   put ".json" after droppedURL
end _convertDroppedURL
  
function _getFeastFolder
   /*
   put $_SERVER ["DOCUMENT_ROOT"] & slash into webRootFolder
   put webRootFolder into feastFolder
   set the itemdelimiter to slash
   put "feast.fm" into item -1 of feastFolder
   */
   put "/var/www/feast.fm/" into feastFolder
   return feastFolder
end _getFeastFolder

command _SetTitleImageAndText pageArray, @pageTitle, @imageURL, @slideText
   put pageArray ["title"] into pageTitle
   put pageArray ["story"] into storyArray
   
   put storyArray [2] into textArray
   put textArray ["text"] into slideText
   
   put storyArray [1] into imageArray
   put imageArray ["text"] into imageHTML
   put html_ExtractImageSource (imageHTML) into imageURL
   
   if imageURL begins with "http://feast.fm/" then
      set the itemdelimiter to slash
      delete item 1 to 3 of imageURL
   end if
end _SetTitleImageAndText

function splash_FetchHtmlTemplate
   put url "https://raw.githubusercontent.com/feastfm/feast-website/master/index-3.html" into someHTML
   return someHTML
end splash_FetchHtmlTemplate


--> Global | Splash | Menu
-
on menu_TestFeast
   put "http://david.feast.fm/feast.json" into droppedURL
   put _getTemplateHTML() into templateHTML
   put "/var/www/feast.fm/index_test.html" into newHtmlFile
   --
   set the itemdelimiter to "?"
   put item 1 of droppedURL into droppedURL
   
   set the itemdelimiter to comma
   
   put _checkAuthoringStatus() into checkedBoolean
   put _checkDroppedURL (droppedURL) into urlOK
   
   if checkedBoolean and urlOK then
      _convertDroppedURL droppedURL
      
      put url droppedURL into someJSON
      put json_ToArray (someJSON) into pageArray
      
      _SetTitleImageAndText pageArray, pageTitle, imageURL, slideText
        
      put feast_Merge (templateHTML,mergeArray) into newHTML
      
      -- write out file
      splash_WriteHtmlAndUpdateGit newHTML
      --
      
      put "Image" && imageURL && "for wiki page" && kwote(pageTitle) & CR & CR & kwote(imageURL) & CR & CR & slideText into someInfo
      put fedwiki_ConstructErrorJSON (someInfo, "Updated Feast.fm Website!") into someJSON
   else
      put fedwiki_ConstructErrorJSON ("The dropped wiki page cannot be used for authoring.", "Not allowed") into someJSON
   end if
   fedwiki_ReturnJSON someJSON
end menu_TestFeast
 
on _
end _
   
on menu_TestFeastPush
   put url "https://rest.livecode.world/feast/write/pushMe" into someJSON
   put json_ToArray (someJSON) into someArray
   display_Array someArray
end menu_TestFeastPush

on menu_TestFeastPull
   put url "https://rest.livecode.world/feast/write/pullMe" into someJSON
   put json_ToArray (someJSON) into someArray
   display_Array someArray
end menu_TestFeastPull

on _
end _

on menu_TestWhoAmI
   put url "https://rest.livecode.world/feast/write/whoami" into someJSON
   put json_ToArray (someJSON) into someArray
   display_Array someArray
end menu_TestWhoAmI

on menu_TestConfigEmail
   put url "https://rest.livecode.world/feast/write/configEmail" into someJSON
   put json_ToArray (someJSON) into someArray
   display_Array someArray
end menu_TestConfigEmail

on menu_TestGitConfig
   put url "https://rest.livecode.world/feast/write/gitconfig" into someJSON
   put json_ToArray (someJSON) into someArray
   display_Array someArray
end menu_TestGitConfig

on menu_TestFeastCommit
   put url "https://rest.livecode.world/feast/write/commit" into someJSON
   put json_ToArray (someJSON) into someArray
   display_Array someArray
end menu_TestFeastCommit

on menu_TestFeastAdd
   put url "https://rest.livecode.world/feast/write/addAll" into someJSON
   put json_ToArray (someJSON) into someArray
   display_Array someArray
end menu_TestFeastAdd

on menu_TestFeastStatus
   put url "https://rest.livecode.world/feast/write/status" into someJSON
   put json_ToArray (someJSON) into someArray
   display_Array someArray
end menu_TestFeastStatus

on menu_TestMergeSlide
   put splash_FetchHtmlTemplate() into someHTML
   
   put splash_GetSlideArray (someHTML) into slideArray
   put "First Title" into slideArray [1]["title"]
   put "Hello <b>third</b> paragraph" into slideArray [3]["text"]
   display_Array slideArray
   
   splash_SetSlide someHTML, 1, "Hello Title", "This is some text"
   put splash_GetSlideTitle (someHTML, 1) into newTitle
   
   put newTitle & CR & someHTML
end menu_TestMergeSlide

on _
end _

on menu_ParseSplashPage
   local someArray
   
   put url "http://david.feast.fm/splash.json" into someJSON
   put json_ToArray (someJSON) into pageArray
   
   put pageArray ["story"] into storyArray
   put item 2 of the extents of storyArray into maxItemNum
   put "Intro" into slideNumOrTitle
   
   repeat with itemNum = 1 to maxItemNum
      put storyArray [itemNum] into itemArray
      
      switch itemArray ["type"]
         case "markdown"
            -- we only use markdown for new merge items
            put itemArray ["text"] into someMarkdown
            
            put line 1 of someMarkdown into markdownTitle
            if char 1 of markdownTitle is not "#" then
               breakpoint
               -- not sure what to do
               next repeat
            end if
            
            -- extract title
            delete char 1 of markdownTitle
            put word 1 to -1 of line 1 of markdownTitle into markdownTitle
            
            /*
            -- now let's extract any further markdown
            -- not used now as this markup does not look good
            
            delete word 1 of markdownTitle
            delete line 1 of someMarkdown
            repeat for each line someMarkdownLine in someMarkdown
               if word 1 to -1 of someMarkdownLine is empty then next repeat
               
               put someMarkdownLine into commentTitle
               exit repeat
            end repeat
            
            -- if word 1 of commentTitle = "-" and word 2 of commentTitle = "Slide" then
            */
            
            -- instead we use
            -- "text": "# Slide 1"
            
            if the number of words of markdownTitle = 2 and word 1 of markdownTitle = "Slide" and word 2 of markdownTitle is a number then
               -- treat as a "slide" section
               
               put word 2 of markdownTitle into slideNumOrTitle
               put markdownTitle into slideArray [slideNumOrTitle]["title"]               
            else
               breakpoint
               -- not sure what to do
               
               -- treat as an arbitrary title section
               put markdownTitle into slideNumOrTitle         
            end if
            break
         case "video"
            break
         case "audio"
            break
         case "image"
            break
         case "reference"
            /*
            -- go and fetch the reference page
            "site": "david.feast.fm",
            "slug": "feast",
            "title": "FEAST",
            */
            put itemArray ["site"] into tld
            put itemArray ["slug"] into referenceSlug
            put itemArray ["title"] into sectionTitle
            
            put _ProcessRefStoryArray (tld, referenceSlug) into slideArrayBit
            put slideArrayBit into slideArray [slideNumOrTitle]
            
            break
         default
            -- it does not matter if it is text or HTML (both are treaded the same as HTML)
            -- will be put in "Intro" section for first paragraphs (when slideNumOrTitle = "Intro"])
            -- after that slideNumOrTitle is a number
            
            put itemArray ["text"] into markdownText
            put markdownText into slideArray [slideNumOrTitle]["text"]
      end switch
      
   end repeat
   
   delete variable slideArray ["Intro"]
   display_Array slideArray
end menu_ParseSplashPage

on menu_ParseRefPage
   -- http://david.feast.fm/feast.json?random=315ed729
   put "david.feast.fm" into tld
   put "feast" into referenceSlug
   
   put splash_ProcessRefArray (tld, referenceSlug) into slideArrayBit
   
   display_Array slideArrayBit
end menu_ParseRefPage

on menu_LocalSlideArray mTarget
   /*
   answer file "Choose index.html file"
   put it into someFile
   */
   put "/Users/BabyBlue/Desktop/git-repos/feast-website/index-3.html" into someFile
   put url ("file:" & someFile) into someHTML
   
   put splash_GetSlideArray (someHTML) into slideArray
   put "First Title" into slideArray [1]["title"]
   put "Hello <b>third</b> paragraph" into slideArray [3]["text"]
   display_Array slideArray
   
   splash_SetSlide someHTML, 1, "Hello Title", "This is some text"
   put splash_GetSlideTitle (someHTML, 1) into newTitle
   
   put newTitle & CR & someHTML
end menu_LocalSlideArray

on _
end _

on menu_ParsePlayerFm
   revXMLDeleteAllTrees
   -- put url "https://player.fm/series/under-the-skin-with-russell-brand/015-yanis-varoufakis-how-to-construct-a-global-revolution" into someHTML
   -- put playerfm_FetchPodcastPageArray (someHtml) into pageArray
   
   put url "http://www.bbc.co.uk/programmes/b07gctb8" into someHTML
   -- put url "http://www.bbc.co.uk/programmes/b06nnqdl" into someHTML
   put bbc_FetchPodcastPageArray (someHtml) into pageArray
   
   display_Array pageArray
end menu_ParsePlayerFm

on menu_ParseOneTab
   put "https://www.one-tab.com/page/VecNztSjSAuL_u_UiaXMjw" into oneTabUrl
   put onetab_FetchPageArray (oneTabUrl) into pageArray
   display_Array pageArray
end menu_ParseOneTab

on _
end _

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Global | Splash | Menu | Props
-

--> Global | Splash | Menu | Disabled
-

--> Dev | Menu
-
on menu_TestCheckmark
   /*
   # Authoring Tools
   
   This is an experimental section that enables us to update the Feast.fm web site - [https://feast.fm feast.fm]
   
   - [x] Allow website update
   */   
   put url "http://david.feast.fm/feast.json" into someJSON
   put json_ToArray (someJSON) into pageArray
   
   _SetTitleImageAndText pageArray, pageTitle, imageURL, slideText
   
   put imageURL
   
   put fedwiki_ItemChecked (pageArray, "Allow website update") into someBoolean
   
   put someBoolean
   display_Array pageArray
end menu_TestCheckmark

on menu_Test
   put "https://rest.livecode.world/test" into someURL
   put url someURL into someJSON
   put json_ToArray (someJSON) into pageArray
   
   display_Array pageArray
end menu_Test

on menu_TestImageSource
   put "fads  <img width=100% src='http://feast.fm/assets/images/refugee_feast_close.jpg' alt='Test'/> sdfafds" into htmlBit
   -- replace "'" with quote in htmlBit
   put html_ExtractImageSource (htmlBit)
end menu_TestImageSource


--> Deps
-
function onetab_FetchPageArray oneTabUrl, pType
   put url oneTabUrl into someHtml
   --
   -- 
   html_Tidy someHtml
   put revXMLCreateTree (someHTML, false, true, false) into treeID
   --
   put revXMLRootNode (treeID) into rootNode
   put word 1 to -1 of revXMLNodeContents (treeID, "/html/head/title") into htmlTitle   
   put word 1 to -1 of revXMLNodeContents (treeID, "/html/body/div[1]/div[6]") into tabTitle
   
   put "Below are a collection of links imported from [[OneTab]]. You can view these links here - [" & oneTabUrl && "one-tab.com]:" into headerBit
   put fedwiki_ConstructNewPageArray (tabTitle, headerBit) into pageArray
   
   put "vertical-align: middle; width:16px; height:16px" into faviconStyle
   put "vertical-align: middle; padding-left: 10px; padding-right: 12px; text-decoration: none;" into someLinkstyle
   put "<img src='[[faviconURL]]' style='[[faviconStyle]]' /><a target=_blank style='[[someLinkstyle]]' href='[[someTextURL]]'>[[someTextLink]]</a>" into linkTemplate
   
   put "<div style='padding-left: 24px; padding-top: 8px; position: relative; font-size: 13px;'>" into divStart
   
   put revXMLChildNames (treeID, "/html/body/div[1]", CR, "div", true) into tNames
   repeat with divNum = 7 to (the number of lines of tNames - 1)
      put "/html/body/div[1]/div[" & divNum & "]" into someNode
      -- put revXMLText (treeID, someNode, true) into someDiv
      
      put someNode & "/img" into imgNode
      put revXMLAttribute (treeID, imgNode, "src") into faviconURL
      
      put someNode & "/a" into aNode
      put revXMLAttribute (treeID, aNode, "href") into someTextURL
      put revXMLNodeContents (treeID, aNode) into someTextLink
      replace CR with space in someTextLink
      
      set the itemdelimiter to slash
      put item 3 of someTextURL into tldBit
      -- replace "www." with empty in tldBit
      set the itemdelimiter to "."
      put item -2 to -1 of tldBit into tldBit
      set the itemdelimiter to ","
      
      put "-" && someTextLink && "- [" & someTextURL && tldBit & "]" into markDownLink
      put CR & markDownLink after markDownLinks
      
      -- let's create new HTML
      -- faviconURL, someTextURL, someTextLink
      put merge (linkTemplate) into htmlLine
      put divStart & htmlLine & "</div>" into divBit
      put divBit & CR after divSection
      
      -- put someDiv & CR & CR after divSection      
   end repeat
   --
   revDeleteXMLTree treeID
   -- delete char -2 to -1 of divSection
   
   switch pType
      case "markdown"
         put "#" && tabTitle & CR & markDownLinks into someMarkDown
         fedwiki_AddMarkdownToPageArray pageArray, someMarkDown
         break
      default -- html
         put "<h3>" & tabTitle & "</h3>" & CR into divHeader
         put headerBit & "<p>" & CR after divHeader
         put divHeader before divSection
         fedwiki_AddHtmlToPageArray pageArray, divSection
   end switch
   
   fedwiki_CleanJournalArray pageArray
   return pageArray
end onetab_FetchPageArray

function onetab_FetchPageArray oneTabUrl
   put url oneTabUrl into someHtml
   --
   html_Tidy someHtml
   put revXMLCreateTree (someHTML, false, true, false) into treeID
   --
   put revXMLRootNode (treeID) into rootNode
   put word 1 to -1 of revXMLNodeContents (treeID, "/html/head/title") into htmlTitle
   put word 1 to -1 of revXMLNodeContents (treeID, "/html/body/div[1]/div[6]") into tabTitle
   
   put "Below are a collection of links imported from [[OneTab]]. You can view these links here - [" & oneTabUrl && "one-tab.com]:" into headerBit
   put fedwiki_ConstructNewPageArray (tabTitle, headerBit) into pageArray
   
   put revXMLChildNames (treeID, "/html/body/div[1]", CR, "div", true) into tNames
   repeat with divNum = 7 to (the number of lines of tNames - 1)
      put "/html/body/div[1]/div[" & divNum & "]" into someNode
      put revXMLText (treeID, someNode, true) into someDiv
      put someDiv & CR & CR after divSection
      
      put someNode & "/img" into imgNode
      put revXMLAttribute (treeID, imgNode, "src") into thumbImageUrl
      
      put someNode & "/a" into aNode
      put revXMLAttribute (treeID, aNode, "href") into someTextURL
      put revXMLNodeContents (treeID, aNode) into someTextLink
      replace CR with space in someTextLink
      
      set the itemdelimiter to slash
      put item 3 of someTextURL into tldBit
      -- replace "www." with empty in tldBit
      set the itemdelimiter to "."
      put item -2 to -1 of tldBit into tldBit
      set the itemdelimiter to ","
      
      put "-" && someTextLink && "- [" & someTextURL && tldBit & "]" into markDownLink
      put CR & markDownLink after markDownLinks
   end repeat
   --
   revDeleteXMLTree treeID
   delete char -2 to -1 of divSection
   
   put "<h3>" & tabTitle & "</h3>" & CR into divHeader
   put headerBit & "<p>" & CR after divHeader
   
   put divHeader before divSection
   
   put "# OneTab Links" & CR & markDownLinks into someMarkDown
   fedwiki_AddMarkdownToPageArray pageArray, someMarkDown
   
   -- fedwiki_AddMarkdownToPageArray pageArray, "# OneTab HTML Links"
   fedwiki_AddHtmlToPageArray pageArray, divSection
   
   fedwiki_CleanJournalArray pageArray
   return pageArray
end onetab_FetchPageArray

function bbc_FetchPodcastPageArray someHtml, pURL
   html_Tidy someHtml
   put revXMLCreateTree (someHTML, false, true, false) into treeID
   --
   put revXMLRootNode (treeID) into rootNode
   
   -- no longer works
   -- put revXMLMatchingNode (treeID, rootNode, "div", "class", "buttons__download", -1, false) into divNode
   --  put revXMLAttributeValues (treeID, divNode, "a", "href", CR, 1) into audioURL
   
   -- this is a real hack as the tree seems utterly broken   
   put revXMLMatchingNode (treeID, rootNode, "div", "id", "orb-modules", -1, false) into orbModulesNode
   put revXMLMatchingNode (treeID, orbModulesNode, "div", "class", "br-container__inner", -1, false) into innerNode
   put innerNode & "/div[2]" into mainContentNode
   put revXMLMatchingNode (treeID, mainContentNode, "ul", "class", "list-unstyled popup__list", -1, false) into ulNode
   
   if ulNode is empty then
      -- no download link
      put empty into audioURL
   else  
      put ulNode & "/li[1]/a" into aNode
      put revXMLAttribute (treeID, aNode, "href") into audioURL
      put revXMLAttribute (treeID, aNode, "download") into downloadURL
   end if
   
   put revXMLNodeContents (treeID, "html/head/title") into htmlTitle
   scrapeID_OpenGraph treeID, htmlTitle, imageURL, podcastDescription, pageURL
   
   put revXMLMatchingNode (treeID, rootNode, "div", "property", "description", -1, false) into divNode
   if divNode is not empty then
      -- probably better to loop through every <p> child element
      put revXMLText (treeID, divNode, true) into podcastDescription
   end if
   --
   revDeleteXMLTree treeID
   
   put item -1 of htmlTitle into pageTitle
   
   replace CR with space in podcastDescription
   replace "</p>" with CR in podcastDescription
   text_StripTags podcastDescription
   
   --                  Show more       /       Show less
   get line -1 of podcastDescription
   if word 1 to 2 of it = "Show more" and word -2 to -1 of it = "Show less" then
      delete line -1 of podcastDescription
   end if
   put word 1 to -1 of line 1 of podcastDescription into firstPara
   
   if pURL is not empty then
      -- set the itemdelimiter to slash
      -- put item 2 of pURL into domainBit
      put space & "- [" & pURL && "bbc]" after firstPara
   end if
   
   put podcast_ConstructPageArray (pageTitle, audioURL, imageURL, firstPara, podcastDescription, htmlTitle) into pageArray
   return pageArray
end bbc_FetchPodcastPageArray

function playerfm_FetchPodcastPageArray someHtml, pURL
   -- /html/body/div[2]/div[4]/div/div/div[2]/div/div/div/div[2]/div[2]/div[2]/a
   -- class="play-prompt playable button"
   
   /*
   <a class="play-prompt playable button" data-handled="true" href="http://rss.art19.com/episodes/2100c23b-4c08-4935-bb70-cc9bfb74e55c.mp3">
   </a>
   */
   
   html_Tidy someHtml
   put revXMLCreateTree (someHTML, false, true, false) into treeID
   --
   put revXMLRootNode (treeID) into rootNode
   
   put revXMLMatchingNode (treeID, rootNode, "a", "class", "play-prompt playable button", -1, false) into aNode
   put revXMLAttribute (treeID, aNode, "href") into audioURL
   
   put revXMLNodeContents (treeID, "html/head/title") into htmlTitle
   
   put revXMLMatchingNode (treeID, rootNode, "div", "class", "description prose cleanslate", -1, false) into divNode
   put revXMLNodeContents (treeID, divNode) into podcastDescription
   replace CR with space in podcastDescription
   
   -- scrapeID_OpenGraph treeID, htmlTitle, imageURL, podcastDescription, pageURL
   --
   revDeleteXMLTree treeID
   
   put "Test" into pageTitle
   put empty into imageURL
   put empty into firstPara
   
   set the itemdelimiter to "-"
   put item 1 of htmlTitle into pageTitle
   if char 1 of pageTitle = "#" then delete word 1 of pageTitle
   put word 1 to -1 of pageTitle into pageTitle
   
   put line 1 of podcastDescription into firstPara
   delete line 1 of podcastDescription
   
   put podcast_ConstructPageArray (pageTitle, audioURL, imageURL, firstPara, podcastDescription, htmlTitle) into pageArray
   return pageArray
end playerfm_FetchPodcastPageArray

function podcast_ConstructPageArray pageTitle, audioURL, imageURL, firstPara, podcastDescription, audioDescription
   put fedwiki_ConstructNewPageArray (pageTitle, firstPara) into pageArray
   if imageURL is not empty then
      put fedwiki_ConstructImageDiv (imageURL) into imageHTML
      fedwiki_AddHtmlToPageArray pageArray, imageHTML
   end if
   
   repeat with lineNum = 2 to the number of lines of podcastDescription
      put word 1 to -1 of line lineNum of podcastDescription into somePara
      fedwiki_AddParagraphToPageArray pageArray, somePara
   end repeat
   fedwiki_AddAudioToPageArray pageArray, audioURL, audioDescription
   fedwiki_CleanJournalArray pageArray
   return pageArray
end podcast_ConstructPageArray

private function _ProcessStoryItem storyArray
   -- helper to construct slideArray
   
   put item 2 of the extents of storyArray into maxItemNum
   repeat with itemNum = 1 to maxItemNum
      put storyArray [itemNum] into itemArray
      switch itemArray ["type"]
         case "markdown"
            break
         case "reference"
            -- let's not recurse fetching reference items
            -- not sure what to do 
            next repeat -- so let's ignore
         case "html"
            /*
            <img width=100% src="http://feast.fm/assets/images/refugee_feast_close.jpg">
            */
            put itemArray ["text"] into htmlBit
            
            -- let's see if it is a simple image
            -- is it the htmlBit item
            if word 1 of dafs = "<img" then
               put html_ExtractImageSource (htmlBit) into srcURL
            else
               -- let's treat it like plain html
               put htmlBit into slideArray [slideNumOrTitle]["text"]
            end if
            break
         case "video"
            break
         case "audio"
            break
         case "image"
            break
         default
            -- it does not matter if it is text or HTML (both are treaded the same as HTML)
            -- will be put in "Intro" section for first paragraphs (when slideNumOrTitle = "Intro"])
            -- after that slideNumOrTitle is a number
            
            put itemArray ["text"] into markdownText
            put markdownText into slideArray [slideNumOrTitle]["text"]
      end switch
   end repeat
end _ProcessStoryItem

command _SetTitleImageAndText pageArray, @pageTitle, @imageURL, @slideText
   put pageArray ["title"] into pageTitle
   put pageArray ["story"] into storyArray
   
   put storyArray [2] into textArray
   put textArray ["text"] into slideText
   
   put storyArray [1] into imageArray
   put imageArray ["text"] into imageHTML
   put html_ExtractImageSource (imageHTML) into imageURL
   if imageURL begins with "http://feast.fm/" then
      set the itemdelimiter to slash
      delete item 1 to 3 of imageURL
   end if
end _SetTitleImageAndText
