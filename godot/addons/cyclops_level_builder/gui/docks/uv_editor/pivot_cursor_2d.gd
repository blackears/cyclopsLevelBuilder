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
extends Node2D
class_name PivotCursor2D

@export var radius:float = 15:
	set(v):
		if v == radius:
			return
		radius = v
		rebuild_mesh = true
		
		queue_redraw()

@export var width:float = 2:
	set(v):
		if v == width:
			return
		width = v
		
		queue_redraw()

@export var segments:int = 32:
	set(v):
		if v == segments:
			return
		segments = v
		rebuild_mesh = true
		
		queue_redraw()
		
@export var main_color:Color = Color.WHITE:
	set(v):
		if v == main_color:
			return
		main_color = v
		
		queue_redraw()
	
@export var dash_color:Color = Color.RED:
	set(v):
		if v == dash_color:
			return
		dash_color = v
		
		queue_redraw()

@export var axes_color:Color = Color.BLACK:
	set(v):
		if v == axes_color:
			return
		axes_color = v
		
		queue_redraw()

var circle_points:PackedVector2Array
var rebuild_mesh:bool = true

func _draw():
	draw_line(Vector2(-radius * 3 / 2.0, 0), Vector2(radius * 3 / 2.0, 0), axes_color, 1)
	draw_line(Vector2(0, -radius * 3 / 2.0), Vector2(0, radius * 3 / 2.0), axes_color, 1)
	
	var seg_scalar:float = 1.0 / segments
	if rebuild_mesh:
		circle_points.resize(segments)
		for i in segments:
			circle_points[i] = Vector2(sin(i * seg_scalar * TAU), cos(i * seg_scalar * TAU)) * radius
			#print("i ", i)
			#print("i * 2.0 * PI ", i * 2.0 * PI)
			#print("sin(float(i) * 2.0 * PI) ", sin(float(i) * 2.0 * PI))
			#print("circle_points[i] ", circle_points[i])
		
		rebuild_mesh = false
	
	for i in segments:
		draw_line(circle_points[i], 
			circle_points[wrap(i + 1, 0, segments)], 
			main_color if ((i / 4) % 2) == 0 else dash_color, 
			width)
	
	
	
	pass
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
