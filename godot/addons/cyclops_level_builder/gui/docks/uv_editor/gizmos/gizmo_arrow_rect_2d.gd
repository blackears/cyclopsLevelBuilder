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
class_name GizmoArrowSquare2D

@export var color:Color = Color.WHITE:
	set(value):
		color = value
		queue_redraw()
		
@export var shaft_length:float = 100:
	set(value):
		shaft_length = value
		queue_redraw()
		
@export var shaft_width:float = 1:
	set(value):
		shaft_width = value
		queue_redraw()
	
@export var head_base_length:float = 5:
	set(value):
		head_base_length = value
		queue_redraw()
	
@export var head_length:float = 12:
	set(value):
		head_length = value
		queue_redraw()

func calc_mesh_points()->PackedVector2Array:
	var points:PackedVector2Array = [
		Vector2(0, shaft_width),
		Vector2(shaft_length, shaft_width),
		Vector2(shaft_length, shaft_width + head_base_length),
		Vector2(shaft_length + head_length, shaft_width + head_base_length),
		Vector2(shaft_length + head_length, -shaft_width - head_base_length),
		Vector2(shaft_length, -shaft_width - head_base_length),
		Vector2(shaft_length, -shaft_width),
		Vector2(0, -shaft_width),
		]
	return points

func pick(p:Vector2, radius:float)->bool:
	var points:PackedVector2Array = calc_mesh_points()
	print("points ", points)
	print("grect pick point local ", p, " name ", name)
	
	
	if MathUtil.intersects_2d_point_polygon(p, points):
		print("hit <1>")
		return true
	if MathUtil.intersects_2d_point_polyline(p, radius, points):
		print("hit <2>")
		return true
	
	return false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _draw():
	var points:PackedVector2Array = calc_mesh_points()
	
	var colors:PackedColorArray
	colors.resize(points.size())
	colors.fill(color)
	
	#print("points ", points)
	
	draw_polygon(points, colors)
