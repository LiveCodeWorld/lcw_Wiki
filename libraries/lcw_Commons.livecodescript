script "lcw_Commons"
--> MetaData
-
license: GPLv3
name: lcw_Commons
type: library
version: 0.1


--> Mediawiki | Image | Not Working
-
function wikipedia_ListImageRepos
   local pApiStem
   put wikpedia_FetchPageImageSandboxArray ("File:Twttr_sketch-Dorsey-2006.jpg", pApiStem) into queryArray
   put queryArray ["query"]["pages"] into pageListArray
   put line 1 of the keys of pageListArray into pageID
   put pageListArray [pageID] into pageArray
   
   put pageArray ["pageimage"] into shortImageFile
   put pageArray ["thumbnail"]["source"] into thumbNailURL
   put pageArray ["thumbnail"]["width"] into thumbNailWidth
   
   put queryArray ["query"]["repos"] into repoListArray
   repeat for each line repoNum in the keys of repoListArray
      put repoListArray [repoNum]["rootUrl"] into rootUrl
      put repoListArray [repoNum]["thumbUrl"] into repoThumbRootUrl
      put repoListArray [repoNum]["url"] into someUrl -- ???
      
      /*
      -- no idea how to construct the url from the available information
      
      put "https://" & rootURL & "/" & shortImageFile into imageURL
      put url imageURL into someImage
      
      put "https://" & repoThumbRootUrl & "/" & shortImageFile into thumbURL
      put url thumbURL into thumbImage
      */
      
      put repoListArray [repoNum]["displayName"] into displayName
      switch displayName
         case "Wikimedia Commons"
            -- https://upload.wikimedia.org/wikipedia/en/9/9f/Twitter_bird_logo_2012.svg
            break
         case "Wikipedia"
            break
         default
            -- do nothing
      end switch  
   end repeat
end wikipedia_ListImageRepos

function wikpedia_FetchPageImageSandboxArray pageTitle, pApiStem
   put "/w/api.php?action=query&format=json&uselang=de&prop=pageimages&meta=filerepoinfo%7Cwikibase&titles=" into sandBoxFragment
   put urlencode (pageTitle) after sandBoxFragment
   put "&iiprop=" & "comment|url|dimensions|size|sha1|metadata|extmetadata|thumbmime" after sandBoxFragment
   put "&iiurlwidth=420" after sandBoxFragment
   put "&redirects=1" after sandBoxFragment
   
   put mediawiki_GetSandboxJSON (sandBoxFragment, pApiStem) into someJSON
   put json_ToArray (someJSON) into sandboxArray
   return sandboxArray
end wikpedia_FetchPageImageSandboxArray


--> Mediawiki | Image
-
function mediawiki_ExtractFirstInterestingImage imageArray
   put mediawiki_ListBuiltInImages() into mediaWikiImageList
   repeat with itemNum = 1 to (item 2 of the extents of imageArray)
      put imageArray [itemNum] into shortImageFile
      if shortImageFile is not among the items of mediaWikiImageList then
         return shortImageFile
      end if
   end repeat
   return empty
end mediawiki_ExtractFirstInterestingImage

function mediawiki_ListPageImages pageTitle, pApiStem
   put "/w/api.php?action=query&prop=images&format=json&imlimit=100&titles=" & urlencode (pageTitle) into sandBoxFragment
   put mediawiki_GetSandboxArray (sandBoxFragment, pApiStem) into sandboxArray
   put sandboxArray ["query"]["pages"] into pagesArray
   set the itemdelimiter to ":"
   repeat for each key pageID in pagesArray
      put pagesArray [pageID]["images"] into imagesArray
      put the number of lines of keys(imagesArray) into maxNum
      repeat with imageNum = 1 to maxNum
         put imagesArray [imageNum]["title"] into shortFileBit
         delete item 1 of shortFileBit -- what if it si not an image file???
         put shortFileBit & CR after shortFileBits
      end repeat
   end repeat
   delete char -1 of shortFileBits
   return shortFileBits
end mediawiki_ListPageImages

function mediwiki_ExtractImageFileFromUrl someUrl
   -- https://en.wikipedia.org/wiki/Alexanderplatz#/media/File:Alexanderplatz_in_Berlin_-_Panorama.jpg
   -- https://commons.wikimedia.org/wiki/File:Alexanderplatz_in_Berlin_-_Panorama.jpg#file
   -- https://en.wikipedia.org/wiki/File:Asger_Jorn_(1963)_by_Erling_Mandelmann.jpg
   -- https://en.wikipedia.org/wiki/Alexanderplatz#/media/File:Alexanderplatz_in_Berlin_-_Panorama.jpg
   -- https://en.wikipedia.org/wiki/Cat#/media/File:AfricanWildCat.jpg
   
   set the itemdelimiter to "/"
   put item -1 of someURL into fileItem
   put item -2 of someURL into mediaItem
   
   switch
      case item -1 of someURL begins with "File:"
       case someURL begins with "https://commons.wikimedia.org/wiki/File:"
      case mediaItem = "media" and someURL contains ".wikipedia.org/wiki/"
         put mediawiki_ExtractShortImageFile (someUrl) into shortImageFile
         return shortImageFile
      default
         -- too complicated and not needed?
         url_Deconstruct someUrl, someProtocol, urlDomain, urlPath, shortName, fileExtension, uName, pWord
         if urlDomain ends with ".wikipedia.org" is false then return empty
         
         if item -1 of urlPath is not among the items of "media/wiki" then return empty
         set the itemdelimiter to ":"
         if item 1 of shortName is not "File" then return empty
         
         put item 2 of shortName & "." & fileExtension into shortFile
         return shortFile
   end switch
end mediwiki_ExtractImageFileFromUrl

function mediawiki_ExtractShortImageFile someUrl
   -- no testing
   set the itemdelimiter to "/"
   put item -1 of someURL into shortImageFile
   set the itemdelimiter to "#"
   put item 1 of shortImageFile into shortImageFile
   if char 1 to 5 of shortImageFile = "File:" then
      delete char 1 to 5 of shortImageFile
   end if
   return shortImageFile
end mediawiki_ExtractShortImageFile

function wikipedia_FetchPageImageInfo pageTitle, pApiStem
   -- /w/api.php?action=query&
   -- prop=pageimages
   -- &format=json
   -- &piprop=thumbnail%7Cname%7Coriginal
   -- &titles=San_Francisco
   
   put "piprop=thumbnail|name|original" into pOtherBits
   put mediawiki_FetchPageBits (pageTitle, "pageimages", pOtherBits, pApiStem) into someJSON
   return someJSON
end wikipedia_FetchPageImageInfo

function wikipedia_FetchPageImages pageTitle, pApiStem
   -- /w/api.php?action=query&prop=images&format=json&titles=Albert%20Einstein
   put mediawiki_FetchPageBits (pageTitle, "images", empty, pApiStem) into someJSON
   return someJSON
end wikipedia_FetchPageImages

function wikimedia_ListImages fromName, pFormat
   -- this does not seem to return good lists of images
   -- lot's of dodgy characters = spam? in file names etc?
   -- api.php?action=query&list=allimages&ailimit=5&aifrom=Albert&aiprop=dimensions|mime [try in ApiSandbox]
   put "Albert Einstein" into fromName
   put "IndustrialSymbiosisWasteHeatExchange.png" into shortImageFile
   if pFormat is empty then put "json" into pFormat
   
   put "?action=query&list=allimages&format=[[pFormat]]" into urlPattern
   -- put "&aifrom=[[fromName]]&ailimit=5&aiprop=dimensions|mime" after urlPattern
   put "&titles=Image:[[shortImageFile]]" after urlPattern
   
   put wikimedia_GetApiRoot() & merge (urlPattern) into someURL
   -- if pExtraProps is not empty then put "&" & pExtraProps after someURL
   
   put url someURL into someJSON
   return someJSON
end wikimedia_ListImages
