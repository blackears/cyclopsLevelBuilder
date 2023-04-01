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
class_name ToolClip

enum ToolState { READY, PICK_POINTS, PICK_SIDE }
var tool_state:ToolState = ToolState.READY

var clip_points:PackedVector3Array
var clip_normals:PackedVector3Array
var clip_block:CyclopsBlock

func has_clip_point(point:Vector3)->bool:
	for p in clip_points:
		if p.is_equal_approx(point):
			return true
	return false

func draw_tool(global_scene:CyclopsGlobalScene):
	global_scene.clear_tool_mesh()
	if !clip_points.is_empty():
		global_scene.draw_loop(clip_points, false)
	

func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:	
	var blocks_root:CyclopsBlocks = self.builder.active_node
	var grid_step_size:float = pow(2, blocks_root.grid_size)
	var global_scene:CyclopsGlobalScene = builder.get_node("/root/CyclopsAutoload")

	if event is InputEventKey:
		var e:InputEventKey = event

		if e.keycode == KEY_BACKSPACE:
			if !clip_points.is_empty():
				var count:int = clip_points.size()
				clip_points.remove_at(count - 1)
				clip_normals.remove_at(count - 1)
				if clip_points.is_empty():
					clip_block = null
					
				draw_tool(global_scene)

			return true
			
		elif e.keycode == KEY_ESCAPE:
			clip_points.clear()
			clip_normals.clear()
			clip_block = null
			draw_tool(global_scene)
			return true
			
		elif e.keycode == KEY_ENTER:
			#Cut at plane
			var cut_plane:Plane
			
			if clip_points.size() == 3:
				cut_plane = Plane(clip_points[0], clip_points[1], clip_points[2])
			elif clip_points.size() == 2:
				var dir:Vector3 = clip_points[1] - clip_points[0]
				var face_dir:Vector3 = clip_normals[0].cross(dir)
				cut_plane = Plane(face_dir.normalized(), clip_points[0])
			else:
				#Cannot cut with fewer than 2 points
				return true
			
			var cmd:CommandClipBlock = CommandClipBlock.new()
			cmd.builder = builder
			cmd.blocks_root_path = blocks_root.get_path()
			cmd.block_path = clip_block.get_path()
			cmd.block_sibling_name = GeneralUtil.find_unique_name(blocks_root, "Block_")
			cmd.cut_plane = cut_plane
			cmd.material_id = builder.tool_material_id
			cmd.uv_transform = builder.tool_uv_transform
			
			var undo:EditorUndoRedoManager = builder.get_undo_redo()
			cmd.add_to_undo_manager(undo)
			
			#Clean up
			clip_points.clear()
			clip_normals.clear()
			clip_block = null

			draw_tool(global_scene)
			
			return true

	if event is InputEventMouseButton:
		
		var e:InputEventMouseButton = event
		if e.button_index == MOUSE_BUTTON_LEFT:

			if e.is_pressed():
				
				var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
				var dir:Vector3 = viewport_camera.project_ray_normal(e.position)				
				
				var result:IntersectResults = blocks_root.intersect_ray_closest(origin, dir)
				
				if result:
					var p:Vector3 = to_local(result.position, blocks_root.global_transform.inverse(), grid_step_size)
					
					if !has_clip_point(p):
						if clip_points.is_empty():
							clip_block = result.object
							
						if clip_points.size() < 3:
							clip_points.append(p)
							clip_normals.append(result.normal)
						else:
							clip_points[2] = p
							clip_normals[2] = result.normal
							
						draw_tool(global_scene)
						
			return true

	return false


func _activate(builder:CyclopsLevelBuilder):
	super._activate(builder)

	var global_scene:CyclopsGlobalScene = builder.get_node("/root/CyclopsAutoload")
	global_scene.clear_tool_mesh()
