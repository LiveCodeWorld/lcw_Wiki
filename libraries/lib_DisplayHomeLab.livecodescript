script "lib_DisplayHomeLab"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_DisplayHomeLab
type: library
version: 0.1

/*Some help*/


--> Working on
-
command array_MakeExpandable @sArray
   repeat for each key sKey in sArray
      put sArray [sKey] into sIndex
      repeat for each line sLine in sIndex
         put empty into sArray [sKey][sLine]
      end repeat
   end repeat
end array_MakeExpandable


--> Display | HomeLab
-


--> Display Pihole
-
command display_PiDomains piName
   put piName & ".local" into localHostName
   --
   put wikiPi_ListShortFolders (localHostName) into piDomains
   --
   display_Tool piDomains, localHostName, "Pi Domains", "lcw_Server"
   return the result
end display_PiDomains

command display_PiholeAdmin
   -- put "http://192.168.0.150/admin/dns_records.php" into someURL
   put "http://pi.hole/admin/dns_records.php" into someURL
   display_Browser someURL, empty, "Pihole Admin"
   return the result
end display_PiholeAdmin

command display_LocalDomains domainName, pDisplayView
   put wikiDomain_List (domainName, true) into subDomainNames
   
   display_Tool subDomainNames, domainName, "Local Subdomains", "lib_Pihole", empty, pDisplayView
   put the result into dView
   
   set the subdomain_Array of dView to indexArray
   return dView
end display_LocalDomains

command display_LocalSubdomains domainName, pDisplayView
   put wikiDomain_SubList (wikiDomain, true) into subDomainNames
   
   display_Tool subDomainNames, domainName, "Local Subdomains", "lib_Pihole", empty, pDisplayView
   put the result into dView
   
   set the subdomain_Array of dView to indexArray
   return dView
end display_LocalSubdomains

command display_PiholeSubdomains pDomainName, pDisplayView
   put pihole_LocalData() into localData
   put pihole_CNAMEArray() into rArray
   put rArray ["data"] into indexArray
   put indexArray_List (indexArray, 1) into subDomainNames
   
   if pDomainName is empty then
      put "All Pihole Subdomains" into sTitle
   else
      put url_GetTLD (pDomainName) into tldDomain
      --
      put localData ["domainArray"][tldDomain] into localName
      put localData ["nameArray"][localName] into piAddress
      
      put pDomainName into sTitle
      filter subDomainNames with ("*." & pDomainName) 
   end if
   
   display_Tool subDomainNames, sTitle, "Pihole Subdomains", "lib_Pihole", empty, pDisplayView
   put the result into dView
   
   set the subdomain_Array of dView to indexArray
   return dView
end display_PiholeSubdomains

command display_PiholeData
   put pihole_FetchData() into indexArray
   --
   display_Data indexArray, "Data", "Pihole"
   return the result
end display_PiholeData

command display_PiholeTools pDisplayView
   put pihole_FetchData() into indexArray
   put indexArray_List (indexArray, 1) into domainNames
   
   display_Tool domainNames, "Domains", "Pihole", "lib_Pihole", empty, pDisplayView
   put the result into dView
   
   set the domain_Array of dView to indexArray
   return dView
end display_PiholeTools


--> Deps
-
