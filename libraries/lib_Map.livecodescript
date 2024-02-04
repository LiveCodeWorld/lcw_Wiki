script "lib_Map"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_Map
type: library
version: 0.1

/*
This library is for creating wiki maps.
it is used by the Map Transport
*/


--> Working on
-
command pageArray_AddMap @pageArray, mapText, pMapLat, pMapLong, pMapZoom, pPinText, pTileType, pID
   if mapText is empty then put "Map" into mapText
   
   # Create basic itemArray
   itemArray_NormalizeID pID
   put pID into itemArray ["id"]
   put "map" into itemArray ["type"]
   put mapText into itemArray ["text"]
   
   # Add lat+long
   if pMapLat is not empty then
      put pMapLat into itemArray ["latlng"]["lat"]
      put pMapLong into itemArray ["latlng"]["lng"]
   end if
   
   # Add pin
   if pPinText is not empty then
      -- "text": "Map\n52.207483, 0.115771 Master's Garden"
      put CR & mapLat & comma && mapLong && pPinText after mapText
   end if
   
   # Add Zoom
   if pMapZoom is not empty then
      put pMapZoom into itemArray ["zoom"]
   end if
   --
   itemArray_Add itemArray, pageArray
   return the result
end pageArray_AddMap


--> PageArray | Map
-
function pageArray_ConstructMapAndImage imageURL, pPageTitle, pImageCaption, pPageDescription, pLinkURL, pTileType
   if pImageCaption is empty then put "This is a [[full width image]]" into pImageCaption
   --
   put imageMagick_FetchIdentity (imageURL) into identityInfo
   put imageMagick_ExtractExifArray (identityInfo) into gpsArray
   map_DeconstructGpsArray gpsArray, mlat, mlon, mZoom
   --
   put wikiPage_Image (imageURL, pPageTitle, pPageDescription, pLinkURL, pImageCaption) into pageArray
   --
   if the result is false then
      put "This image does not have exif geolocation data." into someMarkDown
      pageArray_AddMarkdown pageArray, someMarkDown
   else
      pageArray_AddMarkdown pageArray, "This map shows location where the image was taken accordng to its embedded location data."
      pageArray_AddMap pageArray, "This image was taken near here", mlat, mlon, mZoom, pImageCaption
   end if
   --
   pageArray_AddPagefold pageArray, "Metadata"
   pageArray_AddMarkdown pageArray, "Below we list all the embedded metadata in this image:."
   pageArray_AddCode pageArray, identityInfo
   --
   return pageArray
end pageArray_ConstructMapAndImage

command pageArray_AddImageMetadata @pageArray, imageURL, pMapDescription
   pageArray_AddPagefold pageArray, "Metadata"
   put imageMagick_FetchIdentity (imageURL) into imageInfo
   put imageMagick_ExtractExifArray (imageInfo) into exifArray
   
   put exifArray ["GPSAltitude"] into gpsAltitude
   put exifArray ["GPSLatitude"] into gpsLatitude
   --
   if gpsLatitude is not empty then then
      put exifArray ["GPSLatitudeRef"] into gpsLatitudeRef
      put geo_ConvertGpsLatitude (gpsLatitude, gpsLatitudeRef) into mlat
      
      put exifArray ["GPSLongitude"] into gpsLongitude
      put exifArray ["GPSLongitudeRef"] into gpsLongitudeRef
      -- put exifArray ["gpsAltitude"] into gpsAltitude
      put geo_ConvertGpsLongitude (gpsLongitude, gpsLongitudeRef) into mlon
      --
      if pMapDescription is empty then
         put "This image was taken near this location." into pMapDescription
      end if
      put 15 into mZoom
      pageArray_AddMap pageArray, pMapDescription, mlat, mlon, mZoom
   end if
   --
   put "Below you can see all the metadata that we find embedded in the image:" into someMarkdown
   pageArray_AddMarkdown pageArray, someMarkdown   
   pageArray_AddCode pageArray, imageInfo   
end pageArray_AddImageMetadata

function pageArray_ConstructMap mlat, mlon, exifArray
   put "Here is a newly imported image. You can find the original here" into imageCaption
   if exifArray is an array then
      put CR & "<p>" & CR & geo_ConstructHgeo (mlon, mlat) after imageCaption
   end if
   
   put pageArray_Construct (pageTitle, imageDescription) into pageArray
   
   -- add the image
   put fedwiki_ConstructImageHtml (assetURL, imageCaption, assetURL, "- source") into imageHTML
   pageArray_AddHtml pageArray, imageHTML
   
   -- if there is GPS info add a map
   if exifArray is an array then
      put 16 into mZoom
      --
      put openStreetMap_ConstructUrl (mLat, mLon, mZoom) into openstreetmapURL
      put "[[" & item 1 of locationDescription & "]]" into item 1 of locationDescription
      
      put locationDescription && "- [" & openstreetmapURL && "openstreetmap]" into mapText
      --
      map_AddPinLine mapText, mLat, mLon, pinTitle
      --
      pageArray_AddMap pageArray, mapText, mlat, mlon, mZoom
   else
      put "Image Test" into pageArray ["title"]
   end if
   
   pageArray_CleanJournal pageArray
   --
   return pageArray
end pageArray_ConstructMap


--> Map
-
command map_AddPinLine @mapText, mLat, mLon, pinTitle
   put map_ConstructPinLine (mLat, mLon, pinTitle) into pinLine
   put CR & pinLine after mapText
end map_AddPinLine

function map_ConstructPinLine mLat, mLon, pinTitle
   put mLat & comma & mLon && pinTitle into pinLine
   return pinLine
end map_ConstructPinLine

command map_DeconstructGpsArray gpsArray, @mlat, @mlon, @mZoom
   put empty into mlat
   put empty into mlon
   put empty into mZoom
   put gpsArray ["GPSLatitude"] into gpsLatitude
   if gpsLatitude is empty then return false
   
   put gpsArray ["GPSLatitudeRef"] into gpsLatitudeRef
   put geo_ConvertGpsLatitude (gpsLatitude, gpsLatitudeRef) into mlat
   
   put gpsArray ["GPSLongitude"] into gpsLongitude
   put gpsArray ["GPSLongitudeRef"] into gpsLongitudeRef
   put geo_ConvertGpsLongitude (gpsLongitude, gpsLongitudeRef) into mlon
   
   set the itemdelimiter to slash
   put gpsArray ["GPSAltitude"] into gpsAltitude
   try
      put item 1 of gpsAltitude / item 2 of gpsAltitude into mZoom
      if gpsLatitude is empty then
         return false
      else
         return true
      end if
   catch e
      put empty into mZoom
      return false
   end try
end map_DeconstructGpsArray


--> Wmflabs
-
command wmflabs_ReturnPageArray pageName, geoInfo
   -- put "https://tools.wmflabs.org/geohack/geohack.php?pagename=Harringay&params=51.5819_N_-0.0994_E_region:GB_type:city(13272)" into droppedURL
   -- put "https://tools.wmflabs.org/geohack/geohack.php?pagename=Bilbao&params=43_15_25_N_2_55_25_W_region:ES_type:city" into droppedURL
   --
   put urldecode (pageName) into pageName
   replace "_" with space in pageName
   put "Map of" && pageName into pageTitle
   put pageName into pinTitle
   --         
   geo_ExtractLatLong geoInfo, mLat, mLon, regionInfo
   --
   if mLat is not a number or mLat is not a number then
      transport_ExitAndReturnError ("Problem parsing map data" && geoInfo,mLat,mLon), "Error"
      exit to top
   end if
   put 15 into mZoom -- should work out from regionInfo
   --
   put "http://www.openstreetmap.org/#map=" & mZoom & "/" & mLat & "/" & mLon into openstreetmapURL
   put "This is a map of [[" & pageName & "]]" into mapText
   put mapText && "- [" & openstreetmapURL && "openstreetmap]" into mapDescription
   --
   put openStreetMap_FetchPageArray (pageTitle, mLat, mLon, mZoom, mapDescription, pinTitle) into pageArray
   --
   transport_ReturnPageArray pageArray
end wmflabs_ReturnPageArray


--> OpenStreetMap
-
function openStreetMap_ConstructUrl mLat, mLon, mZoom
   put "http://www.openstreetmap.org/#map=" & mZoom & "/" & mLat & "/" & mLon into openstreetmapURL
   return openstreetmapURL
end openStreetMap_ConstructUrl

function openStreetMap_FetchWikipediaMapPageArray wikiSlug, pMapDescription
   put wikipedia_FetchPageGeolocation (wikiSlug) into geoCoords
   if geoCoords is empty then
      transport_ReturnError "Error", "Wikipedia page has no map coordinates!"
   end if
   --
   put item 1 of geoCoords into mLat
   put item 2 of geoCoords into mLon
   put item 3 of geoCoords into pageTitle
   
   put "[[" & pageTitle & "]]" into pinTitle
   put 13 into mZoom
   put openStreetMap_FetchPageArray (pageTitle, mLat, mLon, mZoom, pMapDescription, pinTitle) into pageArray
   --
   return pageArray
end openStreetMap_FetchWikipediaMapPageArray

command openStreetMap_ReturnPageArray droppedURL
   -- https://www.openstreetmap.org/?mlat=48.39&mlon=-4.49&zoom=12#map=12/48.3900/-4.4900
   -- https://www.openstreetmap.org/?mlat=50.933333&mlon=-2.733333&zoom=12#map=16/50.9333/-2.7333
   --
   set the itemdelimiter to "#"
   put item 1 of droppedURL into possiblyTitle
   put item 2 of droppedURL into afterHashBit
   if possiblyTitle contains "search?query=" then
      set the itemdelimiter to "="
      get item -1 of possiblyTitle
      put urldecode (it) into pageTitle
      put "OpenStreetMap of" && pageTitle into mapDescription
      put pageTitle into pinTitle
   else
      put "Somewhere" into pageTitle
      put "OpenStreetMap of somewhere" into mapDescription
      put "Some place" into pinTitle
   end if
   --
   set the itemdelimiter to "="
   get item -1 of afterHashBit
   set the itemdelimiter to slash
   put item 1 of it into mZoom
   put item 2 of it into mLat
   put item 3 of it into mLon
   --
   put "http://www.openstreetmap.org/#map=" & mZoom & "/" & mLat & "/" & mLon into openstreetmapURL
   put " - [" & openstreetmapURL && "openstreetmap]" after mapDescription
   --
   put openStreetMap_FetchPageArray (pageTitle, mLat, mLon, mZoom, mapDescription, pinTitle) into pageArray
   --
   transport_ReturnPageArray pageArray
end openStreetMap_ReturnPageArray

function openStreetMap_FetchPageArray pageTitle, mlat, mlon, mZoom, pMapDescription, pPinTitle
   -- this is for a map drop from openstreetmap or equivalent
   if pPinTitle is empty then put pageTitle into pinTitle
   put mLat & comma & mLon && pPinTitle into pinLine
   put CR & pinLine after pMapDescription
   put geo_ConstructHgeo (mlon, mlat) into hgeoHTML
   
   -- create a page and description
   put pageArray_Construct (pageTitle, pMapDescription) into pageArray
   pageArray_AddMap pageArray, pMapDescription, mlat, mlon, mZoom
   --
   pageArray_CleanJournal pageArray
   return pageArray
end openStreetMap_FetchPageArray


--> GoogleMaps
-
command googleMaps_ReturnPageArray droppedURL
   -- should use a regular expression to catch all international maps
   -- https://www.google.com/maps/place/Funkhaus+Berlin+Nalepastrasse/@52.479543,13.500279,11z/data=!4m5!3m4!1s0x0:0x163f2116c5300be2!8m2!3d52.4795432!4d13.5002786?hl=en-GB
   set the itemdelimiter to slash
   put urldecode (item 6 of droppedURL) into placeName
   --
   get item 7 of droppedURL
   -- @52.479543,13.500279,11z
   delete char 1 of it
   set the itemdelimiter to comma
   put item 1 of it into mlat
   put item 2 of it into mlon
   put item 3 of it into mZoom
   
   -- hack
   delete char -1 of mZoom
   put "Google Map of" && placeName into mapDescription
   put placeName into pageTitle
   --
   put pageTitle && "- [" & droppedURL && "google]" into mapDescription 
   
   put pageTitle into pinTitle
   put geo_ConstructHgeo (mlon, mlat) into hgeoHTML
   put pageArray_Construct (pageTitle, mapDescription) into pageArray
   --
   put openStreetMap_ConstructUrl (mLat, mLon, mZoom) into openstreetmapURL
   put "[[" & pinTitle & "]]"  && "- [" & openstreetmapURL && "openstreetmap]" into mapText
   put space & "Also view on" && "- [" & droppedURL && "google]" after mapText
   --
   map_AddPinLine mapText, mLat, mLon, pinTitle
   --
   pageArray_AddMap pageArray, mapText, mlat, mlon, mZoom
   pageArray_CleanJournal pageArray
   --
   transport_ReturnPageArray pageArray
end googleMaps_ReturnPageArray


--> Geo
-
function geo_ConvertGpsLongitude gpsLongitude, gpsLongitudeRef
   --  51/1, 33/1, 5798/100
   set the itemdelimiter to slash
   set the linedelimiter to comma
   --
   try
      get line 1 of gpsLongitude
      put item 1 of it / item 2 of it into someDegrees
      --
      get line 2 of gpsLongitude
      put item 1 of it / item 2 of it into someMinutes
      --
      get line 3 of gpsLongitude
      put item 1 of it / item 2 of it into someSeconds
      
      put geo_DmsToDecimal (someDegrees, someMinutes, someSeconds, gpsLongitudeRef) into decLat
      --
      return decLat
   catch e
      return "Error, gpsLongitude is invalid:" && gpsLongitude
   end try
end geo_ConvertGpsLongitude

function geo_ConvertGpsLatitude gpsLatitude, gpsLatitudeRef
   --  51/1, 33/1, 5798/100
   try
      set the itemdelimiter to slash
      set the linedelimiter to comma
      --
      get line 1 of gpsLatitude
      put item 1 of it / item 2 of it into someDegrees
      --
      get line 2 of gpsLatitude
      put item 1 of it / item 2 of it into someMinutes
      --
      get line 3 of gpsLatitude
      put item 1 of it / item 2 of it into someSeconds
      
      put geo_DmsToDecimal (someDegrees, someMinutes, someSeconds, gpsLatitudeRef) into decLat
      --
      return decLat
   catch e
      return "Error, gpsLatitude is invalid:" && gpsLatitude
   end try
end geo_ConvertGpsLatitude

function geo_ConstructHgeo mlon, mlat, plonDisplay, platDisplay
   /*
   <p class="h-geo">
   <data class="p-longitude" value="-27.116667">27ÔøΩ 7' 0'' S</data>,
   <data class="p-latitude" value="-109.366667">109ÔøΩ 22' 0'' W</data>
   </p>
   */
   
   if plonDisplay is empty then put geo_LongToDms (mlat) into plonDisplay
   if platDisplay is empty then put geo_LatToDms (mlon) into platDisplay
   
   put "<p class 'h-geo'>" & CR into htmlTemplate
   put "<data class='p-longitude' value='[[mlon]]'>[[plonDisplay]]</data>," & CR after htmlTemplate
   put "<data class='p-latitude' value='[[mlat]]'>[[platDisplay]]</data>" & CR after htmlTemplate
   put "</p>" after htmlTemplate
   put merge (htmlTemplate) into someHTML
   return someHTML
end geo_ConstructHgeo

function geo_LatToDms decValue
   --    <data class="p-latitude" value="-109.366667">109ÔøΩ 22? 0? W</data>
   -- put "-109.366667" into decValue
   
   if decValue > 0 then
      put "E" into westOrEast
   else
      put -1 * decValue into decValue
      put "W" into westOrEast
   end if
   put geo_DecToDms (decValue, westOrEast) into dms
   return dms
end geo_LatToDms

function geo_LongToDms decValue
   --  <data class="p-longitude" value="-27.116667">27ÔøΩ 7? 0? S</data>,
   -- put "-27.116667" into decValue
   
   if decValue > 0 then
      put "N" into westOrEast
   else
      put -1 * decValue into decValue
      put "S" into northOrSouth
   end if
   put geo_DecToDms (decValue, northOrSouth) into dms
   return dms
end geo_LongToDms

private function geo_DecToDms decValue, nwse
   put trunc (decValue) into someDegrees
   subtract someDegrees from decValue
   put decValue * 60 into minuteValue
   put trunc (minuteValue) into someMinutes
   subtract someMinutes from minuteValue
   put minuteValue * 60 into secondsValue
   put trunc (secondsValue) into someSeconds
   
   put someDegrees & "&deg;" && someMinutes & "&apos;" && someSeconds & "&apos;" & "&apos;" && nwse into dms
   return dms
end geo_DecToDms

function geo_DmsToDecimal someDegrees, someMinutes, someSeconds, nwse
   put char 1 of word 1 of nwse into nwse
   put someDegrees + someMinutes / 60 + someSeconds / 3600 into decValue
   geo_SetNegative decValue, nwse
   return decValue
end geo_DmsToDecimal

command geo_SetNegative @decValue, nwse
   if char 1 of word 1 of nwse is among the items of "w,s" then
      put -1 * decValue into decValue
   end if
end geo_SetNegative

command geo_ParseGeoStuff geoStuff, @nwse, @someDegrees, @someMinutes, @someSeconds
   set the itemdelimiter to "_"  
   repeat with ii =1 to 4
      -- repeat 4 -- bug: server does not deal with repeat loop properly !!!
      put item 1 of geoStuff into someNum
      delete item 1 of geoStuff
      --
      if someNum is not a number then
         put someNum into nwse
         --
         set the itemdelimiter to comma
         put item 1 of decimalTimeItems into someDegrees
         put item 2 of decimalTimeItems into someMinutes
         put item 3 of decimalTimeItems into someSeconds
         return geoStuff
      else
         put someNum & comma after decimalTimeItems
      end if
   end repeat
   --
   put pageArray_Construct ("Should not exit here", ii && geoStuff) into pageArray
   transport_ReturnPageArray pageArray
end geo_ParseGeoStuff

command geo_ExtractLatLong geoStuff, @decLat, @decLong, @regionInfo
   geo_ParseGeoStuff geoStuff, nwse, someDegrees, someMinutes, someSeconds
   put the result into trimmedGeoStuff
   put geo_DmsToDecimal (someDegrees, someMinutes, someSeconds, nwse) into decLat
   --
   geo_ParseGeoStuff trimmedGeoStuff, nwse, someDegrees, someMinutes, someSeconds
   put the result into regionInfo
   put geo_DmsToDecimal (someDegrees, someMinutes, someSeconds, nwse) into decLong
   return true
end geo_ExtractLatLong
