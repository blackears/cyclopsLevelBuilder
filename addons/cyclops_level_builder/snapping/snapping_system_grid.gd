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

var snap_to_grid_util:SnapToGridUtil = SnapToGridUtil.new()

func _activate(plugin:CyclopsLevelBuilder):
	super._activate(plugin)
	
	snap_to_grid_util.unit_size = CyclopsAutoload.settings.get_property(CyclopsGlobalScene.SNAPPING_GRID_UNIT_SIZE, 1)
	snap_to_grid_util.power_of_two_scale = CyclopsAutoload.settings.get_property(CyclopsGlobalScene.SNAPPING_GRID_POWER_OF_TWO_SCALE, 0)
	snap_to_grid_util.use_subdivisions = CyclopsAutoload.settings.get_property(CyclopsGlobalScene.SNAPPING_GRID_USE_SUBDIVISIONS, false)
	snap_to_grid_util.grid_subdivisions = CyclopsAutoload.settings.get_property(CyclopsGlobalScene.SNAPPING_GRID_SUBDIVISIONS, 10)
	snap_to_grid_util.grid_transform = CyclopsAutoload.settings.get_property(CyclopsGlobalScene.SNAPPING_GRID_TRANSFORM, Transform3D.IDENTITY)
	
func _deactivate():
	super._deactivate()
	
	CyclopsAutoload.settings.set_property(CyclopsGlobalScene.SNAPPING_GRID_UNIT_SIZE, snap_to_grid_util.unit_size)
	CyclopsAutoload.settings.set_property(CyclopsGlobalScene.SNAPPING_GRID_POWER_OF_TWO_SCALE, snap_to_grid_util.power_of_two_scale)
	CyclopsAutoload.settings.set_property(CyclopsGlobalScene.SNAPPING_GRID_USE_SUBDIVISIONS, snap_to_grid_util.use_subdivisions)
	CyclopsAutoload.settings.set_property(CyclopsGlobalScene.SNAPPING_GRID_SUBDIVISIONS, snap_to_grid_util.grid_subdivisions)
	CyclopsAutoload.settings.set_property(CyclopsGlobalScene.SNAPPING_GRID_TRANSFORM, snap_to_grid_util.grid_transform)
	
	CyclopsAutoload.save_settings()
	

#Point is in world space
func _snap_point(point:Vector3, move_constraint:MoveConstraint.Type = MoveConstraint.Type.NONE)->Vector3:
	
	var target_point = snap_to_grid_util.snap_point(point)
	return constrain_point(point, target_point, move_constraint)

func _get_properties_editor()->Control:
	var ed:SnappingSystemGridPropertiesEditor = preload("res://addons/cyclops_level_builder/snapping/snapping_system_grid_properties_editor.tscn").instantiate()
	ed.tool = self
	
	return ed
	


