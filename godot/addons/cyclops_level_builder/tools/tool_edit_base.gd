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
extends CyclopsTool
class_name ToolEditBase

var mouse_hover_pos:Vector2

var drag_select_start_pos:Vector2
var drag_select_to_pos:Vector2

func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:	
	
	if event is InputEventKey:
		var e:InputEventKey = event
		
		if e.keycode == KEY_Q && e.alt_pressed:
			select_block_under_cursor(viewport_camera, mouse_hover_pos)
				
			return true
	
	
	elif event is InputEventMouseButton:
		var e:InputEventMouseButton = event
		mouse_hover_pos = e.position
		return false
		
	elif event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event
		mouse_hover_pos = e.position		
		return false
		
	return false

func pick_material(global_scene:CyclopsGlobalScene, selected:bool = false, active = false)->Material:
	if active:
		return global_scene.tool_edit_active_material
	if selected:
		return global_scene.tool_edit_selected_material
	return global_scene.tool_edit_unselected_material

func pick_vertex_material(global_scene:CyclopsGlobalScene, selected:bool = false, active = false)->Material:
	if active:
		return global_scene.vertex_active_material
	if selected:
		return global_scene.vertex_selected_material
	return global_scene.vertex_unselected_material
	
	
func calc_gizmo_basis(average_normal:Vector3, active_block:Node3D, viewport_camera:Camera3D, orientation:TransformSpace.Type)->Basis:
	var result:Basis
	
	match orientation:
		TransformSpace.Type.GLOBAL:
			result = Basis.IDENTITY
		TransformSpace.Type.LOCAL:
			result = active_block.global_basis
			
			#var xform:Transform3D = active_block.global_transform
			#gizmo_translate.global_transform = xform
			#gizmo_translate.global_position = origin
		TransformSpace.Type.NORMAL:
			var up:Vector3 = Vector3.UP
			var x:Vector3 = up.cross(average_normal).normalized()
			var y:Vector3 = average_normal.cross(x)
			#gizmo_translate.global_basis = Basis(x, y, average_normal)
			#gizmo_translate.global_position = origin
			result = Basis(x, y, average_normal)
		TransformSpace.Type.VIEW:
			#gizmo_translate.global_basis = viewport_camera.global_basis
			#gizmo_translate.global_position = origin
			
			result = viewport_camera.global_basis
		TransformSpace.Type.PARENT:
			result = active_block.get_parent_node_3d().global_basis
			#var xform:Transform3D = active_block.get_parent_node_3d().global_transform
			#gizmo_translate.global_transform = xform

	return result	
