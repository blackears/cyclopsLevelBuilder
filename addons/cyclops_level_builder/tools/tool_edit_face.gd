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
class_name ToolEditFace

var handles:Array[HandleFace] = []

enum ToolState { NONE, READY, DRAGGING }
var tool_state:ToolState = ToolState.NONE

var drag_handle:HandleFace
var drag_mouse_start_pos:Vector2
var drag_handle_start_pos:Vector3
			
var tracked_blocks_root:CyclopsBlocks

var cmd_move_face:CommandMoveFaces

func draw_tool():
	var global_scene:CyclopsGlobalScene = builder.get_node("/root/CyclopsAutoload")
	global_scene.clear_tool_mesh()
	
	var blocks_root:CyclopsBlocks = builder.active_node
	for h in handles:
		#print("draw face %s" % h)
		var block:CyclopsConvexBlock = builder.get_node(h.block_path)
		var f:ConvexVolume.FaceInfo = block.control_mesh.faces[h.face_index]
		global_scene.draw_vertex(h.p_ref, pick_material(global_scene, f.selected))
	
func setup_tool():
	handles = []
	
	var blocks_root:CyclopsBlocks = builder.active_node
	if blocks_root == null:
		return
#	var grid_step_size:float = pow(2, blocks_root.grid_size)
		
	for child in blocks_root.get_children():
		if child is CyclopsConvexBlock:
			var block:CyclopsConvexBlock = child
			if block.selected:
				for f_idx in block.control_mesh.faces.size():
					#print("adding face %s" % f_idx)
					
					var ctl_mesh:ConvexVolume = block.control_mesh
					var face:ConvexVolume.FaceInfo = ctl_mesh.faces[f_idx]

					var handle:HandleFace = HandleFace.new()
					
					var p_start:Vector3 = face.get_centroid()
#					p_start = MathUtil.snap_to_grid(p_start, grid_step_size)
					handle.p_ref = p_start
					handle.p_ref_init = p_start
					
					handle.face_index = f_idx
					handle.block_path = block.get_path()
					handles.append(handle)
					
					
					#print("adding handle %s" % handle)


func pick_closest_handle(blocks_root:CyclopsBlocks, viewport_camera:Camera3D, position:Vector2, radius:float)->HandleFace:
	var best_dist:float = INF
	var best_handle:HandleFace = null
	
	var pick_origin:Vector3 = viewport_camera.project_ray_origin(position)
	var pick_dir:Vector3 = viewport_camera.project_ray_normal(position)
	
	for h in handles:
		var block:CyclopsConvexBlock = builder.get_node(h.block_path)
		var ctl_mesh:ConvexVolume = block.control_mesh
		var face:ConvexVolume.FaceInfo = ctl_mesh.faces[h.face_index]
#		var p_ref:Vector3 = h.p_ref
#		var p1:Vector3 = ctl_mesh.vertices[edge.end_index].point
		
		
#		var points:PackedVector3Array = face.get_points()
#		for i in points.size():
#			points[i] += offset
#		var triangles:PackedVector3Array = MathUtil.trianglate_face(points, face.normal)
#		for i in range(0, triangles.size(), 3):
#			MathUtil.intersect_triangle(pick_origin, pick_dir, triangles[i * 3], triangles[i * 3 + 1], triangles[i * 3 + 2])
#		var plane:Plane = face.get_plane()
#		var result = plane.intersects_ray(pick_origin, pick_dir)
#		if result != null:
			
		#####
		
		#Handle intersection
		var p_ref_world:Vector3 = blocks_root.global_transform * h.p_ref
		var p_ref_screen:Vector2 = viewport_camera.unproject_position(p_ref_world)
		
		if position.distance_squared_to(p_ref_screen) > radius * radius:
			#Failed handle radius test
			continue

		var offset:Vector3 = p_ref_world - pick_origin
		var parallel:Vector3 = offset.project(pick_dir)
		var dist = parallel.dot(pick_dir)
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
	draw_tool()
	
	tracked_blocks_root = builder.active_node
	if tracked_blocks_root:
		tracked_blocks_root.blocks_changed.connect(active_node_updated)
		
	

func active_node_updated():
	setup_tool()
	draw_tool()

func _activate(builder:CyclopsLevelBuilder):
	super._activate(builder)
	
	builder.mode = CyclopsLevelBuilder.Mode.FACE
	builder.active_node_changed.connect(active_node_changed)
	
	tracked_blocks_root = builder.active_node
	if tracked_blocks_root:
		tracked_blocks_root.blocks_changed.connect(active_node_updated)
	
	
	setup_tool()
	draw_tool()
	
	
func _deactivate():
	super._deactivate()
	builder.active_node_changed.disconnect(active_node_changed)
	if tracked_blocks_root != null:
		tracked_blocks_root.blocks_changed.disconnect(active_node_updated)

func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:	
	var blocks_root:CyclopsBlocks = self.builder.active_node
	var grid_step_size:float = pow(2, blocks_root.grid_size)
	var global_scene:CyclopsGlobalScene = builder.get_node("/root/CyclopsAutoload")

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
					var handle:HandleFace = pick_closest_handle(blocks_root, viewport_camera, e.position, builder.handle_screen_radius)

					#print("handle %s" % handle)

					if handle:
						var block:CyclopsConvexBlock = builder.get_node(handle.block_path)
						
						var cmd:CommandSelectFaces = CommandSelectFaces.new()
						cmd.builder = builder
						
						cmd.selection_type = Selection.choose_type(e.shift_pressed, e.ctrl_pressed)
						cmd.add_face(handle.block_path, handle.face_index)
						#print("selectibg %s" % handle.face_index)
					
						var undo:EditorUndoRedoManager = builder.get_undo_redo()

						cmd.add_to_undo_manager(undo)
					
					
					tool_state = ToolState.NONE
					draw_tool()
					
				elif tool_state == ToolState.DRAGGING:
					#Finish drag
					#print("cmd finish drag")
					var undo:EditorUndoRedoManager = builder.get_undo_redo()

					cmd_move_face.add_to_undo_manager(undo)
					
					tool_state = ToolState.NONE
				

	elif event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event

		if (e.button_mask & MOUSE_BUTTON_MASK_MIDDLE):
			return false		
			
		if tool_state == ToolState.READY:
			if e.position.distance_squared_to(drag_mouse_start_pos) < 4 * 4:
				var handle:HandleFace = pick_closest_handle(blocks_root, viewport_camera, drag_mouse_start_pos, builder.handle_screen_radius)

				if handle:
					drag_handle = handle
					drag_handle_start_pos = handle.p_ref
					tool_state = ToolState.DRAGGING

					cmd_move_face = CommandMoveFaces.new()
					cmd_move_face.builder = builder
#					cmd_move_vertex.block_path = handle.block_path
#					cmd_move_vertex.vertex_position = handle.initial_position

					var handle_block:CyclopsConvexBlock = builder.get_node(handle.block_path)
					if handle_block.control_mesh.faces[handle.face_index].selected:
						for child in blocks_root.get_children():
							if child is CyclopsConvexBlock:
								var block:CyclopsConvexBlock = child
								var vol:ConvexVolume = block.control_mesh
								for f_idx in vol.faces.size():
									var face:ConvexVolume.FaceInfo = vol.faces[f_idx]
									if face.selected:
										cmd_move_face.add_face(block.get_path(), f_idx)
					else:
						cmd_move_face.add_face(handle.block_path, handle.face_index)
				
			
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
			
			var offset = drag_to - drag_handle_start_pos
			offset = MathUtil.snap_to_grid(offset, grid_step_size)
			drag_to = drag_handle_start_pos + offset
			drag_handle.p_ref = drag_to
			
			cmd_move_face.move_offset = offset
#			print("drag_offset %s" % cmd_move_face.move_offset)
			cmd_move_face.do_it()

			draw_tool()
			return true
		
	return false				
				
