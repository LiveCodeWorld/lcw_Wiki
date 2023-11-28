script "Global | Wiki | Earth | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Wiki | Earth | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_Target [tObject]
   -- return display_MenuTarget(tObject)
   return the display_View of tObject
end menu_Target

getprop menu_CheckTarget [cameraView]
   return exists (cameraView)
end menu_CheckTarget


--> Global | Wiki | Earth | Menu
-
on menu_DisplayDynadotDomains displayView
   display_Dynadot displayView
end menu_DisplayDynadotDomains

on menu_ListDynadotWikis displayView
   put lcw_Ask ("Which domain...", "outlandish.academy", "Dynadot Domain", displayView) into domainName
   display_DynadotWikis domainName, displayView, ""
end menu_ListDynadotWikis

on menu_CreateEarthTunnels displayView
   put "*.platform.earth" into sDomain
   tunnel_Create sDomain
end menu_CreateEarthTunnels

on menu_AddEarthSubdomain displayView
   put lcw_Ask ("Create Dynadot CNAME?", "test.platform.earth", "Dynadot", displayView) into subDomain
   --
   put dynadot_ListSubdomains ("platform.earth", true) into subDomainNames
   set the itemdelimiter to "."
   put item 1 to -3 of subDomain into subDomainName
   switch
      case subDomainName is among the lines of subDomainNames
         lcw_AnswerWarning  "Subdomain '[[subDomainName]]' already registered!", displayView, subDomainName
         break 
      case subDomain = "platform.earth"
      case subDomain = "together.platform.earth"
         lcw_AnswerWarning "Reserved subdomain", displayView
         break
      case item -2 to -1 of subDomain is "platform.earth"
         dynadot_AddSubdomain "platform.earth", subDomainName, "yhdhcbundskxzwc.eu.loclx.io"
         --
         display_EarthWikis
         break
   end switch
end menu_AddEarthSubdomain

private on _
end _

on menu_DisplayEarthSubdomains dView
   display_EarthWikis dView
end menu_DisplayEarthSubdomains

on menu_DiplayLostWikis
   diplay_GitWikiFolders empty, "*platform.earth"
end menu_DiplayLostWikis

on submenu_Dev
   return menu_DevTitle ("Global | Wiki | Earth | Menu")
end submenu_Dev
