script "lib_Wiki"
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

--> Working on
-
function wiki_ShellCommand pSecurityType, pFarm, pLog, pPort, pWithNvm
   if pSecurityType is empty then put "security_legacy" into pSecurityType
   --
   if pWithNvm is true then
      put nvm_GetBin() into wikiBinFile
   else
      put "wiki" into wikiBinFile
   end if
   
   put "/usr/bin/nohup"  into noHupFile
   --
   put merge ("[[noHupFile]] [[wikiBinFile]]") into someShell
   --
   if pFarm is not false then put space & "--farm" after someShell
   if pSecurityType is not empty then put space & "--" & pSecurityType after someShell
   if pPort is empty then
      put space & "--port 80" after someShell
   else
      put space & "--port" && pPort after someShell
   end if
   
   # Add redirect output bit (log if needed)
   put _RedirectBit (pLog) into reDirectOutput
   put space & reDirectOutput after someShell
   put space & "jobs -l" after someShell
   --
   return someShell
end wiki_ShellCommand


--> Private
-
private function _PipeToNothing
   return "> /dev/null 2>&1 < /dev/null"
end _PipeToNothing

function _RedirectBit pLog
   -- put "> /dev/null 2>&1 < /dev/null" into reDirectOutput
   if pLog is true then
      put "> nohup.out 2> error.log &" after reDirectOutput
   else
      put "> /dev/null 2>&1 &" after reDirectOutput
   end if
   return reDirectOutput
end _RedirectBit

private function _BackgroundSleep
   return "& sleep 1"
end _BackgroundSleep

private function _ReturnJobs
   return "; jobs -l"
end _ReturnJobs

private function _ParseWikiShellResult shellResult, pWikiBit
   -- [1]+ 49160 Done(127)               wiki --security_legacy > /dev/null 2>&1 < /dev/null
   
   if pWikiBit is empty then
      put "wiki --security_legacy > /dev/null 2>&1 < /dev/null" into pWikiBit
   end if
   put lineOffset (wikiBit, shellResult) into lineNum
   put word 2 of line lineNum of shellResult into pid
   return pid
end _ParseWikiShellResult


--> Working on
-

--> Wiki
-
function wiki_Started
   return wiki_ProcessIds() is not empty
   -- return "wiki" is among the lines of the openprocesses
end wiki_Started

function wiki_ProcessIds
   -- put "wiki --security_legacy" into wikiCommand
   put "wiki" into wikiCommand
   --
   put merge ("ps aux | grep '[[wikiCommand]]'") into someShell
   put shell (someShell) into shellResult
   put lineOffset (wikiCommand, shellResult) into lineNum
   delete line lineNum of shellResult
   --
   repeat for each line sLine in shellResult
      put word 2 of sLine into pid
      put pid & comma after pids
   end repeat
   delete char -1 of pids
   return pids
end wiki_ProcessIds


--> Wiki | Start
-
command wiki_Start pSecurityType, pFarm, pLog
   put wiki_ProcessIds() into wikiProcessIDs
   if wikiProcessIDs is not empty then return empty -- so we know already started
   
   put wiki_ShellCommand (pSecurityType, pFarm, pLog) into someShell
   put wiki_DoShell() into wikiProcessID
   --
   put wiki_ListBrowsers() into wikiBrowsers
   put wiki_DefaultLocalUrl() into wikiURL
   repeat for each line wikiBrowser in wikiBrowsers
      set the browser_URL of wikiBrowser to wikiURL
   end repeat
   
   # Indicate wiki starting up
   return wikiProcessID
end wiki_Start

command wiki_Stop pIDs
   if the platform = "MacOS" then
      if pIDs is not a number then
         put wiki_ProcessIds() into pIDs
      end if
      --
      repeat for each item pID in pIDs
         kill process pID
      end repeat
   else
      close process wiki
   end if
   --
   put wiki_ListBrowsers() into wikiBrowsers
   repeat for each line wikiBrowser in wikiBrowsers
      set the browser_URL of wikiBrowser to empty
   end repeat
end wiki_Stop

function wiki_DoShell pSecurityType, pFarm, pLog
   put wiki_ShellCommand (pSecurityType, pFarm, pLog) into someShell
   put shell (someShell) into shellResult
   -- [1]+  3122 Running                 /usr/bin/nohup /Users/david/.nvm/versions/node/v21.0.0/bin/wiki --security_legacy > /dev/null 2>&1 &
   put word 2 of shellResult into wikiProcessID
   return wikiProcessID
end wiki_DoShell

function wiki_TerminalCommand
   -- Does not work with Shell as it exits
   put "wiki --security_legacy" into someShell
   
   # Redirect output
   put  space & _PipeToNothing() after someShell
   
   # Background and return jobs
   -- put wikiBit && "& sleep 1; jobs -l" into someShell
   put space & _BackgroundSleep() after someShell
   put space & _ReturnJobs() after someShell
   --
   return someShell
end wiki_TerminalCommand


--> Wiki | Start | Alternative
-
command wiki_StartUsingXterm pXtermBrowser, pLog
   put wiki_TerminalCommand() into someShell -- Does not work with Shell
   --
   ttyd_Execute someShell, pXtermBrowser
   return pXtermBrowser
end wiki_StartUsingXterm

command wiki_OpenProcess pBrowserView
   breakpoint -- old. We now use nohup
   --
   set the cursor to watch
   open process wiki for update
   
   ## Federated Wiki server listening on 3000 in mode: development
   read from process wiki until "Federated Wiki server listening on 3000 in mode: development"
   put it into wikiInfoToParse
   put "http://localhost:3000" into wikiURL
   
   ## Display
   if exists (pBrowserView) then
      set the browser_Url of pBrowserView to wikiURL
   end if
   return wikiURL
end wiki_OpenProcess


--> Wiki
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
