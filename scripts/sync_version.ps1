
(Get-Content "godot/addons/cyclops_level_builder/plugin.cfg") -replace "version=.*", "version=" | Set-Content "godot/addons/cyclops_level_builder/plugin.cfg"