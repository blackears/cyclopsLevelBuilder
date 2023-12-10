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

#const feet_per_meter:float = 3.28084

@export var grid_size:Vector3 = Vector3(1, 1, 1)

@export var use_subdivisions:bool = false
@export var grid_subdivisions:int = 10

@export var power_of_two_scale:int = 0 #Scaling 2^n

#local transform matrix for grid
@export var grid_transform:Transform3D = Transform3D.IDENTITY:
	get:
		return grid_transform
	set(value):
		grid_transform = value
		grid_transform_inv = grid_transform.affine_inverse()
		
var grid_transform_inv:Transform3D = Transform3D.IDENTITY


#Point is in world space
func _snap_point(point:Vector3, move_constraint:MoveConstraint)->Vector3:
	
	var p_local:Vector3 = grid_transform_inv * point
	
	var scale:Vector3 = grid_size * pow(2, power_of_two_scale)
	if use_subdivisions:
		scale /= grid_subdivisions
	
	p_local = floor(p_local / scale + Vector3(.5, .5, .5)) * scale
	
	var target_point:Vector3 = grid_transform * p_local
	return constrain_point(point, target_point, move_constraint)

func _get_properties_editor()->Control:
	var ed:SnappingSystemGridPropertiesEditor = preload("res://addons/cyclops_level_builder/snapping/snapping_system_grid_properties_editor.tscn").instantiate()
	ed.properties = self
	
	return ed



