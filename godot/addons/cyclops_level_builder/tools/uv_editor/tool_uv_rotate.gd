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
class_name ToolUvRotate

enum ToolState { NONE, READY, DRAG_VIEW, DRAG_SELECTION, DRAG_UVS }
var tool_state:ToolState = ToolState.NONE

var gizmo:GizmoRotate2D

var uv_pivot:Vector2

@export var tool_name:String = "Rotate UVs"
@export var tool_icon:Texture2D = preload("res://addons/cyclops_level_builder/art/icons/rotate.svg")
@export_multiline var tool_tooltip:String = "Rotate UVs"


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


func _draw_tool(viewport_camera:Camera3D):
	if !focused:
		return
	
	var uv_ed:UvEditor = view_uv_editor.get_uv_editor()
	var uv_to_viewport_xform:Transform2D = uv_ed.get_uv_to_viewport_xform()
	
	var center_struct:Dictionary = get_selected_uv_center()
	
	if center_struct["count"] > 0:
		var centroid:Vector2 = center_struct["centroid"]
		gizmo.position = uv_to_viewport_xform * centroid
#		print("gizmo.position ", gizmo.position)
		gizmo.visible = true
	else:
		gizmo.visible = false


func rotate_uvs(pivot:Vector2, angle:float)->void:
	var xform_uv:Transform2D
	xform_uv = xform_uv.translated_local(pivot)
	xform_uv = xform_uv.rotated_local(angle)
	xform_uv = xform_uv.translated_local(-pivot)
	
	for block in builder.get_selected_blocks():
		var block_path:NodePath = block.get_path()
		var mvd:MeshVectorData = mvd_cache[block_path]
		
		var uv_arr:DataVectorFloat = mvd.get_face_vertex_data(MeshVectorData.FV_UV0)
		var new_uv_arr:DataVectorFloat = uv_arr.duplicate_explicit()

		var sel_vec:DataVectorByte = mvd.get_face_vertex_data(MeshVectorData.FV_SELECTED)
		
		for i in uv_arr.num_components():
			if !sel_vec.get_value(i):
				continue
			var val:Vector2 = uv_arr.get_value_vec2(i)
			new_uv_arr.set_value_vec2(xform_uv * val, i)
		
		var new_mvd:MeshVectorData = mvd.duplicate_explicit()
		new_mvd.set_face_vertex_data(MeshVectorData.FV_UV0, new_uv_arr)
		
		block.mesh_vector_data = new_mvd
	
func rotate_uvs_command(pivot:Vector2, angle:float)->CommandSetMeshFeatureData:
	var xform_uv:Transform2D
	xform_uv = xform_uv.translated_local(pivot)
	xform_uv = xform_uv.rotated_local(angle)
	xform_uv = xform_uv.translated_local(-pivot)
	
	var cmd:CommandSetMeshFeatureData = CommandSetMeshFeatureData.new()
	cmd.builder = builder
	var fc:CommandSetMeshFeatureData.FeatureChanges = CommandSetMeshFeatureData.FeatureChanges.new()
#	print("block_index_map ", block_index_map)
	
	for block in builder.get_selected_blocks():
		var block_path:NodePath = block.get_path()
		var mvd:MeshVectorData = mvd_cache[block_path]
		
		var uv_arr:DataVectorFloat = mvd.get_face_vertex_data(MeshVectorData.FV_UV0)
		var new_uv_arr:DataVectorFloat = uv_arr.duplicate_explicit()

		var sel_vec:DataVectorByte = mvd.get_face_vertex_data(MeshVectorData.FV_SELECTED)
		
		for i in uv_arr.num_components():
			if !sel_vec.get_value(i):
				continue
			var val:Vector2 = uv_arr.get_value_vec2(i)
			new_uv_arr.set_value_vec2(xform_uv * val, i)
		
		fc.new_data_values[MeshVectorData.FV_UV0] = new_uv_arr

		cmd.set_data(block_path, MeshVectorData.Feature.FACE_VERTEX, fc)
	
		#print("uv_arr ", uv_arr.data)
		#print("new_uv_arr ", new_uv_arr.data)
	return cmd
		
func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:
	if !builder || !focused:
		return false


	var uv_ed:UvEditor = view_uv_editor.get_uv_editor()
	var uv_to_view_xform:Transform2D = uv_ed.get_uv_to_viewport_xform()
	
	if event is InputEventKey:
		var e:InputEventKey = event
		
		if e.keycode == KEY_ESCAPE:
			if tool_state == ToolState.DRAG_UVS:
				rotate_uvs(Vector2.ZERO, 0)
				
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
					
					var part:GizmoRotate2D.Part = gizmo.pick_part(e.position)
					
#					print("GizmoTranslate2D.Part ", part)
					if part == GizmoRotate2D.Part.RING:
						uv_pivot = get_selected_uv_center()["centroid"]
						
						tool_state = ToolState.DRAG_UVS
						cache_selected_blocks()
						return true
					
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
					
				elif tool_state == ToolState.DRAG_UVS:
					var view_to_uv_xform:Transform2D = uv_to_view_xform.affine_inverse()
					
					var start_pos_uv:Vector2 = view_to_uv_xform * mouse_down_pos
					var cur_pos_uv:Vector2 = view_to_uv_xform * e.position
					
					var start_ang:float = (start_pos_uv - uv_pivot).angle()
					var cur_ang:float = (cur_pos_uv - uv_pivot).angle()
					var delta_angle:float = fposmod(cur_ang - start_ang, PI * 2)
					
					var view_to_uv_vec_xform:Transform2D = uv_to_view_xform.affine_inverse()
					view_to_uv_vec_xform.origin = Vector2.ZERO
					
					rotate_uvs(Vector2.ZERO, 0)
					var cmd = rotate_uvs_command(uv_pivot, delta_angle)
					if cmd.will_change_anything():
						var undo:EditorUndoRedoManager = builder.get_undo_redo()
						cmd.add_to_undo_manager(undo)
					
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
			
		elif tool_state == ToolState.DRAG_UVS:
			var view_to_uv_xform:Transform2D = uv_to_view_xform.affine_inverse()
			
			var start_pos_uv:Vector2 = view_to_uv_xform * mouse_down_pos
			var cur_pos_uv:Vector2 = view_to_uv_xform * e.position
			
			var start_ang:float = (start_pos_uv - uv_pivot).angle()
			var cur_ang:float = (cur_pos_uv - uv_pivot).angle()
			var delta_angle:float = fposmod(cur_ang - start_ang, PI * 2)
			
			
			if tool_owner is ViewUvEditor:
				var view_ed:ViewUvEditor = tool_owner
				var snap_mgr:UvEditorSnapping = view_ed.get_snapping_manager()
				if snap_mgr.use_snap:
					pass
			
			rotate_uvs(uv_pivot, delta_angle)
			
			return true
		
		elif tool_state == ToolState.DRAG_SELECTION:
			
			uv_ed.selection_rect = Rect2(mouse_down_pos, e.position - mouse_down_pos)
			return true

	return super._gui_input(viewport_camera, event)

func on_block_selection_changed():
	track_selected_blocks()
	
func _activate(tool_owner:Node):
	super._activate(tool_owner)
	var uv_ed:UvEditor = view_uv_editor.get_uv_editor()
	
	gizmo = preload("res://addons/cyclops_level_builder/gui/docks/uv_editor/gizmos/gizmo_rotate_2d.tscn").instantiate()
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
