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

enum ToolState { NONE, READY, DRAGGING, MOVE_HANDLES_CLICK, DRAG_SELECTION }
var tool_state:ToolState = ToolState.NONE

#var drag_handle:HandleEdge
var drag_mouse_start_pos:Vector2
var drag_handle_start_pos:Vector3

#enum MoveConstraint { NONE, AXIS_X, AXIS_Y, AXIS_Z, PLANE_XY, PLANE_XZ, PLANE_YZ, PLANE_VIEWPORT }
var move_constraint:MoveConstraint.Type = MoveConstraint.Type.NONE

var gizmo_translate:Node3D

var cmd_move_edge:CommandMoveEdges


class PickHandleResult extends RefCounted:
	var handle:HandleEdge
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
		
		var e:ConvexVolume.EdgeInfo = block.control_mesh.edges[h.edge_index]
		if e.selected:
#			print("adding midpoint ", e.get_midpoint())
			origin += l2w * e.get_midpoint()
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
	
	for h in handles:
		var block:CyclopsBlock = builder.get_node(h.block_path)
		if h.edge_index >= block.control_mesh.edges.size():
			#TODO: Sometimes we are retaining handles that do not corepond to the correct edges after an undo operation.
			continue
		var e:ConvexVolume.EdgeInfo = block.control_mesh.edges[h.edge_index]
		var p0:Vector3 = block.global_transform * block.control_mesh.vertices[e.start_index].point
		var p1:Vector3 = block.global_transform * block.control_mesh.vertices[e.end_index].point

		var active:bool = block.control_mesh.active_edge == h.edge_index		
		global_scene.draw_vertex((p0 + p1) / 2, pick_vertex_material(global_scene, e.selected, active))
		global_scene.draw_line(p0, p1, pick_material(global_scene, e.selected, active))

	draw_gizmo(viewport_camera)
	
func setup_tool():
	handles = []
	
#	print("setuo_tool")
	var sel_blocks:Array[CyclopsBlock] = builder.get_selected_blocks()
	for block in sel_blocks:
		for e_idx in block.control_mesh.edges.size():
			var ctl_mesh:ConvexVolume = block.control_mesh
			var e:ConvexVolume.EdgeInfo = ctl_mesh.edges[e_idx]

			var handle:HandleEdge = HandleEdge.new()
#			handle.p_ref = block.global_transform * ctl_mesh.vertices[e.start_index].point
#			handle.p_ref_init = handle.p_ref
			handle.edge_index = e_idx
			handle.block_path = block.get_path()
			handles.append(handle)
	
	
func pick_closest_handle(viewport_camera:Camera3D, position:Vector2, radius:float)->PickHandleResult:
	var best_dist:float = INF
	var best_handle:HandleEdge = null
	var best_pick_position:Vector3
	
	var pick_origin:Vector3 = viewport_camera.project_ray_origin(position)
	var pick_dir:Vector3 = viewport_camera.project_ray_normal(position)
	
	for h in handles:
		var block:CyclopsBlock = builder.get_node(h.block_path)
		var ctl_mesh:ConvexVolume = block.control_mesh
		var edge:ConvexVolume.EdgeInfo = ctl_mesh.edges[h.edge_index]

		var p0 = ctl_mesh.vertices[edge.start_index].point
		var p1 = ctl_mesh.vertices[edge.end_index].point
		var p0_world:Vector3 = block.global_transform * p0
		var p1_world:Vector3 = block.global_transform * p1
		
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
		
#		print("h pos %s ray orig %s ray dir %s offset %s para %s dist %s" % [h.position, pick_origin, pick_dir, offset, parallel, dist])
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
	setup_tool()

func active_node_updated():
	setup_tool()

func _activate(builder:CyclopsLevelBuilder):
	super._activate(builder)
	
	builder.mode = CyclopsLevelBuilder.Mode.EDIT
	builder.edit_mode = CyclopsLevelBuilder.EditMode.EDGE
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
		
			drag_handle_start_pos = part_res.pos_world
#			drag_handle_start_pos = gizmo_translate.global_position
			#var grid_step_size:float = pow(2, builder.get_global_scene().grid_size)

			#drag_handle_start_pos = MathUtil.snap_to_grid(start_pos, grid_step_size)
			#drag_handle_start_pos = builder.get_snapping_manager().snap_point(start_pos, SnappingQuery.new(viewport_camera))

	#		print("res obj %s" % result.object.get_path())
			var sel_blocks:Array[CyclopsBlock] = builder.get_selected_blocks()
			if !sel_blocks.is_empty():
				
				tool_state = ToolState.DRAGGING
				#print("Move block")
				
				cmd_move_edge = CommandMoveEdges.new()
				cmd_move_edge.builder = builder

				for block in sel_blocks:
					var vol:ConvexVolume = block.control_mesh
					for e_idx in vol.edges.size():
						var edge:ConvexVolume.EdgeInfo = vol.edges[e_idx]
						if edge.selected:
							cmd_move_edge.add_edge(block.get_path(), e_idx)

			return


	if e.alt_pressed:
		move_constraint = MoveConstraint.Type.AXIS_Y
	else:
		move_constraint = MoveConstraint.Type.PLANE_XZ
		
	var res:PickHandleResult = pick_closest_handle(viewport_camera, drag_mouse_start_pos, builder.handle_screen_radius)

	if res:
		var handle:HandleEdge = res.handle
#		drag_handle = handle
#					drag_handle_start_pos = handle.p_ref
		drag_handle_start_pos = res.position
		tool_state = ToolState.DRAGGING
		#print("drag habdle start pos ", drag_handle_start_pos)

		cmd_move_edge = CommandMoveEdges.new()
		cmd_move_edge.builder = builder

		var handle_block:CyclopsBlock = builder.get_node(handle.block_path)
		if handle_block.control_mesh.edges[handle.edge_index].selected:
			var sel_blocks:Array[CyclopsBlock] = builder.get_selected_blocks()
			for block in sel_blocks:
				var vol:ConvexVolume = block.control_mesh
				for e_idx in vol.edges.size():
					var edge:ConvexVolume.EdgeInfo = vol.edges[e_idx]
					if edge.selected:
						cmd_move_edge.add_edge(block.get_path(), e_idx)
		else:
			cmd_move_edge.add_edge(handle.block_path, handle.edge_index)
			
		return
	
	#Drag selectio rectangle
	tool_state = ToolState.DRAG_SELECTION
	drag_select_start_pos = e.position
	drag_select_to_pos = e.position

func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:	
		
	var gui_result = super._gui_input(viewport_camera, event)
	if gui_result:
		return true
	
#	var grid_step_size:float = pow(2, builder.get_global_scene().grid_size)


	if event is InputEventKey:
		var e:InputEventKey = event
		
		if e.keycode == KEY_ESCAPE:
			if e.is_pressed():
				if cmd_move_edge:
					cmd_move_edge.undo_it()
					cmd_move_edge = null
					tool_state = ToolState.NONE
					
					setup_tool()
					
			return true

		elif e.keycode == KEY_A:

			if e.is_pressed():
				var cmd:CommandSelectEdges = CommandSelectEdges.new()
				cmd.builder = builder
				
				if e.alt_pressed:
					var sel_blocks:Array[CyclopsBlock] = builder.get_selected_blocks()
					for block in sel_blocks:
						cmd.add_edges(block.get_path(), [])
						
				else:
					var sel_blocks:Array[CyclopsBlock] = builder.get_selected_blocks()
					for block in sel_blocks:
						for e_idx in block.control_mesh.edges.size():
							cmd.add_edge(block.get_path(), e_idx)

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
					
					cmd_move_edge = CommandMoveEdges.new()
					cmd_move_edge.builder = builder

					for block in sel_blocks:
						var vol:ConvexVolume = block.control_mesh
						for e_idx in vol.edges.size():
							var edge:ConvexVolume.EdgeInfo = vol.edges[e_idx]
							if edge.selected:
								cmd_move_edge.add_edge(block.get_path(), e_idx)
					
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
					var cmd:CommandSelectEdges = CommandSelectEdges.new()
					cmd.builder = builder
					
					var sel_blocks:Array[CyclopsBlock]
					for block in sel_blocks:
						cmd.add_edges(block.get_path(), [])

					cmd.selection_type = Selection.choose_type(e.shift_pressed, e.ctrl_pressed)

					var res:PickHandleResult = pick_closest_handle(viewport_camera, e.position, builder.handle_screen_radius)
					if res:
						var handle:HandleEdge = res.handle

	#					print("handle %s" % handle)

						cmd.add_edge(handle.block_path, handle.edge_index)
						#print("selectibg %s" % handle.vertex_index)

					if cmd.will_change_anything():					
						var undo:EditorUndoRedoManager = builder.get_undo_redo()
						cmd.add_to_undo_manager(undo)
										
					tool_state = ToolState.NONE
					
				elif tool_state == ToolState.DRAGGING:
					#Finish drag
					#print("cmd finish drag")
					var undo:EditorUndoRedoManager = builder.get_undo_redo()

					cmd_move_edge.add_to_undo_manager(undo)
					
					tool_state = ToolState.NONE

				elif tool_state == ToolState.MOVE_HANDLES_CLICK:
					var undo:EditorUndoRedoManager = builder.get_undo_redo()
					cmd_move_edge.add_to_undo_manager(undo)
					
					tool_state = ToolState.NONE

				elif tool_state == ToolState.DRAG_SELECTION:
					
					var frustum:Array[Plane] = MathUtil.calc_frustum_camera_rect(viewport_camera, drag_select_start_pos, drag_select_to_pos)

					var cmd:CommandSelectEdges = CommandSelectEdges.new()
					cmd.builder = builder

					var sel_blocks:Array[CyclopsBlock] = builder.get_selected_blocks()
					for block in sel_blocks:
						
						for e_idx in block.control_mesh.edges.size():
							var edge:ConvexVolume.EdgeInfo = block.control_mesh.edges[e_idx]
							var point_w:Vector3 = block.global_transform * edge.get_midpoint()
							
							var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
#							var dir:Vector3 = viewport_camera.project_ray_normal(e.position)

							var global_scene:CyclopsGlobalScene = builder.get_global_scene()

							#Obstruction check
							if !global_scene.xray_mode:  
								var result:IntersectResults = builder.intersect_ray_closest(origin, point_w - origin)
								var res_point_w:Vector3 = result.get_world_position()
								if !res_point_w.is_equal_approx(point_w):
									continue
							
							if MathUtil.frustum_contians_point(frustum, point_w):
								cmd.add_edge(block.get_path(), e_idx)

					cmd.selection_type = Selection.choose_type(e.shift_pressed, e.ctrl_pressed)

					if cmd.will_change_anything():
						var undo:EditorUndoRedoManager = builder.get_undo_redo()

						cmd.add_to_undo_manager(undo)
					
					tool_state = ToolState.NONE
					
				return true
				
		elif e.button_index == MOUSE_BUTTON_RIGHT:
			if e.is_pressed():
				#Right click cancel
				if cmd_move_edge:
					cmd_move_edge.undo_it()
					cmd_move_edge = null
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
			
			var offset:Vector3 = drag_to - drag_handle_start_pos
			offset = builder.get_snapping_manager().snap_point(offset, SnappingQuery.new(viewport_camera))
			#drag_to = drag_handle_start_pos + offset
			
			cmd_move_edge.move_offset = offset
			cmd_move_edge.do_it()

			setup_tool()
#			draw_tool()
			return true

		elif tool_state == ToolState.DRAG_SELECTION:
			drag_select_to_pos = e.position
			return true
					
	return false
