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

enum ToolState { NONE, READY, DRAGGING, MOVE_HANDLES_CLICK, DRAG_SELECTION }
var tool_state:ToolState = ToolState.NONE

#var drag_handle:HandleFace
var drag_mouse_start_pos:Vector2
var drag_handle_start_pos:Vector3
			
#enum MoveConstraint { NONE, AXIS_X, AXIS_Y, AXIS_Z, PLANE_XY, PLANE_XZ, PLANE_YZ, PLANE_VIEWPORT }
var move_constraint:MoveConstraint.Type = MoveConstraint.Type.NONE

var gizmo_translate:Node3D

var cmd_move_face:CommandMoveFaces


class PickHandleResult extends RefCounted:
	var handle:HandleFace
	var position:Vector3
	
func _get_tool_id()->String:
	return TOOL_ID


func draw_gizmo(viewport_camera:Camera3D):
	var global_scene:CyclopsGlobalScene = builder.get_global_scene()
	if !gizmo_translate:
		gizmo_translate = preload("res://addons/cyclops_level_builder/tools/gizmos/gizmo_translate.tscn").instantiate()
	
	var origin:Vector3
	var count:int = 0
	for h in handles:
		var block:CyclopsBlock = builder.get_node(h.block_path)
		var l2w:Transform3D = block.global_transform
		
		var f:ConvexVolume.FaceInfo = block.control_mesh.faces[h.face_index]
		if f.selected:
#			print("adding midpoint ", e.get_midpoint())
			origin += l2w * f.get_centroid()
			count += 1

	if count == 0:
		global_scene.set_custom_gizmo(null)
	else:
		origin /= count
		#print("gizmo origin ", origin)
#		print("final origin ", origin)
		global_scene.set_custom_gizmo(gizmo_translate)
		gizmo_translate.global_transform.origin = origin


func _draw_tool(viewport_camera:Camera3D):
	var global_scene:CyclopsGlobalScene = builder.get_global_scene()
	global_scene.clear_tool_mesh()

	if tool_state == ToolState.DRAG_SELECTION:
		global_scene.draw_screen_rect(viewport_camera, drag_select_start_pos, drag_select_to_pos, global_scene.selection_rect_material)
	
	#var blocks_root:CyclopsBlocks = builder.active_node
	for h in handles:
#		print("draw face %s" % h)
		if Engine.is_editor_hint() && !builder.has_node(h.block_path):
			continue
			
		var block:CyclopsBlock = builder.get_node(h.block_path)
		var f:ConvexVolume.FaceInfo = block.control_mesh.faces[h.face_index]

		var active:bool = block.control_mesh.active_face == h.face_index		
		global_scene.draw_vertex(h.p_center, pick_vertex_material(global_scene, f.selected, active))
		
		var l2w:Transform3D = block.global_transform
		#var w2l:Transform3D = block.global_transform.affine_inverse()
		
		if f.selected:
			var edge_loop:PackedVector3Array = f.get_points()
			for p_idx in edge_loop.size():
				edge_loop[p_idx] += f.normal * builder.tool_overlay_extrude
			global_scene.draw_loop(l2w * edge_loop, true, pick_material(global_scene, f.selected, active))
			
			var tris:PackedVector3Array = f.get_trianges()
			for p_idx in tris.size():
				tris[p_idx] += f.normal * builder.tool_overlay_extrude
			
#			print("draw face %s %s %s" % [h.face_index, f.selected, f.active])
			var mat:Material = global_scene.tool_edit_active_fill_material if active else global_scene.tool_edit_selected_fill_material
			global_scene.draw_triangles(l2w * tris, mat)
		
	draw_gizmo(viewport_camera)
	
func setup_tool():
	handles = []
	#print("setup_tool")
	
	var sel_blocks:Array[CyclopsBlock] = builder.get_selected_blocks()
	for block in sel_blocks:
		var l2w:Transform3D = block.global_transform
		#var w2l:Transform3D = block.global_transform.affine_inverse()
		
		for f_idx in block.control_mesh.faces.size():
#					print("adding face hande %s %s" % [block.name, f_idx])
			
			var ctl_mesh:ConvexVolume = block.control_mesh
			var face:ConvexVolume.FaceInfo = ctl_mesh.faces[f_idx]

			var handle:HandleFace = HandleFace.new()
			
			var p_start:Vector3 = l2w * face.get_centroid()
			#print("p_start %s" % p_start)

			handle.p_center = p_start
#			handle.p_ref = p_start
#			handle.p_ref_init = p_start
			
			handle.face_index = f_idx
#			handle.face_id = face.id
			handle.block_path = block.get_path()
			handles.append(handle)
	
func pick_closest_handle(viewport_camera:Camera3D, position:Vector2, radius:float)->PickHandleResult:
	
	var pick_origin:Vector3 = viewport_camera.project_ray_origin(position)
	var pick_dir:Vector3 = viewport_camera.project_ray_normal(position)
	
	if builder.display_mode == DisplayMode.Type.MATERIAL || builder.display_mode == DisplayMode.Type.MESH:
		var result:IntersectResults = builder.intersect_ray_closest_selected_only(pick_origin, pick_dir)
		if result:
			for h in handles:
				if h.block_path == result.object.get_path() && h.face_index == result.face_index:
					var ret:PickHandleResult = PickHandleResult.new()
					ret.handle = h
					ret.position = result.get_world_position()
					return ret
					
	elif builder.display_mode == DisplayMode.Type.WIRE:
		var best_dist:float = INF
		var best_handle:HandleFace = null
		var best_position:Vector3
		
		
		for h in handles:
#			var h_world_pos:Vector3 = blocks_root.global_transform * h.p_ref
			var h_world_pos:Vector3 = h.p_center
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
	setup_tool()
	

func active_node_updated():
	setup_tool()
	#draw_tool()

func _activate(builder:CyclopsLevelBuilder):
	super._activate(builder)
	
	builder.mode = CyclopsLevelBuilder.Mode.EDIT
	builder.edit_mode = CyclopsLevelBuilder.EditMode.FACE
	builder.active_node_changed.connect(active_node_changed)
	
	setup_tool()
	
	
func _deactivate():
	super._deactivate()
	builder.active_node_changed.disconnect(active_node_changed)

	var global_scene:CyclopsGlobalScene = builder.get_global_scene()
	global_scene.set_custom_gizmo(null)


func start_drag(viewport_camera:Camera3D, event:InputEvent):
	var e:InputEventMouseMotion = event
	move_constraint = MoveConstraint.Type.NONE

	if gizmo_translate:
	
		var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
		var dir:Vector3 = viewport_camera.project_ray_normal(e.position)
		
		var part_res:GizmoTranslate.IntersectResult = gizmo_translate.intersect(origin, dir, viewport_camera)
		if part_res:
			#print("Gizmo hit ", part_res.part)
			match part_res.part:
				GizmoTranslate.Part.AXIS_X:
					move_constraint = MoveConstraint.Type.AXIS_X
				GizmoTranslate.Part.AXIS_Y:
					move_constraint = MoveConstraint.Type.AXIS_Y
				GizmoTranslate.Part.AXIS_Z:
					move_constraint = MoveConstraint.Type.AXIS_Z
				GizmoTranslate.Part.PLANE_XY:
					move_constraint = MoveConstraint.Type.PLANE_XY
				GizmoTranslate.Part.PLANE_XZ:
					move_constraint = MoveConstraint.Type.PLANE_XZ
				GizmoTranslate.Part.PLANE_YZ:
					move_constraint = MoveConstraint.Type.PLANE_YZ
		
			var start_pos:Vector3 = part_res.pos_world
			#var grid_step_size:float = pow(2, builder.get_global_scene().grid_size)

#			drag_handle_start_pos = MathUtil.snap_to_grid(start_pos, grid_step_size)
			#drag_handle_start_pos = builder.get_snapping_manager().snap_point(start_pos, SnappingQuery.new(viewport_camera))

			drag_handle_start_pos = start_pos
#			drag_handle_start_pos = gizmo_translate.global_position

	#		print("res obj %s" % result.object.get_path())
			var sel_blocks:Array[CyclopsBlock] = builder.get_selected_blocks()
			if !sel_blocks.is_empty():
				
				tool_state = ToolState.DRAGGING
				#print("Move block")
				
				cmd_move_face = CommandMoveFaces.new()
				cmd_move_face.builder = builder

				for block in sel_blocks:
					var vol:ConvexVolume = block.control_mesh
					for f_idx in vol.faces.size():
						var face:ConvexVolume.FaceInfo = vol.faces[f_idx]
						if face.selected:
							cmd_move_face.add_face(block.get_path(), f_idx)

			return


	if e.alt_pressed:
		move_constraint = MoveConstraint.Type.AXIS_Y
	else:
		move_constraint = MoveConstraint.Type.PLANE_XZ
		

	var res:PickHandleResult = pick_closest_handle(viewport_camera, drag_mouse_start_pos, builder.handle_screen_radius)

	if res:
		#print("pick handle %s" % res.handle)
		
		var handle:HandleFace = res.handle
		#drag_handle = handle
		drag_handle_start_pos = res.position
		#print("drag_handle_start_pos %s" % drag_handle_start_pos)
		tool_state = ToolState.DRAGGING

		cmd_move_face = CommandMoveFaces.new()
		cmd_move_face.builder = builder

		var handle_block:CyclopsBlock = builder.get_node(handle.block_path)
		if handle_block.control_mesh.faces[handle.face_index].selected:
			var sel_blocks:Array[CyclopsBlock] = builder.get_selected_blocks()
			for block in sel_blocks:
				var vol:ConvexVolume = block.control_mesh
				for f_idx in vol.faces.size():
					var face:ConvexVolume.FaceInfo = vol.faces[f_idx]
					if face.selected:
						cmd_move_face.add_face(block.get_path(), f_idx)

		else:
			cmd_move_face.add_face(handle.block_path, handle.face_index)
			
		return


	#Drag selectio rectangle
	tool_state = ToolState.DRAG_SELECTION
	drag_select_start_pos = e.position
	drag_select_to_pos = e.position
	
func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:	
	var gui_result = super._gui_input(viewport_camera, event)
	if gui_result:
		return true
		
	#var grid_step_size:float = pow(2, builder.get_global_scene().grid_size)



	if event is InputEventKey:
		var e:InputEventKey = event
		
		if e.keycode == KEY_ESCAPE:
			if e.is_pressed():
				if cmd_move_face:
					cmd_move_face.undo_it()
					cmd_move_face = null
					tool_state = ToolState.NONE
					
					setup_tool()
					
			return true

		elif e.keycode == KEY_A:

			if e.is_pressed():
				var cmd:CommandSelectFaces = CommandSelectFaces.new()
				cmd.builder = builder
				
				if e.alt_pressed:
					var sel_blocks:Array[CyclopsBlock] = builder.get_selected_blocks()
					for block in sel_blocks:
						cmd.add_faces(block.get_path(), [])
						
				else:
					var sel_blocks:Array[CyclopsBlock] = builder.get_selected_blocks()
					for block in sel_blocks:
						for f_idx in block.control_mesh.faces.size():
							cmd.add_face(block.get_path(), f_idx)

				cmd.selection_type = Selection.Type.REPLACE

				if cmd.will_change_anything():
					var undo:EditorUndoRedoManager = builder.get_undo_redo()

					cmd.add_to_undo_manager(undo)
					
		elif e.keycode == KEY_G:
			
			if e.is_pressed() && tool_state == ToolState.NONE:
				var sel_blocks:Array[CyclopsBlock] = builder.get_selected_blocks()
				if !sel_blocks.is_empty():

					tool_state = ToolState.MOVE_HANDLES_CLICK
					move_constraint = MoveConstraint.Type.PLANE_VIEWPORT

					drag_handle_start_pos = Vector3.INF
					
					cmd_move_face = CommandMoveFaces.new()
					cmd_move_face.builder = builder

					for block in sel_blocks:
						var vol:ConvexVolume = block.control_mesh
						for f_idx in vol.faces.size():
							var face:ConvexVolume.FaceInfo = vol.faces[f_idx]
							if face.selected:
								cmd_move_face.add_face(block.get_path(), f_idx)
					
			return true

		elif e.keycode == KEY_X:
			if tool_state == ToolState.MOVE_HANDLES_CLICK:
				if e.shift_pressed:
					move_constraint = MoveConstraint.Type.PLANE_YZ
				else:
					move_constraint = MoveConstraint.Type.AXIS_X
			return true

		elif e.keycode == KEY_Y:
			if tool_state == ToolState.MOVE_HANDLES_CLICK:
				if e.shift_pressed:
					move_constraint = MoveConstraint.Type.PLANE_XZ
				else:
					move_constraint = MoveConstraint.Type.AXIS_Y
			return true

		elif e.keycode == KEY_Z:
			if tool_state == ToolState.MOVE_HANDLES_CLICK:
				if e.shift_pressed:
					move_constraint = MoveConstraint.Type.PLANE_XY
				else:
					move_constraint = MoveConstraint.Type.AXIS_Z
			return true

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
					
					var sel_blocks:Array[CyclopsBlock] = builder.get_selected_blocks()
					for block in sel_blocks:
						cmd.add_faces(block.get_path(), [])
					
					var res:PickHandleResult = pick_closest_handle(viewport_camera, e.position, builder.handle_screen_radius)
					if res:
						var handle:HandleFace = res.handle
						#print("pick handle %s" % handle)
							
						cmd.add_face(handle.block_path, handle.face_index)
						#print("selecting %s" % handle.face_index)
						
					cmd.selection_type = Selection.choose_type(e.shift_pressed, e.ctrl_pressed)
						
					if cmd.will_change_anything():
						var undo:EditorUndoRedoManager = builder.get_undo_redo()
						cmd.add_to_undo_manager(undo)
					
					
					tool_state = ToolState.NONE
					
				elif tool_state == ToolState.DRAGGING:
					#Finish drag
					var undo:EditorUndoRedoManager = builder.get_undo_redo()

					cmd_move_face.add_to_undo_manager(undo)
					
					tool_state = ToolState.NONE
				

				elif tool_state == ToolState.MOVE_HANDLES_CLICK:
					var undo:EditorUndoRedoManager = builder.get_undo_redo()
					cmd_move_face.add_to_undo_manager(undo)
					
					tool_state = ToolState.NONE
					
				elif tool_state == ToolState.DRAG_SELECTION:
					
					var frustum:Array[Plane] = MathUtil.calc_frustum_camera_rect(viewport_camera, drag_select_start_pos, drag_select_to_pos)

					var cmd:CommandSelectFaces = CommandSelectFaces.new()
					cmd.builder = builder

					var sel_blocks:Array[CyclopsBlock] = builder.get_selected_blocks()
					for block in sel_blocks:
						
						for f_idx in block.control_mesh.faces.size():
							var face:ConvexVolume.FaceInfo = block.control_mesh.faces[f_idx]
							var point_w:Vector3 = block.global_transform * face.get_centroid()
							
							var origin:Vector3 = viewport_camera.project_ray_origin(e.position)

							var global_scene:CyclopsGlobalScene = builder.get_global_scene()

							#Obstruction check
							if !global_scene.xray_mode:  
								var result:IntersectResults = builder.intersect_ray_closest(origin, point_w - origin)
								var res_point_w:Vector3 = result.get_world_position()
								if !res_point_w.is_equal_approx(point_w):
									continue
							
							if MathUtil.frustum_contians_point(frustum, point_w):
								cmd.add_face(block.get_path(), f_idx)

					cmd.selection_type = Selection.choose_type(e.shift_pressed, e.ctrl_pressed)

					if cmd.will_change_anything():
						var undo:EditorUndoRedoManager = builder.get_undo_redo()

						cmd.add_to_undo_manager(undo)
					
					tool_state = ToolState.NONE
					
				return true
				
		elif e.button_index == MOUSE_BUTTON_RIGHT:
			if e.is_pressed():
				#Right click cancel
				if cmd_move_face:
					cmd_move_face.undo_it()
					cmd_move_face = null
					tool_state = ToolState.NONE
					
					setup_tool()
					
			return true

	elif event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event

		if (e.button_mask & MOUSE_BUTTON_MASK_MIDDLE):
			return false		
			
		if tool_state == ToolState.READY:
			if e.position.distance_squared_to(drag_mouse_start_pos) > MathUtil.square(builder.drag_start_radius):
				start_drag(viewport_camera, event)
			return true
				
			
		elif tool_state == ToolState.DRAGGING || tool_state == ToolState.MOVE_HANDLES_CLICK:

			var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
			var dir:Vector3 = viewport_camera.project_ray_normal(e.position)


			if !drag_handle_start_pos.is_finite():
				#If start point set to infinite, replace with point along view ray
				drag_handle_start_pos = origin + dir * 20

			var drag_to:Vector3
			match move_constraint:
				MoveConstraint.Type.AXIS_X:
					drag_to = MathUtil.closest_point_on_line(origin, dir, drag_handle_start_pos, Vector3.RIGHT)
				MoveConstraint.Type.AXIS_Y:
					drag_to = MathUtil.closest_point_on_line(origin, dir, drag_handle_start_pos, Vector3.UP)
				MoveConstraint.Type.AXIS_Z:
					drag_to = MathUtil.closest_point_on_line(origin, dir, drag_handle_start_pos, Vector3.BACK)
				MoveConstraint.Type.PLANE_XY:
					drag_to = MathUtil.intersect_plane(origin, dir, drag_handle_start_pos, Vector3.BACK)
				MoveConstraint.Type.PLANE_XZ:
					drag_to = MathUtil.intersect_plane(origin, dir, drag_handle_start_pos, Vector3.UP)
				MoveConstraint.Type.PLANE_YZ:
					drag_to = MathUtil.intersect_plane(origin, dir, drag_handle_start_pos, Vector3.RIGHT)
				MoveConstraint.Type.PLANE_VIEWPORT:
					drag_to = MathUtil.intersect_plane(origin, dir, drag_handle_start_pos, viewport_camera.global_transform.basis.z)

			#print("drag_handle_start_pos %s" % drag_handle_start_pos)
			
#			var drag_to:Vector3
#			if e.alt_pressed:
#				drag_to = MathUtil.closest_point_on_line(origin, dir, drag_handle_start_pos, Vector3.UP)
#			else:
#				drag_to = MathUtil.intersect_plane(origin, dir, drag_handle_start_pos, Vector3.UP)

			#print("drag_to %s" % drag_to)
			
			var offset = drag_to - drag_handle_start_pos
#			offset = MathUtil.snap_to_grid(offset, grid_step_size)
			offset = builder.get_snapping_manager().snap_point(offset, SnappingQuery.new(viewport_camera))

			#print("offset %s" % offset)
			
			cmd_move_face.move_offset = offset
			cmd_move_face.do_it()

			setup_tool()
			return true

		elif tool_state == ToolState.DRAG_SELECTION:
			drag_select_to_pos = e.position
			return true
		
	return false				
				
