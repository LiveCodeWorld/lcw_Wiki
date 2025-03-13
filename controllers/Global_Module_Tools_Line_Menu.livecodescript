script "Global | Module | Tools | Line | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Module | Tools | Line | Menu
type: controller
version: 0.2

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray


--> Display | Events
-
on mDoubleUp_ModuleTools dView, shortFile
   if the optionKey is "Down" then breakpoint
   
   put the title_Text of dView into moduleName
   put the displayed_ModuleFolder of dView into moduleFolder
   put the selected_Path of dView into fPath
   replace comma with slash in fPath
   put moduleFolder & fPath into sFile
   --
   if there is not a file sFile then breakpoint
   -- 
   set the itemDelimiter to "."
   put item -1 of sFile into fExt
    switch
      case shortFile = "README.html"
         display_TiddlyFile sFile
         break
      case fExt = "md"
      case fExt = "html"
         code_EditFile sFile
         break
      case fExt = "array"
         display_ArrayFile sFile
         put the result into dView
         set the displayed_ModuleFolder of dView to moduleFolder
         break    
      case fExt = "json"
         display_JsonFile sFile
         put the result into dView
         set the displayed_ModuleFolder of dView to moduleFolder
         break
      case there is a stack sFile
         if fExt = "livecode" then
            set the loc of stack sFile to the screenloc
            show stack sFile
            go to stack sFile
         else
            edit the script of stack sFile
         end if
         break
      case fExt = "livecode"
      case fExt = "livecodescript"
         breakpoint
      default
         put sFile
         breakpoint
   end switch
end mDoubleUp_ModuleTools


--> Menu | Props
-
getprop menu_Target [tObject]
   put the display_View of tObject into dView
   put the displayed_Object of dView into viewObject
   put the top_Line of tObject into shortFolder
   --
   put shortFolder into LocalArray ["shortFolder"]
   put dView into LocalArray ["dView"]
   put the selected_Path of tObject into LocalArray ["sPath"]
   --
   return viewObject
end menu_Target

getprop disabled_Library [viewObject]
   return LocalArray ["shortFolder"] is not "Libraries"
end disabled_Library

getprop disabled_Library [viewObject]
   return LocalArray ["shortFolder"] is not "Libraries"
end disabled_Library

getprop disabled_Controller [viewObject]
   return LocalArray ["shortFolder"] is not "Controllers"
end disabled_Controller

getprop disabled_Module [viewObject]
   return LocalArray ["Modules"] is not "Models"
end disabled_Module

getprop disabled_Model [viewObject]
   return LocalArray ["shortFolder"] is not "Models"
end disabled_Model

getprop disabled_View [viewObject]
   return LocalArray ["shortFolder"] is not "Views"
end disabled_View

private function _GetMenu menuBit
   put the long id of me into myController
   put merge ("Global | Module | [[menuBit]] | Line | Menu") into gMenuTitle
   return gMenuTitle
end _GetMenu

private function _SelectedLine
   put LocalArray ["dView"] into dView
   return the selected_Line of dView
end _SelectedLine

private function _SelectedFile
   put _SelectedLine() into shortFile
   put _SelectedFolder() into mFolder
   --
   put mFolder & shortFile into sFile
   if there is a file sFile then
      return sFile
   else
      return empty
   end if
end _SelectedFile

private function _SelectedFolder
   put LocalArray ["sPath"] into sPath
   put _ModuleFolder() into mFolder
   --
   if the number of items of sPath = 1 then
      put mFolder into sFolder
   else
      put item 1 of sPath into shortFolder
      put mFolder & shortFolder & slash into sFolder
   end if
   
   if there is a folder sFolder then
      return sFolder
   else
      return empty
   end if
end _SelectedFolder

private function _FilePath
   put LocalArray ["dView"] into dView
   put the displayed_ModuleFolder of dView into mFolder
   put the selected_Path of dView into pathBit
   replace comma with slash in pathBit
   --
   put mFolder & pathBit into sFile
   return sFile
end _FilePath

private function _AssetFolder
   put _ModuleFolder() into mFolder
   return mFolder & "assets/"
end _AssetFolder

private function _ModuleFolder
   put LocalArray ["dView"] into dView
   put the displayed_ModuleFolder of dView into mFolder
   return mFolder
end _ModuleFolder

private function _ModuleName moduleView
   put LocalArray ["dView"] into dView
   put the title_Text of dView into moduleName
   get the stack_Name of moduleView 
   if it = moduleName then
      return moduleName
   else
      breakpoint
   end if
end _ModuleName

private command _Refresh moduleView
   put _ModuleName (moduleView) into moduleName
   display_ModuleTools moduleName
end _Refresh

getprop disabled_TrashMenu [viewObject]
   return LocalArray ["shortFolder"] is not "controllers"
end disabled_TrashMenu

getprop disabled_Behavior [viewObject]
   return LocalArray ["shortFolder"] is not "Behaviors"
end disabled_Behavior

getprop disabled_RemoveBehavior [viewObject]
   return LocalArray ["shortFolder"] is not "Behaviors"
end disabled_RemoveBehavior


--> Global | Module | Tools | Line | Menu
-
on menu_Refresh tiddlyView
   put the view_Name of tiddlyView into moduleName
   display_ModuleTools moduleName
end menu_Refresh

on menu_OpenAssetFolder
   put _AssetFolder() into assetFolder
   --
   code_EditFile assetFolder
end menu_OpenAssetFolder

on menu_DeleteFile tiddlyView
   put _SelectedFile() into sFile
   put _SelectedLine() into shortFile
   --
   lcw_Answer "Delete file '[[shortFile]]'?", dView, shortFile
   delete file sFile
   --
   menu_Refresh tiddlyView
end menu_DeleteFile

on _
end _

on menu_ScriptTools
   put _SelectedFile() into sFile
   put the name of stack sFile into bObject
   --
   display_ScriptTools bObject
end menu_ScriptTools

on menu_EditScript viewObject
   put _SelectedFile() into sFile
   edit the script of stack sFile
end menu_EditScript

getprop disabled_EditScript
   put _SelectedFile() into sFile
   return exists (stack sFile) is false
end disabled_EditScript

on menu_ListModuleDepkeys viewObject
   put _SelectedFile() into sFile
   put the name of stack sFile into bObject
   --
   put the module_BehaviorDepkeys of bObject into depKeys
   if depKeys is empty then
      lcw_AnswerWarning "No deps for this behavior!", viewObject
   else
      # Collect and display script
      put the name of bObject into sTitle
      put script_CollectFromObjects (depKeys, true) into newDepScript
      display_Text newDepScript, sTitle, "Deps Outside Module"
   end if
end menu_ListModuleDepkeys

on __
end __

on menu_RenameBehavior moduleView
   put _SelectedFile() into stackPath
   put the short name of stack stackPath into oldName
   put lcw_Ask ("Change the name of this behavior?", oldName, dView) into newBehaviorName
   
   # Rename bheavior and its script metadata
   module_RenameBehavior stackPath, newBehaviorName
   
   # Also rename short file
   put newBehaviorName & ".livecodescript" into newShortFile
   project_ChangeStackShortFileName stackPath, newShortFile
   
   # Refresh
   _Refresh moduleView
end menu_RenameBehavior

getprop disabled_RenameBehavior [viewObject]
   put LocalArray ["sPath"] into sPath
   return item 1 of sPath is not "behaviors"
end disabled_RenameBehavior

on menu_RenameBehaviorFile moduleView
   put _SelectedFile() into stackPath
   set the itemdelimiter to slash
   put item -1 of stackPath into shortFile
   
   # Warn and Ask
   put LocalArray ["dView"] into dView
   if exists (stack stackPath) is false then
      lcw_AnswerWarning "Stack does nto exist!", dView
   end if
   put lcw_Ask ("Change short file...", shortFile, dView) into newShortFile
   
   # Change short file
   project_ChangeStackShortFileName stackPath, newShortFile
   
   # Refresh
   _Refresh moduleView
end menu_RenameBehaviorFile

getprop disabled_RenameBehaviorFile [viewObject]
   put LocalArray ["sPath"] into sPath
   return item 1 of sPath is not "behaviors"
end disabled_RenameBehaviorFile

on menu_BehaviorDepScript moduleView
   put _SelectedFile() into sFile
   put the name of stack sFile into bObject
   --
   -- display_ScriptDeps bObject
   put the module_BehaviorDepHkeyArray [true] of bObject into hKeyArray
   set the script_HkeyArray of bObject to hKeyArray
   --
   display_ScriptHkeyArrayDeps hkeyArray, bObject
end menu_BehaviorDepScript

getprop disabled_BehaviorDepScript [viewObject]
   put LocalArray ["sPath"] into sPath
   return item 1 of sPath is not "behaviors"
end disabled_BehaviorDepScript

on menu_RemoveBehavior viewObject
   put the behavior_Objects of viewObject into bObjects
   put _FilePath() into sFile
   --
   if exists (stack sFile) then
      put the name of stack sFile into bObject
      line_Delete bObject, bObjects
      put bObjects
   else
      breakpoint
   end if
end menu_RemoveBehavior

on ___
end ___

on menu_TrashMenu viewObject
   put _FilePath() into stackPath
   put the short name of stack stackPath into mName
   --
   put LocalArray ["dView"] into dView
   lcw_Answer "Trash Menu '[[mName]]?", dView, mName
   --
   module_TrashStack stackPath
   --
   put the title_Text of dView into moduleName
   display_ModuleTools moduleName
   -- put the project_Name of stack moduleName into projectName
   -- display_Project projectName, true
   -- display_GitRefreshProjectName projectName
end menu_TrashMenu

on ____
end ____

on submenu_Controller
   return _GetMenu ("Controllers")
end submenu_Controller

on submenu_Library
   return _GetMenu ("Lib")
end submenu_Library

on submenu_Model
   return _GetMenu ("Model")
end submenu_Model

on submenu_View
   return _GetMenu ("View")
end submenu_View

on submenu_Behavior
   return _GetMenu ("Behavior")
end submenu_Behavior

on submenu_Dev
   return menu_DevTitle ("Global | Module | Tools | Line | Menu")
end submenu_Dev
