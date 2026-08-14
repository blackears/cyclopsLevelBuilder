# Cyclops Level Builder

Cyclops Level Builder lets you quickly build environments in the Godot viewport.  Click and drag to create and edit blocks.  Use the material editor to assign materials.  All blocks have collision, so you will be able to interact with them right away.

Cyclops Level Builder 1.5.0 works with Godot version 4.7 and later.  Cyclops Level Builder 1.0.2 works with Godot version 4.2 and later.  Versions 1.0.1 and earlier will work with Godot 4.0.

[![Quick demo video](https://img.youtube.com/vi/mbw_6dnOt_g/0.jpg)](https://www.youtube.com/watch?v=mbw_6dnOt_g)


## Installation

* [Download the latest release](https://github.com/blackears/cyclopsLevelBuilder/releases) from the releases page.  Unzip it into a temporary directory.
* Copy the `/addons/cyclops_level_builder` folder and everything in it into the `/addons` folder of the project you want to use Cyclops Level Builder in.
* Click on `Project/Project Settings`.
    * Select the `Plugins` tab and check `Enable` next to the Cyclops Level Builder entry.
    ![Enable addon](doc/enable_addon.jpg)
    * Select the `Globals` tab and make sure that there is an entry called `CyclopsAutoload` and it has the path `res://addons/cyclops_level_builder/cyclops_autoload.tscn`, and that it is enabled.  This should be done automatically with version 1.5.0, but needs to be added manually in earlier versions.  It could also be disabled if you are upgrading from an earlier version of Cyclops Level Builder.


## Upgrading

> It is strongly recommended that you make a backup of your project before upgrading to a newer version of Cyclops Level Builder.

Some updates may break previously built scenes.  You can use the import/export features to migrate level assets between incompatible versions.  Also, if you use a version control system - such as Github - you can restore previously trashed data and then export it.

If you're upgrading your project from Cyclops v1.0.0, v1.0.1 or an earlier development version of v1.0.2, you will need to upgrade your CyclopsBlocks object.  To do this, simply select your CyclopsBlocks object in the Scene outliner and click the Upgrade button that appears in the toolbar.  This will create a new subtree in your scene where the CyclopsConvexBlock objects are replaced with the new CyclopsBlock object.  Your old CyclopsBlocks will still be there, but with its visibility turned off.  You can now delete the CyclopsBlocks object if you no longer require it.


## Documentation

[Documentation for using Cyclops Level Builder is available here.](https://blackears.github.io/cyclopsLevelBuilder/)


## Contributing 

Please open small issues.  PRs are welcome for small fixes.  Broader ideas can be opened for discussion in the [Discussions](https://github.com/blackears/cyclopsLevelBuilder/discussions) forum.


## Support

If you found this software useful, please consider buying me a coffee on Kofi.  Every contribution helps me to make more software:

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/Y8Y43J6OB)

