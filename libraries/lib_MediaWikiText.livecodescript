script "lib_MediaWikiText"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_MediaWikiText
type: library
version: 0.1

/* A library to parse and process Mediawiki text.
This library is about cleaning and parsing standard wiki-text from Mediawikis such as Wikipeedia.
*/


--> Working on
-
command _CleanTemplates @wikiText
   /*
   This needs fixing as it is a mess.
   
   Issue is that no regular expression seems able to detect complex nested templates such as cladograms
   Nor can I find a way to return the text without templates - ie use api to strip them.
   Looks like might be able to get rid of them with the following heuristic.
   - Remove/delete/skip line if first char of indented line begins with:
   - "{{" or "|" or "}}"
   
   Sometimes it starts with "* " and at other times as in "Ant" there are some annoying sentances thrown in the middle :(
   
   The best heuristic seems to be to count "{{" and "}}"
   */
   
   -- now let's iterate whole text
   -- we can try this once for the first header template, or repeat till we don't find a line beginnng with "{{"
   put 0 into openCount
   repeat 1000
      put line_BeginsWith ("{{", wikiText) into startLineNum
      
      if startLineNum = 0 then exit repeat
      repeat 1000
         put word 1 to -1 of line startLineNum of wikiText into nextLine
         switch
            case nextLine is empty
               delete line startLineNum of wikiText
               next repeat
               break
               -- maybe faster to repeat code with breaks to avoid checking each condition
            case char 1 to 2 of nextLine = "{{" -- could count
            case char -2 to -1 of nextLine = "}}" -- could count
            case char 1 of nextLine = "|"
            case char 1 of nextLine = "*"
               _AddBracketCount openCount, nextLine
               delete line startLineNum of wikiText
               break
            default
               -- case nextLine is empty
               if openCount > 0 then
                  delete line startLineNum of wikiText
                  next repeat
               else
                  exit repeat
               end if
         end switch
      end repeat
   end repeat
   
   -- strip the simple ones
   _StripTemplates wikitext
   return wikiText
end _CleanTemplates



--> Media | Wiki | Text
-
command mediawiki_CleanPageDescription @pageDescription, @infoBoxArray
   put mediawikia_ExtractInfobox (pageDescription) into infoBox
   put mediawiki_ConvertInfoBox (infoBox) into infoBoxArray
   fedwikipedia_CleanWikiText pageDescription
end mediawiki_CleanPageDescription

command fedwikipedia_CleanWikiText @wikiText
   -- _StripCitations wikiText -- these are always withing "<ref>" tags
   _CleanReferences wikiText
   _CleanSeeAlso wikiText
   _CleanTable wikiText
   _CleanComments wikiText
   _CleanBlockQuotes wikiText
   
   _CleanTemplates wikiText
   
   -- hacks
   replace "'''" with "__" in wikiText -- for bold markdown
   replace "()" with empty in wikiText
   replace "[ ]" with empty in wikiText
   replace "&nbsp;" with empty in wikiText
   replace "to(-)" with " to " in wikiText
   -- replace "[]" with empty in wikiText
   
   replace (CR & "*") with (CR & "* ") in wikiText
   --
   put word 1 to -1 of wikiText into wikiText
end fedwikipedia_CleanWikiText


--> MediaWiki | WikiText | Clean
-
command _CleanReferences @wikiText
   -- strips them all for now, and in doing so strips citations as well.
   /*
   -- piping does not work
   put "(<ref" & notClosing & shortClosing & ")" after someReg -- <ref name="dfsa" />
   put "|" after someReg
   put "(" & openingTag & notClosing & closingTag after someReg -- <ref name=...>...</ref> or <ref>...</ref>
   */
   
   local someReg
   
   -- Good regExpressions
   -- put "(<ref" & notClosing & "/>)" after someReg -- <ref name="dfsa" />
   -- put "(<ref>" & notClosing & "</ref>)" after someReg
   
   -- some utility chunks
   put "[^\>]*" into notClosing
   put "\<ref" & notClosing & "\>" into openingTag
   put "\</ref\>)" into closingTag
   put "/\>)" into shortClosing
   -- put "[^\<]*" into notOpening
   
   put "(?mi)" into someReg -- seems to have no effect???
   put "(<ref>" & notClosing & closingTag after someReg -- <ref>...</ref>
   text_StripReg wikiText, someReg
   
   put "(?mi)" into someReg -- seems to have no effect???
   put "(\<ref" & notClosing & shortClosing after someReg -- <ref name="dfsa" />
   text_StripReg wikiText, someReg
   
   put "(?mi)" into someReg -- seems to have no effect???
   put "(" & openingTag & notClosing & closingTag after someReg -- <ref name=...>...</ref> or <ref>...</ref>
   text_StripReg wikiText, someReg
   
   return wikiText
end _CleanReferences

private command _AddBracketCount @openCount, nextLine
   -- need to add the number of "{{" and subtract the number of "}}" to figure out what to add to total
   -- word 1 to -1 of line startLineNum = nextLine
   
   -- could do for entire body of text
   -- safer inside handler as we are not changing wikiText
   text_StipQuoted nextLine
   
   put text_CountStrings ("{{", nextLine) into addNum
   add addNum to openCount
   
   put text_CountStrings ("}}", nextLine) into subtractNum
   subtract subtractNum from openCount
end _AddBracketCount

private command _StripTemplates @wikitext
   -- now let's try a regular expression
   -- we can try a regular expression
   -- U is for non-greedy, m is for multiline search
   -- put "(?miU)" before someReg -- multiline search
   -- put "[^\}]*" into notThis
   put ".*" into notThis
   put "(\{\{" & notThis & "\}\})" into someReg
   put "(?mi)" before someReg -- multiline search
   --
   text_StripReg wikiText, someReg
end _StripTemplates

private command _CleanTable @wikiText
   -- woud be great to parse and create a fedwiki table?
   
   /*
   Hello
   
   {| class="wikitable sortable" style="float:right; margin:10px;"
   |-
   ! [[Region]] !! Number of<br />species&nbsp;<ref name = HolldoblerWilsonAnts>Hölldobler & Wilson (1990), p. 4</ref>
   |-
   | [[Neotropic ecozone|Neotropics]] ||align="right"| 2162
   |-
   | [[Nearctic ecozone|Nearctic]] ||align="right"| 580
   |-
   | [[Europe]] ||align="right"| 180
   |-
   | [[Africa]] ||align="right"| 2500
   |-
   | [[Asia]] ||align="right"| 2080
   |-
   | [[Melanesia]] ||align="right"| 275
   |-
   | [[Australia]] ||align="right"| 985
   |-
   | [[Polynesia]] ||align="right"| 42
   |}
   
   World
   */
   
   put "[^\}]*" into notClosingBracket
   put "(?mi)(\{\|" & notClosingBracket & "\|\})" into someReg
   text_StripReg wikiText, someReg
   return wikiText
end _CleanTable

command _CleanBlockQuotes @wikiText
   replace "<blockquote>" with (CR & "<blockquote>") in wikiText
   replace "</blockquote>" with ("</blockquote>" & CR) in wikiText
end _CleanBlockQuotes

private command _CleanSeeAlso @wikiSectionLine
   -- some start text {{See also|1920s Berlin}} end text 
   
   put "[^\}]+" into untilCurlyBracket
   put "\{\{See also\|(" & untilCurlyBracket & ")\}\}" into someReg
   put "(?m)" before someReg -- multiline search
   repeat
      if matchchunk (wikiSectionLine, someReg, wikiAlsoStart, wikiAlsoEnd) is true then
         put char wikiAlsoStart to wikiAlsoEnd of wikiSectionLine into wikiAlsoLink
         if wikiAlsoStart = 12 then
            put "See also [[" & wikiAlsoLink & "]]" into cleanAlso
         else
            put "(see also [[" & wikiAlsoLink & "]])" into cleanAlso
         end if
         put cleanAlso into char (wikiAlsoStart - 11) to (wikiAlsoEnd + 2) of wikiSectionLine
      else
         exit repeat
      end if
   end repeat
end _CleanSeeAlso

command _CleanComments @wikiText
   -- As an example here is a <!-- Bot generated title --> that needs to be removed.
   --
   put "[^\>]*" into notClosingBracket
   --
   put "(\<\!--" into someReg
   put notClosingBracket after someReg
   put "--\>)" after someReg
   --
   put "(?mi)" before someReg -- multiline search
   text_StripReg wikiText, someReg
end _CleanComments


--> Deps
-
