script "Global | Obeya | Studio | Three | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Obeya | Studio | Three | Menu
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
   put the browser_View of tObject into browserView
   return browserView
end menu_Target


--> Global | Obeya | Studio | Three | Menu
-
on menu_ShowTerminal browserView
   put "radar" into shortPluginName
   --
   put the other_Browser of browserView into oBrowser
   put "cd $(npm prefix -g); npm i wiki-plugin-" & shortPluginName into sShellCommand
   --
   display_Xterm oBrowser, sShellCommand
end menu_ShowTerminal

on menu_ShowChatGpt browserView
   put the other_Browser of browserView into oBrowser
   set the browser_URL of oBrowser to "https://auth0.openai.com/authorize?client_id=TdJIcbe16WoTHtN95nyywh5E4yOo6ItG&scope=openid%20email%20profile%20offline_access%20model.request%20model.read%20organization.read%20organization.write&response_type=code&redirect_uri=https%3A%2F%2Fchat.openai.com%2Fapi%2Fauth%2Fcallback%2Fauth0&audience=https%3A%2F%2Fapi.openai.com%2Fv1&state=TCb84sVofxommgO0nGSP6XeL_hIdIIvaeXtgt26fiD4&code_challenge=N28l-klMH55P8456l89bQgkMxADesMuYms3VYIyCECQ&code_challenge_method=S256"
end menu_ShowChatGpt

on menu_ShowAsana browserView
   put the other_Browser of browserView into oBrowser
   set the browser_URL of oBrowser to "https://app.asana.com/0/1206580415766932/1206580454304519"
end menu_ShowAsana

private on _
end _

on menu_ShowWiki.W  wikiView
   put the card_Object of wikiView into arrayObject
   --
   set the rectArray_AnimateScaled of arrayObject to "Wiki"
end menu_ShowWiki.W

on menu_ShowVideo.D wikiView
   put the card_Object of wikiView into arrayObject
   --
   set the rectArray_AnimateScaled of arrayObject to "Full"
end menu_ShowVideo.D

on menu_ShowThree.T wikiView
   put the card_Object of wikiView into arrayObject
   --
   set the rectArray_AnimateScaled of arrayObject to "Three"
end menu_ShowThree.T

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Obeya | Studio | Three | Menu")
end submenu_Dev
