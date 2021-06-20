script "lib_AtopiaCreation"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_AtopiaCreation
type: library
version: 0.1

/*Some help*/


--> Working on
-
function fedray_FetchNewWikiDomainArray wikiDomain, pSitemapArray, pTreeFileArray
   if pSitemapArray is empty then put fedwiki_FetchSitemapArray (wikiDomain) into pSitemapArray
   if pSitemapArray is empty then return empty
   --
   put fedray_FetchNewCreateDomainArray (wikiDomain, pSitemapArray, pTreeFileArray) into wikiDomainArray
   fedray_UpdateWikiDomainArray wikiDomainArray, wikiDomain, pSitemapArray
   return wikiDomainArray
end fedray_FetchNewWikiDomainArray

function fedray_FetchNewCreateDomainArray wikiDomain, pSitemapArray, pTreeFileArray
   if pSitemapArray is empty then put fedwiki_FetchSitemapArray (wikiDomain) into pSitemapArray
   --
   put atopia_FetchServerIP() into pAtopiaIP
   put dig_GetIP (wikiDomain) into someIP
   put someIP into createDomainArray ["ipAddress"]
   --
   if someIP = pAtopiaIP then
      put atopia_GetFolderCreationDate (wikiDomain, pTreeFileArray) into mSeconds
      convert mSeconds to seconds
      put 1000 * mSeconds into wikiCreationDate
   else
      put fedwiki_ExtractSiteCreationDate (wikiDomain, pSitemapArray) into wikiCreationDate
   end if
   put wikiCreationDate into createDomainArray ["created"]
   --
   put fedwiki_FetchOwnerName (wikiDomain) into ownerName
   put ownerName into createDomainArray ["owner"]
   --
   return createDomainArray
end fedray_FetchNewCreateDomainArray

command fedray_UpdateLastModified @fedray, wikiDomain, pForceAddFedrayCreate
   put fedwiki_FetchSitemapArray (wikiDomain) into sitemapArray
   if sitemapArray is not an array then
      delete variable fedray [wikiDomain]
      return empty
   end if
   --
   if fedray_AlreadyCreated (wikiDomain, fedray, pForceAddFedrayCreate) then
      put fedray [wikiDomain] into wikiDomainArray
   else
      put fedray_FetchNewCreateDomainArray (wikiDomain, sitemapArray) into wikiDomainArray
   end if
   --
   fedray_UpdateWikiDomainArray wikiDomainArray, wikiDomain, sitemapArray
   put wikiDomainArray into fedray [wikiDomain]
   return sitemapArray
end fedray_UpdateLastModified

function atopia_FetchWikiDomainArray wikiDomain, pForceAddFedrayCreate
   local fedray
   fedray_AddCreateDomainEntry fedray, wikiDomain, pForceAddFedrayCreate
   fedray_UpdateModified fedray, wikiDomain
   put fedray [wikiDomain] into wikiDomainArray
   return wikiDomainArray
end atopia_FetchWikiDomainArray

command fedray_UpdateModified @fedray, wikiDomain, pSitemapArray
   if pSitemapArray is not an array then put fedwiki_FetchSitemapArray (wikiDomain) into pSitemapArray
   fedray_AddSiteMapArray fedray, wikiDomain, pSitemapArray
   return pSitemapArray
end fedray_UpdateModified

command fedray_AddSiteMapArray @fedray, wikiDomain, sitemapArray
   if sitemapArray is not an array then
      delete variable fedray [wikiDomain]
      return false
   end if
   
   -- wasteful
   put fedray [wikiDomain] into wikiDomainArray
   fedray_UpdateWikiDomainArray wikiDomainArray, wikiDomain, sitemapArray
   put wikiDomainArray into fedray [wikiDomain]
   --
   return true
end fedray_AddSiteMapArray


--> Fedray | CreateDomainEntry
-
function fedray_AlreadyCreated wikiDomain, fedray, pForceAddFedrayCreate
   if pForceAddFedrayCreate is true then return false
   put fedray [wikiDomain]["created"] into creationDate
   return creationDate is not empty 
end fedray_AlreadyCreated

command fedray_AddCreateDomainEntry @fedray, wikiDomain, pForceAddFedrayCreate
   -- this is slower and should be used only when creating
   -- or if a site is moved to another server or has a new owner
   if fedray_AlreadyCreated (wikiDomain, fedray, pForceAddFedrayCreate) then return empty
   put fedwiki_FetchSitemapArray (wikiDomain) into sitemapArray
   if sitemapArray is empty then return empty
   put fedray_FetchNewCreateDomainArray (wikiDomain, sitemapArray) into createDomainArray
   put createDomainArray into fedray [wikiDomain]
   --
   return sitemapArray
end fedray_AddCreateDomainEntry

function fedray_FetchCreateDomainArray wikiDomain, pSitemapArray
   if pSitemapArray is empty then put fedwiki_FetchSitemapArray (wikiDomain) into pSitemapArray
   if pSitemapArray is empty then return empty
   --
   put fedray_FetchNewCreateDomainArray (wikiDomain, pSitemapArray) into createDomainArray
   return createDomainArray
end fedray_FetchCreateDomainArray


--> Fedwiki | Create
-
function fedwiki_FetchOwnerName wikiDomain
   /*
   get "https://fedwiki.rodwell.me/view/narrative-chart/view/coffeehouse-culture"
   set the itemdelimiter to slash
   put item 3 of it into wikiDomain
   */
   put "http://" & wikiDomain & "/welcome-visitors.html" into someURL
   put url someURL into someHTML
   --
   put "//*[@id='site-owner']" into someXPath 
   replace "'" with quote in someXPath
   --
   -- put scrape_WithXPath (someHTML, someXPath) into someContent
   put revXMLCreateTree (someHTML, false, true, false) into treeID
   put revXMLDataFromXPathQuery (treeID, someXPath) into someContent
   revXMLDeleteTree treeID
   --
   put line 2 to 3 of someContent into someName
   replace CR with space in someName
   
   -- Site Owned by:  David Bovill
   return word 1 to -1 of someName
end fedwiki_FetchOwnerName


--> Fedwiki | Creation | Site
-
function fedwiki_FetchSiteCreationDate wikiDomain, pSitemapArray
   -- here we check each page and item of the journal (slow)
   if pSitemapArray is empty then
      put fedwiki_FetchSitemapArray (wikiDomain) into pSitemapArray
   end if
   put fedwiki_ExtractSiteCreationDate (wikiDomain, pSitemapArray) into wikiCreationDate
   return wikiCreationDate
end fedwiki_FetchSiteCreationDate

function fedwiki_ExtractSiteCreationDate wikiDomain, sitemapArray
   -- slow and wasteful as it fetches every pageArray for the site then throws it away
   put fedwiki_GetSitemapSlugs (sitemapArray) into pageSlugs
   if pageSlugs is empty then return empty
   --
   put the milliseconds into wikiCreationDate
   repeat for each line pSlug in pageSlugs
      put fedwiki_FirstAuthorDate (wikiDomain, pSlug) into mSeconds
      if mSeconds is empty then
         -- page does not exits for some reason even though it is in the sitemap?
         -- probably problem fetching url (see load bug)
         next repeat
      else if mSeconds < wikiCreationDate then
         put mSeconds into wikiCreationDate
      end if
   end repeat
   return wikiCreationDate
end fedwiki_ExtractSiteCreationDate


--> Experiments
-
function fedwiki_FetchFirstCreatedSlugArray wikiDomain
   -- not used (yet)
   -- allows us to get the pageArray info of the first author created page
   -- wasteful as we throw away all the sites pageArrays we fetch
   -- here we check each page and item of the journal (slow)
   put fedwiki_ListSitemapSlugs (wikiDomain) into pSlugs
   sort pSlugs
   --
   put the milliseconds into creationDate
   repeat for each line pSlug in pSlugs
      -- put fedwiki_FirstAuthorDate (wikiDomain, pSlug) into mSeconds
      put pageArray_Fetch (wikiDomain, pSlug) into pageArray
      put pageArray_ExtractFirstAuthorDate (pageArray, wikiDomain) into mSeconds
      --
      if mSeconds is empty then
         next repeat -- page does not exits for some reason even though it is in the sitemap?
      else if mSeconds < creationDate then
         put mSeconds into creationDate
         put creationDate into firstCreatedArray ["creationDate"]
         put pSlug into firstCreatedArray ["slug"]
         put pageArray into firstCreatedArray ["pageArray"]
      end if
   end repeat
   return firstCreatedArray
end fedwiki_FetchFirstCreatedSlugArray


--> Fedwiki | Creation | Page
-
function fedwiki_PageCreationDate wikiDomain, pSlug
   -- as specified in the journal's creation date
   -- if the page was forked it may have nothing to do with the sites author (see )
   put pageArray_Fetch (wikiDomain, pSlug) into pageArray
   put pageArray_GetCreationDate (pageArray) into createdDate
   return createdDate
end fedwiki_PageCreationDate

function fedwiki_FirstAuthorDate wikiDomain, pSlug
   put pageArray_Fetch (wikiDomain, pSlug) into pageArray
   put pageArray_ExtractFirstAuthorDate (pageArray, wikiDomain) into mSeconds
   return mSeconds
end fedwiki_FirstAuthorDate


--> PageArray | Date
-
function pageArray_ExtractFirstAuthorDate pageArray, wikiDomain
   put pageArray ["journal"] into journalArray
   -- put journalArray [1]["date"] into creationDate
   put 1420938220851 into wikiBirthDay -- last edit of standard welcome-visitors page
   
   put journalArray [1]["date"] into creationDate
   put item 2 of the extents of journalArray into maxItem
   repeat with checkItemNum = 2 to maxItem -- forget creation event
      put journalArray [checkItemNum]["date"] into mSeconds
      if mSeconds > wikiBirthDay then
         put mSeconds into creationDate
         put checkItemNum + 1 into nextItemNum
         if nextItemNum > maxItem then
            return creationDate
         end if
         --
         repeat with itemNum = nextItemNum to item 2 of the extents of journalArray
            put journalArray [itemNum]["type"] into actionType
            if actionType = "fork" then
               put journalArray [itemNum]["site"] into forkDomain
               switch
                  case forkDomain is empty
                     next repeat
                     break
                  case forkDomain = wikiDomain
                     put journalArray [itemNum]["date"] into creationDate
                     put true into wasForked
                     break
                  default
                     if wasForked is true then
                        return creationDate
                     else
                        get journalArray [itemNum]["date"]
                        if it is a number then
                           put it into creationDate
                        else
                           -- should be?
                        end if
                        put false into wasForked
                     end if
               end switch
            end if
         end repeat
         return creationDate
      end if
   end repeat
   return creationDate
end pageArray_ExtractFirstAuthorDate

function pageArray_GuessFirstWelcomeDate pageArray
   put 1420938220851 into wikiBirthDay -- last edit of standard welcome-visitors page
   put pageArray ["journal"] into journalArray
   repeat with itemNum = 1 to item 2 of the extents of journalArray
      put journalArray [itemNum]["date"] into mSeconds
      if mSeconds > wikiBirthDay then
         return mSeconds
      end if
   end repeat
end pageArray_GuessFirstWelcomeDate


--> Deps
-
