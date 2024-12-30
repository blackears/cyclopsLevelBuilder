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
class_name GizmoRect2D

signal pressed(pos:Vector2)
signal released(pos:Vector2)
signal dragged_to(pos:Vector2)

@export var color:Color = Color(1, 1, 1, .5):
	set(value):
		color = value
		queue_redraw()

@export var color_outline:Color = Color.WHITE:
	set(value):
		color_outline = value
		queue_redraw()

@export var rect:Rect2 = Rect2(-10, -10, 20, 20):
	set(value):
		rect = value
		queue_redraw()

var dragging:bool = false

func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseButton:
		print("GizmoRect2D InputEventMouseButton")
		var e:InputEventMouseButton = event
		
		if e.is_pressed():
			var local_pos:Vector2 = global_transform.affine_inverse() * e.position
			var hit:bool = pick(local_pos, 0)
			
			if hit:
				dragging = true
				pressed.emit(e.position)
				
				get_viewport().set_input_as_handled()
		else:
			if dragging:
				dragging = false
				released.emit(e.position)
				get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event
		
		if dragging:
			dragged_to.emit(e.position)
			get_viewport().set_input_as_handled()
			

func pick(p:Vector2, radius:float)->bool:
	return rect.has_point(p)

func _draw():
	var colors:PackedColorArray
	
	draw_rect(rect, color)
	draw_rect(rect, color_outline, false)
	
		
