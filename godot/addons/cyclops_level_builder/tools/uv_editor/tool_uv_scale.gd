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
class_name ToolUvScale

enum ToolState { NONE, READY, DRAG_SELECTION, DRAG_UVS }
var tool_state:ToolState = ToolState.NONE

var gizmo:GizmoScale2D

var move_constraint:MoveConstraint.Type
var uv_pivot:Vector2
var drag_dir:Vector2

@export var tool_name:String = "Scale UVs"
@export var tool_icon:Texture2D = preload("res://addons/cyclops_level_builder/art/icons/scale.svg")
@export_multiline var tool_tooltip:String = "Scale UVs"

@export var scale_ratio:float = .005

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
		
	var uv_ed:UvEditor = view.get_uv_editor()
	var uv_to_viewport_xform:Transform2D = uv_ed.get_uv_to_viewport_xform()
	
	var center_struct:Dictionary = get_selected_uv_center()
	
	if center_struct["count"] > 0:
		var centroid:Vector2 = center_struct["centroid"]
		gizmo.position = uv_to_viewport_xform * centroid
#		print("gizmo.position ", gizmo.position)
		gizmo.visible = true
	else:
		gizmo.visible = false


func scale_uvs(scale_axes:Vector2, pivot:Vector2, commit:bool):
	var uv_xform:Transform2D
	uv_xform = uv_xform.translated_local(pivot)
	uv_xform = uv_xform.scaled_local(scale_axes)
	uv_xform = uv_xform.translated_local(-pivot)
	
	if commit:
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
#				new_uv_arr.set_value_vec2(val + offset, i)
				new_uv_arr.set_value_vec2(uv_xform * val, i)
			
			fc.new_data_values[MeshVectorData.FV_UV0] = new_uv_arr

			cmd.set_data(block_path, MeshVectorData.Feature.FACE_VERTEX, fc)
		
			#print("uv_arr ", uv_arr.data)
			#print("new_uv_arr ", new_uv_arr.data)
		
		if cmd.will_change_anything():
	#		print("cmd.will_change_anything() true")
			var undo:EditorUndoRedoManager = builder.get_undo_redo()
			cmd.add_to_undo_manager(undo)
	else:
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
#				new_uv_arr.set_value_vec2(val + offset, i)
				new_uv_arr.set_value_vec2(uv_xform * val, i)
			
			var new_mvd:MeshVectorData = mvd.duplicate_explicit()
			new_mvd.set_face_vertex_data(MeshVectorData.FV_UV0, new_uv_arr)
			
			block.mesh_vector_data = new_mvd


func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:
	if !builder || !focused:
		return false
		
	#print("tool_uv_move._gui_input()")
	
	var uv_ed:UvEditor = view.get_uv_editor()
	var uv_to_view_xform:Transform2D = uv_ed.get_uv_to_viewport_xform()
	
	if event is InputEventKey:
		var e:InputEventKey = event
		
		if e.keycode == KEY_ESCAPE:
			if tool_state == ToolState.DRAG_UVS:
				scale_uvs(Vector2.ONE, uv_pivot, false)
				
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
					uv_pivot = get_selected_uv_center()["centroid"]
					drag_dir = Vector2.ZERO
					
					var part:GizmoScale2D.Part = gizmo.pick_part(e.position)
					
#					print("GizmoTranslate2D.Part ", part)
					if part == GizmoScale2D.Part.AXIS_X:
						tool_state = ToolState.DRAG_UVS
						move_constraint = MoveConstraint.Type.AXIS_X
						cache_selected_blocks()
						return true
						
					if part == GizmoScale2D.Part.AXIS_Y:
						tool_state = ToolState.DRAG_UVS
						move_constraint = MoveConstraint.Type.AXIS_Y
						cache_selected_blocks()
						return true
						
					if part == GizmoScale2D.Part.PLANE_Z:
						tool_state = ToolState.DRAG_UVS
						move_constraint = MoveConstraint.Type.PLANE_XY
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
					var offset:Vector2 = e.position - mouse_down_pos
					
					var amount:float = offset.dot(drag_dir)
					
					var axis_scale = Vector2(amount, amount)
					
					if move_constraint == MoveConstraint.Type.AXIS_X:
						axis_scale.y = 0
					elif move_constraint == MoveConstraint.Type.AXIS_Y:
						axis_scale.x = 0

					axis_scale = axis_scale * scale_ratio + Vector2.ONE
			
					scale_uvs(Vector2.ONE, uv_pivot, false)
					scale_uvs(axis_scale, uv_pivot, true)
					
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
			var offset:Vector2 = e.position - mouse_down_pos
			if drag_dir.is_zero_approx():
				drag_dir = offset.normalized()
			var amount:float = offset.dot(drag_dir)
			
			var axis_scale = Vector2(amount, amount)
			
			if move_constraint == MoveConstraint.Type.AXIS_X:
				axis_scale.y = 0
			elif move_constraint == MoveConstraint.Type.AXIS_Y:
				axis_scale.x = 0

			axis_scale = axis_scale * scale_ratio + Vector2.ONE
			
			if tool_owner is ViewUvEditor:
				var view_ed:ViewUvEditor = tool_owner
				var snap_mgr:UvEditorSnapping = view_ed.get_snapping_manager()
				if snap_mgr.use_snap:
					pass
			
			scale_uvs(axis_scale, uv_pivot, false)
					
		elif tool_state == ToolState.DRAG_SELECTION:
			
			uv_ed.selection_rect = Rect2(mouse_down_pos, e.position - mouse_down_pos)
			return true

	return super._gui_input(viewport_camera, event)

	
func _activate(tool_owner:Node):
	super._activate(tool_owner)

	var uv_ed:UvEditor = view.get_uv_editor()
	
	gizmo = preload("res://addons/cyclops_level_builder/gui/docks/uv_editor/gizmos/gizmo_scale_2d.tscn").instantiate()
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
	track_selected_blocks()
