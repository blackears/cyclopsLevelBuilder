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
class_name ToolCylinder

const TOOL_ID:String = "cylinder"

enum ToolState { READY, FIRST_RING, SECOND_RING, DRAG_HEIGHT }
var tool_state:ToolState = ToolState.READY

#@export var segments:int = 16
#@export var tube:bool = false
var settings:ToolCylinderSettings = ToolCylinderSettings.new()

var floor_normal:Vector3
var base_center:Vector3
var block_drag_cur:Vector3
var drag_offset:Vector3
var first_ring_radius:float
var second_ring_radius:float



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

	if tool_state == ToolState.FIRST_RING:
		var bounding_points:PackedVector3Array = MathUtil.create_circle_points(base_center, floor_normal, first_ring_radius, settings.segments)
		global_scene.draw_loop(bounding_points, true, global_scene.tool_material)
		global_scene.draw_points(bounding_points, global_scene.vertex_tool_material)
		
	elif tool_state == ToolState.SECOND_RING:
		for radius in [first_ring_radius, second_ring_radius]:
			var bounding_points:PackedVector3Array = MathUtil.create_circle_points(base_center, floor_normal, radius, settings.segments)
			global_scene.draw_loop(bounding_points, true, global_scene.tool_material)
			global_scene.draw_points(bounding_points, global_scene.vertex_tool_material)

	elif tool_state == ToolState.DRAG_HEIGHT:	
		var bounding_points:PackedVector3Array = MathUtil.create_circle_points(base_center, floor_normal, first_ring_radius, settings.segments)
		global_scene.draw_prism(bounding_points, drag_offset, global_scene.tool_material, global_scene.vertex_tool_material)
		
		if settings.tube:
			bounding_points = MathUtil.create_circle_points(base_center, floor_normal, second_ring_radius, settings.segments)
			global_scene.draw_prism(bounding_points, drag_offset, global_scene.tool_material, global_scene.vertex_tool_material)
		

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
					tool_state = ToolState.FIRST_RING

					first_ring_radius = 0
					second_ring_radius = 0
					
					var result:IntersectResults = builder.intersect_ray_closest(origin, dir)
					if result:
						#print("init base point block")
#						floor_normal = result.normal
						floor_normal = result.get_world_normal()

#						var p:Vector3 = to_local(result.position, blocks_root.global_transform.inverse(), grid_step_size)
						var p:Vector3 = builder.get_snapping_manager().snap_point(result.get_world_position(), SnappingQuery.new(viewport_camera))
						base_center = p

						return true
						
					else:
						#print("init base point empty space")
						var hit_result = calc_hit_point_empty_space(origin, dir, viewport_camera)
						var start_pos:Vector3 = hit_result[0]
						floor_normal = hit_result[1]
#						floor_normal = Vector3.UP

#						var start_pos:Vector3 = origin + builder.block_create_distance * dir
						
						#var p:Vector3 = to_local(start_pos, blocks_root.global_transform.inverse(), grid_step_size)

						var p:Vector3 = builder.get_snapping_manager().snap_point(start_pos, SnappingQuery.new(viewport_camera))
						base_center = p
						
						return true	
			else:
				if tool_state == ToolState.FIRST_RING:
					if settings.tube:
						tool_state = ToolState.SECOND_RING
					else:
						var camera_dir:Vector3 = viewport_camera.project_ray_normal(e.position)
						var angle_with_base:float = acos(floor_normal.dot(camera_dir))
						var drag_angle_limit:float = builder.get_global_scene().drag_angle_limit
						if angle_with_base < drag_angle_limit || angle_with_base > PI - drag_angle_limit:
							block_drag_cur = base_center + floor_normal
							
							create_block()
							
							tool_state = ToolState.READY
						else:
							tool_state = ToolState.DRAG_HEIGHT
					return true
				
				elif tool_state == ToolState.SECOND_RING:
					var camera_dir:Vector3 = viewport_camera.project_ray_normal(e.position)
					var angle_with_base:float = acos(floor_normal.dot(camera_dir))
					var drag_angle_limit:float = builder.get_global_scene().drag_angle_limit
					if angle_with_base < drag_angle_limit || angle_with_base > PI - drag_angle_limit:
						block_drag_cur = base_center + floor_normal
						
						create_block()
						
						tool_state = ToolState.READY
					else:
					
						tool_state = ToolState.DRAG_HEIGHT
					return true

				elif tool_state == ToolState.DRAG_HEIGHT:

					create_block()
										
					tool_state = ToolState.READY
					return true
		
		elif e.button_index == MOUSE_BUTTON_RIGHT:
			if tool_state == ToolState.FIRST_RING || tool_state == ToolState.SECOND_RING || tool_state == ToolState.DRAG_HEIGHT:
				if e.is_pressed():
					tool_state = ToolState.READY
				return true
					
		elif e.button_index == MOUSE_BUTTON_WHEEL_UP:
			if tool_state == ToolState.FIRST_RING || tool_state == ToolState.SECOND_RING || tool_state == ToolState.DRAG_HEIGHT:
				if e.pressed:
					settings.segments += 1
				return true
					
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if tool_state == ToolState.FIRST_RING || tool_state == ToolState.SECOND_RING || tool_state == ToolState.DRAG_HEIGHT:
				if e.pressed:
					settings.segments = max(settings.segments - 1, 3)
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

		if tool_state == ToolState.FIRST_RING:
			var p_isect:Vector3 = MathUtil.intersect_plane(origin, dir, base_center, floor_normal)
			#var p_snapped = to_local(p_isect, blocks_root.global_transform.inverse(), grid_step_size)
			#var p_snapped = MathUtil.snap_to_grid(p_isect, grid_step_size)
			var p_snapped:Vector3 = builder.get_snapping_manager().snap_point(p_isect, SnappingQuery.new(viewport_camera))
			first_ring_radius = (p_snapped - base_center).length()

			return true
			
		elif tool_state == ToolState.SECOND_RING:
			var p_isect:Vector3 = MathUtil.intersect_plane(origin, dir, base_center, floor_normal)
			#var p_snapped = to_local(p_isect, blocks_root.global_transform.inverse(), grid_step_size)
#			var p_snapped = MathUtil.snap_to_grid(p_isect, grid_step_size)
			var p_snapped:Vector3 = builder.get_snapping_manager().snap_point(p_isect, SnappingQuery.new(viewport_camera))
			second_ring_radius = (p_snapped - base_center).length()

			return true
			
		elif tool_state == ToolState.DRAG_HEIGHT:
			block_drag_cur = MathUtil.closest_point_on_line(origin, dir, base_center, floor_normal)
			
			block_drag_cur = builder.get_snapping_manager().snap_point(block_drag_cur, SnappingQuery.new(viewport_camera))
			
			drag_offset = block_drag_cur - base_center
#			var bounding_points:PackedVector3Array = MathUtil.bounding_polygon_3d(base_points, floor_normal)
			
#			global_scene.clear_tool_mesh()
#			global_scene.draw_prism(bounding_points, drag_offset, global_scene.tool_material)

			return true

	return super._gui_input(viewport_camera, event)		

func create_block():
	var blocks_root:Node = builder.get_block_add_parent()
	
	var cmd:CommandAddCylinder = CommandAddCylinder.new()
	cmd.builder = builder
	cmd.block_name_prefix = "Block_"
	cmd.blocks_root_path = blocks_root.get_path()
	cmd.tube = settings.tube
	cmd.origin = base_center
	cmd.axis_normal = floor_normal
	cmd.height = drag_offset.length() if drag_offset.dot(floor_normal) > 0 else - drag_offset.length()
	if settings.tube:
		cmd.radius_inner = min(first_ring_radius, second_ring_radius)
		cmd.radius_outer = max(first_ring_radius, second_ring_radius)
	else:
		cmd.radius_inner = first_ring_radius
		cmd.radius_outer = first_ring_radius
	cmd.segments = settings.segments
	cmd.uv_transform = builder.tool_uv_transform
	cmd.material_path = builder.tool_material_path

	var undo:EditorUndoRedoManager = builder.get_undo_redo()

	cmd.add_to_undo_manager(undo)
