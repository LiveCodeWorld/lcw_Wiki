﻿script "lib_Wiki"
--> MetaData
-
license: GPLv3
name: lib_Wiki
type: library
version: 0.4

/*
This is a library for working with Fedwiki inside of a Livecode desktop or obile application.
There is also a lot of code in the group "Wiki" of the stack "Fedwiki Editor" of project "lcw_Wiki"
*/

--> Variables
-

--> Working on
-


--> Wiki
-


--> Wiki | CSS
-
command wiki_ConvertCSS @someCSS
   put lineOffset ("width: 430px;", someCSS) into lineNum
   put "  width: 350px;" into line lineNum of someCSS
   
   put lineOffset ("width: 420px;", someCSS) into lineNum
   put "  width: 344px;" into line lineNum of someCSS
   
   put lineOffset ("#persona-logout-btn {", someCSS) into lineNum
   put CR & "visibility: hidden;" after line lineNum of someCSS
   
   put lineOffset ("#persona-login-btn,", someCSS) into lineNum
   put ".searchbox {float: left}" into csssTweak
   put CR & ".menu {float: left}" after csssTweak
   put csssTweak & CR & CR before line lineNum of someCSS
   
   /*
   -- this scales everything
   put 0.91 into hScale
   put 1 into vScale
   
   put "-moz-transform: scale([[hScale]], [[vScale]]);" into extraCSS
   put CR & "-webkit-transform: scale([[hScale]], [[vScale]]);" after extraCSS
   put CR & "-o-transform: scale([[hScale]], [[vScale]]);" after extraCSS
   put CR & "-ms-transform: scale([[hScale]], [[vScale]]);" after extraCSS
   put CR & "transform: scale([[hScale]], [[vScale]]);" after extraCSS
   put CR & "-moz-transform-origin: top left;" after extraCSS
   put CR & "-webkit-transform-origin: top left;" after extraCSS
   put CR & "-o-transform-origin: top left;" after extraCSS
   put CR & "-ms-transform-origin: top left;" after extraCSS
   put CR & "transform-origin: top left;" after extraCSS
   put merge(extraCSS) into extraCSS
   put lineOffset (".main {", someCSS) into lineNum
   put CR & extraCSS after line lineNum of someCSS
   */
   
   /*
   -- this hides the whole footer
   put lineOffset ("footer {", someCSS) into lineNum
   put CR & "visibility: hidden;" after line lineNum of someCSS
   put lineOffset ("bottom: 60px;", someCSS) into lineNum
   put "  bottom: 16px;" into line lineNum of someCSS
   */
   
   /*
   -- this hides the whole footer
   put lineOffset ("footer {", someCSS) into lineNum
   put CR & "visibility: hidden;" after line lineNum of someCSS
   put lineOffset ("bottom: 60px;", someCSS) into lineNum
   put "  bottom: 16px;" into line lineNum of someCSS
   */
end wiki_ConvertCSS

