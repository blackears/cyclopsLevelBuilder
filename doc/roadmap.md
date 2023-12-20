# Roadmap

Here's a list of changes I'm thinking of making in future revisions of the project.


### Make the UI independent of the Godot editor

One of the features that Cyclops has had since the beginning is the ability to create and edit blocks directly in the editor viewport.  While this does offer great integration, it also comes with a ton of restrictions that make it hard to add features and debug.  Some things I'd like to add are simply impossible with the way the Godot editor is currently designed, and other things are pretty janky - like having to select a block for the toolbar to appear, or having the viewport display not update right away.  For this reason, I'm considering making Cyclops a stand alone program - still available in Godot for display, but edited in either a separate program or in a 'main screen' plugin.

Please let me know what you think on the discussion board.

### Allow for face-corner UVs

Right now all uvs are auto-generated.  While this is helpful for laying in blocks in world space, it does limit your control over how uvs are arranged on your face.  I would like to add extra data to the block so that uvs can be specified exactly rather than calculated.  If this goes ahead, there should still be a way to autogenerate uvs since this an easy and useful way to arrange uvs for level blocks.


### UI Improvements

The Material manager dock could use some improvements.  The flow layout it currently uses is functional, but it would be nice if things were arranged in columns.  It would also be useful to arrange materials into something like a directory tree since it can become overwhelming once more than fifty or so materials have been added.

### UV Viewport manipulator

Right now the only way to manipulate face uvs is using the UV Transform dock editor.  I'd like to create a control in the viewport that does much the same thing and which should be easier to use.

### General bug fixes

Bug reports have already begun to pour in.  There are lots of minor fixes that need fixing, so keeping the issue count low in the bug tracker is something to work on.

## Support

If you found this software useful, please consider buying me a coffee on Kofi.  Every contribution helps me to make more software:

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/Y8Y43J6OB)
