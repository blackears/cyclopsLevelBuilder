# Design

This is an overview of the general design ideas behind Cyclops Level Builder.  It is focused on providing a way to block in levels for rapid level design.  While the blocks can be used directly in final levels, it is meant more to sketch out levels with the blocks later being replaced with finished assets.

Cyclops Level Builder is currently based around using convex blocks, a technique used in games such as the original Quake.  Convex blocks allow for a clean design and provide for very fast collision detection.  That said, they can also be somewhat limiting, so this might change in future revisions of the project.

Snapping is useful in making sure that blocks line up, and Cyclops Level Builder was built with snapping in mind.  For level design, keeping blocks flush and aligned with each other makes for smooth transitions between blocks.  Right now all blocks will snap to the grid, and the gird snapping size can be adjusted.  Snapping cannot be turned off at the moment, but this may change in a future version.

Each CyclopsBlock has automatically generated uvs that are calculated using the triplanar mapping technique.  Essentially, the normal of each face is compared to each major axis and then the texture is projected onto that face along that axis.  Each face also has a Transform2D to further modify the uvs.  The UVs cannot be individually set at this time.  Since this tool is meant for designing levels, it treats uvs as primarily existing in world space, although you can 'lock' the uvs so that when you move blocks the uvs stay relative to the object rather than the world.  Only one uv layer is generated, so any materials you design should be aware only the first uv slot will have uv information.


## Major components of the project

### Cyclops Global Scene

The `CyclopsGlobalScene` is an autoloaded scene used mostly to display graphics related to tools.  When the `_draw_tool()` method of a tool is called, it will usually make a call to one of the global scene's `draw_*` methods to actually show the geometry.  The global scene also contains general settings that define the look of the tools.

### Cyclops Level Builder

This file is in the root of the `/addons` folder and extends `EditorPlugin`.  It is the first point of contact for everything Cyclops Level Builder does and mostly acts as a dispatcher to send user input out to the tools which do the bulk of the work.

### Nodes

The `/nodes` directory contains the `Node` derived classes that are placed in your scene and which form the bodies of the blocks.  In the current design, `CyclopsBlocks` is the root of a blocks construct and `CyclopsBlock` nodes are added to it as children to represent each block.  Since `CyclopsBlock` extends a `Node` rather than a `Node3D`, they cannot exist outside of the `CyclopsBlocks` root.  Whenever the `CyclopsBlocks` updates itself, it will create a `CyclopsBlockBody` for each `CyclopsBlock`.  These will not be visible in the editor's outliner, but they are still present and provide both the mesh and collision objects used by Godot.

### Commands

Ultimately, all key presses, mouse inputs and user interface interactions are translated into commands.  In fact, you can think of everything that Cyclops Level Editor does as just a fancy user interface that produces a series of commands.

Commands are the only part of Cyclops Level Builder that should interact with the nodes directly.  Commands implement an interface that lets them work with Godot's undo editor.  Each command has a `do_it()` method for performing its work, and an `undo_it()` method to restore the editor state to what it was before.  

You start to use a command by creating a new instance of it and setting its parameters.  You should be careful not to include any data in a command that could potentially not be the same after undoing.  In particular, do not store a direct reference to any `Node` since the objects they point to can potentially be freed later.  This can cause problems when the user uses undo to restore a deleted object.  A better approach is to store a `NodePath` so that you can fetch the `Node` from the scene.

When your command is set up, get the `EditorUndoRedoManager` manager from the plugin and then pass it to the `add_to_undo_manager()` method of the command.  This will place the command in the undo stack and call the `do_it()` method on it.

Some tools will call the `do_it()` method several times before calling `undo_it()`.  Generally this is done to support mouse dragging operations.  If your command is going to be used by a tool, make sure it can handle multiple calls to `do_it()` before `undo_it()` is called.

Commands are kept in the `/commands` folder.  The filename of a command should start with `cmd_` and have a class name that starts with `Command`.  All commands extend the `CyclopsCommand` class.

### Actions

Actions are meant to link user interface buttons and menu options to commands.  They provide a name and accellerator key along with code to call the command you're wrapping.

Actions are kept in the `/actions` subdirectory.  Action files start with the `action_` prefix and their class names begin with the word `Action`.  All actions extend the `CyclopsAction` class.  The `_execute()` method of an action is meant to perform its work and will be called when it is invoked by the user interface.

### Tools

Tools are meant to be used over an extended period of time to allow the users to perform complicated operations that involve mouse input, key presses and other user input.  Tools will generally start building a command when they are first activated and execute the command when they come to a commit point in the process.  Tools are very flexible and each will have unique ways to define when they start building a command and when they execute it.

Every tool is started by selecting its activation button in the toolbar.  The tool will then run until a new tool is selected from the toolbar.

Tools are stored in the `/tools` directory.  Tool files begin with the 'tool_' prefix and their class names begin with the word 'Tool'.  All tools extend the `CyclopsTool` class.

A button will be displayed for each tool in the editor toolbar whenever the CyclopsBlocks is selected.  When a user clicks on a tool button, they switch to using that tool.  `_activate()` will be called when the user switches to using the tool and `_deactivate()` will be called when the users switches away.  `_draw_tool()` will be used to draw extra graphics needed to illustrate the current state of the tool.  `_gui_input()` will receive key, mouse and other input events from the plugin so the tool can operate on them.  Tools should try to avoid consuming input events they do not need so that they can be used by other parts of the Godot editor.

### Docks

The `/docks` directory contains the extra docking windows used in the project.  At the moment, the Material and UV Transform docks are stored there.

### Math

The `/math` directory contains classes purely related to math and meshes.  `MathUtil` is a general math class with static methods for a lot of basic math calculations.  `QuickHull` implements the quick hull algorithm and is the backbone for creating blocks.  `ConvexVolume` is the main class the block nodes rely on for storing their data.


## Support

If you found this software useful, please consider buying me a coffee on Kofi.  Every contribution helps me to make more software:

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/Y8Y43J6OB)

