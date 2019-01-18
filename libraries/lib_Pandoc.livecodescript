script "lib_Pandoc"
--> MetaData
-
license: GPLv3
name: lib_Pandoc
type: library
version: 0.1


--> Pandoc
-
function pandoc_ConvertHTML someHTML, pFormat
   if pFormat is empty then put "plain" into pFormat
   file_SaveTempText someHTML, "html"
   put the result into someFile
   put "pandoc --from html --to" && pFormat && "-i" && someFile into someShell
   put shell (SomeShell) into convertedText
   return convertedText
end pandoc_ConvertHTML

function pandoc_ConvertWikiText wikiText, pFormat
   if pFormat is empty then put "plain" into pFormat
   file_SaveTempText wikiText, "wiki"
   put the result into someFile
   put "pandoc --from mediawiki --to" && pFormat && "-i" && someFile into someShell
   put shell (SomeShell) into convertedText
   return convertedText
end pandoc_ConvertWikiText

function pandoc_ListInputFormats
   get "commonmark,docbook,docx,epub,haddock,html,json,latex,markdown,markdown_github,markdown_mmd,markdown_phpextra,"
   put "markdown_strict,mediawiki,native,odt,opml,org,rst,t2t,textile,twiki" after it
end pandoc_ListInputFormats

function pandoc_ListExportFormats
   get "asciidoc,beamer,commonmark,context,docbook,docx,dokuwiki,dzslides,epub,epub3,fb2,haddock,html,html5,icml,json,"
   put "latex,man,markdown,markdown_github,markdown_mmd,markdown_phpextra,markdown_strict,mediawiki,native,odt," after it
   put "opendocument,opml,org,pdf,plain,revealjs,rst,rtf,s5,slideous,slidy,texinfo,textile" after it
   return it
end pandoc_ListExportFormats


