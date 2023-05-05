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

const TOOL_ID:String = "edit_face"

var handles:Array[HandleFace] = []

enum ToolState { NONE, READY, DRAGGING }
var tool_state:ToolState = ToolState.NONE

var drag_handle:HandleFace
var drag_mouse_start_pos:Vector2
var drag_handle_start_pos:Vector3
			
var tracked_blocks_root:CyclopsBlocks

var cmd_move_face:CommandMoveFaces


class PickHandleResult extends RefCounted:
	var handle:HandleFace
	var position:Vector3
	
func _get_tool_id()->String:
	return TOOL_ID

func _draw_tool(viewport_camera:Camera3D):
	var global_scene:CyclopsGlobalScene = builder.get_global_scene()
	global_scene.clear_tool_mesh()
	
	var blocks_root:CyclopsBlocks = builder.active_node
	for h in handles:
#		print("draw face %s" % h)
		var block:CyclopsConvexBlock = builder.get_node(h.block_path)
		var f:ConvexVolume.FaceInfo = block.control_mesh.faces[h.face_index]

		var active:bool = block.control_mesh.active_face == h.face_index		
		global_scene.draw_vertex(h.p_ref, pick_material(global_scene, f.selected, active))
		
		
		if f.selected:
			var edge_loop:PackedVector3Array = f.get_points()
			for p_idx in edge_loop.size():
				edge_loop[p_idx] += f.normal * builder.tool_overlay_extrude
			global_scene.draw_loop(edge_loop, true, pick_material(global_scene, f.selected, active))
			
			var tris:PackedVector3Array = f.get_trianges()
			for p_idx in tris.size():
				tris[p_idx] += f.normal * builder.tool_overlay_extrude
			
#			print("draw face %s %s %s" % [h.face_index, f.selected, f.active])
			var mat:Material = global_scene.tool_edit_active_fill_material if active else global_scene.tool_edit_selected_fill_material
			global_scene.draw_triangles(tris, mat)
		
	
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
#					print("adding face hande %s %s" % [block.name, f_idx])
					
					var ctl_mesh:ConvexVolume = block.control_mesh
					var face:ConvexVolume.FaceInfo = ctl_mesh.faces[f_idx]

					var handle:HandleFace = HandleFace.new()
					
					var p_start:Vector3 = face.get_centroid()
#					p_start = MathUtil.snap_to_grid(p_start, grid_step_size)
					handle.p_ref = p_start
					handle.p_ref_init = p_start
					
					handle.face_index = f_idx
					handle.face_id = face.id
					handle.block_path = block.get_path()
					handles.append(handle)
					
					
					#print("adding handle %s" % handle)

func pick_closest_handle(viewport_camera:Camera3D, position:Vector2, radius:float)->PickHandleResult:
	var blocks_root:CyclopsBlocks = builder.active_node
	if blocks_root == null:
		return
	
	var pick_origin:Vector3 = viewport_camera.project_ray_origin(position)
	var pick_dir:Vector3 = viewport_camera.project_ray_normal(position)
	
	if builder.display_mode == DisplayMode.Type.TEXTURED:
		var result:IntersectResults = blocks_root.intersect_ray_closest_selected_only(pick_origin, pick_dir)
		if result:
			for h in handles:
				if h.block_path == result.object.get_path() && h.face_id == result.face_id:
					var ret:PickHandleResult = PickHandleResult.new()
					ret.handle = h
					ret.position = result.position
					return ret
					
	elif builder.display_mode == DisplayMode.Type.WIRE:
		var best_dist:float = INF
		var best_handle:HandleFace = null
		var best_position:Vector3
		
		
		for h in handles:
			var h_world_pos:Vector3 = blocks_root.global_transform * h.p_ref
			var h_screen_pos:Vector2 = viewport_camera.unproject_position(h_world_pos)
			if position.distance_squared_to(h_screen_pos) > radius * radius:
				#Failed handle radius test
				continue
			
			var offset:Vector3 = h_world_pos - pick_origin
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
			best_position = h_world_pos
		
		var result:PickHandleResult = PickHandleResult.new()
		result.handle = best_handle
		result.position = best_position
		return result
	
	return null	
	


func active_node_changed():
	if tracked_blocks_root != null:
		tracked_blocks_root.blocks_changed.disconnect(active_node_updated)
		tracked_blocks_root = null
		
	setup_tool()
	#draw_tool()
	
	tracked_blocks_root = builder.active_node
	if tracked_blocks_root:
		tracked_blocks_root.blocks_changed.connect(active_node_updated)
		
	

func active_node_updated():
	setup_tool()
	#draw_tool()

func _activate(builder:CyclopsLevelBuilder):
	super._activate(builder)
	
	builder.mode = CyclopsLevelBuilder.Mode.EDIT
	builder.edit_mode = CyclopsLevelBuilder.EditMode.FACE
	builder.active_node_changed.connect(active_node_changed)
	
	tracked_blocks_root = builder.active_node
	if tracked_blocks_root:
		tracked_blocks_root.blocks_changed.connect(active_node_updated)
	
	
	setup_tool()
	#draw_tool()
	
	
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
#	var global_scene:CyclopsGlobalScene = builder.get_node("/root/CyclopsAutoload")
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

					var cmd:CommandSelectFaces = CommandSelectFaces.new()
					cmd.builder = builder
					
					for child in builder.active_node.get_children():
						if child is CyclopsConvexBlock:
							var cur_block:CyclopsConvexBlock = child
							if cur_block.selected:
								cmd.add_faces(cur_block.get_path(), [])

					var res:PickHandleResult = pick_closest_handle(viewport_camera, e.position, builder.handle_screen_radius)
					if res:
						var handle:HandleFace = res.handle
						#print("handle %s" % handle)
							
						cmd.add_face(handle.block_path, handle.face_index)
						#print("selecting %s" % handle.face_index)
						
					cmd.selection_type = Selection.choose_type(e.shift_pressed, e.ctrl_pressed)
						
					if cmd.will_change_anything():
						var undo:EditorUndoRedoManager = builder.get_undo_redo()
						cmd.add_to_undo_manager(undo)
					
					
					tool_state = ToolState.NONE
#					draw_tool()
					
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
			if e.position.distance_squared_to(drag_mouse_start_pos) > MathUtil.square(builder.drag_start_radius):
				var res:PickHandleResult = pick_closest_handle(viewport_camera, drag_mouse_start_pos, builder.handle_screen_radius)

				if res:
					var handle:HandleFace = res.handle
					drag_handle = handle
#					drag_handle_start_pos = handle.p_ref
					drag_handle_start_pos = res.position
					tool_state = ToolState.DRAGGING

					cmd_move_face = CommandMoveFaces.new()
					cmd_move_face.builder = builder

					var handle_block:CyclopsConvexBlock = builder.get_node(handle.block_path)
					if handle_block.control_mesh.faces[handle.face_index].selected:
						for child in blocks_root.get_children():
							if child is CyclopsConvexBlock:
								var block:CyclopsConvexBlock = child
								if block.selected:
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

#			draw_tool()
			return true
		
	return false				
				
