script "Global_GeoJson_Menu"
--> MetaData
-
license: GPLv3
name: Global_GeoJson_Menu
type: controller
version: 0.1


private function _FetchCSV csvURL
   put "https://github.com/matslats/cccmap/raw/master/ces_exchanges.csv" into csvURL
   put url csvURL into someCSV
   
   -- xid,nid,full_title,location,province,country_code,country_name,currency_name
   put line 1 of someCSV into headerItems
   -- put headerItems
   
   -- CTTE,CEN0001,Cape Town Talent Exchange,Cape Town,Western Cape,ZA,South Africa,Talent
   put line 2 of someCSV into csvLine
   put item 4 to 7 of csvLine into someAddress
   
   return someAddress
end _FetchCSV


--> Global | GeoJson | Menu
-
on menu_BatchStatus
   
end menu_BatchStatus

on menu_BatchEncode
   /*
   recId|searchText|country
   0001|Invalidenstraße 116 10115 Berlin|DEU
   0002|Am Kronberger Hang 8 65824 Schwalbach|DEU
   0003|425 W Randolph St Chicago IL 60606|USA
   0004|One Main Street Cambridge MA 02142|USA
   0005|200 S Mathilda Ave Sunnyvale CA 94086|USA
   */
   put script_GetCommentAboveMe() into someCSV
   
   put here_BatchGeocodeCreateJob (someCSV) into someXML
   
   put someXML
   -- display_JSON someJSON
end menu_BatchEncode

on menu_TestCesCreation
   /*
   https://geocoder.cit.api.here.com/6.2/geocode.json?searchtext=200%20S%20Mathilda%20Sunnyvale%20CA&app_id=DemoAppId01082013GAL&app_code=AJKnXv84fjrb0KIHawS0Tg&gen=8 
   */
   put _FetchCSV() into someAddress
   
   -- Cape Town,Western Cape,ZA,South Africa
   put urlencode (item 1 of someAddress) into someCity
   -- put item 2 of someAddress into someCity
   -- put item 3 of someAddress into someCity
   put urlencode (item 4 of someAddress) into someCountry
   
   put here_ConstructGeocodeUrl (someCountry, someCity) into restURL
   put url restURL into returnedJSON
   
   -- <ns2:Error xmlns:ns2="http://www.navteq.com/lbsp/Errors/1" type="PermissionError" subtype="InvalidCredentials"><Details>invalid credentials for </Details></ns2:Error>
   put jsonImport (returnedJSON) into returnedArray
   
   put returnedArray ["Response"]["View"][1]["Result"][1]["Location"]["DisplayPosition"] into locationArray
   put locationArray ["Latitude"] into someLatitude
   put locationArray ["Longitude"] into someLongitude
   
   -- display_Array returnedArray
   put restURL & CR & someLatitude & CR & someLongitude
end menu_TestCesCreation

on menu_CreateCesGeojson
   local ApiToken = "pk.eyJ1IjoiZm9ydHlmb3hlcyIsImEiOiJjajFmMjllYWswMDBpMnhydnRoeW43ZGp5In0.xuTLuceEqx4GN_7nD2rXVQ"
   local BaseApiUrl = "https://api.mapbox.com"
   
   put _FetchCSV() into someAddress
   
   put headerItems & CR & someAddress
   
   -- /geocoding/v5/{mode}/{query}.json
   
   put BaseApiUrl & "/geocoding/v5/{mode}/[[query]].json" into someURL
   put "?access_token=your-access-token" after someURL
end menu_CreateCesGeojson

on menu_CreateHourbankGeojson
   put url "http://hourworld.org/public_data.xml"
end menu_CreateHourbankGeojson

on menu_DisplayCommunityForgeGeojson
   put url "https://github.com/matslats/cccmap/raw/master/sites.json "
end menu_DisplayCommunityForgeGeojson

on _
end _

on menu_Test mTarget
   put url "http://hourworld.org/public_data.xml"
end menu_Test


--> Global | GeoJson | Menu | Props
-

--> Global | GeoJson | Menu | Disabled
-
