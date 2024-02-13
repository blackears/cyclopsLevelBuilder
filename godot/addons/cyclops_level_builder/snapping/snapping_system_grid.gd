# MIT License
#
# Copyright (c) 2023 Mark McKay
# https://github.com/blackears/cyclopsLevelBuilder
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool

extends CyclopsSnappingSystem
class_name SnappingSystemGrid

const SNAPPING_TOOL_ID:String = "grid"

var snap_to_grid_util:SnapToGridUtil = SnapToGridUtil.new()

func _activate(plugin:CyclopsLevelBuilder):
	super._activate(plugin)
	
	snap_to_grid_util = plugin.get_global_scene().calc_snap_to_grid_util()

	var cache:Dictionary = plugin.get_snapping_cache(SNAPPING_TOOL_ID)
	snap_to_grid_util.load_from_cache(cache)
		
func _deactivate():
	super._deactivate()

	flush_cache()

func flush_cache():
	var cache:Dictionary = snap_to_grid_util.save_to_cache()
	plugin.set_snapping_cache(SNAPPING_TOOL_ID, cache)

#Point is in world space
func _snap_point(point:Vector3, query:SnappingQuery)->Vector3:
		
	var target_point = snap_to_grid_util.snap_point(point)
	return target_point

func _snap_angle(angle:float, query:SnappingQuery)->float:
	var snap_angle:float = plugin.get_global_scene().settings.get_property(CyclopsGlobalScene.SNAPPING_GRID_ANGLE)
	return floor(angle / snap_angle) * snap_angle


func _get_properties_editor()->Control:
	var ed:SnappingSystemGridPropertiesEditor = preload("res://addons/cyclops_level_builder/snapping/snapping_system_grid_properties_editor.tscn").instantiate()
	ed.tool = self
	
	return ed
	


