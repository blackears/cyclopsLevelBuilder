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
extends Gizmo2D
class_name GizmoRing2D

@export var color:Color = Color(1, 1, 1, 1):
	set(value):
		color = value
		queue_redraw()

@export var radius:float = 20:
	set(value):
		radius = value
		queue_redraw()

@export var width:float = 2:
	set(value):
		width = value
		queue_redraw()

@export var segments:float = 32:
	set(value):
		segments = value
		queue_redraw()

#func pick(p:Vector2, radius:float)->bool:
	#return rect.has_point(p)
func calc_mesh_points()->PackedVector2Array:
	var points:PackedVector2Array
	
	var angle_incrment = (PI * 2) / segments

	for s_idx in segments + 1:
		var a0:float = angle_incrment * s_idx
		
		var sin_a0:float = sin(a0)
		var cos_a0:float = cos(a0)
		
		points.append(Vector2(sin_a0, cos_a0) * radius)
	
	#for s_idx in segments:
		#var a0:float = angle_incrment * s_idx
		#var a1:float = angle_incrment * (s_idx + 1)
		#
		#var sin_a0:float = sin(a0)
		#var sin_a1:float = sin(a1)
		#var cos_a0:float = cos(a0)
		#var cos_a1:float = cos(a1)
		#
		#points.append(Vector2(sin_a0, cos_a0) * (radius - thickness))
		#points.append(Vector2(sin_a0, cos_a0) * (radius + thickness))
		#points.append(Vector2(sin_a1, cos_a1) * (radius + thickness))
		#points.append(Vector2(sin_a1, cos_a1) * (radius - thickness))
	
	return points

func pick(p:Vector2, select_radius:float = 0)->bool:
	var points:PackedVector2Array = calc_mesh_points()
	
	if MathUtil.intersects_2d_point_polyline(p, select_radius, points):
		return true
	
	return false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _draw():
	var points:PackedVector2Array = calc_mesh_points()
	
	draw_polyline(points, color, width)
	#print("points ", points)
		
