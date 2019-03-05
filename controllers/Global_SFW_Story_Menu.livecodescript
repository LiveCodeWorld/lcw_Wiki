script "Global_SFW_Story_Menu"
--> MetaData
-
license: GPLv3
name: Global_SFW_Story_Menu
type: controller
version: 0.1


--> Global | SFW | Story | Menu
-
on menu_FetchLastPage dgView
   put the browser_Url of dgView into someUrl
   
   -- url_Deconstruct someUrl, someProtocol, fedwikiDomain, urlPath, shortName, fileExtension, uName, pWord
   set the itemdelimiter to "/"
   put item 3 of someUrl into fedwikiDomain
   put item 4 to -1 of someUrl into urlPath
   
   put fedwiki_ExtractPageSlugsFromPath (urlPath) into pageSlugs
   put line -1 of pageSlugs into pageSlug
   put pageJson_Fetch (fedwikiDomain, pageSlug) into someJSON
   put json_ToArray (someJSON) into someArray
   display_Array someArray, "pageJson_Fetch"
end menu_FetchLastPage

on menu_WikiSiteMap dgView
   put the browser_Url of dgView into someUrl
   url_Deconstruct someUrl, someProtocol, fedwikiDomain, urlPath, shortName, fileExtension, uName, pWord
   put fedwiki_FetchSiteExport (fedwikiDomain) into siteJSON
end menu_WikiSiteMap

on _
end _

on menu_FindSites dgView
   put "tigrutigru" into nameStem
   put "https://www.google.se/?gfe_rd=cr&ei=ihuFVb6rFaar8wfVj4GoBA" into someURL
   put merge("&gws_rd=ssl#q=%22Welcome+visitors%22+%22site+owned+by+[[nameStem]]%22") after someURL
   -- set the browser_URL of dgView to someURL
   put url someURL
end menu_FindSites

on menu_ChangeStyleWithJavascript dgView
   put the browser_ID of dgView into browserID
   -- put "alert('This is a debugging message');" into someJavascript
   put "document.getElementById('site-owner').style.visibility = 'hidden'" into someJavascript
   put revBrowserExecuteScript (browserID, someJavascript)
end menu_ChangeStyleWithJavascript

on menu_HideFooter dgView, someBoolean
   put the browser_ID of dgView into browserID
   if someBoolean is true then
      -- put "document.getElementById('site-owner').style.visibility = 'hidden'" into someJavascript
      put "var myElement = document.querySelector('footer');myElement.style.visibility = 'hidden'" into someJavascript
   else
      put "var myElement = document.querySelector('footer');myElement.style.visibility = 'visible'" into someJavascript
   end if
   put revBrowserExecuteScript (browserID, someJavascript)
end menu_HideFooter

on _
end _

on menu_MakeTextBigger dgView
   put the browser_ID of dgView into instanceID
   revBrowserMakeTextBigger instanceID
end menu_MakeTextBigger

on menu_MakeTextSmaller dgView
   put the browser_ID of dgView into instanceID
   revBrowserMakeTextSmaller instanceID
   revBrowserRedraw instanceID
end menu_MakeTextSmaller

on _
end _

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Global | SFW | Story | Menu | Props
-

--> Global | SFW | Story | Menu | Disabled
-

--> Dev | Menu
-
on menu_Dev mTarget
   beep
end menu_Dev

