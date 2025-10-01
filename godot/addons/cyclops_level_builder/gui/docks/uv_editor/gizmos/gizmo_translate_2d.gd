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
class_name GizmoTranslate2D

signal pressed(pos:Vector2, part:Part)
signal released(pos:Vector2, part:Part)
signal dragged_to(pos:Vector2, part:Part)

enum Part { NONE, AXIS_X, AXIS_Y, PLANE_Z }

@onready var axis_x:GizmoArrow2D = $axis_x
@onready var axis_y:GizmoArrow2D = $axis_y
@onready var plane_z:GizmoRect2D = $plane_z

func pick_part(pos:Vector2)->Part:
#	print("pick_part ", pos)
	if plane_z.pick(plane_z.global_transform.affine_inverse() * pos, 0):
		return Part.PLANE_Z

	if axis_x.pick(axis_x.global_transform.affine_inverse() * pos, 0):
		return Part.AXIS_X

	if axis_y.pick(axis_y.global_transform.affine_inverse() * pos, 0):
		return Part.AXIS_Y
		
	return Part.NONE


func _on_axis_x_pressed(pos: Vector2) -> void:
	pressed.emit(pos, Part.AXIS_X)

func _on_axis_x_released(pos: Vector2) -> void:
	released.emit(pos, Part.AXIS_X)


func _on_axis_x_dragged_to(pos: Vector2) -> void:
	dragged_to.emit(pos, Part.AXIS_X)


func _on_axis_y_pressed(pos: Vector2) -> void:
	pressed.emit(pos, Part.AXIS_Y)


func _on_axis_y_released(pos: Vector2) -> void:
	released.emit(pos, Part.AXIS_Y)


func _on_axis_y_dragged_to(pos: Vector2) -> void:
	dragged_to.emit(pos, Part.AXIS_Y)


func _on_plane_z_pressed(pos: Vector2) -> void:
	pressed.emit(pos, Part.PLANE_Z)


func _on_plane_z_released(pos: Vector2) -> void:
	released.emit(pos, Part.PLANE_Z)


func _on_plane_z_dragged_to(pos: Vector2) -> void:
	dragged_to.emit(pos, Part.PLANE_Z)
