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

enum ToolState { NONE, READY, DRAGGING, DRAGGING_ADD, MOVE_HANDLES_CLICK, DRAG_SELECTION }
var tool_state:ToolState = ToolState.NONE

#enum MoveConstraint { NONE, AXIS_X, AXIS_Y, AXIS_Z, PLANE_XY, PLANE_XZ, PLANE_YZ, PLANE_VIEWPORT }
var move_constraint:MoveConstraint.Type = MoveConstraint.Type.NONE

#var mouse_hover_pos:Vector2

#var drag_handle:HandleVertex
var drag_mouse_start_pos:Vector2
var drag_handle_start_pos:Vector3
var drag_home_block:NodePath
var added_point_pos:Vector3

var cmd_move_vertex:CommandMoveVertices
var cmd_add_vertex:CommandAddVertices

var gizmo_translate:Node3D
	
var watched_blocks:Array[CyclopsBlock]

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
		var v:ConvexVolume.VertexInfo = block.control_mesh.vertices[h.vertex_index]
		if v.selected:
			origin += h.position
			count += 1

	if count == 0:
		global_scene.set_custom_gizmo(null)
	else:
		origin /= count
		#print("gizmo origin ", origin)
		global_scene.set_custom_gizmo(gizmo_translate)
		gizmo_translate.global_transform.origin = origin

func _draw_tool(viewport_camera:Camera3D):
	var global_scene:CyclopsGlobalScene = builder.get_global_scene()
	global_scene.clear_tool_mesh()

	if tool_state == ToolState.DRAG_SELECTION:
		global_scene.draw_screen_rect(viewport_camera, drag_select_start_pos, drag_select_to_pos, global_scene.selection_rect_material)
	
	for h in handles:
		var block:CyclopsBlock = builder.get_node(h.block_path)
		var v:ConvexVolume.VertexInfo = block.control_mesh.vertices[h.vertex_index]
		
		#print("draw vert %s %s" % [h.vertex_index, v.selected])
		var active:bool = block.control_mesh.active_vertex == h.vertex_index
		global_scene.draw_vertex(h.position, pick_vertex_material(global_scene, v.selected, active))
	
	draw_gizmo(viewport_camera)
	
func on_block_changed():
	setup_tool()
	
func setup_tool():
	handles = []
	#print("setup_tool")

	for block in watched_blocks:
		block.mesh_changed.disconnect(on_block_changed)
	watched_blocks.clear()
	
	var sel_blocks:Array[CyclopsBlock] = builder.get_selected_blocks()

	for block in sel_blocks:
#		print("block sel %s" % block.block_data.vertex_selected)
		var l2w:Transform3D = block.global_transform
		block.mesh_changed.connect(on_block_changed)
		watched_blocks.append(block)

		for v_idx in block.control_mesh.vertices.size():
			var v:ConvexVolume.VertexInfo = block.control_mesh.vertices[v_idx]
			var handle:HandleVertex = HandleVertex.new()
			handle.position = l2w * v.point
			handle.initial_position = handle.position
			handle.vertex_index = v_idx
			handle.block_path = block.get_path()
			handles.append(handle)
			
			#print("adding handle %s" % handle)


func pick_closest_handle(viewport_camera:Camera3D, position:Vector2, radius:float)->HandleVertex:
#	print("pick radius ", radius)
	var best_dist:float = INF
	var best_handle:HandleVertex = null
	
	var origin:Vector3 = viewport_camera.project_ray_origin(position)
	var dir:Vector3 = viewport_camera.project_ray_normal(position)
	
	for h in handles:
#		var h_world_pos:Vector3 = blocks_root.global_transform * h.position
		var h_world_pos:Vector3 = h.position
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
	setup_tool()
	

func active_node_updated():
	setup_tool()

func _activate(builder:CyclopsLevelBuilder):
	super._activate(builder)
	
	builder.mode = CyclopsLevelBuilder.Mode.EDIT
	builder.edit_mode = CyclopsLevelBuilder.EditMode.VERTEX
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
#			print("Gizmo hit ", part_res.part)
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
		
			drag_handle_start_pos = gizmo_translate.global_position
#			var grid_step_size:float = pow(2, builder.get_global_scene().grid_size)

#			drag_handle_start_pos = MathUtil.snap_to_grid(start_pos, grid_step_size)
			#drag_handle_start_pos = builder.get_snapping_manager().snap_point(\
				#start_pos, SnappingQuery.new(viewport_camera))

	#		print("res obj %s" % result.object.get_path())
			var sel_blocks:Array[CyclopsBlock] = builder.get_selected_blocks()
			if !sel_blocks.is_empty():
				
				tool_state = ToolState.DRAGGING
				#print("Move block")
				
				cmd_move_vertex = CommandMoveVertices.new()
				cmd_move_vertex.builder = builder

				for block in sel_blocks:
					var vol:ConvexVolume = block.control_mesh
					for v_idx in vol.vertices.size():
						var v:ConvexVolume.VertexInfo = vol.vertices[v_idx]
						if v.selected:
							cmd_move_vertex.add_vertex(block.get_path(), v_idx)
						if vol.active_vertex == v_idx:
							drag_handle_start_pos = block.global_transform * v.point
							drag_home_block = block.get_path()

			return

	if e.alt_pressed:
		move_constraint = MoveConstraint.Type.AXIS_Y
	else:
		move_constraint = MoveConstraint.Type.PLANE_XZ
		
	var handle:HandleVertex = pick_closest_handle(viewport_camera, drag_mouse_start_pos, builder.handle_screen_radius)

	if handle:
		#drag_handle = handle
		drag_handle_start_pos = handle.position
		drag_home_block = handle.block_path
		tool_state = ToolState.DRAGGING

		cmd_move_vertex = CommandMoveVertices.new()
		cmd_move_vertex.builder = builder

		var handle_block:CyclopsBlock = builder.get_node(handle.block_path)
		if handle_block.control_mesh.vertices[handle.vertex_index].selected:
			var sel_blocks:Array[CyclopsBlock] = builder.get_selected_blocks()
			for block in sel_blocks:
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
			#Add vertex under cursor
			var pick_origin:Vector3 = viewport_camera.project_ray_origin(e.position)
			var pick_dir:Vector3 = viewport_camera.project_ray_normal(e.position)
			var result:IntersectResults = builder.intersect_ray_closest_selected_only(pick_origin, pick_dir)
			if result:
				#print("start drag add")
				drag_handle_start_pos = result.get_world_position()
				added_point_pos = result.get_world_position()
				tool_state = ToolState.DRAGGING_ADD

				cmd_add_vertex = CommandAddVertices.new()
				cmd_add_vertex.builder = builder

				cmd_add_vertex.block_path = result.object.get_path()
				cmd_add_vertex.points_to_add = [added_point_pos]
				#print("init point %s" % added_point_pos)
			
			return true

	#Drag selection rectangle
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
				if cmd_move_vertex:
					cmd_move_vertex.undo_it()
					cmd_move_vertex = null
					tool_state = ToolState.NONE
					
					setup_tool()
					
				if cmd_add_vertex:
					cmd_add_vertex.undo_it()
					cmd_add_vertex = null
					tool_state = ToolState.NONE
					
					setup_tool()
					
			return true

		elif e.keycode == KEY_A:

			if e.is_pressed():
				var cmd:CommandSelectVertices = CommandSelectVertices.new()
				cmd.builder = builder
				
				if e.alt_pressed:
					var sel_blocks:Array[CyclopsBlock] = builder.get_selected_blocks()
					for block in sel_blocks:
						cmd.add_vertices(block.get_path(), [])
						
				else:
					var sel_blocks:Array[CyclopsBlock] = builder.get_selected_blocks()
					for block in sel_blocks:
						for v_idx in block.control_mesh.vertices.size():
							cmd.add_vertex(block.get_path(), v_idx)

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
					
					cmd_move_vertex = CommandMoveVertices.new()
					cmd_move_vertex.builder = builder

					for block in sel_blocks:
						var vol:ConvexVolume = block.control_mesh
						for v_idx in vol.vertices.size():
							var v:ConvexVolume.VertexInfo = vol.vertices[v_idx]
							if v.selected:
								cmd_move_vertex.add_vertex(block.get_path(), v_idx)
					
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
					#print("Start READY")
					
				return true
			else:
				if tool_state == ToolState.READY:
					#print("cmd select")
					var handle:HandleVertex = pick_closest_handle(viewport_camera, drag_mouse_start_pos, builder.handle_screen_radius)

					var cmd:CommandSelectVertices = CommandSelectVertices.new()
					cmd.builder = builder

					var sel_blocks:Array[CyclopsBlock] = builder.get_selected_blocks()
					for block in sel_blocks:
						cmd.add_vertices(block.get_path(), [])
						

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

				elif tool_state == ToolState.MOVE_HANDLES_CLICK:
					var undo:EditorUndoRedoManager = builder.get_undo_redo()
					cmd_move_vertex.add_to_undo_manager(undo)
					
					tool_state = ToolState.NONE
					

				elif tool_state == ToolState.DRAG_SELECTION:
					
					var frustum:Array[Plane] = MathUtil.calc_frustum_camera_rect(viewport_camera, drag_select_start_pos, drag_select_to_pos)

					var cmd:CommandSelectVertices = CommandSelectVertices.new()
					cmd.builder = builder

					var sel_blocks:Array[CyclopsBlock] = builder.get_selected_blocks()
					for block in sel_blocks:
						
						for v_idx in block.control_mesh.vertices.size():
							var v:ConvexVolume.VertexInfo = block.control_mesh.vertices[v_idx]
							var point_w:Vector3 = block.global_transform * v.point
							
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
								cmd.add_vertex(block.get_path(), v_idx)

					cmd.selection_type = Selection.choose_type(e.shift_pressed, e.ctrl_pressed)

					if cmd.will_change_anything():
						var undo:EditorUndoRedoManager = builder.get_undo_redo()

						cmd.add_to_undo_manager(undo)
					
					tool_state = ToolState.NONE

				return true

		elif e.button_index == MOUSE_BUTTON_RIGHT:
			if e.is_pressed():
				#Right click cancel
				if cmd_move_vertex:
					cmd_move_vertex.undo_it()
					cmd_move_vertex = null
					tool_state = ToolState.NONE
					
					setup_tool()
					
				if cmd_add_vertex:
					cmd_add_vertex.undo_it()
					cmd_add_vertex = null
					tool_state = ToolState.NONE

					setup_tool()
					
			return true
								
	elif event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event
		#mouse_hover_pos = e.position

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

			
			#drag_to = MathUtil.snap_to_grid(drag_to, grid_step_size)
			#print("send snap bock-2- ", drag_home_block)
			drag_to = builder.get_snapping_manager().snap_point(drag_to, SnappingQuery.new(viewport_camera, [drag_home_block]))
			#drag_handle.position = drag_to
			
			cmd_move_vertex.move_offset = drag_to - drag_handle_start_pos
			cmd_move_vertex.do_it()

			setup_tool()
			return true

		elif tool_state == ToolState.DRAGGING_ADD:

			var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
			var dir:Vector3 = viewport_camera.project_ray_normal(e.position)
			
			var drag_to:Vector3
			if e.alt_pressed:
				drag_to = MathUtil.closest_point_on_line(origin, dir, drag_handle_start_pos, Vector3.UP)
			else:
				drag_to = MathUtil.intersect_plane(origin, dir, drag_handle_start_pos, Vector3.UP)

			#drag_to = MathUtil.snap_to_grid(drag_to, grid_step_size)
			print("send snap bock ", drag_home_block)
			drag_to = builder.get_snapping_manager().snap_point(drag_to, SnappingQuery.new(viewport_camera, [drag_home_block]))

			added_point_pos = drag_to
			#print("drag point to %s" % drag_to)

			cmd_add_vertex.points_to_add = [drag_to]
			cmd_add_vertex.do_it()
			
			setup_tool()

		elif tool_state == ToolState.DRAG_SELECTION:
			drag_select_to_pos = e.position
			return true
								
	return false

