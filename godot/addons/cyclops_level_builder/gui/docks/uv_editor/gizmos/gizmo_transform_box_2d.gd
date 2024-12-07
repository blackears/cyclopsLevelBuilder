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
class_name GizmoTransformBox2D

@export var color:Color = Color.WHITE:
	set(value):
		color = value
		queue_redraw()

@export var outline_color:Color = Color.BLACK:
	set(value):
		outline_color = value
		queue_redraw()

@export var rect:Rect2 = Rect2(0, 0, 60, 60):
	set(value):
		rect = value
		queue_redraw()

@export var dash_width:float = 2:
	set(value):
		dash_width = value
		queue_redraw()

@export var dash_size:float = 6:
	set(value):
		dash_size = value
		queue_redraw()

func _draw() -> void:
	#draw_rect(rect, color, false)
	var points_edges = [
		rect.position,
		Vector2(rect.position.x, rect.end.y),
		rect.end,
		Vector2(rect.end.x, rect.position.y),
		]
		
	for p_idx in points_edges.size():
		var p0:Vector2 = points_edges[p_idx]
		var p1:Vector2 = points_edges[wrap(p_idx + 1, 0, points_edges.size())]
		
		draw_dashed_line(p0, p1, color, dash_width, dash_size)
	
	%handle_00.position = rect.position
	%handle_01.position = rect.position + rect.size * Vector2(0, .5)
	%handle_02.position = rect.position + rect.size * Vector2(0, 1)
	%handle_10.position = rect.position + rect.size * Vector2(.5, 0)
	%handle_12.position = rect.position + rect.size * Vector2(.5, 1)
	%handle_20.position = rect.position + rect.size * Vector2(1, 0)
	%handle_21.position = rect.position + rect.size * Vector2(1, .5)
	%handle_22.position = rect.position + rect.size * Vector2(1, 1)
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
