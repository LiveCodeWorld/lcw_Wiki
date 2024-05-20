script "lib_Astral"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_Astral
type: library
version: 0.1

/*Some help*/



--> Variable
-
constant AstralTunnelMainDomain = "pz2lxakw1leizrw.cname.eu.loclx.io"
constant AstralTunnelSubDomain = "a2v0pgisrrpogjv.cname.eu.loclx.io"


--> Working on
-


--> Astral
-
function astral_FetchPeopleSubDomainList
   put astral_FetchPeopleDomains() into peopleDomains
   put astral_SubFromDomains (peopleDomains, comma) into peopleSubDomainItems
   return peopleSubDomainItems
end astral_FetchPeopleSubDomainList

function astral_SubFromDomains aDomains, pDelim
   if pDelim is empty then put CR into pDelim
   set the itemdelimiter to "."
   repeat for each line aDomain in aDomains
      if item -2 to -1 of aDomain = "astralship.wiki" then
         put item 1 to -3 of aDomain & pDelim after subDomains
      end if
   end repeat
   delete char -1 of subDomains
   return subDomains
end astral_SubFromDomains

function astral_FetchPeopleDomains
   put roster_FromReferences ("people.astralship.wiki", "people") into peopleDomains
   return peopleDomains
end astral_FetchPeopleDomains

command astral_AddSubdomain domainName, subDomainName
   put dynadot_GetDns (domainName) into dnsArray
   --
   put dnsArray ["GetDnsResponse"]["GetDns"]["NameServerSettings"] into nsSettingsArray
   put dynadot_GetSubDomainNames (dnsArray) into existingSubdomains -- redundant repeat loop to speedup
   put nsSettingsArray ["MainDomains"] into mainDomainArray
   put nsSettingsArray ["SubDomains"] into subDomainArray
   
   # Construct Main ParamArray
   put "cname" into mainRecordType
   put AstralTunnelMainDomain into mainRecord
   put domainName into paramArray ["domain"]
   put mainRecord into paramArray ["main_record0"]
   put mainRecordType into paramArray ["main_record_type0"]
   
   # Re-add original subdomains
   dynadot_ReAddSubdomains paramArray, subDomainArray
   put the result into lastSubNum
   
   if subDomainName is not among the lines of existingSubdomains then
      # Add new subDomainNames
      put lastSubNum + 1 into subNum
      dynadot_AddSubdomainNum paramArray, subDomainName, subNum, AstralTunnelSubDomain, "cname"
   end if
   
   # Construct Rest URL
   put dynadot_ConstructRestUrl ("set_dns2", paramArray) into restURL
   
   # Json RPC GET
   put dynadot_GetApiKey() into authToken
   put jsonrpc_GetArray (restURL, authToken) into rData
   return rData
end astral_AddSubdomain
