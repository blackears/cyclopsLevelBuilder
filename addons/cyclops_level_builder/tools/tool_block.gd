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

enum DragStyle { NONE, BLOCK_BASE, BLOCK_HEIGHT }
var drag_style:DragStyle = DragStyle.NONE
#enum State { READY, DRAG_BASE }
#var dragging:bool = false
var mouse_start:Vector2

var block_drag_cur:Vector3
var block_drag_p0_local:Vector3
var block_drag_p1_local:Vector3
var block_drag_p2_local:Vector3

var drag_floor_normal:Vector3

func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:	
	var blocks_root:CyclopsBlocks = self.builder.active_node
	
	if event is InputEventMouseButton:
		
		var e:InputEventMouseButton = event
		if e.button_index == MOUSE_BUTTON_LEFT:

			if e.is_pressed():
				if drag_style == DragStyle.NONE:
					mouse_start = e.position
					
					var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
					var dir:Vector3 = viewport_camera.project_ray_normal(e.position)

					var result = blocks_root.intersect_ray(origin, dir)
					if !result:
						drag_floor_normal = Vector3.UP
						
						drag_style = DragStyle.BLOCK_BASE
						var start_pos:Vector3 = origin + builder.block_create_distance * dir
						var w2l = blocks_root.global_transform.inverse()
						var start_pos_local:Vector3 = w2l * start_pos

						#print("start_pos %s" % start_pos)
						#print("start_pos_local %s" % start_pos_local)
						
						var grid_step_size:float = pow(2, blocks_root.grid_size)

						
						#print("start_pos_local %s" % start_pos_local)
						block_drag_p0_local = MathUtil.snap_to_grid(start_pos_local, grid_step_size)
						
						#print("block_drag_start_local %s" % block_drag_start_local)
					#print("set 1 drag_style %s" % drag_style)
				
			else:
				if drag_style == DragStyle.BLOCK_BASE:
					block_drag_p1_local = block_drag_cur
					drag_style = DragStyle.BLOCK_HEIGHT
					
					#print("set 2 drag_style %s" % drag_style)
					
				elif drag_style == DragStyle.BLOCK_HEIGHT:
#					print("Adding block %s %s %s" % [block_drag_p0_local, block_drag_p1_local, block_drag_p2_local])
					block_drag_p2_local = block_drag_cur
					drag_style = DragStyle.NONE

					var global_scene:CyclopsGlobalScene = builder.get_node("/root/CyclopsAutoload")
					global_scene.clear_tool_mesh()

					var bounds:AABB = AABB(block_drag_p0_local, Vector3.ZERO)
					bounds = bounds.expand(block_drag_p1_local)
					bounds = bounds.expand(block_drag_p2_local)
					
#					print("AABB %s" % bounds)
					
					if bounds.has_volume():
					
						#print("set 3 drag_style %s" % drag_style)
						
		#				var brush:GeometryBrush = preload("../controls/geometry_brush.tscn").instantiate()
						var block:CyclopsBlock = preload("../controls/cyclops_block.gd").new()
						var name_idx:int = 0
						while true:
							var name = "Block_%s" % name_idx
							if !builder.active_node.find_child(name, false):
								block.name = name
								break
							name_idx += 1
						
						blocks_root.add_child(block)
						#brush.owner = builder.active_node
						block.owner = builder.get_editor_interface().get_edited_scene_root()
						#print("adding to %s" % builder.active_node.name)
						
						var mesh:ControlMesh = ControlMesh.new()
						mesh.init_block(bounds)
						mesh.triplanar_unwrap()
						#mesh.dump()
						#block.control_mesh = mesh

						block.block_data = mesh.to_block_data()
					

			
			#print("pick origin %s " % origin)
				
			return  true
			
	elif event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event

		var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
		var dir:Vector3 = viewport_camera.project_ray_normal(e.position)
		
		var start_pos:Vector3 = origin + builder.block_create_distance * dir
		var w2l = blocks_root.global_transform.inverse()
		var origin_local:Vector3 = w2l * origin
		var dir_local:Vector3 = w2l.basis * dir
		
		#print("drag_style %s" % drag_style)
		
		if drag_style == DragStyle.BLOCK_BASE:

			block_drag_cur = MathUtil.intersect_plane(origin_local, dir_local, block_drag_p0_local, drag_floor_normal)
			
			var grid_step_size:float = pow(2, blocks_root.grid_size)
			block_drag_cur = MathUtil.snap_to_grid(block_drag_cur, grid_step_size)
			
			var global_scene:CyclopsGlobalScene = builder.get_node("/root/CyclopsAutoload")
			global_scene.draw_rect(block_drag_p0_local, block_drag_cur)

		elif drag_style == DragStyle.BLOCK_HEIGHT:
#			block_drag_cur = MathUtil.intersect_plane(origin_local, dir_local, block_drag_p0_local, Vector3.UP)
			block_drag_cur = MathUtil.closest_point_on_line(origin_local, dir_local, block_drag_p1_local, drag_floor_normal)
			
			var grid_step_size:float = pow(2, blocks_root.grid_size)
			block_drag_cur = MathUtil.snap_to_grid(block_drag_cur, grid_step_size)
			
			var global_scene:CyclopsGlobalScene = builder.get_node("/root/CyclopsAutoload")
			global_scene.draw_cube(block_drag_p0_local, block_drag_p1_local, block_drag_cur)
	
	return false
	#return EditorPlugin.AFTER_GUI_INPUT_STOP if true else EditorPlugin.AFTER_GUI_INPUT_PASS


