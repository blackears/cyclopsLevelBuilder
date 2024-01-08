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

enum ToolState { NONE, READY, BLOCK_BASE, BLOCK_HEIGHT, MOVE_FACE }
var tool_state:ToolState = ToolState.NONE

#var drag_angle_limit:float = deg_to_rad(5)

var viewport_camera_start:Camera3D
var event_start:InputEventMouseButton

var block_drag_cur:Vector3
var block_drag_p0:Vector3
var block_drag_p1:Vector3
var block_drag_p2:Vector3

var drag_floor_normal:Vector3

var settings:ToolBlockSettings = ToolBlockSettings.new()

#Keep a copy of move command here while we are building it
var cmd_move_face:CommandMoveFacePlanar
var move_face_origin:Vector3 #Kep track of the origin when moving a face

var base_points:PackedVector3Array

var mouse_hover_pos:Vector2

func _get_tool_id()->String:
	return TOOL_ID

func _get_tool_properties_editor()->Control:
	var ed:ToolBlockSettingsEditor = preload("res://addons/cyclops_level_builder/tools/tool_block_settings_editor.tscn").instantiate()
	
	ed.settings = settings
	
	return ed

func start_block_drag(viewport_camera:Camera3D, event:InputEvent):
	var blocks_root:Node = builder.get_block_add_parent()
	var e:InputEventMouseButton = event
	
	var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
	var dir:Vector3 = viewport_camera.project_ray_normal(e.position)

	#print("origin %s  dir %s" % [origin, dir])

	var result:IntersectResults = builder.intersect_ray_closest(origin, dir)
	#print("result %s" % result)
	
	if result:
		#print("Hit! %s" % result)
		drag_floor_normal = MathUtil.snap_to_best_axis_normal(result.get_world_normal())

		var start_pos:Vector3 = result.get_world_position()

		#var grid_step_size:float = pow(2, builder.get_global_scene().grid_size)
		#block_drag_p0 = MathUtil.snap_to_grid(start_pos, grid_step_size)

		block_drag_p0 = builder.get_snapping_manager().snap_point(start_pos, SnappingQuery.new(viewport_camera))

		
		if e.ctrl_pressed:
			tool_state = ToolState.MOVE_FACE
			
			cmd_move_face = CommandMoveFacePlanar.new()
			cmd_move_face.builder = builder
			cmd_move_face.blocks_root_path = builder.get_block_add_parent().get_path()
			cmd_move_face.block_path = result.object.get_path()
			cmd_move_face.face_id = result.face_id
			cmd_move_face.lock_uvs = builder.lock_uvs
			cmd_move_face.move_dir_normal = result.object.control_mesh.faces[result.face_id].normal

			move_face_origin = result.object.global_transform * result.position
			#print("moving face move_face_origin %s" % move_face_origin)
			
		else:
			tool_state = ToolState.BLOCK_BASE

		
	else:
		#print("Miss")
		var hit_result = calc_hit_point_empty_space(origin, dir, viewport_camera)
		block_drag_p0 = hit_result[0]
		drag_floor_normal = hit_result[1]
		
		tool_state = ToolState.BLOCK_BASE

func _draw_tool(viewport_camera:Camera3D):
	var global_scene:CyclopsGlobalScene = builder.get_global_scene()
	global_scene.clear_tool_mesh()
	global_scene.draw_selected_blocks(viewport_camera)

	if tool_state == ToolState.BLOCK_BASE:
		global_scene.draw_loop(base_points, true, global_scene.tool_material)
		global_scene.draw_points(base_points, global_scene.vertex_tool_material)
		
	if tool_state == ToolState.BLOCK_HEIGHT:
		global_scene.draw_cube(block_drag_p0, block_drag_p1, block_drag_cur, global_scene.tool_material, global_scene.vertex_tool_material)


func create_block():
	block_drag_p2 = block_drag_cur
#	print("Adding block %s %s %s" % [block_drag_p0, block_drag_p1, block_drag_p2])

	var bounds:AABB = AABB(block_drag_p0, Vector3.ZERO)
	bounds = bounds.expand(block_drag_p1)
	bounds = bounds.expand(block_drag_p2)
	
	if bounds.has_volume():
		var blocks_root:Node = builder.get_block_add_parent()
	
		var command:CommandAddBlock = CommandAddBlock.new()
		
		command.builder = builder
		command.blocks_root_path = blocks_root.get_path()
		command.block_name = GeneralUtil.find_unique_name(blocks_root, "Block_")						
		command.bounds = bounds
#						command.origin = block_drag_p0
		command.uv_transform = builder.tool_uv_transform
		command.material_path = builder.tool_material_path

		var undo:EditorUndoRedoManager = builder.get_undo_redo()

		command.add_to_undo_manager(undo)


func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:
	#print("tool_block gui_input %s" % event)
	
	var blocks_root:Node = builder.get_block_add_parent()

	if event is InputEventKey:
		var e:InputEventKey = event
		
		if e.keycode == KEY_ESCAPE:
			if e.is_pressed():
				tool_state = ToolState.NONE
			return true
		
		if e.keycode == KEY_Q && e.alt_pressed:
			if e.is_pressed():
				var origin:Vector3 = viewport_camera.project_ray_origin(mouse_hover_pos)
				var dir:Vector3 = viewport_camera.project_ray_normal(mouse_hover_pos)
			
				var result:IntersectResults = builder.intersect_ray_closest(origin, dir)
				if result:
					var cmd:CommandSelectBlocks = CommandSelectBlocks.new()
					cmd.builder = builder
					cmd.block_paths.append(result.object.get_path())
					
					if cmd.will_change_anything():
						var undo:EditorUndoRedoManager = builder.get_undo_redo()
						cmd.add_to_undo_manager(undo)
						
						_deactivate()
						_activate(builder)
				
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
					
					tool_state = ToolState.NONE
					
				elif tool_state == ToolState.BLOCK_BASE:
					block_drag_p1 = block_drag_cur
					
					var camera_dir:Vector3 = viewport_camera.project_ray_normal(e.position)
					var angle_with_base:float = acos(drag_floor_normal.dot(camera_dir))

					var drag_angle_limit:float = builder.get_global_scene().drag_angle_limit
					if angle_with_base < drag_angle_limit || angle_with_base > PI - drag_angle_limit:
						block_drag_cur = block_drag_p1 + drag_floor_normal * settings.default_block_height
						
						create_block()
						
						tool_state = ToolState.NONE
					else:
					
						tool_state = ToolState.BLOCK_HEIGHT
					
				elif tool_state == ToolState.BLOCK_HEIGHT:
					create_block()

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

		mouse_hover_pos = e.position

		var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
		var dir:Vector3 = viewport_camera.project_ray_normal(e.position)
		
		var start_pos:Vector3 = origin + builder.block_create_distance * dir
		
		#print("tool_state %s" % tool_state)
		if (e.button_mask & MOUSE_BUTTON_MASK_MIDDLE):
			return super._gui_input(viewport_camera, event)
		
		if tool_state == ToolState.NONE:
			if e.ctrl_pressed:
				#block_drag_cur = MathUtil.intersect_plane(origin_local, dir_local, block_drag_p0_local, drag_floor_normal)
				var result:IntersectResults = builder.intersect_ray_closest(origin, dir)
				#print("picked result %s" % result)
				if result:
					var block:CyclopsBlock = result.object
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

			block_drag_cur = MathUtil.intersect_plane(origin, dir, block_drag_p0, drag_floor_normal)
			
			#print("block_drag_cur %s" % block_drag_cur)

			block_drag_cur = builder.get_snapping_manager().snap_point(block_drag_cur, SnappingQuery.new(viewport_camera))

			#print("block_drag_cur snapped %s" % block_drag_cur)
			
			#Draw tool
			var p01:Vector3
			var p10:Vector3
			if abs(drag_floor_normal.x) > abs(drag_floor_normal.y) and abs(drag_floor_normal.x) > abs(drag_floor_normal.z):
				p01 = Vector3(block_drag_p0.x, block_drag_p0.y, block_drag_cur.z)
				p10 = Vector3(block_drag_p0.x, block_drag_cur.y, block_drag_p0.z)
			elif abs(drag_floor_normal.y) > abs(drag_floor_normal.z):
				p01 = Vector3(block_drag_p0.x, block_drag_p0.y, block_drag_cur.z)
				p10 = Vector3(block_drag_cur.x, block_drag_p0.y, block_drag_p0.z)
			else:
				p01 = Vector3(block_drag_p0.x, block_drag_cur.y, block_drag_p0.z)
				p10 = Vector3(block_drag_cur.x, block_drag_p0.y, block_drag_p0.z)

			base_points = [block_drag_p0, p01, block_drag_cur, p10]

			return true

		elif tool_state == ToolState.BLOCK_HEIGHT:
			block_drag_cur = MathUtil.closest_point_on_line(origin, dir, block_drag_p1, drag_floor_normal)
			
			block_drag_cur = builder.get_snapping_manager().snap_point(block_drag_cur, SnappingQuery.new(viewport_camera))

			return true

		elif tool_state == ToolState.MOVE_FACE:			
			var drag_to:Vector3 = MathUtil.closest_point_on_line(origin, dir, move_face_origin, cmd_move_face.move_dir_normal)
			#print("move_face_origin %s norm %s" % [move_face_origin, cmd_move_face.move_dir_normal])

			drag_to = builder.get_snapping_manager().snap_point(drag_to, SnappingQuery.new(viewport_camera))
			
			#print("move_face drag_to %s" % [drag_to])
			cmd_move_face.move_amount = (drag_to - move_face_origin).dot(cmd_move_face.move_dir_normal)
			#print("move by %s" % [drag_to - move_face_origin])
			
			cmd_move_face.do_it_intermediate()
		
			return true
	
	return super._gui_input(viewport_camera, event)		


func _activate(builder:CyclopsLevelBuilder):
	super._activate(builder)
	
	builder.mode = CyclopsLevelBuilder.Mode.OBJECT
	var global_scene:CyclopsGlobalScene = builder.get_global_scene()
	global_scene.clear_tool_mesh()
	
	var cache:Dictionary = builder.get_tool_cache(TOOL_ID)
	#print("loaded cache ", str(cache))
	settings.load_from_cache(cache)

func _deactivate():
	var cache:Dictionary = settings.save_to_cache()
	builder.set_tool_cache(TOOL_ID, cache)
	
