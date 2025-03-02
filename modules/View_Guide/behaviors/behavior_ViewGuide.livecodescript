script "behavior_ViewGuide" with behavior "behavior_View|Layouts|Horizontal|Two"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_ViewGuide
type: behavior
version: 0.2

/*Here you make make notes as a basic form of help for this view.
Full help text can be found on the linked wiki for the view.*/

--> Variables
-
constant bName = "behavior_View|Layouts|Horizontal|Two"


--> Working on
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


--> Events
-
on preOpenControl
   view_Init
   pass preOpenControl
end preOpenControl

command view_Init
   put the view_BehaviorStackNames of me into sNames
   put the uOPN ["behavior_StackNames"] of me into sNames 
   set the behavior_StackNames of me to sNames
   --   
   LayoutControl
   --
   lcw_Notify the behavior_StackNames of me, "Behaviors"
   pass view_Init
end view_Init

getprop view_BehaviorStackNames
   put the uOPN ["behavior_StackNames"] of me into sNames
   return sNames
end view_BehaviorStackNames

setprop view_BehaviorStackNames sNames
   set the uOPN ["behavior_StackNames"] of me to sNames
   --
   view_Init
end view_BehaviorStackNames


