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
class_name ToolUvBoxTransform

enum ToolState { NONE, READY, DRAG_VIEW, DRAG_SELECTION, DRAG_UVS }
var tool_state:ToolState = ToolState.NONE

@export var tool_name:String = "Box Transform UVs"
@export var tool_icon:Texture2D = preload("res://addons/cyclops_level_builder/art/icons/box_transform.svg")
@export_multiline var tool_tooltip:String = "Box Transform UVs"


var gizmo:GizmoTransformBox2D

func _get_tool_name()->String:
	return tool_name

func _get_tool_icon()->Texture2D:
	return tool_icon

func _get_tool_tooltip()->String:
	return tool_tooltip

func _get_tool_properties_editor()->Control:
	return null

func _can_handle_object(node:Node)->bool:
	#print("_can_handle_object -- uv move")
	#return node is CyclopsBlock
	return true

func reset_gizmo():
	print("reset_gizmo()")
	var uv_ed:UvEditor = view.get_uv_editor()

	var uv_to_viewport_xform:Transform2D = uv_ed.get_uv_to_viewport_xform()
	
	var uv_rect:Rect2 = get_uv_bounds()
	if uv_rect.size.is_zero_approx():
		gizmo.visible = false
		return
	
	var view_a:Vector2 = uv_to_viewport_xform * uv_rect.position
	var view_b:Vector2 = uv_to_viewport_xform * uv_rect.end
	
	var view_00:Vector2 = view_a.min(view_b)
	var view_11:Vector2 = view_a.max(view_b)
	
	
	gizmo.visible = true
	gizmo.rect = Rect2(view_00, view_11 - view_00)
	
	pass

func _draw_tool(viewport_camera:Camera3D):
	if !gizmo:
		return
	
	var uv_ed:UvEditor = view.get_uv_editor()

	var uv_to_viewport_xform:Transform2D = uv_ed.get_uv_to_viewport_xform()
	
	var uv_rect:Rect2 = get_uv_bounds()
	if uv_rect.size.is_zero_approx():
		gizmo.visible = false
		return
	
	gizmo.visible = true
	
	
	#var center_struct:Dictionary = get_selected_uv_center()
	#
	#if center_struct["count"] >= 2:
		#var centroid:Vector2 = center_struct["centroid"]
		#gizmo.position = uv_to_viewport_xform * centroid
##		print("gizmo.position ", gizmo.position)
		#gizmo.visible = true
	#else:
		#gizmo.visible = false
		
func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:
	if !builder || !focused:
		return false

	var uv_ed:UvEditor = view.get_uv_editor()
	var uv_to_view_xform:Transform2D = uv_ed.get_uv_to_viewport_xform()
	

	if event is InputEventKey:
		var e:InputEventKey = event
		
		if e.keycode == KEY_ESCAPE:
			if tool_state == ToolState.DRAG_UVS:
				#scale_uvs(Vector2.ONE, uv_pivot, false)
				
				get_viewport().set_input_as_handled()
				tool_state = ToolState.NONE
				return true
				
			elif tool_state == ToolState.DRAG_SELECTION:
				uv_ed.show_selection_rect = false
				
				tool_state = ToolState.NONE
				return true

	elif event is InputEventMouseButton:
		#print("mouse bn ", event)

		var e:InputEventMouseButton = event
		if e.button_index == MOUSE_BUTTON_LEFT:

			if e.is_pressed():
				if tool_state == ToolState.NONE:
					mouse_down_pos = e.position
					
					var part:GizmoTransformBox2D.Part = gizmo.pick_part(e.position)
					
					###########
					
					tool_state = ToolState.READY
					#print("mouse ready")

					return true
			else:
				if tool_state == ToolState.READY:
					#Do single click
					var block_indices:Dictionary = uv_ed.get_uv_indices_in_region(
							Rect2(e.position - Vector2.ONE * builder.drag_start_radius / 2, 
							Vector2.ONE * builder.drag_start_radius),
							true)
					
					select_face_vertices(block_indices,
						Selection.choose_type(e.shift_pressed, e.ctrl_pressed))

					tool_state = ToolState.NONE
					return true
					
				elif tool_state == ToolState.DRAG_SELECTION:
					#Finish drag rect
#					print("finish drag rect")
					var p0:Vector2 = Vector2(min(mouse_down_pos.x, e.position.x), 
						min(mouse_down_pos.y, e.position.y))
					var p1:Vector2 = Vector2(max(mouse_down_pos.x, e.position.x), 
						max(mouse_down_pos.y, e.position.y))
					
					var block_indices:Dictionary = uv_ed.get_uv_indices_in_region(
							Rect2(p0, p1 - p0),
							false)
					
#					print("block_indices ", block_indices)
					select_face_vertices(block_indices,
						Selection.choose_type(e.shift_pressed, e.ctrl_pressed))
					
					uv_ed.show_selection_rect = false
					tool_state = ToolState.NONE
				
					return true
			return true

		return false
		
	elif event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event
		
		mouse_hover_pos = e.position

		if tool_state == ToolState.READY:
			var offset:Vector2 = e.position - mouse_down_pos
			if offset.length_squared() > MathUtil.square(builder.drag_start_radius):
#				print("start drag")
				
				tool_state = ToolState.DRAG_SELECTION
				uv_ed.show_selection_rect = true
				uv_ed.selection_rect = Rect2(mouse_down_pos, e.position - mouse_down_pos)
#				print("sel rect ", uv_ed.selection_rect)

			return true
			
		elif tool_state == ToolState.DRAG_SELECTION:
			
			uv_ed.selection_rect = Rect2(mouse_down_pos, e.position - mouse_down_pos)
			return true

	return super._gui_input(viewport_camera, event)
	
func _activate(tool_owner:Node):
	super._activate(tool_owner)
	
	var uv_ed:UvEditor = view.get_uv_editor()
	
	gizmo = preload("res://addons/cyclops_level_builder/gui/docks/uv_editor/gizmos/gizmo_transform_box_2d.tscn").instantiate()
	uv_ed.add_gizmo(gizmo)

	var ed_iface:EditorInterface = builder.get_editor_interface()
	var ed_sel:EditorSelection = ed_iface.get_selection()
	ed_sel.selection_changed.connect(on_block_selection_changed)
	
	track_selected_blocks()
	
	_draw_tool(null)

func _deactivate():
	super._deactivate()

	mvd_cache.clear()
	
	clear_tracked_blocks()
	
	gizmo.queue_free()
	gizmo = null
	
	var ed_iface:EditorInterface = builder.get_editor_interface()
	var ed_sel:EditorSelection = ed_iface.get_selection()
	ed_sel.selection_changed.disconnect(on_block_selection_changed)
	

func on_block_selection_changed():
	print("on_block_selection_changed()")
	track_selected_blocks()
	reset_gizmo()

#Override mesh changed signal
func on_mesh_changed(block:CyclopsBlock):
	print("on_mesh_changed(block:CyclopsBlock)")
	super.on_mesh_changed(block)
	reset_gizmo()
	
