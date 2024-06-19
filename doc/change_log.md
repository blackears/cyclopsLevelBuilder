# Cyclops Level Builder Change Log

### v1.0.5

* Editor toolbar is now always present.
* Tool objects now have a method to indicate which nodes they are able to edit.
* Fixing error when tessellating faces.


### v1.0.4
* You can now right-click fly when the vertex, edge or face tools are selected.
* Adding alignment option to primitive creation tools so that you can turn off the auto alignment to surfaces.
* ConvexVolume is now generating indexed meshes which should take up less memory and also allow occluders to be baked properly on exported scenes.
* Intersection and subtraction commands now preserve original transform of components
* Snap to grid command now uses new snapping manager
* Improving face-vertex accuracy when transferring mesh attributes
* Replacing ConvexBlockData with MeshVectorData which provides a flexible way to add data layers to mesh features
* Now including .import files when creating addon archive
* Creating action to export Cyclops scenes in a custom file format
* Adding new menubar for Cyclops that will always be shown in the toolbar
* Adding Import MeshInstance command
* Adding importer/exporter for custom Cyclops file format
* Adding a variety of gizmo coordinate orientations for tools
* Fixing incorrect translation for some of the planar handles on the translation gizmo
* Adding way to use hotkeys to switch between tools.


### v1.0.3
* The create shape tools now have an option for referencing the current active object to determine where in space they are drawn.
* Shape creation tools now let you specify collision settings.
* Right click cancel now does not undo rotation and move after operation has been completed.
* Now flushing snapping changes whenever a setting is changed.
* Renaming Settings to CyclopsSettings
* Now generating tangent vectors for block meshes.
* Restoring ability for UVs to remain in place when moving blocks.
* ~~Adding option to clear UV transform in material brush.~~
* Adding tool to export current scene as Godot scene with only native Godot objects.
* Overhaul of the material manager.  Will now automatically track all materials in project and provide filters to let you focus on subsets of materials.
* Can drag and drop Texture2D resources from the file explorer into the material directory window to automatically create new materials.  Dragging more than one texture will create an animated texture sequence.
* Adding command to merge vertices at center.
* Material brush can now apply UV coordinates
* Material brush can sample brush settings from under the cursor by pressing Shift-X
* Adding face-vertices to ConvexBlockData
* Creating vertex paint brush for painting face-vertices
* Fixing error where box selecting vertices, edges or faces sometimes caused a null pointer problem.


