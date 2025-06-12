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
extends ToolUv
class_name ToolUvViewportNavigation

enum ToolState { NONE, READY, DRAG_VIEW }
var tool_state:ToolState = ToolState.NONE

@export var tool_name:String = "UV Viewport Navigation"
@export var tool_icon:Texture2D = null
@export_multiline var tool_tooltip:String = "UV Viewport Navigation"


func _get_tool_name()->String:
	return tool_name

func _get_tool_icon()->Texture2D:
	return tool_icon

func _get_tool_tooltip()->String:
	return tool_tooltip

func _is_selectable()->bool:
	return false


func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:
	#var builder:CyclopsLevelBuilder = view.plugin
	#
	#if !builder:
		#return false
		
	print("nav event")

	var uv_ed:UvEditor = view.get_uv_editor()
	var uv_to_view_xform:Transform2D = uv_ed.get_uv_to_viewport_xform()
	
	if event is InputEventKey:
		var e:InputEventKey = event

		if e.keycode == KEY_A:
			var block_indices:Dictionary
			if e.alt_pressed:
				block_indices = {}
			else:
				block_indices = uv_ed.get_uv_indices_in_region(
					Rect2(-Vector2.INF, Vector2.INF),
					false)
			
#					print("block_indices ", block_indices)
			select_face_vertices(block_indices, Selection.Type.REPLACE)

			get_viewport().set_input_as_handled()
			return true

		elif e.keycode == KEY_F:
			focus_on_selected_uvs()
	
			get_viewport().set_input_as_handled()
			return true

	elif event is InputEventMouseButton:

		var e:InputEventMouseButton = event
		if e.button_index == MOUSE_BUTTON_MIDDLE:

			if e.is_pressed():
				if tool_state == ToolState.NONE:
					mouse_down_pos = e.position
					
					tool_state = ToolState.DRAG_VIEW
					drag_start_view_xform = uv_ed.proj_transform

					return true
				
				
				pass
			else:
				if tool_state == ToolState.DRAG_VIEW:
					tool_state = ToolState.NONE
					return true

		elif e.button_index == MOUSE_BUTTON_RIGHT:
			if e.is_pressed():
				if e.shift_pressed:
					var uv_editor:UvEditor = view.get_uv_editor()
					var xform:Transform2D = uv_editor.get_uv_to_viewport_xform()
					uv_editor.pivot_cursor_position = xform.affine_inverse() * e.position
					
			return true

		elif e.button_index == MOUSE_BUTTON_WHEEL_UP:
			if e.pressed:
#				print("uv_move wheel up")
				
				var view_xform:Transform2D = uv_ed.get_view_transform()
				
				var new_xform:Transform2D
#				print("uv_to_view_xform ", uv_to_view_xform)
				new_xform = new_xform.translated_local(e.position)
				new_xform = new_xform.scaled_local(Vector2(zoom_wheel_amount, zoom_wheel_amount))
				new_xform = new_xform.translated_local(-e.position)
				new_xform = new_xform * view_xform * uv_ed.proj_transform
				
				uv_ed.proj_transform = view_xform.affine_inverse() * new_xform

				return true

		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if e.pressed:
				var view_xform:Transform2D = uv_ed.get_view_transform()
				
				var new_xform:Transform2D
#				print("uv_to_view_xform ", uv_to_view_xform)
				new_xform = new_xform.translated_local(e.position)
				new_xform = new_xform.scaled_local(Vector2(1 / zoom_wheel_amount, 1 / zoom_wheel_amount))
				new_xform = new_xform.translated_local(-e.position)
				new_xform = new_xform * view_xform * uv_ed.proj_transform
				
				uv_ed.proj_transform = view_xform.affine_inverse() * new_xform
				
				return true
	
	elif event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event
		
		mouse_hover_pos = e.position
		
		if tool_state == ToolState.DRAG_VIEW:
			var offset:Vector2 = e.position - mouse_down_pos
			var view_xform:Transform2D = uv_ed.get_view_transform()
			var new_xform:Transform2D = (view_xform * drag_start_view_xform).translated(offset)
			
			uv_ed.proj_transform = view_xform.affine_inverse() * new_xform
			
			return true

	return false
