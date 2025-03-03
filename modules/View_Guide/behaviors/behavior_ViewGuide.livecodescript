script "behavior_ViewGuide" with behavior "behavior_View|Layouts|Horizontal|Two"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_ViewGuide
type: behavior
version: 0.3

/*Here you make make notes as a basic form of help for this view.
Full help text can be found on the linked wiki for the view.*/

--> Variables
-
constant bName = "behavior_View|Layouts|Horizontal|Two"


--> Working on
-

--> Events
-
on preOpenControl
   _InitView
   pass preOpenControl
end preOpenControl


--> Props | Layout
-
getprop layout_BehaviorArray
   put the layout_View of the target into layoutView
   if exists (layoutView) is false then return empty
   put revRuggedId (layoutView) into layoutView
   
   put the behavior_Objects of layoutView into bObjects
   put bObjects into bArray [layoutView]
   
   put the layout_ChildArray of me into childArray
end layout_BehaviorArray

getprop layout_ObjectData
   put the layout_View of the target into layoutView
   if exists (layoutView) is false then return empty
   
   put revRuggedId (layoutView) into layoutView
   put the view_Name of layoutView into layoutViewName
   --
   put layoutView into layoutObjectData [1]["object"]
   put layoutViewName into layoutObjectData [1]["vName"]
   
   put the layout_ChildArray of me into childArray
   put childArray into layoutObjectData [1]["children"]
   return layoutObjectData
end layout_ObjectData

getprop layout_ChildArray
   put the layout_View of the target into layoutView
   if exists (layoutView) is false then
      breakpoint
      put the long id of the target into layoutView
   end if
   --
   put the top_Views of layoutView into childViews
   repeat with itemNum = 1 to the number of lines of childViews
      put line itemNum of childViews into childView
      --
      put the view_Name of childView into childViewName
      put revRuggedId (childView) into childView
      --
      put childView into childArray [itemNum]["object"]
      put childViewName into childArray [itemNum]["vName"]
   end repeat
   return childArray
end layout_ChildArray


--> Prop
-
getprop view_BehaviorStackNames
   put the uOPN ["behavior_StackNames"] of me into sNames
   return sNames
end view_BehaviorStackNames

setprop view_BehaviorStackNames sNames
   set the uOPN ["behavior_StackNames"] of me to sNames
   --
   set the behavior_StackNames of me to sNames
   return sNames
end view_BehaviorStackNames


--> Prop | Deps
-
getprop behavior_Objects [useRugged]
   put the long id of the target into tObject
   put behavior_GetHierarchy (tObject, useRugged) into bObjects
   return bObjects
end behavior_Objects

setprop behavior_StackNames stackNames
   if stackNames is empty then return empty
   replace comma with CR in stackNames
   put the long id of the target into tObject
   
   # Clear any behaviors (or we might cause a loop)
   behavior_ClearHierarchy tObject
   
   repeat for each line stackName in stackNames
      if exists (stack stackName) is false then next repeat
      put the name of stack stackName into bObject
      if tObject = bObject then next repeat
      
      put the behavior of tObject into tBehavior
      put the behavior of bObject into bBehavior
      --
      set the behavior of tObject to bObject
      put bObject into tObject
      put bObject & CR after bObjects
   end repeat
   delete char -1 of bObjects
   return bObjects
end behavior_StackNames

getprop object_IsView
   put the uRIP ["type"] of the target into vName
   return vName is not empty
end object_IsView

getprop top_ControlIDs
   put word 1 of the target into tWord
   switch
      case tWord = "stack"
         -- should we search. backgrounds?
         put the number of cards of the target into maxNum
         repeat with cardNum = 1 to maxNum
            put the long id of card cardNum of the target into cardObject
            put the childControlIDs of cardObject & CR after stackControlIds
         end repeat
         delete char -1 of stackControlIds
         return stackControlIds
      case tWord is among the items of "card,group"
         return the childControlIDs of the target
      default
         return empty
   end switch
end top_ControlIDs

getprop top_Views [vParam]
   local topViews
   put the top_ControlIDs of the target into topControlIDs
   repeat for each line cID in topControlIDs
      put the long id of control id cID into tObject
      if vParam is empty then
         if the object_IsView of tObject is true then
            put tObject & CR after topViews
         end if
      else
         put the vParam of tObject into vObject
         if exists (vObject) then
            put vObject & CR after topViews
         end if
      end if
   end repeat
   delete char -1 of topViews
   return topViews
end top_Views

getprop view_Name
   put the long id of the target into tObject   
   if the uRIP ["type"] of tObject is not "view" then return empty
   put the uRIP ["name"] of tObject into viewName
   return viewName
end view_Name


--> Behavior
-
command behavior_ClearHierarchy tObject, pMoreObjects
   put behavior_GetHierarchy (tObject) into bObjects
   _ClearHierarchyAndObjects bObjects, pMoreObjects
   put the result into hObjects
   return hObjects
end behavior_ClearHierarchy

function behavior_GetHierarchy tObject, pUseRugged
   repeat
      put the behavior of tObject into bObject
      if exists (bObject) is false then exit repeat
      if pUseRugged is not false then
         put revRuggedId (bObject) into bObject
      end if
      put bObject & CR after bObjects
      put bObject into tObject
   end repeat
   delete char -1 of bObjects
   return bObjects
end behavior_GetHierarchy


--> Private
-
private command _InitView
   put the view_BehaviorStackNames of me into sNames
   put the uOPN ["behavior_StackNames"] of me into sNames 
   set the behavior_StackNames of me to sNames
   --   
   dispatch "LayoutControl"
   --
   -- lcw_Notify "Set behavior_StackNames", "Behaviors"
end _InitView

private command _ClearBehaviors bObjects
   -- not guaranteed to remove behavior loops
   try
      repeat for each line bObject in bObjects
         if exists (bObject) then
            set the behavior of bObject to empty
         end if
      end repeat
   catch sError
      -- causes issues with modyfying script when running
      -- breakpoint
   end try
end _ClearBehaviors

private command _ClearHierarchyAndObjects bObjects, pMoreObjects
   repeat for each line sObject in pMoreObjects
      put revRuggedId (sObject) into rObject
      if rObject is not among the lines of bObjects then
         put CR & rObject after bObjects
      end if
   end repeat
   put word 1 to -1 of bObjects into bObjects
   --
   _ClearBehaviors bObjects
   return bObjects
end _ClearHierarchyAndObjects
