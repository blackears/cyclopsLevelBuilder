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
extends ToolEditBase
class_name ToolEditVertex

const TOOL_ID:String = "edit_vertex"

var handles:Array[HandleVertex] = []

enum ToolState { NONE, READY, DRAGGING, DRAGGING_ADD }
var tool_state:ToolState = ToolState.NONE

#var mouse_hover_pos:Vector2

var drag_handle:HandleVertex
var drag_mouse_start_pos:Vector2
var drag_handle_start_pos:Vector3
var added_point_pos:Vector3

var cmd_move_vertex:CommandMoveVertices
var cmd_add_vertex:CommandAddVertices

var tracked_blocks_root:CyclopsBlocks

func _get_tool_id()->String:
	return TOOL_ID

func _draw_tool(viewport_camera:Camera3D):
	var global_scene:CyclopsGlobalScene = builder.get_global_scene()
	global_scene.clear_tool_mesh()
	
	#var blocks_root:CyclopsBlocks = builder.active_node
	for h in handles:
		var block:CyclopsConvexBlock = builder.get_node(h.block_path)
		var v:ConvexVolume.VertexInfo = block.control_mesh.vertices[h.vertex_index]
		
		#print("draw vert %s %s" % [h.vertex_index, v.selected])
		var active:bool = block.control_mesh.active_vertex == h.vertex_index
		global_scene.draw_vertex(h.position, pick_material(global_scene, v.selected, active))
	
func setup_tool():
	handles = []
#	print("setup_tool")
	
	var blocks_root:CyclopsBlocks = builder.active_node
	if blocks_root == null:
		return
		
	for child in blocks_root.get_children():
		if child is CyclopsConvexBlock:
			var block:CyclopsConvexBlock = child
			if block.selected:
#				print("block sel %s" % block.block_data.vertex_selected)

				for v_idx in block.control_mesh.vertices.size():
					var v:ConvexVolume.VertexInfo = block.control_mesh.vertices[v_idx]
					var handle:HandleVertex = HandleVertex.new()
					handle.position = v.point
					handle.vertex_index = v_idx
					handle.initial_position = v.point
					handle.block_path = block.get_path()
					handles.append(handle)
					
					#print("adding handle %s" % handle)


func pick_closest_handle(blocks_root:CyclopsBlocks, viewport_camera:Camera3D, position:Vector2, radius:float)->HandleVertex:
	var best_dist:float = INF
	var best_handle:HandleVertex = null
	
	var origin:Vector3 = viewport_camera.project_ray_origin(position)
	var dir:Vector3 = viewport_camera.project_ray_normal(position)
	
	for h in handles:
		var h_world_pos:Vector3 = blocks_root.global_transform * h.position
		var h_screen_pos:Vector2 = viewport_camera.unproject_position(h_world_pos)
		if position.distance_squared_to(h_screen_pos) > radius * radius:
			#Failed handle radius test
			continue
		
		var offset:Vector3 = h_world_pos - origin
		var parallel:Vector3 = offset.project(dir)
		var dist = parallel.dot(dir)
		if dist <= 0:
			#Behind camera
			continue
		
		#print("h pos %s ray orig %s ray dir %s offset %s para %s dist %s perp %s" % [h.position, ray_origin, ray_dir, offset, parallel, dist, perp])
		if dist >= best_dist:
			continue
		
		best_dist = dist
		best_handle = h

	return best_handle
			
func active_node_changed():
	if tracked_blocks_root != null:
		tracked_blocks_root.blocks_changed.disconnect(active_node_updated)
		tracked_blocks_root = null
		
	setup_tool()
	
	tracked_blocks_root = builder.active_node
	if tracked_blocks_root:
		tracked_blocks_root.blocks_changed.connect(active_node_updated)
		
	

func active_node_updated():
	setup_tool()

func _activate(builder:CyclopsLevelBuilder):
	super._activate(builder)
	
	builder.mode = CyclopsLevelBuilder.Mode.EDIT
	builder.edit_mode = CyclopsLevelBuilder.EditMode.VERTEX
	builder.active_node_changed.connect(active_node_changed)
	
	tracked_blocks_root = builder.active_node
	if tracked_blocks_root:
		tracked_blocks_root.blocks_changed.connect(active_node_updated)
	
	setup_tool()
	
	
func _deactivate():
	super._deactivate()
	builder.active_node_changed.disconnect(active_node_changed)
	if tracked_blocks_root != null:
		tracked_blocks_root.blocks_changed.disconnect(active_node_updated)


func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:	
	if !builder.active_node is CyclopsBlocks:
		return false
		
	var gui_result = super._gui_input(viewport_camera, event)
	if gui_result:
		return true
	
	var blocks_root:CyclopsBlocks = self.builder.active_node
	var grid_step_size:float = pow(2, builder.get_global_scene().grid_size)

	if event is InputEventMouseButton:
		
		var e:InputEventMouseButton = event
		if e.button_index == MOUSE_BUTTON_LEFT:

			if e.is_pressed():
				
				if tool_state == ToolState.NONE:
					drag_mouse_start_pos = e.position
					tool_state = ToolState.READY
					
				return true
			else:
				if tool_state == ToolState.READY:
					#print("cmd select")
					var handle:HandleVertex = pick_closest_handle(blocks_root, viewport_camera, drag_mouse_start_pos, builder.handle_screen_radius)

					var cmd:CommandSelectVertices = CommandSelectVertices.new()
					cmd.builder = builder

					for child in builder.active_node.get_children():
						if child is CyclopsConvexBlock:
							var cur_block:CyclopsConvexBlock = child
							if cur_block.selected:
								cmd.add_vertices(cur_block.get_path(), [])

					cmd.selection_type = Selection.choose_type(e.shift_pressed, e.ctrl_pressed)

					if handle:
						cmd.add_vertex(handle.block_path, handle.vertex_index)
						#print("selectibg %s" % handle.vertex_index)
					
					if cmd.will_change_anything():
						var undo:EditorUndoRedoManager = builder.get_undo_redo()

						cmd.add_to_undo_manager(undo)
					
					
					tool_state = ToolState.NONE
					cmd_move_vertex = null
					
				elif tool_state == ToolState.DRAGGING:
					#Finish drag
					#print("cmd finish drag")
					var undo:EditorUndoRedoManager = builder.get_undo_redo()

					cmd_move_vertex.add_to_undo_manager(undo)
					
					tool_state = ToolState.NONE
					
				elif tool_state == ToolState.DRAGGING_ADD:
					#Finish drag
					#print("cmd finish drag add")
					var undo:EditorUndoRedoManager = builder.get_undo_redo()

					cmd_add_vertex.add_to_undo_manager(undo)
					
					tool_state = ToolState.NONE
					cmd_add_vertex = null

	elif event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event
		#mouse_hover_pos = e.position

		if (e.button_mask & MOUSE_BUTTON_MASK_MIDDLE):
			return false		
			
		if tool_state == ToolState.READY:
			if e.position.distance_squared_to(drag_mouse_start_pos) > MathUtil.square(builder.drag_start_radius):
				var handle:HandleVertex = pick_closest_handle(blocks_root, viewport_camera, drag_mouse_start_pos, builder.handle_screen_radius)

				if handle:
					drag_handle = handle
					drag_handle_start_pos = handle.position
					tool_state = ToolState.DRAGGING

					cmd_move_vertex = CommandMoveVertices.new()
					cmd_move_vertex.builder = builder

					var handle_block:CyclopsConvexBlock = builder.get_node(handle.block_path)
					if handle_block.control_mesh.vertices[handle.vertex_index].selected:
						for child in blocks_root.get_children():
							if child is CyclopsConvexBlock:
								var block:CyclopsConvexBlock = child
								if block.selected:
									var vol:ConvexVolume = block.control_mesh
									for v_idx in vol.vertices.size():
										var v:ConvexVolume.VertexInfo = vol.vertices[v_idx]
										if v.selected:
											cmd_move_vertex.add_vertex(block.get_path(), v_idx)
					else:
						cmd_move_vertex.add_vertex(handle.block_path, handle.vertex_index)
						
					return true
						
				else:
					if e.ctrl_pressed:
						var pick_origin:Vector3 = viewport_camera.project_ray_origin(e.position)
						var pick_dir:Vector3 = viewport_camera.project_ray_normal(e.position)
						var result:IntersectResults = blocks_root.intersect_ray_closest_selected_only(pick_origin, pick_dir)
						if result:
							#print("start drag add")
							drag_handle_start_pos = result.position
							added_point_pos = result.position
							tool_state = ToolState.DRAGGING_ADD

							cmd_add_vertex = CommandAddVertices.new()
							cmd_add_vertex.builder = builder

							cmd_add_vertex.block_path = result.object.get_path()
							cmd_add_vertex.points_to_add = [added_point_pos]
							#print("init point %s" % added_point_pos)
						
						return true
			
		elif tool_state == ToolState.DRAGGING:

			var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
			var dir:Vector3 = viewport_camera.project_ray_normal(e.position)

			var start_pos:Vector3 = origin + builder.block_create_distance * dir
			var w2l = blocks_root.global_transform.inverse()
			var origin_local:Vector3 = w2l * origin
			var dir_local:Vector3 = w2l.basis * dir
			
			var drag_to:Vector3
			if e.alt_pressed:
				drag_to = MathUtil.closest_point_on_line(origin_local, dir_local, drag_handle_start_pos, Vector3.UP)
			else:
				drag_to = MathUtil.intersect_plane(origin_local, dir_local, drag_handle_start_pos, Vector3.UP)
			
			drag_to = MathUtil.snap_to_grid(drag_to, grid_step_size)
			drag_handle.position = drag_to
			
			cmd_move_vertex.move_offset = drag_to - drag_handle.initial_position
			cmd_move_vertex.do_it()

#			draw_tool()
			return true

		elif tool_state == ToolState.DRAGGING_ADD:

			var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
			var dir:Vector3 = viewport_camera.project_ray_normal(e.position)

			var start_pos:Vector3 = origin + builder.block_create_distance * dir
			var w2l = blocks_root.global_transform.inverse()
			var origin_local:Vector3 = w2l * origin
			var dir_local:Vector3 = w2l.basis * dir
			
			var drag_to:Vector3
			if e.alt_pressed:
				drag_to = MathUtil.closest_point_on_line(origin_local, dir_local, drag_handle_start_pos, Vector3.UP)
			else:
				drag_to = MathUtil.intersect_plane(origin_local, dir_local, drag_handle_start_pos, Vector3.UP)

			drag_to = MathUtil.snap_to_grid(drag_to, grid_step_size)
			
			added_point_pos = drag_to
			#print("drag point to %s" % drag_to)

			cmd_add_vertex.points_to_add = [drag_to]
			cmd_add_vertex.do_it()
					
	return false

