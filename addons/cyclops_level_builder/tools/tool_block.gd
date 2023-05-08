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
class_name ToolBlock

const TOOL_ID:String = "block"

enum ToolState { NONE, READY, BLOCK_BASE, BLOCK_HEIGHT, MOVE_BLOCK, MOVE_FACE }
var tool_state:ToolState = ToolState.NONE
#enum State { READY, DRAG_BASE }
#var dragging:bool = false
var viewport_camera_start:Camera3D
var event_start:InputEventMouseButton

var block_drag_cur:Vector3
var block_drag_p0_local:Vector3
var block_drag_p1_local:Vector3
var block_drag_p2_local:Vector3

var drag_floor_normal:Vector3

#var min_drag_distance:float = 4

#Keep a copy of move command here while we are building it
var cmd_move_blocks:CommandMoveBlocks
var cmd_move_face:CommandMoveFacePlanar
var move_face_origin:Vector3 #Kep track of the origin when moving a face

var base_points:PackedVector3Array

func _get_tool_id()->String:
	return TOOL_ID

func start_block_drag(viewport_camera:Camera3D, event:InputEvent):
	var blocks_root:CyclopsBlocks = self.builder.active_node
	var e:InputEventMouseButton = event
	
	var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
	var dir:Vector3 = viewport_camera.project_ray_normal(e.position)

#					print("origin %s  dir %s" % [origin, dir])

	var result:IntersectResults = blocks_root.intersect_ray_closest(origin, dir)
#					print("result %s" % result)
	
	if result:
#						print("Hit! %s" % result)
		drag_floor_normal = MathUtil.snap_to_best_axis_normal(result.normal)

		var start_pos:Vector3 = result.position
		var w2l = blocks_root.global_transform.inverse()
		var start_pos_local:Vector3 = w2l * start_pos

		var grid_step_size:float = pow(2, builder.get_global_scene().grid_size)

		block_drag_p0_local = MathUtil.snap_to_grid(start_pos_local, grid_step_size)
		
		if e.ctrl_pressed:
			tool_state = ToolState.MOVE_FACE
			
			cmd_move_face = CommandMoveFacePlanar.new()
			cmd_move_face.builder = builder
			cmd_move_face.blocks_root_path = builder.active_node.get_path()
			cmd_move_face.block_path = result.object.get_path()
			cmd_move_face.face_id = result.face_id
			cmd_move_face.lock_uvs = builder.lock_uvs
			cmd_move_face.move_dir_normal = result.object.control_mesh.faces[result.face_id].normal

			move_face_origin = result.position
			
		elif result.object.selected:
			tool_state = ToolState.MOVE_BLOCK
			
			cmd_move_blocks = CommandMoveBlocks.new()
			cmd_move_blocks.builder = builder
			cmd_move_blocks.lock_uvs = builder.lock_uvs
			for child in blocks_root.get_children():
				if child is CyclopsConvexBlock and child.selected:
					cmd_move_blocks.add_block(child.get_path())
		else:
			tool_state = ToolState.BLOCK_BASE

		
	else:
#						print("Miss")
		drag_floor_normal = Vector3.UP
		
		tool_state = ToolState.BLOCK_BASE
		var start_pos:Vector3 = origin + builder.block_create_distance * dir
		var w2l = blocks_root.global_transform.inverse()
		var start_pos_local:Vector3 = w2l * start_pos

		#print("start_pos %s" % start_pos)
		#print("start_pos_local %s" % start_pos_local)
		
		var grid_step_size:float = pow(2, builder.get_global_scene().grid_size)

		
		#print("start_pos_local %s" % start_pos_local)
		block_drag_p0_local = MathUtil.snap_to_grid(start_pos_local, grid_step_size)
		
		#print("block_drag_start_local %s" % block_drag_start_local)
	#print("set 1 tool_state %s" % tool_state)

func _draw_tool(viewport_camera:Camera3D):
	var global_scene:CyclopsGlobalScene = builder.get_global_scene()
	global_scene.clear_tool_mesh()
	global_scene.draw_selected_blocks(viewport_camera)

	if tool_state == ToolState.BLOCK_BASE:
		global_scene.draw_loop(base_points, true, global_scene.tool_material)
		global_scene.draw_points(base_points, global_scene.tool_material)
		
	if tool_state == ToolState.BLOCK_HEIGHT:
		global_scene.draw_cube(block_drag_p0_local, block_drag_p1_local, block_drag_cur, global_scene.tool_material)

func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:
	if !builder.active_node is CyclopsBlocks:
		return false
	var blocks_root:CyclopsBlocks = builder.active_node

	if event is InputEventKey:
		var e:InputEventKey = event
		
		if e.keycode == KEY_ESCAPE:
			if e.is_pressed():
				tool_state = ToolState.NONE
			return true
		
	
	elif event is InputEventMouseButton:
		
		var e:InputEventMouseButton = event
		if e.button_index == MOUSE_BUTTON_LEFT:

			if e.is_pressed():
				if tool_state == ToolState.NONE:
					event_start = event
					viewport_camera_start = viewport_camera
					
					tool_state = ToolState.READY
				
			else:
				if tool_state == ToolState.READY:
					
					var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
					var dir:Vector3 = viewport_camera.project_ray_normal(e.position)

					var result:IntersectResults = blocks_root.intersect_ray_closest(origin, dir)
					
					var cmd:CommandSelectBlocks = CommandSelectBlocks.new()
					cmd.builder = builder
					cmd.selection_type = Selection.choose_type(e.shift_pressed, e.ctrl_pressed)

					if result:
						cmd.block_paths.append(result.object.get_path())
						
					if cmd.will_change_anything():
						var undo:EditorUndoRedoManager = builder.get_undo_redo()
						cmd.add_to_undo_manager(undo)
					
					tool_state = ToolState.NONE
					
				elif tool_state == ToolState.BLOCK_BASE:
					block_drag_p1_local = block_drag_cur
					tool_state = ToolState.BLOCK_HEIGHT
					
					#print("set 2 tool_state %s" % tool_state)
					
				elif tool_state == ToolState.BLOCK_HEIGHT:
#					print("Adding block %s %s %s" % [block_drag_p0_local, block_drag_p1_local, block_drag_p2_local])
					block_drag_p2_local = block_drag_cur
					tool_state = ToolState.NONE

					var bounds:AABB = AABB(block_drag_p0_local, Vector3.ZERO)
					bounds = bounds.expand(block_drag_p1_local)
					bounds = bounds.expand(block_drag_p2_local)
					
#					print("AABB %s" % bounds)
					
					if bounds.has_volume():
						var command:CommandAddBlock2 = CommandAddBlock2.new()
						
						command.builder = builder
						command.blocks_root_path = blocks_root.get_path()
						command.block_name = GeneralUtil.find_unique_name(builder.active_node, "Block_")						
						command.bounds = bounds
						command.uv_transform = builder.tool_uv_transform
						command.material_path = builder.tool_material_path

						var undo:EditorUndoRedoManager = builder.get_undo_redo()

						command.add_to_undo_manager(undo)

				elif tool_state == ToolState.MOVE_BLOCK:

					var undo:EditorUndoRedoManager = builder.get_undo_redo()
					cmd_move_blocks.add_to_undo_manager(undo)
					
					tool_state = ToolState.NONE			
				
				elif tool_state == ToolState.MOVE_FACE:

					var undo:EditorUndoRedoManager = builder.get_undo_redo()
					cmd_move_face.add_to_undo_manager(undo)
					
					tool_state = ToolState.NONE			
				
			return true
		
		elif e.button_index == MOUSE_BUTTON_RIGHT:
			if tool_state == ToolState.BLOCK_BASE || tool_state == ToolState.BLOCK_HEIGHT:
				if e.is_pressed():
					tool_state = ToolState.NONE
				return true
			
			
	elif event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event

		var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
		var dir:Vector3 = viewport_camera.project_ray_normal(e.position)
		
		var start_pos:Vector3 = origin + builder.block_create_distance * dir
		var w2l = blocks_root.global_transform.inverse()
		var origin_local:Vector3 = w2l * origin
		var dir_local:Vector3 = w2l.basis * dir
	
#		var global_scene:CyclopsGlobalScene = builder.get_node("/root/CyclopsAutoload")
		
		#print("tool_state %s" % tool_state)
		if (e.button_mask & MOUSE_BUTTON_MASK_MIDDLE):
			return super._gui_input(viewport_camera, event)
		
		if tool_state == ToolState.NONE:
			if e.ctrl_pressed:
				#block_drag_cur = MathUtil.intersect_plane(origin_local, dir_local, block_drag_p0_local, drag_floor_normal)
				var result:IntersectResults = blocks_root.intersect_ray_closest(origin_local, dir_local)
				if result:
					var block:CyclopsConvexBlock = result.object
					var convex_mesh:ConvexVolume = block.control_mesh
					base_points = convex_mesh.get_face(result.face_id).get_points()
					return true
			
			return false
				
		elif tool_state == ToolState.READY:
			var offset:Vector2 = e.position - event_start.position
			if offset.length_squared() > MathUtil.square(builder.drag_start_radius):
				start_block_drag(viewport_camera_start, event_start)

			return true
				
		elif tool_state == ToolState.BLOCK_BASE:

			block_drag_cur = MathUtil.intersect_plane(origin_local, dir_local, block_drag_p0_local, drag_floor_normal)
			
			#print("block_drag_cur %s" % block_drag_cur)
			
			var grid_step_size:float = pow(2, builder.get_global_scene().grid_size)
			block_drag_cur = MathUtil.snap_to_grid(block_drag_cur, grid_step_size)

			#print("block_drag_cur snapped %s" % block_drag_cur)
			
			#Draw tool
			var p01:Vector3
			var p10:Vector3
			if abs(drag_floor_normal.x) > abs(drag_floor_normal.y) and abs(drag_floor_normal.x) > abs(drag_floor_normal.z):
				p01 = Vector3(block_drag_p0_local.x, block_drag_p0_local.y, block_drag_cur.z)
				p10 = Vector3(block_drag_p0_local.x, block_drag_cur.y, block_drag_p0_local.z)
			elif abs(drag_floor_normal.y) > abs(drag_floor_normal.z):
				p01 = Vector3(block_drag_p0_local.x, block_drag_p0_local.y, block_drag_cur.z)
				p10 = Vector3(block_drag_cur.x, block_drag_p0_local.y, block_drag_p0_local.z)
			else:
				p01 = Vector3(block_drag_p0_local.x, block_drag_cur.y, block_drag_p0_local.z)
				p10 = Vector3(block_drag_cur.x, block_drag_p0_local.y, block_drag_p0_local.z)

			base_points = [block_drag_p0_local, p01, block_drag_cur, p10]

			return true

		elif tool_state == ToolState.BLOCK_HEIGHT:
			block_drag_cur = MathUtil.closest_point_on_line(origin_local, dir_local, block_drag_p1_local, drag_floor_normal)
			
			var grid_step_size:float = pow(2, builder.get_global_scene().grid_size)
			block_drag_cur = MathUtil.snap_to_grid(block_drag_cur, grid_step_size)

			return true

		elif tool_state == ToolState.MOVE_BLOCK:
			if e.alt_pressed:
#				block_drag_cur = MathUtil.closest_point_on_line(origin_local, dir_local, block_drag_p0_local, drag_floor_normal)
				block_drag_cur = MathUtil.closest_point_on_line(origin_local, dir_local, block_drag_p0_local, Vector3.UP)
			else:
#				block_drag_cur = MathUtil.intersect_plane(origin_local, dir_local, block_drag_p0_local, drag_floor_normal)
				block_drag_cur = MathUtil.intersect_plane(origin_local, dir_local, block_drag_p0_local, Vector3.UP)
			
			var grid_step_size:float = pow(2, builder.get_global_scene().grid_size)
			block_drag_cur = MathUtil.snap_to_grid(block_drag_cur, grid_step_size)
			
			cmd_move_blocks.move_offset = block_drag_cur - block_drag_p0_local
			cmd_move_blocks.do_it()

			return true
			
		elif tool_state == ToolState.MOVE_FACE:			
			var drag_to:Vector3 = MathUtil.closest_point_on_line(origin_local, dir_local, move_face_origin, cmd_move_face.move_dir_normal)
			#print("move_face_origin %s norm %s" % [move_face_origin, cmd_move_face.move_dir_normal])
			var grid_step_size:float = pow(2, builder.get_global_scene().grid_size)
			drag_to = MathUtil.snap_to_grid(drag_to, grid_step_size)
			
			cmd_move_face.move_amount = (drag_to - move_face_origin).dot(cmd_move_face.move_dir_normal)
			
			cmd_move_face.do_it_intermediate()
		
			return true
	
	return super._gui_input(viewport_camera, event)		


func _activate(builder:CyclopsLevelBuilder):
	super._activate(builder)
	
	builder.mode = CyclopsLevelBuilder.Mode.OBJECT
	var global_scene:CyclopsGlobalScene = builder.get_global_scene()
	global_scene.clear_tool_mesh()

