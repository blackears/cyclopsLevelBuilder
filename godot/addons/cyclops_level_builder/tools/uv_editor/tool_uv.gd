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
class_name ToolUv


var mouse_hover_pos:Vector2
var mouse_down_pos:Vector2

var drag_start_view_xform:Transform2D

var zoom_wheel_amount:float = 1.2

var tracked_blocks:Array[CyclopsBlock]
var mvd_cache:Dictionary

@export var view:ViewUvEditor

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
#	print("on_mesh_changed")
	_draw_tool(null)

func cache_selected_blocks():
	mvd_cache.clear()
	
	for block in builder.get_selected_blocks():
		var block_path:NodePath = block.get_path()
		var mvd:MeshVectorData = block.mesh_vector_data
		mvd_cache[block_path] = mvd.duplicate_explicit()

func get_selected_uv_center()->Dictionary:
	#print("get_selected_uv_center()")
	var count:int = 0
	var sum:Vector2
	
	for block in builder.get_selected_blocks():
		var block_path:NodePath = block.get_path()
		var mvd:MeshVectorData = block.mesh_vector_data
		#Get selection mask
		var sel_vec:DataVectorByte = mvd.get_face_vertex_data(MeshVectorData.FV_SELECTED)
		
		var uv_vec:DataVectorFloat = mvd.get_face_vertex_data(MeshVectorData.FV_UV0)
		for i in sel_vec.size():
			#print("uv sel ", i)
			if sel_vec.data[i]:
				sum += uv_vec.get_value_vec2(i)
				count += 1
	
	return {"centroid": sum / count, "count": count}

func focus_on_selected_uvs():
	var count:int = 0
	var bounds:Rect2
	
	for block in builder.get_selected_blocks():
		var block_path:NodePath = block.get_path()
		var mvd:MeshVectorData = block.mesh_vector_data
		
		var uv_arr:DataVectorFloat = mvd.get_face_vertex_data(MeshVectorData.FV_UV0)

		var sel_vec:DataVectorByte = mvd.get_face_vertex_data(MeshVectorData.FV_SELECTED)
		for i in sel_vec.num_components():
			if !sel_vec.get_value(i):
				continue
			
			var uv:Vector2 = uv_arr.get_value_vec2(i)
			if count == 0:
				bounds = Rect2(uv, Vector2.ZERO)
			else:
				bounds = bounds.expand(uv)
			
			count += 1
	
	if count == 0:
		bounds = Rect2(Vector2.ZERO, Vector2.ONE)

	if count == 1:
#		bounds = Rect2(bounds.position - min_focus_size / 2.0, min_focus_size)
		bounds = Rect2(bounds.position - Vector2.ONE / 2.0, Vector2.ONE)
	
	var uv_ed:UvEditor = view.get_uv_editor()
	var viewport_size:Vector2 = view.get_uv_editor_viewport_size()
	
	var uv_bounds_size:float = max(bounds.size.x, bounds.size.y)
	var view_bounds_size:float = min(viewport_size.x, viewport_size.y)
	
	#print("uv_bounds_size ", uv_bounds_size)
	#print("view_bounds_size ", view_bounds_size)
	
	var xform:Transform2D
	xform = xform.translated_local(viewport_size / 2)
	xform = xform.scaled_local(Vector2(view_bounds_size, -view_bounds_size))
	xform = xform.scaled_local(Vector2(1.0 / uv_bounds_size, 1.0 / uv_bounds_size))
	xform = xform.translated_local(-bounds.get_center())
	
	uv_ed.set_uv_to_viewport_xform(xform)


func select_face_vertices(block_index_map:Dictionary, sel_type:Selection.Type):
	var cmd:CommandSetMeshFeatureData = CommandSetMeshFeatureData.new()
	cmd.builder = builder
#	print("block_index_map ", block_index_map)
	
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
		
#		print("end tgt sel ", new_sel_vec)
		fc.new_data_values[MeshVectorData.FV_SELECTED] = DataVectorByte.new(new_sel_vec, DataVector.DataType.BOOL)

		cmd.set_data(block_path, MeshVectorData.Feature.FACE_VERTEX, fc)
		
	if cmd.will_change_anything():
#		print("cmd.will_change_anything() true")
		var undo:EditorUndoRedoManager = builder.get_undo_redo()
		cmd.add_to_undo_manager(undo)


func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:
	if !builder:
		return false

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

	#elif event is InputEventMouseButton:
#
		#var e:InputEventMouseButton = event
		#if e.button_index == MOUSE_BUTTON_MIDDLE:
#
			#if e.is_pressed():
				#if tool_state == ToolState.NONE:
					#mouse_down_pos = e.position
					#
					#tool_state = ToolState.DRAG_VIEW
					#drag_start_view_xform = uv_ed.proj_transform
#
					#return true
				#
				#
				#pass
			#else:
				#if tool_state == ToolState.DRAG_VIEW:
					#tool_state = ToolState.NONE
					#return true

	return false
