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
class_name GizmoTransformBox2D

enum Part { NONE, PLANE_Z, 
	CORNER_00, CORNER_10, CORNER_20,
	CORNER_01, CORNER_21,
	CORNER_02, CORNER_12, CORNER_22,
	CORNER_ROT_00, CORNER_ROT_10, CORNER_ROT_20,
	CORNER_ROT_01, CORNER_ROT_21,
	CORNER_ROT_02, CORNER_ROT_12, CORNER_ROT_22,
	PIVOT
}


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

@export var pivot:Vector2 = Vector2(10, 20):
	set(value):
		pivot = value
		queue_redraw()

@onready var handle_00:GizmoRect2D = %handle_00
@onready var handle_01:GizmoRect2D = %handle_01
@onready var handle_02:GizmoRect2D = %handle_02
@onready var handle_10:GizmoRect2D = %handle_10
@onready var handle_12:GizmoRect2D = %handle_12
@onready var handle_20:GizmoRect2D = %handle_20
@onready var handle_21:GizmoRect2D = %handle_21
@onready var handle_22:GizmoRect2D = %handle_22

@onready var handle_rot_00:GizmoRect2D = %handle_rot_00
@onready var handle_rot_01:GizmoRect2D = %handle_rot_01
@onready var handle_rot_02:GizmoRect2D = %handle_rot_02
@onready var handle_rot_10:GizmoRect2D = %handle_rot_10
@onready var handle_rot_12:GizmoRect2D = %handle_rot_12
@onready var handle_rot_20:GizmoRect2D = %handle_rot_20
@onready var handle_rot_21:GizmoRect2D = %handle_rot_21
@onready var handle_rot_22:GizmoRect2D = %handle_rot_22

@onready var handle_pivot:GizmoCircle2D = %handle_pivot


func pick_part(pos:Vector2)->Part:
#	print("pick_part ", pos)
	if handle_00.pick(handle_00.global_transform.affine_inverse() * pos, 0):
		return Part.CORNER_00
	if handle_01.pick(handle_01.global_transform.affine_inverse() * pos, 0):
		return Part.CORNER_01
	if handle_02.pick(handle_02.global_transform.affine_inverse() * pos, 0):
		return Part.CORNER_02
	if handle_10.pick(handle_10.global_transform.affine_inverse() * pos, 0):
		return Part.CORNER_10
	if handle_12.pick(handle_12.global_transform.affine_inverse() * pos, 0):
		return Part.CORNER_12
	if handle_20.pick(handle_20.global_transform.affine_inverse() * pos, 0):
		return Part.CORNER_20
	if handle_21.pick(handle_21.global_transform.affine_inverse() * pos, 0):
		return Part.CORNER_21
	if handle_22.pick(handle_22.global_transform.affine_inverse() * pos, 0):
		return Part.CORNER_22

	if handle_rot_00.pick(handle_rot_00.global_transform.affine_inverse() * pos, 0):
		return Part.CORNER_ROT_00
	if handle_rot_01.pick(handle_rot_01.global_transform.affine_inverse() * pos, 0):
		return Part.CORNER_ROT_01
	if handle_rot_02.pick(handle_rot_02.global_transform.affine_inverse() * pos, 0):
		return Part.CORNER_ROT_02
	if handle_rot_10.pick(handle_rot_10.global_transform.affine_inverse() * pos, 0):
		return Part.CORNER_ROT_10
	if handle_rot_12.pick(handle_rot_12.global_transform.affine_inverse() * pos, 0):
		return Part.CORNER_ROT_12
	if handle_rot_20.pick(handle_rot_20.global_transform.affine_inverse() * pos, 0):
		return Part.CORNER_ROT_20
	if handle_rot_21.pick(handle_rot_21.global_transform.affine_inverse() * pos, 0):
		return Part.CORNER_ROT_21
	if handle_rot_22.pick(handle_rot_22.global_transform.affine_inverse() * pos, 0):
		return Part.CORNER_ROT_22

	if handle_pivot.pick(handle_pivot.global_transform.affine_inverse() * pos, 0):
		return Part.PIVOT

	if rect.has_point(global_transform.affine_inverse() * pos):
		return Part.PLANE_Z

	return Part.NONE

func _draw() -> void:
	print("gizmo_transform_box _draw()")
	print("rect ", rect)
	
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
	
	handle_00.position = rect.position
	handle_01.position = rect.position + rect.size * Vector2(0, .5)
	handle_02.position = rect.position + rect.size * Vector2(0, 1)
	handle_10.position = rect.position + rect.size * Vector2(.5, 0)
	handle_12.position = rect.position + rect.size * Vector2(.5, 1)
	handle_20.position = rect.position + rect.size * Vector2(1, 0)
	handle_21.position = rect.position + rect.size * Vector2(1, .5)
	handle_22.position = rect.position + rect.size * Vector2(1, 1)
	
	handle_pivot.position = pivot

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
