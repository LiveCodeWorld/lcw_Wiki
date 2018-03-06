script "lib_Geojson"
--> MetaData
-
license: GPLv3
name: lib_Geojson
type: library
version: 0.1


--> GeoJson
-
function here_FetchCompletedBatch requestID
   /*
   jobs/{REQUEST_ID}/result
   jobs/{REQUEST_ID}/errors
   jobs/{REQUEST_ID}/no-matches
   */
   -- put "OMw7qpmorXwlvuHdNUokgDOfXZAsqeU5" into requestID
   
   put "https://batch.geocoder.cit.api.here.com/6.2/jobs/" into restURL
   put requestID after restURL
   
   put slash & "result" after restURL
   
   put "?action=status" after restURL
   _AddHereAuthentication restURL
   
   put url restURL into zippedData
   return zippedData
end here_FetchCompletedBatch

command here_BatchDeleteJob requestID
   put "OMw7qpmorXwlvuHdNUokgDOfXZAsqeU5" into requestID
   
   put "https://batch.geocoder.cit.api.here.com/6.2/jobs/" into restURL
   put requestID after restURL
   put "?" after restURL
   _AddHereAuthentication restURL
   delete url restURL
   put the result into someXML
   return someXML
end here_BatchDeleteJob

function here_BatchJobStatus requestID
   -- put "OMw7qpmorXwlvuHdNUokgDOfXZAsqeU5" into requestID
   
   put "https://batch.geocoder.cit.api.here.com/6.2/jobs/" into restURL
   put requestID after restURL
   put "?action=status" after restURL
   _AddHereAuthentication restURL
   put url restURL into someXML
   return someXML
end here_BatchJobStatus

function here_BatchGeocodeCreateJob someCSV
   put here_ConstructBatchGeocodeUrl ("david.bovill@gmail.com") into restURL
   
   -- libURLSetCustomHTTPHeaders "Content-Type: text/plain"
   set the httpHeaders to "Content-Type: text/plain"
   post someCSV to url restURL
   put it into someXML
   
   -- put LibUrlLastHTTPHeaders()
   
   return someXML
end here_BatchGeocodeCreateJob

function here_ConstructBatchGeocodeUrl someEmail
   put urlencode (someEmail) into someEmail
   
   put "https://batch.geocoder.cit.api.here.com/6.2/jobs" into restURL
   put "?action=run" after restURL
   put "&mailto=" & someEmail after restURL 
   put "&gen=8" after restURL
   put "&header=true" after restURL
   --
   put "&indelim=%7C" after restURL
   put "&outdelim=%7C" after restURL
   --
   put "&outcols=displayLatitude,displayLongitude,locationLabel,houseNumber,street,district,city,postalCode,county,state,country" after restURL
   --
   put "&outputCombined=false" after restURL
   --
   _AddHereAuthentication restURL
   
   return restURL
end here_ConstructBatchGeocodeUrl

function here_ConstructGeocodeUrl someCountry, someCity, pSomeStreet, pHouseNumber
   -- put "https://geocoder.cit.api.here.com/6.2/geocode.json?searchtext=" into restURL
   put urlencode (someCountry) into someCountry
   put urlencode (someCity) into someCity
   
   put "https://geocoder.cit.api.here.com/6.2/geocode" into restURL
   -- put ".xml" after restURL
   put ".json" after restURL
   put "?" after restURL
   
   put "&gen=9" after restURL
   
   if pHouseNumber is not empty then put "&housenumber=" & pHouseNumber after restURL
   if pSomeStreet is not empty then put "&street=" & pSomeStreet after restURL
   
   put "&city=" & someCity after restURL
   put "&country=" & someCountry after restURL
   
   _AddHereAuthentication restURL
   return restURL
end here_ConstructGeocodeUrl


--> GeoJson
-
private command _AddHereAuthentication @restURL
   put "M5qVMa4IexMsrweakINS" into HereAppID
   put "Ms926cLT1p7_UCPfAu81Lg" into HereAppCode
   
   put "&app_id=" & HereAppID after restURL
   put "&app_code=" & HereAppCode after restURL
end _AddHereAuthentication
