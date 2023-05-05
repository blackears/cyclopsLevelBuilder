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
class_name ToolDuplicate

const TOOL_ID:String = "duplicate"

var drag_start_point:Vector3
var cmd_duplicate:CommandDuplicateBlocks

enum ToolState { READY, DRAGGING, DONE }
var tool_state:ToolState = ToolState.READY

func _get_tool_id()->String:
	return TOOL_ID

func _draw_tool(viewport_camera:Camera3D):
	var global_scene:CyclopsGlobalScene = builder.get_global_scene()
	global_scene.clear_tool_mesh()
	global_scene.draw_selected_blocks(viewport_camera)

func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:	
	if !builder.active_node is CyclopsBlocks:
		return false
		
	var blocks_root:CyclopsBlocks = self.builder.active_node
	var grid_step_size:float = pow(2, builder.get_global_scene().grid_size)
#	var global_scene:CyclopsGlobalScene = builder.get_node("/root/CyclopsAutoload")
	#_draw_tool(viewport_camera)
	
	if event is InputEventMouseButton:
		
		var e:InputEventMouseButton = event
		if e.button_index == MOUSE_BUTTON_LEFT:

			if !e.is_pressed():
				if tool_state == ToolState.DRAGGING:
					#print("committing duplicate")
					var undo:EditorUndoRedoManager = builder.get_undo_redo()

					if cmd_duplicate.will_change_anything():
						cmd_duplicate.add_to_undo_manager(undo)
					
					tool_state = ToolState.DONE
					builder.switch_to_tool(ToolBlock.new())
					
		return true
					
	elif event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event

		if (e.button_mask & MOUSE_BUTTON_MASK_MIDDLE):
			return super._gui_input(viewport_camera, event)		

		var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
		var dir:Vector3 = viewport_camera.project_ray_normal(e.position)
		
		var start_pos:Vector3 = origin + builder.block_create_distance * dir
		var w2l = blocks_root.global_transform.inverse()
		var origin_local:Vector3 = w2l * origin
		var dir_local:Vector3 = w2l.basis * dir
	
		if tool_state == ToolState.DRAGGING:
			var drag_to:Vector3
			if e.alt_pressed:
				drag_to = MathUtil.closest_point_on_line(origin_local, dir_local, drag_start_point, Vector3.UP)
			else:
				drag_to = MathUtil.intersect_plane(origin_local, dir_local, drag_start_point, Vector3.UP)
			
			var offset:Vector3 = drag_to - drag_start_point
			offset = MathUtil.snap_to_grid(offset, grid_step_size)

			#print("duplicate drag by %s" % offset)
			
			cmd_duplicate.move_offset = offset
			cmd_duplicate.do_it()
		
		return true
			
	
	return false
	

func _activate(builder:CyclopsLevelBuilder):
	super._activate(builder)

	#builder.mode = CyclopsLevelBuilder.Mode.OBJECT
	var global_scene:CyclopsGlobalScene = builder.get_global_scene()
	global_scene.clear_tool_mesh()
	
	#Invoke command immediately
	cmd_duplicate = CommandDuplicateBlocks.new()
	cmd_duplicate.builder = builder
	var blocks_root:CyclopsBlocks = builder.active_node
	cmd_duplicate.blocks_root_path = blocks_root.get_path()
	var centroid:Vector3
	var count:int = 0
	for child in blocks_root.get_children():
		if child is CyclopsConvexBlock:
			var block:CyclopsConvexBlock = child
			if block.selected:
				cmd_duplicate.blocks_to_duplicate.append(block.get_path())
				centroid += block.control_mesh.bounds.get_center()
				count += 1
	cmd_duplicate.lock_uvs = builder.lock_uvs
	
	centroid /= count
	drag_start_point = centroid
	tool_state = ToolState.DRAGGING
	
	cmd_duplicate.do_it()
	


