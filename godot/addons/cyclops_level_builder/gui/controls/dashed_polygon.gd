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
class_name DashedPolygon


@export var points:PackedVector2Array:
	set(value):
		if value == points:
			return
		points = value
		queue_redraw()

@export var color:Color = Color.WHITE:
	set(value):
		if value == color:
			return
		color = value
		queue_redraw()

@export var dash_width:float = 2:
	set(value):
		if dash_width == value:
			return
		dash_width = value
		queue_redraw()

@export var dash_size:float = 6:
	set(value):
		if value == dash_size:
			return
		dash_size = value
		queue_redraw()
		
func _draw() -> void:
	for p_idx in points.size():
		var p0:Vector2 = points[p_idx]
		var p1:Vector2 = points[wrap(p_idx + 1, 0, points.size())]
		
		draw_dashed_line(p0, p1, color, dash_width, dash_size)
