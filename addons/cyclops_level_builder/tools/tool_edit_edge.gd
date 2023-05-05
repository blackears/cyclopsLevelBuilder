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
class_name ToolEditEdge

const TOOL_ID:String = "edit_edge"

var handles:Array[HandleEdge] = []

enum ToolState { NONE, READY, DRAGGING }
var tool_state:ToolState = ToolState.NONE

var drag_handle:HandleEdge
var drag_mouse_start_pos:Vector2
var drag_handle_start_pos:Vector3
			
var tracked_blocks_root:CyclopsBlocks

var cmd_move_edge:CommandMoveEdges


class PickHandleResult extends RefCounted:
	var handle:HandleEdge
	var position:Vector3
	
	
func _get_tool_id()->String:
	return TOOL_ID

func _draw_tool(viewport_camera:Camera3D):
	var global_scene:CyclopsGlobalScene = builder.get_global_scene()
	global_scene.clear_tool_mesh()	
	
	#var blocks_root:CyclopsBlocks = builder.active_node
	for h in handles:
		var block:CyclopsConvexBlock = builder.get_node(h.block_path)
		var e:ConvexVolume.EdgeInfo = block.control_mesh.edges[h.edge_index]
		var p0:Vector3 = block.control_mesh.vertices[e.start_index].point
		var p1:Vector3 = block.control_mesh.vertices[e.end_index].point

		var active:bool = block.control_mesh.active_edge == h.edge_index		
		global_scene.draw_vertex((p0 + p1) / 2, pick_material(global_scene, e.selected, active))
		global_scene.draw_line(p0, p1, pick_material(global_scene, e.selected, active))
	
func setup_tool():
	handles = []
	
	var blocks_root:CyclopsBlocks = builder.active_node
	if blocks_root == null:
		return
		
	for child in blocks_root.get_children():
		if child is CyclopsConvexBlock:
			var block:CyclopsConvexBlock = child
			if block.selected:
				for e_idx in block.control_mesh.edges.size():
					var ctl_mesh:ConvexVolume = block.control_mesh
					var e:ConvexVolume.EdgeInfo = ctl_mesh.edges[e_idx]

					var handle:HandleEdge = HandleEdge.new()
					handle.p_ref = ctl_mesh.vertices[e.start_index].point
					handle.p_ref_init = handle.p_ref
#					handle.p1 = ctl_mesh.vertices[e.end_index].point
#					handle.p1_init = handle.p1
					handle.edge_index = e_idx
					handle.block_path = block.get_path()
					handles.append(handle)
					
					
					#print("adding handle %s" % handle)

	
func pick_closest_handle(blocks_root:CyclopsBlocks, viewport_camera:Camera3D, position:Vector2, radius:float)->PickHandleResult:
	var best_dist:float = INF
	var best_handle:HandleEdge = null
	var best_pick_position:Vector3
	
	var pick_origin:Vector3 = viewport_camera.project_ray_origin(position)
	var pick_dir:Vector3 = viewport_camera.project_ray_normal(position)
	
	for h in handles:
		var block:CyclopsConvexBlock = builder.get_node(h.block_path)
		var ctl_mesh:ConvexVolume = block.control_mesh
		var edge:ConvexVolume.EdgeInfo = ctl_mesh.edges[h.edge_index]

		var p0 = ctl_mesh.vertices[edge.start_index].point
		var p1 = ctl_mesh.vertices[edge.end_index].point
		var p0_world:Vector3 = blocks_root.global_transform * p0
		var p1_world:Vector3 = blocks_root.global_transform * p1
		
		var p0_screen:Vector2 = viewport_camera.unproject_position(p0_world)
		var p1_screen:Vector2 = viewport_camera.unproject_position(p1_world)
		
		var dist_to_seg_2d_sq = MathUtil.dist_to_segment_squared_2d(position, p0_screen, p1_screen)
		
		if dist_to_seg_2d_sq > radius * radius:
			#Failed handle radius test
			continue

		var point_on_seg:Vector3 = MathUtil.closest_point_on_segment(pick_origin, pick_dir, p0_world, p1_world)
		
		var offset:Vector3 = point_on_seg - pick_origin
		var parallel:Vector3 = offset.project(pick_dir)
		var dist = parallel.dot(pick_dir)
		if dist <= 0:
			#Behind camera
			continue
		
		#print("h pos %s ray orig %s ray dir %s offset %s para %s dist %s perp %s" % [h.position, ray_origin, ray_dir, offset, parallel, dist, perp])
		if dist >= best_dist:
			continue
		
		best_pick_position = point_on_seg
		best_dist = dist
		best_handle = h
	
	if !best_handle:
		return null
	
	var result:PickHandleResult = PickHandleResult.new()
	result.handle = best_handle
	result.position = best_pick_position
	return result

func active_node_changed():
	if tracked_blocks_root != null:
		tracked_blocks_root.blocks_changed.disconnect(active_node_updated)
		tracked_blocks_root = null
		
	setup_tool()
#	draw_tool()
	
	tracked_blocks_root = builder.active_node
	if tracked_blocks_root:
		tracked_blocks_root.blocks_changed.connect(active_node_updated)
		

func active_node_updated():
	setup_tool()
#	draw_tool()

func _activate(builder:CyclopsLevelBuilder):
	super._activate(builder)
	
	builder.mode = CyclopsLevelBuilder.Mode.EDIT
	builder.edit_mode = CyclopsLevelBuilder.EditMode.EDGE
	builder.active_node_changed.connect(active_node_changed)
	
	tracked_blocks_root = builder.active_node
	if tracked_blocks_root:
		tracked_blocks_root.blocks_changed.connect(active_node_updated)
	
	
	setup_tool()
#	draw_tool()
	
	
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
	#var global_scene:CyclopsGlobalScene = builder.get_node("/root/CyclopsAutoload")
	#_draw_tool(viewport_camera)

#	if event is InputEventKey:
#		return true

	if event is InputEventMouseButton:
		
		var e:InputEventMouseButton = event
		if e.button_index == MOUSE_BUTTON_LEFT:

			if e.is_pressed():
				
				if tool_state == ToolState.NONE:
					drag_mouse_start_pos = e.position
					tool_state = ToolState.READY
					
				return true
			else:
#				print("bn up: state %s" % tool_state)
				if tool_state == ToolState.READY:
					#print("cmd select")
					var cmd:CommandSelectEdges = CommandSelectEdges.new()
					cmd.builder = builder
					
					for child in builder.active_node.get_children():
						if child is CyclopsConvexBlock:
							var cur_block:CyclopsConvexBlock = child
							if cur_block.selected:
								cmd.add_edges(cur_block.get_path(), [])

					cmd.selection_type = Selection.choose_type(e.shift_pressed, e.ctrl_pressed)

					var res:PickHandleResult = pick_closest_handle(blocks_root, viewport_camera, e.position, builder.handle_screen_radius)
					if res:
						var handle:HandleEdge = res.handle

	#					print("handle %s" % handle)

						cmd.add_edge(handle.block_path, handle.edge_index)
						#print("selectibg %s" % handle.vertex_index)

					if cmd.will_change_anything():					
						var undo:EditorUndoRedoManager = builder.get_undo_redo()
						cmd.add_to_undo_manager(undo)
										
					tool_state = ToolState.NONE
#					draw_tool()
					
				elif tool_state == ToolState.DRAGGING:
					#Finish drag
					#print("cmd finish drag")
					var undo:EditorUndoRedoManager = builder.get_undo_redo()

					cmd_move_edge.add_to_undo_manager(undo)
					
					tool_state = ToolState.NONE
					#setup_tool()

	elif event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event

		if (e.button_mask & MOUSE_BUTTON_MASK_MIDDLE):
			return false		
			
		if tool_state == ToolState.READY:
			if e.position.distance_squared_to(drag_mouse_start_pos) > MathUtil.square(builder.drag_start_radius):
				var res:PickHandleResult = pick_closest_handle(blocks_root, viewport_camera, drag_mouse_start_pos, builder.handle_screen_radius)

				if res:
					var handle:HandleEdge = res.handle
					drag_handle = handle
#					drag_handle_start_pos = handle.p_ref
					drag_handle_start_pos = res.position
					tool_state = ToolState.DRAGGING

					cmd_move_edge = CommandMoveEdges.new()
					cmd_move_edge.builder = builder
#					cmd_move_vertex.block_path = handle.block_path
#					cmd_move_vertex.vertex_position = handle.initial_position

					var handle_block:CyclopsConvexBlock = builder.get_node(handle.block_path)
					if handle_block.control_mesh.edges[handle.edge_index].selected:
						for child in blocks_root.get_children():
							if child is CyclopsConvexBlock:
								var block:CyclopsConvexBlock = child
								if block.selected:
									var vol:ConvexVolume = block.control_mesh
									for e_idx in vol.edges.size():
										var edge:ConvexVolume.EdgeInfo = vol.edges[e_idx]
										if edge.selected:
											cmd_move_edge.add_edge(block.get_path(), e_idx)
					else:
						cmd_move_edge.add_edge(handle.block_path, handle.edge_index)
				
			
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
			
			var offset:Vector3 = drag_to - drag_handle_start_pos
			offset = MathUtil.snap_to_grid(offset, grid_step_size)
			drag_to = drag_handle_start_pos + offset
			drag_handle.p_ref = drag_to
#			drag_handle.p1 = drag_handle.p1_init + offset
			
			cmd_move_edge.move_offset = offset
			cmd_move_edge.do_it()

#			draw_tool()
			return true
		
	return false
