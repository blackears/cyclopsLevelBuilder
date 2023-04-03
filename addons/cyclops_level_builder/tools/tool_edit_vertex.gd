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
class_name ToolEditVertex

var handles:Array[HandleVertex] = []

enum ToolState { READY, DRAGGING }
var tool_state:ToolState = ToolState.READY

var drag_handle:HandleVertex
var drag_mouse_start_pos:Vector2
var drag_handle_start_pos:Vector3

var cmd_move_vertex:CommandMoveVertex

func draw_tool():
	var global_scene:CyclopsGlobalScene = builder.get_node("/root/CyclopsAutoload")
	global_scene.clear_tool_mesh()
	
	var blocks_root:CyclopsBlocks = builder.active_node
	for h in handles:
		global_scene.draw_vertex(h.position)
	
func setup_tool():
	handles = []
	
	var blocks_root:CyclopsBlocks = builder.active_node
	for child in blocks_root.get_children():
		if child is CyclopsConvexBlock:
			var block:CyclopsConvexBlock = child
			if block.selected:
				var points:PackedVector3Array = block.control_mesh.calc_convex_hull_points()

				for p in points:
					var handle:HandleVertex = HandleVertex.new()
					handle.position = p
					handle.initial_position = p
					handle.block_path = block.get_path()
					handles.append(handle)
					
					#print("adding handle %s" % handle)


func pick_closest_handle(ray_origin:Vector3, ray_dir:Vector3, radius:float)->HandleVertex:
	var best_dist:float = INF
	var best_handle:HandleVertex = null
	
	for h in handles:
		var offset = h.position - ray_origin
		var parallel:Vector3 = offset.project(ray_dir)
		var dist = parallel.dot(ray_dir)
		if dist <= 0:
			continue
		
		var perp:Vector3 = offset - parallel	
		if perp.length_squared() > radius * radius:
			continue
		
		#print("h pos %s ray orig %s ray dir %s offset %s para %s dist %s perp %s" % [h.position, ray_origin, ray_dir, offset, parallel, dist, perp])
		if dist >= best_dist:
			continue
		
		best_dist = dist
		best_handle = h

	return best_handle
			
		
	
func _activate(builder:CyclopsLevelBuilder):
	super._activate(builder)
	
	setup_tool()

	draw_tool()
	
	
#func _deactivate():
#	super._deactivate()
#	pass


func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:	
	var blocks_root:CyclopsBlocks = self.builder.active_node
	var grid_step_size:float = pow(2, blocks_root.grid_size)
	var global_scene:CyclopsGlobalScene = builder.get_node("/root/CyclopsAutoload")

	if event is InputEventKey:
		return true

	if event is InputEventMouseButton:
		
		var e:InputEventMouseButton = event
		if e.button_index == MOUSE_BUTTON_LEFT:

			if e.is_pressed():
				var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
				var dir:Vector3 = viewport_camera.project_ray_normal(e.position)

				var start_pos:Vector3 = origin + builder.block_create_distance * dir
				var w2l = blocks_root.global_transform.inverse()
				var origin_local:Vector3 = w2l * origin
				var dir_local:Vector3 = w2l.basis * dir
				
				if tool_state == ToolState.READY:
					var handle:HandleVertex = pick_closest_handle(origin_local, dir_local, builder.handle_point_radius)
					
					#print("picked handle %s" % handle)
					if handle:
						drag_handle = handle
						drag_mouse_start_pos = e.position
						drag_handle_start_pos = handle.position
						tool_state = ToolState.DRAGGING

						cmd_move_vertex = CommandMoveVertex.new()
						cmd_move_vertex.builder = builder
						cmd_move_vertex.block_path = handle.block_path
						cmd_move_vertex.vertex_position = handle.initial_position
						
				return true
			else:
				if tool_state == ToolState.DRAGGING:
					#Finish drag
					var undo:EditorUndoRedoManager = builder.get_undo_redo()

					cmd_move_vertex.add_to_undo_manager(undo)
									
					tool_state = ToolState.READY
					setup_tool()

	elif event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event

		if (e.button_mask & MOUSE_BUTTON_MASK_MIDDLE):
			return false		
			
		if tool_state == ToolState.DRAGGING:

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

			draw_tool()
			return true
		
	return false

