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
extends Resource
class_name SnapToGridUtil

#const feet_per_meter:float = 3.28084

@export var unit_size:float = 1

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

func load_from_cache(cache:Dictionary):
	unit_size = cache.get("unit_size", 1)
	use_subdivisions = cache.get("use_subdivisions", false)
	grid_subdivisions = cache.get("grid_subdivisions", 10)
	power_of_two_scale = cache.get("power_of_two_scale", 0)
	#print("load grid_transform before")
	grid_transform = SerialUtil.load_cache_transform_3d(cache.get("grid_transform", ""), Transform3D.IDENTITY)
	#print("load grid_transform after ")
	
	if is_zero_approx(grid_transform.basis.determinant()):
		#print("replace")
		grid_transform = Transform3D.IDENTITY
	#grid_transform = cache.get("grid_transform", Transform3D.IDENTITY)
	
func save_to_cache():
	#print("save SnapToGridUtil")
	return {
		"unit_size": unit_size,
		"use_subdivisions": use_subdivisions,
		"grid_subdivisions": grid_subdivisions,
		"power_of_two_scale": power_of_two_scale,
		"grid_transform": SerialUtil.save_cache_transform_3d(grid_transform),
	}

#Point is in world space
func snap_point(point:Vector3)->Vector3:
	
	var p_local:Vector3 = grid_transform_inv * point
	
	#print("unit_size %s  pow 2 %s" % [unit_size, pow(2, power_of_two_scale)])
	var scale:Vector3 = Vector3.ONE * unit_size * pow(2, power_of_two_scale)
	if use_subdivisions:
		scale /= float(grid_subdivisions)
	
	p_local = floor(p_local / scale + Vector3(.5, .5, .5)) * scale
	
	var target_point:Vector3 = grid_transform * p_local
	
	#print("point %s  target_point %s  scale %s" % [point, target_point, scale])
	return target_point

func _to_string():
	return "unit_size %s  use_subdiv %s  subdiv %s  pot %s  xform %s" \
		% [unit_size, use_subdivisions, grid_subdivisions, power_of_two_scale, grid_transform]


