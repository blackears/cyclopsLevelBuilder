# Prism Tool

The prism tool lets you place multiple points for your base before dragging out the length of your block.

* Click in empty space or on the surface of a block to begin placing points for the base of your block.
     * Keep clicking to place more points for the base
     * To remove the last point you added, press the Backspace key
     * While drawing the base, you can remove any point already placed by right clicking on it
     * To cancel building the block, press the Escape key
     * When you're finished building your base, press Enter to switch to dragging the height of the block.  You can also double click to switch to dragging the height.

![Create prism](create_prism.gif)


### Tool Properties

* Collision Type - Type of collision shape that will be created for this block when it is exported
* Collision Layers - Collision layer flags for created block
* Collision Mask - Collision mask flags for created block
* Alignment
    * Align to surface - The base of the block you're creating will lie along the surface of the nearest surface under the cursor
    * XY Plane - The base of the block will lie on the XY plane
    * XZ Plane - The base of the block will lie on the XZ plane
    * YZ Plane - The base of the block will lie on the YZ plane

* Match active block - Elevation and height properties of the block you are drawing will be copied from the current active block.  This will be in effect if you start drawing the block when the mouse is over an empty space or if `Alignment` has been set to something other than `Align to surface`.
* Orthogonal Viewport - These properties affect properties of the shape you create when you are drawing in an orthogonal viewport and you are not using the active block to define these properties
    * Default Block Elevation - Default elevation of block.
    * Default Block Height - Default height of block.


## Support

If you found this software useful, please consider buying me a coffee on Kofi.  Every contribution helps me to make more software:

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/Y8Y43J6OB)
