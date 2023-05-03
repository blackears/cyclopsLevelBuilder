#Roadmap

Here's a list of changes I'm thinking of making in future revisions of the project.


### Make Blocks extend Node3D

At the moment, `CyclopsConvexBlock` extends `Node` and must be a child of a `CyclopsBlocks` node to be rendered.  Behind the scenes, the `CyclopsBlocks` is creating `CyclopsConvexBlockBody` nodes to draw the geometry.  Not only is this overly complicated, but it prevents the user from arranging the blocks in the scene tree and tweaking individual properties on the block, such as if it should have collision or be part of a moving platform.  I went with the original design because I was worried about how this would affect snapping, but I think I can get around this if I design a new move tool specific for moving blocks.

I feel this is the most important change to make, although this will also involve rewriting a lot of code.

### Switch from using convex blocks to general blocks

At the moment, all blocks in the scene are forced to be convex.  It could be useful to switch to using a general mesh that allows users to make blocks with indentations, inside corners or faces with cuts in them.  This would make a lot of vertex, edge and face operations more accurate and allow users to have more control.  You could potentially even model characters or objects this way.  However, it might also make things more messy and make laying in level blocks less efficient.  I'm not entirely sure if I should go ahead with this idea.

### Allow for face-corner UVs

Right now all uvs are auto-generated.  While this is helpful for laying in blocks in world space, it does limit your control over how uvs are arranged on your face.  I would like to add extra data to the block so that uvs can be specified exactly rather than calculated.  If this goes ahead, there should still be a way to autogenerate uvs since this an easy and useful way to arrange uvs for level blocks.


### UI Improvements

At the moment, the editor toolbar does not look very good.  I'm not sure how to format the control so it sits nicely in the editor menu.  There also need to be icons generated for the different tools.

The Material manager dock could also use some improvements.  The flow layout it currently uses is functional, but it would be nice if things were arranged in columns.  It would also be useful to arrange materials into something like a directory tree since it can become overwhelming once more than fifty or so materials have been added.

### UV Viewport manipulator

Right now the only way to manipulate face uvs is using the UV Transform dock editor.  I'd like to create a control in the viewport that does much the same thing and which should be easier to use.

### General bug fixes

Bug reports have already begun to pour in.  There are lots of minor fixes that need fixing, so keeping the issue count low in the bug tracker is something to work on.

## Support

If you found this software useful, please consider buying me a coffee on Kofi.  Every contribution helps me to make more software:

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/Y8Y43J6OB)
