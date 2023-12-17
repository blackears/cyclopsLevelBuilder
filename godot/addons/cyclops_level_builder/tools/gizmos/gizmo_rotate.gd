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
extends GizmoBase
class_name GizmoRotate

enum Part { NONE, PLANE_XY, PLANE_XZ, PLANE_YZ, VIEWPORT, TRACKBALL }


class IntersectResult:
	var part:Part
	var pos_world:Vector3
	
	
# Called when the node enters the scene tree for the first time.
func _ready():
	$gizmo_rotate/rot_axis_viewport.visible = false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	get_viewport()
	pass


func intersect(ray_origin:Vector3, ray_dir:Vector3, viewport_camera:Camera3D)->IntersectResult:
	var result:IntersectResult = IntersectResult.new()
	result.part = Part.NONE

	for child in $gizmo_rotate.get_children():
		var part_res:MathUtil.IntersectTriangleResult = intersect_part(ray_origin, ray_dir, viewport_camera, child)
		
		if part_res:
			result.pos_world = part_res.position
			match child.name:
				"rot_axis_x":
					result.part = Part.PLANE_YZ
				"rot_axis_y":
					result.part = Part.PLANE_XZ
				"rot_axis_z":
					result.part = Part.PLANE_XY
					
			return result
#			print("hit " + child.name)
#			return
	
	return null


