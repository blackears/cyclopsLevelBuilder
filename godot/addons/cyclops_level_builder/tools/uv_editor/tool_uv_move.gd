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
class_name ToolUvMove

enum ToolState { NONE, READY, DRAG_VIEW, DRAG_SELECTION }
var tool_state:ToolState = ToolState.NONE

var settings:ToolUvMoveSettings = ToolUvMoveSettings.new()

var mouse_hover_pos:Vector2
var mouse_down_pos:Vector2

var drag_start_view_xform:Transform2D

var zoom_wheel_amount:float = 1.2

func is_uv_tool():
	return true
	
func _get_tool_name()->String:
	return "Move UVs"

func _get_tool_icon()->Texture2D:
	#return preload("res://addons/cyclops_level_builder/art/icons/move.svg")
	var tag_:ToolTag = load("res://addons/cyclops_level_builder/data/tool_tags/tool_tag_move.tres")
	return tag_.icon

func _get_tool_tooltip()->String:
	return "Move UVs"

func _get_tool_properties_editor()->Control:
	var ed:ToolUvMoveSettingsEditor = preload("res://addons/cyclops_level_builder/tools/uv_editor/tool_uv_move_settings_editor.tscn").instantiate()
	
	ed.settings = settings
	
	return ed

func _can_handle_object(node:Node)->bool:
	#print("_can_handle_object -- uv move")
	#return node is CyclopsBlock
	return true

var gizmo:GizmoTranslate2D

func _draw_tool(viewport_camera:Camera3D):
	var view:ViewUvEditor = builder.view_uv_editor
	var uv_ed:UvEditor = view.get_uv_editor()
	
	#if !gizmo:
		#gizmo = preload("res://addons/cyclops_level_builder/gui/docks/uv_editor/gizmos/gizmo_translate_2d.tscn").instantiate()
		#uv_ed.add_child(gizmo)
	
	var centroid:Vector2 = get_selected_uv_center()
	var xform:Transform2D = uv_ed.get_uv_to_viewport_xform()
	
	var view_pos:Vector2 = xform * centroid
	gizmo.position = view_pos
	
	return
	
func get_selected_uv_center()->Vector2:
	var count:int = 0
	var sum:Vector2
	
	for block in builder.get_selected_blocks():
		var block_path:NodePath = block.get_path()
		var mvd:MeshVectorData = block.mesh_vector_data
		#Get selection mask
		var sel_vec:DataVectorByte = mvd.get_face_vertex_data(MeshVectorData.FV_SELECTED)
		
		var uv_vec:DataVectorFloat = mvd.get_face_vertex_data(MeshVectorData.FV_UV0)
		for i in sel_vec.size():
			if mvd.sel_vec[i]:
				sum += uv_vec.get_value_vec2(i)
				count += 1
				
	return sum / count

	

func select_face_vertices(block_index_map:Dictionary, sel_type:Selection.Type):
	var cmd:CommandSetMeshFeatureData = CommandSetMeshFeatureData.new()
	cmd.builder = builder
	print("block_index_map ", block_index_map)
	
	for block in builder.get_selected_blocks():
		var block_path:NodePath = block.get_path()

		var fc:CommandSetMeshFeatureData.FeatureChanges = CommandSetMeshFeatureData.FeatureChanges.new()
		
		var mvd:MeshVectorData = block.mesh_vector_data
		#Get selection mask
		var sel_vec:DataVectorByte = mvd.get_face_vertex_data(MeshVectorData.FV_SELECTED)
#		print("source sel ", sel_vec.data)
		
		var new_sel_vec:PackedByteArray
		#new_sel_vec.resize(sel_vec.size())
		new_sel_vec = sel_vec.get_buffer_byte_data().duplicate()
#		print("start tgt sel ", new_sel_vec)
		#new_sel_vec.set(
		match sel_type:
			Selection.Type.REPLACE:
				new_sel_vec.fill(false)
				if block_index_map.has(block_path):
					var sel_indices:PackedInt32Array = block_index_map[block_path]
					for i in sel_indices:
						new_sel_vec[i] = true

			Selection.Type.ADD:
				if block_index_map.has(block_path):
					var sel_indices:PackedInt32Array = block_index_map[block_path]
					for i in sel_indices:
						new_sel_vec[i] = true

			Selection.Type.SUBTRACT:
				if block_index_map.has(block_path):
					var sel_indices:PackedInt32Array = block_index_map[block_path]
					for i in sel_indices:
						new_sel_vec[i] = false

			Selection.Type.TOGGLE:
				if block_index_map.has(block_path):
					var sel_indices:PackedInt32Array = block_index_map[block_path]
					for i in sel_indices:
						new_sel_vec[i] = !new_sel_vec[i]
		
		print("end tgt sel ", new_sel_vec)
		fc.new_data_values[MeshVectorData.FV_SELECTED] = DataVectorByte.new(new_sel_vec, DataVector.DataType.BOOL)
					
		cmd.set_data(block_path, MeshVectorData.Feature.FACE_VERTEX, fc)
		
	if cmd.will_change_anything():
		print("cmd.will_change_anything() true")
		var undo:EditorUndoRedoManager = builder.get_undo_redo()
		cmd.add_to_undo_manager(undo)

	
	

func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:
	if !builder:
		return false
		
	#print("tool_uv_move._gui_input()")
	
	var view:ViewUvEditor = builder.view_uv_editor
	var uv_ed:UvEditor = view.get_uv_editor()
	
	
	
	if event is InputEventMouseButton:
		#print("mouse bn ", event)

		var e:InputEventMouseButton = event
		if e.button_index == MOUSE_BUTTON_LEFT:

			if e.is_pressed():
				if tool_state == ToolState.NONE:
					mouse_down_pos = e.position
					
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
					#for block in builder.get_selected_blocks():
						#var block_path:NodePath = block.get_path()
						
						

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

		elif e.button_index == MOUSE_BUTTON_MIDDLE:

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
				

		elif e.button_index == MOUSE_BUTTON_WHEEL_UP:
			if e.pressed:
#				print("uv_move wheel up")
				
#				var uv_to_view_xform:Transform2D = uv_ed.get_uv_to_viewport_xform()
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

	return false


func _activate(tool_owner:Node):
	super._activate(tool_owner)

	var view:ViewUvEditor = builder.view_uv_editor
	var uv_ed:UvEditor = view.get_uv_editor()
	
	gizmo = preload("res://addons/cyclops_level_builder/gui/docks/uv_editor/gizmos/gizmo_translate_2d.tscn").instantiate()
	uv_ed.add_child(gizmo)

	var ed_iface:EditorInterface = builder.get_editor_interface()
	var ed_sel:EditorSelection = ed_iface.get_selection()
	ed_sel.selection_changed.connect(on_block_selection_changed)

func _deactivate():
	super._deactivate()

	clear_tracked_blocks()
	
	gizmo.queue_free()
	gizmo = null
	
	var ed_iface:EditorInterface = builder.get_editor_interface()
	var ed_sel:EditorSelection = ed_iface.get_selection()
	ed_sel.selection_changed.disconnect(on_block_selection_changed)

func on_block_selection_changed():
	track_selected_blocks()
	
	pass

var tracked_blocks:Array[CyclopsBlock]

func clear_tracked_blocks():
	for block in tracked_blocks:
		if is_instance_valid(block):
			block.mesh_changed.disconnect(on_mesh_changed)

	tracked_blocks.clear()

func track_selected_blocks():
	clear_tracked_blocks()
	
	var ed_iface:EditorInterface = builder.get_editor_interface()
	var ed_sel:EditorSelection = ed_iface.get_selection()
	
	for node in ed_sel.get_selected_nodes():
		if node is CyclopsBlock:
			tracked_blocks.append(node)
			node.mesh_changed.connect(on_mesh_changed)


func on_mesh_changed(block:CyclopsBlock):
	_draw_tool(null)
	pass
