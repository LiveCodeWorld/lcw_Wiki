script "lib_Transport"
--> MetaData
-
license: GPLv3
name: lib_Transport
type: library
version: 0.1

/*
This library is for creating and manipulating Transporter wiki pages.
*/


--> Working on
-
on hkey_Rename hkey
   hkey_Deconstruct hkey, hName, hType, hObject, hNum
   switch
      case hName = "mock_DropJson"
         return empty
      case hName begins with "rig"
         put "revIgniter" into hObject -- could be "stack 'revIgniter'"?
         put hKeyLine_FromTripple (hName, hType, hObject) into rigKey
         return rigKey
      default
         return hKey
   end switch
end hkey_Rename

on graph_TidyLinkArray @hkeyArray
   -- before graph arrays have been created
   -- let's just process hkeyArray for transportation purposes
   put the long id of me into processObject
   hkeyArray_Process hkeyArray, processObject
end graph_TidyLinkArray


--> Display | Transport
-
command display_TransportObjectDeps sObject
   put the dep_StackNames of sObject into depStackNames
   display_TransportDeps depStackNames
   put the result into displayView
   --
   set the title_Text of displayView to the name of sObject
end display_TransportObjectDeps

command display_TransportHkeyDeps hKey
   hkey_Normalize hKey
   --
   put deps_HkeyStackNames (hKey) into depStackNames
   display_TransportDeps depStackNames
   put the result into displayView
   --
   set the title_Text of displayView to hKey
end display_TransportHkeyDeps

command display_TransportDeps depStackNames
   sort items of depStackNames
   put stack_ConvertNamesToShortPaths (depStackNames, badNames) into depShortFiles
   --
   display_ServerStacks depShortFiles
   put the result into displayView
   --
   if badNames is not empty then
      display_Lines badNames, "Bad Objects"
   end if
   return displayView
end display_TransportDeps


--> Transport | Check
-
function transport_ListMissingHkeys sObject
   transport_CollectCalls sObject, callObjectArray, missingArray, revIgniterArray
   put keys (missingArray) into mKeys
   repeat for each line mKey in mKeys
      put word 1 to 2 of mKey into shortMissing
      put shortMissing & CR after missingHkeys
   end repeat
   delete char -1 of missingHkeys
   return missingHkeys
end transport_ListMissingHkeys

command transport_CollectCalls sObject, @callObjectArray, @missingArray, @revIgniterArray
   put the rig_ControllerHkeys of sObject into hKeys
   repeat for each line hKey in hKeys
      put hkey_GetLinkArray (hKey) into hkeyLinkArray
      hkeyArray_SetObjectArray callObjectArray, hkeyLinkArray
   end repeat
   
   put revRuggedID (sObject) into sObject
   delete variable callObjectArray [sObject]
   put callObjectArray ["Missing"] into missingArray
   delete variable callObjectArray ["Missing"]
   put callObjectArray ["revIgniter"] into revIgniterArray
   delete variable callObjectArray ["revIgniter"]
   put keys (callObjectArray) into depStacks
   return depStacks
end transport_CollectCalls

command transporter_CreateGraph hObject, pDisplayGraphs, pForceReIndex
   put the behavior of hObject into oBehavior
   set the behavior of hObject to empty
   put the long id of me into processObject
   --
   put transport_GetObjectHierarchy (hObject) into searchHierarchy
   put the rig_ControllerHkeys of hObject into hKeys
   repeat for each line hkey in hKeys
      set the cursor to busy
      put transport_GraphIsNew (hKey) is false into graphIsOld
      put pForceReIndex is true OR graphIsOld into graphAgain
      if graphAgain then
         if pDisplayGraphs is true then
            display_ClusterDepGraph hkey, searchHierarchy, true, processObject
         else
            graph_HkeyCreateCluster hkey, searchHierarchy, true, processObject
         end if  
      end if
   end repeat
   set the behavior of hObject to oBehavior
   return hKeys
end transporter_CreateGraph

command transporter_CreateHkeyGraph hKey
   hKey_Deconstruct hKey, hName, hType, hObject, hNum
   put transport_GetObjectHierarchy (hObject) into searchHierarchy
   --
   put the behavior of hObject into oBehavior
   set the behavior of hObject to empty
   display_ClusterDepGraph hkey, searchHierarchy, true
   set the behavior of hObject to oBehavior
end transporter_CreateHkeyGraph


--> Transport
-
function transport_GetObjectHierarchy hObject
   put the dep_StackNames of hObject into stackNames
   put hObject into searchHierarchy
   repeat for each item stackName in stackNames
      if exists (stack stackName) is false then
         breakpoint
         next repeat
      end if
      put CR & the name of stack stackName after searchHierarchy
   end repeat
   return searchHierarchy
end transport_GetObjectHierarchy

function transport_GraphIsNew hKey
   put hkey_IsTransportHandler (hKey) into isTransporter
   if isTransporter is false then return empty
   
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   put overlay_GetHkeyHash (hKey) into oHash
   put the mainstack_Hash of hObject into mHash
   if oHash = mHash then
      return true
   else
      return false
   end if
end transport_GraphIsNew

function transport_ShortFileDeps hObject
   local allDepShortFiles
   put the rig_ControllerHkeys of hObject into hKeys
   repeat for each line hKey in hKeys
      put transport_HkeyShortFileDeps (hKey) into depShortFiles
      line_Add depShortFiles, allDepShortFiles
   end repeat
   return allDepShortFiles
end transport_ShortFileDeps

function transport_HkeyShortFileDeps hKey
   put deps_HkeyStackNames (hKey) into stackNames
   put stack_ConvertNamesToShortPaths (stackNames, badObjects) into depShortFiles
   sort depShortFiles
   return depShortFiles
end transport_HkeyShortFileDeps

command transport_UpdatePageGraph @pageArray, hKey
   put hkey_DotFile (hKey) into dotFile
   put url ("file:" & dotFile) into dotText
   --
   put pageArray_FindItemType ("graphviz", pageArray) into itemNum
   if itemNum > 0 then
      put dotText into pageArray ["story"][itemNum]["text"]
   end if
end transport_UpdatePageGraph


--> Tranport | Help
-
command transport_CreateHelp hKey, pScriptHelp
   _TransportInfo hKey, wikiDomain, pageTitle, pageSlug, hObject
   if the result = "index" then
      put _TransportHkeyCurlyData (hKey) into curlyData
      help_Create pageTitle, "transport", curlyData, pScriptHelp
   else
      -- updates "Welcome Visitors" every time! Could check.
      transport_CreateRouteWelcomeHelp hKey
      transport_CreateRouteHelp hKey
   end if
   put the result into shellResult
   return shellResult
end transport_CreateHelp

command transport_CreateRouteWelcomeHelp routeHkey
   hkey_Normalize routeHkey
   put routeHkey into indexHkey
   put "index" into word 2 of indexHkey
   _TransportInfo indexHkey, indexDomain, indexTitle, indexSlug, iObject   
   _TransportInfo routeHkey, rootDomain, routeTitle, routeSlug, rObject
   
   -- check Welcome-visitors for subdomain
   put transport_FetchPageArray (indexHkey) into pageArray
   switch
      case pageArray is empty
         breakpoint -- Welcome-visitors for subdomain does not exist. Let's create it
         break
      case pageArray ["title"] is not indexTitle
         breakpoint -- 
         
         help_Create indexTitle, "transport", curlyData, pScriptHelp
         put the result into pageArray
         if pageArray is not an array then
            breakpoint
            return empty
         end if
         
         pageArray_Rename pageArray, "Welcome Visitors"
         pageArray_StripJournal pageArray
         pageArray_AddFork pageArray, "transport.livecode.world,handler.livecode.world,library.livecode.world,model.livecode.world,fedwiki.org"
         break
      default
         breakpoint -- Welcome-visitors for subdomain already exists so let's update metadata
         
         put pageArray_Fetch (rootDomain, "welcome-visitors") into pageArray -- get old subpage welcome
         put _TransportHkeyCurlyData (indexHkey) into curlyData -- update with latest index.lc metadata
         curly_MergePageArray pageArray, curlyData
   end switch
   --
   pageArray_Store rootDomain, "welcome-visitors", pageArray
   return pageArray
end transport_CreateRouteWelcomeHelp

command transport_CreateRouteHelp hKey
   put _TransportHkeyCurlyData (hKey) into curlyData
   _TransportInfo hKey, wikiDomain, pageTitle, pageSlug, hObject
   --
   put pageArray_Fetch ("transport.livecode.world", "transport-route-template") into pageArray
   pageArray_Rename pageArray, pageTitle
   --
   curly_MergePageArray pageArray, curlyData
   pageArray_StripJournal pageArray
   pageArray_AddFork pageArray, "transport.livecode.world,handler.livecode.world,library.livecode.world,model.livecode.world,fedwiki.org"
   --
   pageArray_Store wikiDomain, pageSlug, pageArray
   put the result into shellResult
   return shellResult
end transport_CreateRouteHelp

command transport_UpdateHelp hKey
   put transport_FetchPageArray (hKey) into pageArray
   put _TransportHkeyCurlyData (hKey) into curlyData
   curly_MergePageArray pageArray, curlyData
   transport_StorePageArray hKey, pageArray
end transport_UpdateHelp

function transport_HelpURL hKey, pCheckURL
   _TransportInfo hKey, wikiDomain, pageTitle, pageSlug, hObject
   if pCheckURL is true then
      put fedwiki_IsWikiPage (wikiDomain, pageSlug) into isWiki
      if isWiki is false then
         return empty
      end if
   end if
   put fedwiki_PageUrl (wikiDomain, pageSlug) into someURL
   return someURL
end transport_HelpURL

function transport_IndexHkey hObject
   put hKeyLine_FromTripple ("index", "c", hObject) into hKey
   return hKey
end transport_IndexHkey

function transport_IndexDotText hObject
   put transport_IndexHkey (hObject) into hKey
   put hkey_GetDotText (hKey) into dotText
   return dotText   
end transport_IndexDotText


--> Transport | Model
-
function transport_FetchPageArray hKey
   _TransportInfo hKey, wikiDomain, pageTitle, pageSlug, hObject
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   return pageArray
end transport_FetchPageArray

command transport_StorePageArray hKey, pageArray
   _TransportInfo hKey, wikiDomain, pageTitle, pageSlug, hObject
   pageArray_Store wikiDomain, pageSlug, pageArray
   put the result into shellResult
   return shellResult
end transport_StorePageArray


--> Private
-
private function _TransportHkeyCurlyData hKey
   put help_HkeyCurlyData (hKey) into curlyData
   --
   _TransportInfo hKey, wikiDomain, pageTitle, pageSlug, hObject
   put the result into hName
   put hName into curlyData ["all"]["hName"]
   put pageTitle into curlyData ["all"]["transportName"]
   --
   _SetTransportMetadata curlyData, hKey
   _SetCurlyRestURL curlyData, hObject, hName
   _SetCurlyTransportRoutes curlyData, hObject
   _SetTransportWhere curlyData, hKey
   --
   return curlyData
end _TransportHkeyCurlyData

private command _SetTransportWhere @curlyData, hKey
   _TransportInfo hKey, wikiDomain, pageTitle, pageSlug, hObject
   put pageArray_ConstructReference (pageSlug, wikiDomain, wikiDomain, pageTitle) into itemArray
   curly_SetReplaceArray curlyData, itemArray, "4ecda1442570d900"
end _SetTransportWhere

private function _TransportObjectCurlyData sObject
   put the github_HandlerURL [shortHkey] of sObject && "github" into githubLink
   put githubLink into curlyData ["all"]["github link"]
   --
   _SetCurlyRestURL curlyData, sObject
   --
   put the dep_StackNames of sObject into depStackNames
   put fedwiki_MarkdownIndex (depStackNames) into curlyData ["all"]["Deps List"]
   --
   put transport_IndexDotText (hObject) into dotText
   --
   return curlyData
end _TransportObjectCurlyData

private command _SetTransportMetadata @curlyData, hKey
   put hkey_GetType (hKey) into handlerType
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   put the github_RelativePath of hObject into relPath
   --
   put "Type: transport" & CR after handlerMetaData
   put "Project:" && the project_Name of hObject & CR after handlerMetaData
   put "Github:" && relPath & CR after handlerMetaData
   delete char -1 of handlerMetaData
   --
   put handlerMetaData into curlyData ["id"]["da8cf69872f38050"]
end _SetTransportMetadata

private command _SetCurlyTransportRoutes @curlyData, sObject
   put the rig_ControllerHandlers of sObject into handlerNames
   replace comma with CR in handlerNames
   line_Delete "index", handlerNames
   if handlerNames is not empty then
      put fedwiki_MarkdownIndex (handlerNames) into curlyData ["id"]["642e249b4a7faa02"]
   end if
end _SetCurlyTransportRoutes

private command _SetCurlyRestURL @curlyData, sObject, hName
   put the stack_Name of sObject into stackName
   set the itemdelimiter to "."
   put item 1 of stackName into shortFile
   put "https://rest.livecode.world/" & shortFile into restURL
   if hName is not "index" then
      put slash & hName after restURL
   end if
   put "POST" && restURL into curlyData ["id"]["10ea2af363e51a5f"]
   put restURL into curlyData ["all"]["restURL"]
end _SetCurlyRestURL

private command _TransportInfo hKey, @wikiDomain, @pageTitle, @pageSlug, @hObject
   put "transport.livecode.world" into wikiDomain
   --
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   put the stack_Name of hObject into stackName
   --
   if hName = "index" then
      put help_ConstructTransportTitle (stackName) into pageTitle
   else
      set the itemdelimiter to "."
      put hName into pageTitle
      put item 1 of stackName into subdomain
      put tolower (subdomain) & "." before wikiDomain
   end if
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   return hName
end _TransportInfo
