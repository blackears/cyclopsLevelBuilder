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
class_name ToolStairs

const TOOL_ID:String = "stairs"

enum ToolState { READY, DRAG_BASE, DRAG_HEIGHT }
var tool_state:ToolState = ToolState.READY

var settings:ToolStairsSettings = ToolStairsSettings.new()

var floor_normal:Vector3
var drag_origin:Vector3
var base_drag_cur:Vector3
var block_drag_cur:Vector3


func _activate(builder:CyclopsLevelBuilder):
	super._activate(builder)

	builder.mode = CyclopsLevelBuilder.Mode.OBJECT
	var global_scene:CyclopsGlobalScene = builder.get_global_scene()
	global_scene.clear_tool_mesh()

	var cache:Dictionary = builder.get_tool_cache(TOOL_ID)
	settings.load_from_cache(cache)

func _deactivate():
	var cache:Dictionary = settings.save_to_cache()
	builder.set_tool_cache(TOOL_ID, cache)
			
func _get_tool_properties_editor()->Control:
	var res_insp:ResourceInspector = preload("res://addons/cyclops_level_builder/controls/resource_inspector/resource_inspector.tscn").instantiate()
	
	res_insp.target = settings
	
	return res_insp
	
func _draw_tool(viewport_camera:Camera3D):
	var global_scene:CyclopsGlobalScene = builder.get_global_scene()
	global_scene.clear_tool_mesh()
	global_scene.draw_selected_blocks(viewport_camera)


	if tool_state == ToolState.DRAG_BASE:
		var p01:Vector3
		var p10:Vector3
		var axis:MathUtil.Axis = MathUtil.get_longest_axis(floor_normal)
		match axis:
			MathUtil.Axis.X:
				p01 = Vector3(drag_origin.x, drag_origin.y, base_drag_cur.z)
				p10 = Vector3(drag_origin.x, base_drag_cur.y, drag_origin.z)
			MathUtil.Axis.Y:
				p01 = Vector3(drag_origin.x, drag_origin.y, base_drag_cur.z)
				p10 = Vector3(base_drag_cur.x, drag_origin.y, drag_origin.z)
			MathUtil.Axis.Z:
				p01 = Vector3(drag_origin.x, base_drag_cur.y, drag_origin.z)
				p10 = Vector3(base_drag_cur.x, drag_origin.y, drag_origin.z)

		var base_points:PackedVector3Array = [drag_origin, p01, base_drag_cur, p10]
		
		global_scene.draw_loop(base_points, true, global_scene.tool_material)
		global_scene.draw_points(base_points, global_scene.vertex_tool_material)
		
	if tool_state == ToolState.DRAG_HEIGHT:
		var tan_bi:Array[Vector3] = MathUtil.get_axis_aligned_tangent_and_binormal(floor_normal)
		var u_normal:Vector3 = tan_bi[0]
		var v_normal:Vector3 = tan_bi[1]

		#Rotate ccw by 90 degree increments
		match settings.direction:
			1:
				var tmp:Vector3 = u_normal
				u_normal = -v_normal
				v_normal = tmp
			2:
				u_normal = -u_normal
				v_normal = -v_normal
			3:
				var tmp:Vector3 = -u_normal
				u_normal = v_normal
				v_normal = tmp
		
		var u_span:Vector3 = (base_drag_cur - drag_origin).project(u_normal)
		var v_span:Vector3 = (base_drag_cur - drag_origin).project(v_normal)
		
		var stairs_origin:Vector3 = drag_origin
		if u_span.dot(u_normal) < 0:
			stairs_origin += u_span
			u_span = -u_span
		if v_span.dot(v_normal) < 0:
			stairs_origin += v_span
			v_span = -v_span
		
		#Stairs should ascend along v axis
		global_scene.draw_cube(drag_origin, base_drag_cur, block_drag_cur, global_scene.tool_material, global_scene.vertex_tool_material)
		
		var height_offset = block_drag_cur - base_drag_cur
		if height_offset.dot(floor_normal) < 0:
			return
		var num_steps:int = min(v_span.length() / settings.step_depth, height_offset.length() / settings.step_height)

		var max_height:float = floor(height_offset.length() / settings.step_height) * settings.step_height

		var step_span:Vector3 = v_normal * settings.step_depth
		for i in num_steps:
			var base_points:PackedVector3Array = [stairs_origin + step_span * i, \
				stairs_origin + u_span + step_span * i, \
				stairs_origin + u_span + step_span * (i + 1), \
				stairs_origin + step_span * (i + 1)]
			global_scene.draw_prism(base_points, \
				floor_normal * (max_height - settings.step_height * i), \
				global_scene.tool_material, \
				global_scene.vertex_tool_material)


func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:	
		
	var blocks_root:Node = builder.get_block_add_parent()
	#var grid_step_size:float = pow(2, builder.get_global_scene().grid_size)

	if event is InputEventKey:
		var e:InputEventKey = event
		
		if e.keycode == KEY_ESCAPE:
			if e.is_pressed():
				tool_state = ToolState.READY
			return true
			
	elif event is InputEventMouseButton:
		
		var e:InputEventMouseButton = event
		if e.button_index == MOUSE_BUTTON_LEFT:

			if e.is_pressed():
				
				var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
				var dir:Vector3 = viewport_camera.project_ray_normal(e.position)
				
				if tool_state == ToolState.READY:
					tool_state = ToolState.DRAG_BASE

					
					var result:IntersectResults = builder.intersect_ray_closest(origin, dir)
					if result:
						#print("init base point block")
						floor_normal = result.get_world_normal()

#						var p:Vector3 = MathUtil.snap_to_grid(result.get_world_position(), grid_step_size)
						var p:Vector3 = builder.get_snapping_manager().snap_point(result.get_world_position(), SnappingQuery.new(viewport_camera))
						drag_origin = p
						base_drag_cur = p

						return true
						
					else:
						#print("init base point empty space")
						var hit_result = calc_hit_point_empty_space(origin, dir, viewport_camera)
						var start_pos:Vector3 = hit_result[0]
						floor_normal = hit_result[1]

						#var p:Vector3 = MathUtil.snap_to_grid(start_pos, grid_step_size)
						var p:Vector3 = builder.get_snapping_manager().snap_point(start_pos, SnappingQuery.new(viewport_camera))
						drag_origin = p
						base_drag_cur = p
						
						return true	

			else:
				if tool_state == ToolState.DRAG_BASE:
					var camera_dir:Vector3 = viewport_camera.project_ray_normal(e.position)
					var angle_with_base:float = acos(floor_normal.dot(camera_dir))
					var drag_angle_limit:float = builder.get_global_scene().drag_angle_limit
					if angle_with_base < drag_angle_limit || angle_with_base > PI - drag_angle_limit:
						block_drag_cur = base_drag_cur + floor_normal
						
						create_block()
						
						tool_state = ToolState.READY
					else:
						tool_state = ToolState.DRAG_HEIGHT
						block_drag_cur = base_drag_cur
					return true
				
				elif tool_state == ToolState.DRAG_HEIGHT:
					#Create shape
					create_block()

					tool_state = ToolState.READY
					return true
					
		elif e.button_index == MOUSE_BUTTON_RIGHT:
			if tool_state == ToolState.DRAG_BASE || tool_state == ToolState.DRAG_HEIGHT:
				if e.is_pressed():
					tool_state = ToolState.READY
				return true
					
		elif e.button_index == MOUSE_BUTTON_WHEEL_UP:
			if tool_state == ToolState.DRAG_BASE || tool_state == ToolState.DRAG_HEIGHT:
				if e.pressed:
					if e.ctrl_pressed:
						if e.shift_pressed:
							var size = log(settings.step_depth) / log(2)
							settings.step_depth = pow(2, size + 1)
						else:
							var size = log(settings.step_height) / log(2)
							settings.step_height = pow(2, size + 1)
					else:
						settings.direction = wrap(settings.direction + 1, 0, 4)
				return true
					
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if tool_state == ToolState.DRAG_BASE || tool_state == ToolState.DRAG_HEIGHT:
				if e.pressed:
					if e.ctrl_pressed:
						if e.shift_pressed:
							var size = log(settings.step_depth) / log(2)
							settings.step_depth = pow(2, size - 1)
						else:
							var size = log(settings.step_height) / log(2)
							settings.step_height = pow(2, size - 1)
					else:
						settings.direction = wrap(settings.direction - 1, 0, 4)
				return true
				

	elif event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event

		if (e.button_mask & MOUSE_BUTTON_MASK_MIDDLE):
			return false

		var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
		var dir:Vector3 = viewport_camera.project_ray_normal(e.position)

		var start_pos:Vector3 = origin + builder.block_create_distance * dir
#		var w2l = blocks_root.global_transform.inverse()
#		var origin_local:Vector3 = w2l * origin
#		var dir_local:Vector3 = w2l.basis * dir

		if tool_state == ToolState.DRAG_BASE:
			var p_isect:Vector3 = MathUtil.intersect_plane(origin, dir, drag_origin, floor_normal)
			#var p_snapped = to_local(p_isect, blocks_root.global_transform.inverse(), grid_step_size)
#			var p_snapped:Vector3 = MathUtil.snap_to_grid(p_isect, grid_step_size)
			var p_snapped:Vector3 = builder.get_snapping_manager().snap_point(p_isect, SnappingQuery.new(viewport_camera))
			base_drag_cur = p_snapped

			return true
			
		elif tool_state == ToolState.DRAG_HEIGHT:
			block_drag_cur = MathUtil.closest_point_on_line(origin, dir, base_drag_cur, floor_normal)
			
			#block_drag_cur = to_local(block_drag_cur, blocks_root.global_transform.inverse(), grid_step_size)
			block_drag_cur = builder.get_snapping_manager().snap_point(block_drag_cur, SnappingQuery.new(viewport_camera))
			
			return true
				
	return super._gui_input(viewport_camera, event)		

func create_block():
	var blocks_root:Node = builder.get_block_add_parent()
	
	var cmd:CommandAddStairs = CommandAddStairs.new()
	cmd.builder = builder
	cmd.blocks_root_path = blocks_root.get_path()
	cmd.block_name_prefix = "Block_"
	cmd.floor_normal = floor_normal
	cmd.drag_origin = drag_origin
	cmd.base_drag_cur = base_drag_cur
	cmd.block_drag_cur = block_drag_cur
	cmd.step_height = settings.step_height
	cmd.step_depth = settings.step_depth
	cmd.direction = settings.direction
	cmd.uv_transform = builder.tool_uv_transform
	cmd.material_path = builder.tool_material_path

	var undo:EditorUndoRedoManager = builder.get_undo_redo()

	cmd.add_to_undo_manager(undo)
