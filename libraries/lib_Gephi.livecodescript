script "lib_Gephi"
--> MetaData
-
license: GPLv3
name: lib_Gephi
type: library
version: 0.2

/*
See also "lib_Azure"
*/


--> WordCloud
-


--> Gephi
-
function gephi_FetchTimelineArray
   put pageArray_Fetch ("software.democracy.garden", "timeline-lookup") into pageArray
   put pageArray_GetFirstCode (pageArray) into someCSV
   split someCSV by CR and comma
   return someCSV
end gephi_FetchTimelineArray

function gephi_FetchCategoryArray
   put pageArray_Fetch ("software.democracy.garden", "category-lookup") into pageArray
   put pageArray_GetFirstCode (pageArray) into someCSV
   split someCSV by CR and comma
   return someCSV
end gephi_FetchCategoryArray

function gephi_ConstructTableArray pSlugs, wikiDomain
   put gephi_FetchTimelineArray() into timelineArray
   put gephi_FetchCategoryArray() into categoryArray
   --
   put gephi_ConstructLinkArrays (pSlugs, wikiDomain) into bigArray
   put bigArray ["pageLinkArray"] into pageLinkArray
   put bigArray ["pageNodeArray"] into pageNodeArray
   -- put keys (pageNodeArray) into allTitles
   -- sort allTitles
   
   -- construct node table
   /*
   Id,Label,timeset,color
   Democracy,Democracy,"<[0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]>",People
   */
   repeat for each key pageTitle in pageNodeArray
      put pageNodeArray [pageTitle]["Category"] into someCategory
      put pageNodeArray [pageTitle]["Moment"] into someMoment
      put timelineArray [someMoment] into someTimeLine
      if someTimeLine is empty then
         put timelineArray ["Prehistory"] into someTimeLine
      end if
      put categoryArray [someCategory] into gephiCategory
      
      put pageTitle,pageTitle,someTimeLine,gephiCategory into nodeTableLine
      put nodeTableLine & CR after nodeTableLines
   end repeat
   delete char -1 of nodeTableLines
   put "Id,Label,timeset,color" & CR before nodeTableLines
   put nodeTableLines into gephiTableArray ["nodeTableLines"]
   
   -- construct link table
   put "1.0" into linkWeight -- for now
   put "Directed" into linkType -- for now
   repeat for each key linkTarget in pageLinkArray
      /*
      Source,Target,Weight,Type
      Democracy,Liquid Democracy,1.0,Directed
      Citizen Assembly,Random,10.0,Directed
      */
      
      put empty into csvLine
      --
      put pageLinkArray [linkTarget]["titleLinks"] into titleLinks
      put word 1 to -1 of titleLinks into titleLinks
      repeat for each line linkSource in titleLinks
         put linkSource,linkTarget,linkWeight,linkType into csvLine
         put csvLine & CR after csvLines
      end repeat
   end repeat
   delete char -1 of csvLines
   put "Source,Target,Weight,Type" & CR before csvLines
   put csvLines into gephiTableArray ["csvLines"]
   --
   return gephiTableArray
end gephi_ConstructTableArray

function gephi_ConstructCsv pSlugs, wikiDomain
   -- Keyword,color,moment,relation1,Weight 1,relation 2,Weight 2,relations 3,Weight 3
   
   put gephi_ConstructLinkArray (pSlugs, wikiDomain) into pageLinkArray
   put gephi_ExtractAllPages (pageLinkArray) into allPageTitles
   --
   repeat for each key pageTitle in pageLinkArray
      put empty into csvLine
      --
      put pageLinkArray [pageTitle]["titleLinks"] into titleLinks
      put pageLinkArray [pageTitle]["place"]["Category"] into someCategory
      put pageLinkArray [pageTitle]["place"]["Moment"] into someMoment
      --
      put 1 into sWeigth -- for now
      --
      put pageTitle,someCategory,someMoment into csvLine
      --
      put word 1 to -1 of titleLinks into titleLinks
      repeat for each line titleLink in titleLinks
         put comma & titleLink & comma & sWeigth after csvLine
      end repeat
      --
      put csvLine & CR after gephiCSV
   end repeat
   delete char -1 of gephiCSV
   --
   put CR & CR & allPageTitles after gephiCSV
   --
   return gephiCSV
end gephi_ConstructCsv

function gephi_ExtractAllPages pageLinkArray
   repeat for each key pageTitle in pageLinkArray
      put empty into allTitleArray [pageTitle]
      --
      put pageLinkArray [pageTitle]["titleLinks"] into titleLinks
      repeat for each line titleLink in titleLinks
         put empty into allTitleArray [titleLink]
      end repeat
   end repeat
   put keys (allTitleArray) into allPageTitles
   sort allPageTitles
   return word 1 to -1 of allPageTitles
end gephi_ExtractAllPages

function gephi_ConstructCsvFromLineUp urlArray
   breakpoint
   repeat for each key indexNum in urlArray
      put urlArray [indexNum]["pageSlug"] into pageSlug
      put urlArray [indexNum]["pageDomain"] into pageDomain
      -- 
   end repeat
end gephi_ConstructCsvFromLineUp

function gephi_ConstructLinkArray pSlugs, wikiDomain
   put "Concepts" into sectionTitle
   --
   repeat for each line pSlug in pSlugs
      put pageArray_Fetch (wikiDomain, pSlug) into pageArray
      --
      put pageArray_GetTitleLinks (sectionTitle, pageArray) into titleLinks
      put pageArray ["title"] into pageTitle
      --
      put pageArray_GetTitleText ("Place", pageArray) into itemText
      
      delete line 1 of itemText
      replace "[[" with empty in itemText
      replace "]]" with empty in itemText
      
      set the itemdelimiter to ":"
      repeat for each line someLine in itemText
         put item 1 of someLine into firstItem
         if word 1 of firstItem = "-" then delete word 1 of firstItem
         put word 1 to -1 of firstItem into someKey
         if someKey is empty then next repeat
         
         put word 1 to -1 of item 2 of someLine into someValue
         put someValue into pageLinkArray [pageTitle]["place"][someKey]
      end repeat
      --
      put titleLinks into pageLinkArray [pageTitle]["titleLinks"]
   end repeat
   return pageLinkArray
end gephi_ConstructLinkArray

function gephi_ConstructLinkArrays pSlugs, wikiDomain
   put "Concepts" into sectionTitle
   --
   repeat for each line pSlug in pSlugs
      put pageArray_Fetch (wikiDomain, pSlug) into pageArray
      put pageArray_GetTitleLinks (sectionTitle, pageArray) into titleLinks
      put pageArray ["title"] into pageTitle
      put titleLinks into pageLinkArray [pageTitle]["titleLinks"]
      --
      _AddPace pageNodeArray, pageArray, pageTitle
      --
      put empty into allTitleArray [pageTitle]
      repeat for each line titleLink in titleLinks
         put empty into allTitleArray [titleLink]
         
         if pageNodeArray [titleLink] is not an array then
            put fedwiki_ConstructSlug (titleLink) into linkSlug
            put pageArray_Fetch (wikiDomain, linkSlug) into pageArray
            _AddPace pageNodeArray, pageArray, titleLink
         end if
      end repeat
   end repeat
   
   put pageLinkArray into bigArray ["pageLinkArray"]
   put pageNodeArray into bigArray ["pageNodeArray"]
   put keys (allTitleArray) into allTitles
   sort allTitles
   put allTitles into bigArray ["allTitles"]
   --
   return bigArray
end gephi_ConstructLinkArrays

private command _AddPace @pageNodeArray, pageArray, pageTitle
   put empty into pageNodeArray [pageTitle] -- to show case where there is no place
   
   if pageNodeArray [pageTitle] is an array then return false
   
   put pageArray_GetTitleText ("Place", pageArray) into itemText
   delete line 1 of itemText
   replace "[[" with empty in itemText
   replace "]]" with empty in itemText
   
   set the itemdelimiter to ":"
   repeat for each line someLine in itemText
      put item 1 of someLine into firstItem
      if word 1 of firstItem = "-" then delete word 1 of firstItem
      put word 1 to -1 of firstItem into someKey
      if someKey is empty then
         next repeat
      end if
      
      put word 1 to -1 of item 2 of someLine into someValue
      put someValue into pageNodeArray [pageTitle][someKey]
   end repeat
   return true
end _AddPace
