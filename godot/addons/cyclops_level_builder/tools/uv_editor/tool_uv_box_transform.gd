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

enum ToolState { NONE, READY, DRAG_VIEW, DRAG_SELECTION, DRAG_HANDLE }
var tool_state:ToolState = ToolState.NONE

enum DragHandleStyle { NONE, TRANSLATE, ROTATE, SCALE_FREE, SCALE_UNIFORM, SCALE_AXIS_X, SCALE_AXIS_Y, PIVOT }
var drag_uv_style:DragHandleStyle

var drag_handle_start_pos_uv:Vector2
var drag_pivot_pos_uv:Vector2

#var tool_xform_init:Transform2D
var tool_xform_start:Transform2D
var tool_xform_cur:Transform2D

var session_started:bool = false

#var start_drag_bounds:Rect2
var start_drag_bound_xform:Transform2D

#Manual pivot in tool space
var rotate_pivot_tool:Vector2

#var visible:bool = false
var gizmo:GizmoTransformBox2D

@export var tool_name:String = "Box Transform UVs"
@export var tool_icon:Texture2D = preload("res://addons/cyclops_level_builder/art/icons/box_transform.svg")
@export_multiline var tool_tooltip:String = "Box Transform UVs"

@export var rotate_handle_offset:float = 15

@onready var handle_scale_00:ToolUvBoxHandle = %handle_scale_00
@onready var handle_scale_01:ToolUvBoxHandle = %handle_scale_01
@onready var handle_scale_02:ToolUvBoxHandle = %handle_scale_02
@onready var handle_scale_10:ToolUvBoxHandle = %handle_scale_10
@onready var handle_scale_12:ToolUvBoxHandle = %handle_scale_12
@onready var handle_scale_20:ToolUvBoxHandle = %handle_scale_20
@onready var handle_scale_21:ToolUvBoxHandle = %handle_scale_21
@onready var handle_scale_22:ToolUvBoxHandle = %handle_scale_22
@onready var handle_rot_00:ToolUvBoxHandle = %handle_rot_00
@onready var handle_rot_01:ToolUvBoxHandle = %handle_rot_01
@onready var handle_rot_02:ToolUvBoxHandle = %handle_rot_02
@onready var handle_rot_10:ToolUvBoxHandle = %handle_rot_10
@onready var handle_rot_12:ToolUvBoxHandle = %handle_rot_12
@onready var handle_rot_20:ToolUvBoxHandle = %handle_rot_20
@onready var handle_rot_21:ToolUvBoxHandle = %handle_rot_21
@onready var handle_rot_22:ToolUvBoxHandle = %handle_rot_22
@onready var handle_pivot:ToolUvBoxHandle = %handle_pivot
@onready var handle_transform:ToolUvBoxHandle = %handle_transform

#enum ToolConstraint { NONE, AXIS_X, AXIS_Y, UNIFORM }

#var drag_constraint:ToolConstraint

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

func update_uv_handles():
	var handle_to_uv_xform:Transform2D = tool_xform_cur * start_drag_bound_xform
	
	var uv_ed:UvEditor = view.get_uv_editor()
	var uv_to_viewport_xform:Transform2D = uv_ed.get_uv_to_viewport_xform()
	var viewport_to_uv_xform:Transform2D = uv_to_viewport_xform.affine_inverse()
	
	var handle_to_viewport_xform:Transform2D = uv_to_viewport_xform * handle_to_uv_xform
	var handle_offset_x:Vector2 = viewport_to_uv_xform.basis_xform(
		handle_to_viewport_xform.x.normalized())
	var handle_offset_y:Vector2 = viewport_to_uv_xform.basis_xform(
		handle_to_viewport_xform.y.normalized())
	var viewport_handle_xform:Transform2D = Transform2D(handle_offset_x, handle_offset_y, Vector2.ZERO)
	
	handle_scale_00.uv_position = handle_to_uv_xform * Vector2(0, 0)
	handle_scale_01.uv_position = handle_to_uv_xform * Vector2(0, .5)
	handle_scale_02.uv_position = handle_to_uv_xform * Vector2(0, 1)
	handle_scale_10.uv_position = handle_to_uv_xform * Vector2(.5, 0)
	handle_scale_12.uv_position = handle_to_uv_xform * Vector2(.5, 1)
	handle_scale_20.uv_position = handle_to_uv_xform * Vector2(1, 0)
	handle_scale_21.uv_position = handle_to_uv_xform * Vector2(1, .5)
	handle_scale_22.uv_position = handle_to_uv_xform * Vector2(1, 1)
	
	handle_rot_00.uv_position = handle_scale_00.uv_position + viewport_handle_xform * Vector2(-1, -1) * rotate_handle_offset
	handle_rot_01.uv_position = handle_scale_01.uv_position + viewport_handle_xform * Vector2(-1, 0) * rotate_handle_offset
	handle_rot_02.uv_position = handle_scale_02.uv_position + viewport_handle_xform * Vector2(-1, 1) * rotate_handle_offset
	handle_rot_10.uv_position = handle_scale_10.uv_position + viewport_handle_xform * Vector2(0, -1) * rotate_handle_offset
	handle_rot_12.uv_position = handle_scale_12.uv_position + viewport_handle_xform * Vector2(0, 1) * rotate_handle_offset
	handle_rot_20.uv_position = handle_scale_20.uv_position + viewport_handle_xform * Vector2(1, -1) * rotate_handle_offset
	handle_rot_21.uv_position = handle_scale_21.uv_position + viewport_handle_xform * Vector2(1, 0) * rotate_handle_offset
	handle_rot_22.uv_position = handle_scale_22.uv_position + viewport_handle_xform * Vector2(1, 1) * rotate_handle_offset

	handle_pivot.uv_position = handle_to_uv_xform * rotate_pivot_tool
	

func reset_tool():
#	print("reset_tool()")
	tool_xform_start = Transform2D.IDENTITY
	tool_xform_cur = Transform2D.IDENTITY
	
	var uv_rect:Rect2 = get_uv_bounds()
	if uv_rect.size.is_zero_approx():
#		visible = false
		gizmo.visible = false
		return
		
	rotate_pivot_tool = Vector2(.5, .5)
	
	#start_drag_bounds = uv_rect
	#Map [0 1] unit square to inital selection rectangle
	start_drag_bound_xform = Transform2D(0, uv_rect.size, 0, uv_rect.position)
	#print("start_drag_bound_xform ", start_drag_bound_xform)
	#print("uv_rect ", uv_rect)
	
	
	var origin:Vector2 = uv_rect.position
	var x_span:Vector2 = Vector2(uv_rect.size.x, 0)
	var y_span:Vector2 = Vector2(0, uv_rect.size.y)
	
	
	gizmo.visible = true

	_draw_tool(null)
	

func _draw_tool(viewport_camera:Camera3D):
	if !gizmo:
		return

	update_uv_handles()
	
	var uv_ed:UvEditor = view.get_uv_editor()
	var uv_to_viewport_xform:Transform2D = uv_ed.get_uv_to_viewport_xform()
	
	for handle:ToolUvBoxHandle in get_children():
		if handle.viewport_handle:
			handle.viewport_handle.position = uv_to_viewport_xform * handle.uv_position
	

func transform_uvs(uv_xform:Transform2D, commit:bool):
	#print("transform_uvs uv_xform ", uv_xform)
	#print("commit ", commit)
	
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

	var uv_ed:UvEditor = view.get_uv_editor()
	var uv_to_view_xform:Transform2D = uv_ed.get_uv_to_viewport_xform()
	

	if event is InputEventKey:
		var e:InputEventKey = event
		
		if e.keycode == KEY_ESCAPE:
			if tool_state == ToolState.DRAG_HANDLE:
				transform_uvs(Transform2D.IDENTITY, false)
				
				get_viewport().set_input_as_handled()
				tool_state = ToolState.NONE
				session_started = false
				
				reset_tool()
				return true
				
			elif tool_state == ToolState.DRAG_SELECTION:
				uv_ed.show_selection_rect = false
				
				tool_state = ToolState.NONE
				get_viewport().set_input_as_handled()
				return true

		elif e.keycode == KEY_ENTER:
			if tool_state == ToolState.DRAG_HANDLE:
				session_started = false
				reset_tool()
				get_viewport().set_input_as_handled()
				return true

	elif event is InputEventMouseButton:
#		print("mouse bn ", event)

		var e:InputEventMouseButton = event
		if e.button_index == MOUSE_BUTTON_LEFT:

			if e.is_pressed():
				if tool_state == ToolState.NONE:
					mouse_down_pos = e.position
					#print("mouse down ", mouse_down_pos)

					var uv_to_viewport_xform:Transform2D = uv_ed.get_uv_to_viewport_xform()
					var viewport_to_uv_xform:Transform2D = uv_to_viewport_xform.affine_inverse()
					#tool_xform_init = viewport_to_uv_xform * mouse_down_pos
					drag_handle_start_pos_uv = viewport_to_uv_xform * mouse_down_pos
					
					var part:GizmoTransformBox2D.Part = gizmo.pick_part(e.position)
					var shift_down:bool = e.shift_pressed
					
					#print("part <0>", part)
					drag_uv_style = DragHandleStyle.NONE
					
					match part:
						GizmoTransformBox2D.Part.PLANE_Z:
							drag_uv_style = DragHandleStyle.TRANSLATE
							
						GizmoTransformBox2D.Part.CORNER_00:
							drag_uv_style = DragHandleStyle.SCALE_UNIFORM if shift_down else DragHandleStyle.SCALE_FREE
							drag_pivot_pos_uv = viewport_to_uv_xform * gizmo.handle_22.global_position
							tool_xform_start = tool_xform_cur
						GizmoTransformBox2D.Part.CORNER_01:
							drag_uv_style = DragHandleStyle.SCALE_AXIS_X
							drag_pivot_pos_uv = viewport_to_uv_xform * gizmo.handle_21.global_position
							tool_xform_start = tool_xform_cur
						GizmoTransformBox2D.Part.CORNER_02:
							drag_uv_style = DragHandleStyle.SCALE_UNIFORM if shift_down else DragHandleStyle.SCALE_FREE
							drag_pivot_pos_uv = viewport_to_uv_xform * gizmo.handle_20.global_position
							tool_xform_start = tool_xform_cur
							
						GizmoTransformBox2D.Part.CORNER_10:
							drag_uv_style = DragHandleStyle.SCALE_AXIS_Y
							drag_pivot_pos_uv = viewport_to_uv_xform * gizmo.handle_12.global_position
							tool_xform_start = tool_xform_cur
						GizmoTransformBox2D.Part.CORNER_12:
							drag_uv_style = DragHandleStyle.SCALE_AXIS_Y
							drag_pivot_pos_uv = viewport_to_uv_xform * gizmo.handle_10.global_position
							tool_xform_start = tool_xform_cur
							
						GizmoTransformBox2D.Part.CORNER_20:
							drag_uv_style = DragHandleStyle.SCALE_UNIFORM if shift_down else DragHandleStyle.SCALE_FREE
							drag_pivot_pos_uv = viewport_to_uv_xform * gizmo.handle_02.global_position
							tool_xform_start = tool_xform_cur
						GizmoTransformBox2D.Part.CORNER_21:
							drag_uv_style = DragHandleStyle.SCALE_AXIS_X
							drag_pivot_pos_uv = viewport_to_uv_xform * gizmo.handle_01.global_position
							tool_xform_start = tool_xform_cur
						GizmoTransformBox2D.Part.CORNER_22:
							drag_uv_style = DragHandleStyle.SCALE_UNIFORM if shift_down else DragHandleStyle.SCALE_FREE
							drag_pivot_pos_uv = viewport_to_uv_xform * gizmo.handle_00.global_position
							tool_xform_start = tool_xform_cur

						GizmoTransformBox2D.Part.CORNER_ROT_00:
							drag_uv_style = DragHandleStyle.ROTATE
							drag_pivot_pos_uv = viewport_to_uv_xform * gizmo.handle_pivot.global_position
							tool_xform_start = tool_xform_cur
						GizmoTransformBox2D.Part.CORNER_ROT_01:
							drag_uv_style = DragHandleStyle.ROTATE
							drag_pivot_pos_uv = viewport_to_uv_xform * gizmo.handle_pivot.global_position
							tool_xform_start = tool_xform_cur
						GizmoTransformBox2D.Part.CORNER_ROT_02:
							drag_uv_style = DragHandleStyle.ROTATE
							drag_pivot_pos_uv = viewport_to_uv_xform * gizmo.handle_pivot.global_position
							tool_xform_start = tool_xform_cur
						GizmoTransformBox2D.Part.CORNER_ROT_10:
							drag_uv_style = DragHandleStyle.ROTATE
							drag_pivot_pos_uv = viewport_to_uv_xform * gizmo.handle_pivot.global_position
							tool_xform_start = tool_xform_cur
						GizmoTransformBox2D.Part.CORNER_ROT_12:
							drag_uv_style = DragHandleStyle.ROTATE
							drag_pivot_pos_uv = viewport_to_uv_xform * gizmo.handle_pivot.global_position
							tool_xform_start = tool_xform_cur
						GizmoTransformBox2D.Part.CORNER_ROT_20:
							drag_uv_style = DragHandleStyle.ROTATE
							drag_pivot_pos_uv = viewport_to_uv_xform * gizmo.handle_pivot.global_position
							tool_xform_start = tool_xform_cur
						GizmoTransformBox2D.Part.CORNER_ROT_21:
							drag_uv_style = DragHandleStyle.ROTATE
							drag_pivot_pos_uv = viewport_to_uv_xform * gizmo.handle_pivot.global_position
							tool_xform_start = tool_xform_cur
						GizmoTransformBox2D.Part.CORNER_ROT_22:
							drag_uv_style = DragHandleStyle.ROTATE
							drag_pivot_pos_uv = viewport_to_uv_xform * gizmo.handle_pivot.global_position
							tool_xform_start = tool_xform_cur

						GizmoTransformBox2D.Part.PIVOT:
							drag_uv_style = DragHandleStyle.PIVOT
							drag_pivot_pos_uv = viewport_to_uv_xform * gizmo.handle_pivot.global_position
							tool_xform_start = tool_xform_cur
							
					
					if !session_started:
						if drag_uv_style != DragHandleStyle.NONE:
							session_started = true
							cache_selected_blocks()
						
						
					tool_state = ToolState.READY
					#print("part <1>", part)
					#print("drag_uv_style", drag_uv_style)
					#print("drag_pivot_pos_uv", drag_pivot_pos_uv)

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
					
					#reset_tool()
					return true
					
				elif tool_state == ToolState.DRAG_HANDLE:
					transform_uvs(tool_xform_cur, true)
					
					tool_state = ToolState.NONE
					pass
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
					session_started = false
					
					reset_tool()
					#view.queue_redraw()
				
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
#				print("drag_uv_style ", drag_uv_style)

				if drag_uv_style == DragHandleStyle.NONE:
					tool_state = ToolState.DRAG_SELECTION
					uv_ed.show_selection_rect = true
					uv_ed.selection_rect = Rect2(mouse_down_pos, e.position - mouse_down_pos)
	#				print("sel rect ", uv_ed.selection_rect)
				else:
					tool_state = ToolState.DRAG_HANDLE

			return true
			
		elif tool_state == ToolState.DRAG_HANDLE:
			var uv_to_viewport_xform:Transform2D = uv_ed.get_uv_to_viewport_xform()
			var viewport_to_uv_xform:Transform2D = uv_to_viewport_xform.affine_inverse()
			
			var mouse_uv_pos:Vector2 = viewport_to_uv_xform * e.position
			var drag_offset_uv = mouse_uv_pos - drag_handle_start_pos_uv
				
			var start_tool_bounds_xform =  tool_xform_start * start_drag_bound_xform
			
			if drag_uv_style == DragHandleStyle.SCALE_FREE \
				|| drag_uv_style == DragHandleStyle.SCALE_AXIS_X \
				|| drag_uv_style == DragHandleStyle.SCALE_AXIS_Y \
				|| drag_uv_style == DragHandleStyle.SCALE_UNIFORM:
				
				match drag_uv_style:
					DragHandleStyle.SCALE_AXIS_X:
						drag_offset_uv = drag_offset_uv.project(start_tool_bounds_xform.x)
					DragHandleStyle.SCALE_AXIS_Y:
						drag_offset_uv = drag_offset_uv.project(start_tool_bounds_xform.y)
					DragHandleStyle.SCALE_UNIFORM:
						var proj_axis:Vector2 = drag_handle_start_pos_uv - drag_pivot_pos_uv
						drag_offset_uv = drag_offset_uv.project(proj_axis)
						
				var init_handle_offset:Vector2 = drag_handle_start_pos_uv - drag_pivot_pos_uv
				var cur_handle_offset:Vector2 = init_handle_offset + drag_offset_uv
				
				var xform:Transform2D
				xform = xform.translated_local(drag_pivot_pos_uv)
				xform = xform.scaled_local(cur_handle_offset / init_handle_offset)
				xform = xform.translated_local(-drag_pivot_pos_uv)
				tool_xform_cur = xform * tool_xform_start
				
				transform_uvs(tool_xform_cur, false)
				
				_draw_tool(null)
				
				return true
			elif drag_uv_style == DragHandleStyle.PIVOT:
				var tool_to_uv_xform = start_tool_bounds_xform.affine_inverse()
				var mouse_tool_pos = tool_to_uv_xform * mouse_uv_pos
				#handle_pivot.uv_position = mouse_uv_pos
				rotate_pivot_tool = mouse_tool_pos
				
				_draw_tool(null)
				return true
				
			elif drag_uv_style == DragHandleStyle.ROTATE:
				#mouse_uv_pos - drag_handle_start_pos_uv
				#drag_offset_uv
				#drag_pivot_pos_uv
				var a:Vector2 = drag_handle_start_pos_uv - drag_pivot_pos_uv
				var b:Vector2 = mouse_uv_pos - drag_pivot_pos_uv
				var angle:float = a.angle_to(b)
				
				var xform:Transform2D
				xform = xform.translated_local(drag_pivot_pos_uv)
				xform = xform.rotated_local(angle)
				xform = xform.translated_local(-drag_pivot_pos_uv)
				tool_xform_cur = xform * tool_xform_start
				
				transform_uvs(tool_xform_cur, false)
				
				_draw_tool(null)
				
			
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
	
	handle_scale_00.viewport_handle = gizmo.handle_00
	handle_scale_01.viewport_handle = gizmo.handle_01
	handle_scale_02.viewport_handle = gizmo.handle_02
	handle_scale_10.viewport_handle = gizmo.handle_10
	handle_scale_12.viewport_handle = gizmo.handle_12
	handle_scale_20.viewport_handle = gizmo.handle_20
	handle_scale_21.viewport_handle = gizmo.handle_21
	handle_scale_22.viewport_handle = gizmo.handle_22
	handle_rot_00.viewport_handle = gizmo.handle_rot_00
	handle_rot_01.viewport_handle = gizmo.handle_rot_01
	handle_rot_02.viewport_handle = gizmo.handle_rot_02
	handle_rot_10.viewport_handle = gizmo.handle_rot_10
	handle_rot_12.viewport_handle = gizmo.handle_rot_12
	handle_rot_20.viewport_handle = gizmo.handle_rot_20
	handle_rot_21.viewport_handle = gizmo.handle_rot_21
	handle_rot_22.viewport_handle = gizmo.handle_rot_22
	handle_pivot.viewport_handle = gizmo.handle_pivot

	var ed_iface:EditorInterface = builder.get_editor_interface()
	var ed_sel:EditorSelection = ed_iface.get_selection()
	ed_sel.selection_changed.connect(on_block_selection_changed)
	
	track_selected_blocks()

	reset_tool()
	
	#_draw_tool(null)

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
#	print("on_block_selection_changed()")
	track_selected_blocks()
	reset_tool()
	_draw_tool(null)

#Override mesh changed signal
func on_mesh_changed(block:CyclopsBlock):
#	print("on_mesh_changed(block:CyclopsBlock)")
	super.on_mesh_changed(block)
	#reset_tool()
	#_draw_tool(null)
	
