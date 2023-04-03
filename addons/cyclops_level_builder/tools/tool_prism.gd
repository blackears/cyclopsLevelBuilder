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

enum ToolState { READY, BASE_POINTS, DRAG_HEIGHT }
var tool_state:ToolState = ToolState.READY

var floor_normal:Vector3
var base_points:PackedVector3Array
var block_drag_cur:Vector3


func _activate(builder:CyclopsLevelBuilder):
	super._activate(builder)

	var global_scene:CyclopsGlobalScene = builder.get_node("/root/CyclopsAutoload")
	global_scene.clear_tool_mesh()
	

func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:	
	var blocks_root:CyclopsBlocks = self.builder.active_node
	var grid_step_size:float = pow(2, blocks_root.grid_size)
	var global_scene:CyclopsGlobalScene = builder.get_node("/root/CyclopsAutoload")

	if event is InputEventKey:
		if tool_state == ToolState.BASE_POINTS:
			tool_state = ToolState.DRAG_HEIGHT
			return true
	
	if event is InputEventMouseButton:
		
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
#						floor_normal = MathUtil.snap_to_best_axis_normal(result.normal)
						floor_normal = result.normal

						var p:Vector3 = to_local(result.position, blocks_root.global_transform.inverse(), grid_step_size)
#
						base_points.append(p)

						global_scene.clear_tool_mesh()					
						global_scene.draw_loop(base_points, false)
						return true
						
					else:
						floor_normal = Vector3.UP
						
						var p:Vector3 = to_local(result.position, blocks_root.global_transform.inverse(), grid_step_size)
						base_points.append(p)
						
						global_scene.clear_tool_mesh()
						global_scene.draw_loop(base_points, false)
						return true
						
				elif tool_state == ToolState.BASE_POINTS:
					var p_isect:Vector3 = MathUtil.intersect_plane(origin, dir, base_points[0], floor_normal)

					var p:Vector3 = to_local(p_isect, blocks_root.global_transform.inverse(), grid_step_size)
					base_points.append(p)

					#print("base %s " % base_points)
					var bounding_points:PackedVector3Array = MathUtil.bounding_polygon_3d(base_points, floor_normal)
					#print("bounding %s " % bounding_points)
					global_scene.clear_tool_mesh()
					global_scene.draw_loop(bounding_points, true)
					
					return true
				elif tool_state == ToolState.DRAG_HEIGHT:
					var bounding_points:PackedVector3Array = MathUtil.bounding_polygon_3d(base_points, floor_normal)
					var offset:Vector3 = block_drag_cur - base_points[0]

					var command:CommandAddPrism = CommandAddPrism.new()
					command.block_name = GeneralUtil.find_unique_name(builder.active_node, "Block_")
					command.blocks_root_inst_id = blocks_root.get_instance_id()
					command.block_owner = builder.get_editor_interface().get_edited_scene_root()
					command.base_polygon = bounding_points
					command.extrude = offset

					var undo:EditorUndoRedoManager = builder.get_undo_redo()

					command.add_to_undo_manager(undo)
					
					global_scene.clear_tool_mesh()
					
					tool_state = ToolState.READY
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

		if tool_state == ToolState.DRAG_HEIGHT:
			block_drag_cur = MathUtil.closest_point_on_line(origin_local, dir_local, base_points[0], floor_normal)
			
			block_drag_cur = to_local(block_drag_cur, blocks_root.global_transform.inverse(), grid_step_size)
			
			var offset:Vector3 = block_drag_cur - base_points[0]
			var bounding_points:PackedVector3Array = MathUtil.bounding_polygon_3d(base_points, floor_normal)
			
			global_scene.clear_tool_mesh()
			global_scene.draw_prism(bounding_points, offset)

			return true

	return super._gui_input(viewport_camera, event)		


