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
class_name ToolPrism

const TOOL_ID:String = "prism"

enum ToolState { READY, BASE_POINTS, DRAG_HEIGHT }
var tool_state:ToolState = ToolState.READY

var floor_normal:Vector3
var base_points:PackedVector3Array
var block_drag_cur:Vector3
var drag_offset:Vector3
var preview_point:Vector3

func _activate(builder:CyclopsLevelBuilder):
	super._activate(builder)

	builder.mode = CyclopsLevelBuilder.Mode.OBJECT
	var global_scene:CyclopsGlobalScene = builder.get_node("/root/CyclopsAutoload")
	global_scene.clear_tool_mesh()
	

func _draw_tool(viewport_camera:Camera3D):
	var global_scene:CyclopsGlobalScene = builder.get_node("/root/CyclopsAutoload")
	global_scene.clear_tool_mesh()
	global_scene.draw_selected_blocks(viewport_camera)

	if tool_state == ToolState.BASE_POINTS:
		var bounding_points:PackedVector3Array = MathUtil.bounding_polygon_3d(base_points, floor_normal)
		global_scene.draw_loop(bounding_points, true, global_scene.tool_material)
		global_scene.draw_points(bounding_points, global_scene.tool_material)

		global_scene.draw_vertex(preview_point, global_scene.tool_material)

	if tool_state == ToolState.DRAG_HEIGHT:		
		var bounding_points:PackedVector3Array = MathUtil.bounding_polygon_3d(base_points, floor_normal)
		global_scene.draw_prism(bounding_points, drag_offset, global_scene.tool_material)
	

func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:	
	if !builder.active_node is CyclopsBlocks:
		return false
		
	var blocks_root:CyclopsBlocks = self.builder.active_node
	var grid_step_size:float = pow(2, builder.get_global_scene().grid_size)
#	var global_scene:CyclopsGlobalScene = builder.get_node("/root/CyclopsAutoload")
#	global_scene.clear_tool_mesh()
#	global_scene.draw_selected_blocks(viewport_camera)

	#_draw_tool(viewport_camera)

	if event is InputEventKey:
		var e:InputEventKey = event
		
		if e.keycode == KEY_ENTER:
			if e.is_pressed():
				if tool_state == ToolState.BASE_POINTS:
					drag_offset = Vector3.ZERO
					tool_state = ToolState.DRAG_HEIGHT
			return true
			
		elif e.keycode == KEY_BACKSPACE:
			if e.is_pressed():
				base_points.remove_at(base_points.size() - 1)
			return true
			
		elif e.keycode == KEY_ESCAPE:
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
					base_points.clear()
					tool_state = ToolState.BASE_POINTS

					var result:IntersectResults = blocks_root.intersect_ray_closest(origin, dir)
					if result:
						#print("init base point block")
						floor_normal = result.normal

						var p:Vector3 = to_local(result.position, blocks_root.global_transform.inverse(), grid_step_size)
#
						base_points.append(p)
						preview_point = p

						return true
						
					else:
						#print("init base point empty space")
						floor_normal = Vector3.UP

						var start_pos:Vector3 = origin + builder.block_create_distance * dir
						
						var p:Vector3 = to_local(start_pos, blocks_root.global_transform.inverse(), grid_step_size)
						base_points.append(p)
						
						return true
						
				elif tool_state == ToolState.BASE_POINTS:
					#print("add base point")
					if e.double_click:
						if e.is_pressed():
							drag_offset = Vector3.ZERO
							tool_state = ToolState.DRAG_HEIGHT
						return true

					var p_isect:Vector3 = MathUtil.intersect_plane(origin, dir, base_points[0], floor_normal)
					var p:Vector3 = to_local(p_isect, blocks_root.global_transform.inverse(), grid_step_size)
					base_points.append(p)

					var bounding_points:PackedVector3Array = MathUtil.bounding_polygon_3d(base_points, floor_normal)					
					return true
					
				elif tool_state == ToolState.DRAG_HEIGHT:
					var bounding_points:PackedVector3Array = MathUtil.bounding_polygon_3d(base_points, floor_normal)
					drag_offset = block_drag_cur - base_points[0]
					#drag_offset = Vector3.ZERO

					var command:CommandAddPrism = CommandAddPrism.new()
					command.block_name = GeneralUtil.find_unique_name(builder.active_node, "Block_")
					command.blocks_root_inst_id = blocks_root.get_instance_id()
					command.block_owner = builder.get_editor_interface().get_edited_scene_root()
					command.base_polygon = bounding_points
					command.extrude = drag_offset
					command.uv_transform = builder.tool_uv_transform
					command.material_path = builder.tool_material_path

					var undo:EditorUndoRedoManager = builder.get_undo_redo()

					command.add_to_undo_manager(undo)
					
#					global_scene.clear_tool_mesh()
#					global_scene.draw_selected_blocks(viewport_camera)
					
					tool_state = ToolState.READY
					return true

		if e.button_index == MOUSE_BUTTON_RIGHT:
			
			if tool_state == ToolState.BASE_POINTS:
				if e.is_pressed():
					for p_idx in base_points.size():
						var screem_pos:Vector2 = viewport_camera.unproject_position(base_points[p_idx])
						if screem_pos.distance_to(e.position) < builder.handle_screen_radius:
							base_points.remove_at(p_idx)
							break
				return true		
			
	elif event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event

		if (e.button_mask & MOUSE_BUTTON_MASK_MIDDLE):
			return false		

		var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
		var dir:Vector3 = viewport_camera.project_ray_normal(e.position)

		var start_pos:Vector3 = origin + builder.block_create_distance * dir
		var w2l = blocks_root.global_transform.inverse()
		var origin_local:Vector3 = w2l * origin
		var dir_local:Vector3 = w2l.basis * dir

		if tool_state == ToolState.BASE_POINTS:
			var p_isect:Vector3 = MathUtil.intersect_plane(origin, dir, base_points[0], floor_normal)
			preview_point = to_local(p_isect, blocks_root.global_transform.inverse(), grid_step_size)
			

		elif tool_state == ToolState.DRAG_HEIGHT:
			block_drag_cur = MathUtil.closest_point_on_line(origin_local, dir_local, base_points[0], floor_normal)
			
			block_drag_cur = to_local(block_drag_cur, blocks_root.global_transform.inverse(), grid_step_size)
			
			drag_offset = block_drag_cur - base_points[0]
			var bounding_points:PackedVector3Array = MathUtil.bounding_polygon_3d(base_points, floor_normal)
			
#			global_scene.clear_tool_mesh()
#			global_scene.draw_prism(bounding_points, drag_offset, global_scene.tool_material)

			return true

	return super._gui_input(viewport_camera, event)		


