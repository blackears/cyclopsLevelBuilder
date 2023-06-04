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
class_name ToolMove

const TOOL_ID:String = "move"


enum ToolState { NONE, READY, MOVE_BLOCK, DRAG_SELECTION }
var tool_state:ToolState = ToolState.NONE

#var viewport_camera_start:Camera3D
var event_start:InputEventMouseButton

var block_drag_cur:Vector3
var block_drag_p0:Vector3

var drag_select_start_pos:Vector2
var drag_select_to_pos:Vector2

#Keep a copy of move command here while we are building it
var cmd_move_blocks:CommandMoveBlocks

var base_points:PackedVector3Array

func _get_tool_id()->String:
	return TOOL_ID

func start_drag(viewport_camera:Camera3D, event:InputEvent):
#	var blocks_root:CyclopsBlocks = self.builder.active_node
	var blocks_root:Node = builder.get_block_add_parent()
	var e:InputEventMouseButton = event
	
	var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
	var dir:Vector3 = viewport_camera.project_ray_normal(e.position)

	var result:IntersectResults = builder.intersect_ray_closest(origin, dir)
#					print("result %s" % result)
	
	if result:

		if result.object.selected:

			var start_pos:Vector3 = result.get_world_position()
#			var w2l = blocks_root.global_transform.inverse()
#			var start_pos_local:Vector3 = w2l * start_pos

			var grid_step_size:float = pow(2, builder.get_global_scene().grid_size)

			block_drag_p0 = MathUtil.snap_to_grid(start_pos, grid_step_size)
			
			if result.object.selected:
				tool_state = ToolState.MOVE_BLOCK
				
				cmd_move_blocks = CommandMoveBlocks.new()
				cmd_move_blocks.builder = builder
				cmd_move_blocks.lock_uvs = builder.lock_uvs
				for child in builder.get_blocks():
					if child.selected:
						cmd_move_blocks.add_block(child.get_path())
				
				return
		
	tool_state = ToolState.DRAG_SELECTION
	drag_select_start_pos = e.position
	drag_select_to_pos = e.position


func _draw_tool(viewport_camera:Camera3D):
	var global_scene:CyclopsGlobalScene = builder.get_global_scene()
	global_scene.clear_tool_mesh()
	global_scene.draw_selected_blocks(viewport_camera)

	if tool_state == ToolState.DRAG_SELECTION:
		#print("draw sel %s " % drag_select_to_pos)
		global_scene.draw_screen_rect(viewport_camera, drag_select_start_pos, drag_select_to_pos, global_scene.selection_rect_material)

func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:

	if event is InputEventKey:
		var e:InputEventKey = event
		
		if e.keycode == KEY_ESCAPE:
			if e.is_pressed():
				tool_state = ToolState.NONE
				if cmd_move_blocks:
					cmd_move_blocks.undo()
					cmd_move_blocks = null
					
			return true
		
	
	elif event is InputEventMouseButton:
		
		var e:InputEventMouseButton = event
		if e.button_index == MOUSE_BUTTON_LEFT:

			if e.is_pressed():
				if tool_state == ToolState.NONE:
					event_start = event
					
					tool_state = ToolState.READY
				
			else:
				if tool_state == ToolState.READY:
					
					#We just clicked with the mouse
					var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
					var dir:Vector3 = viewport_camera.project_ray_normal(e.position)

					var result:IntersectResults = builder.intersect_ray_closest(origin, dir)
					
					#print("Invokke select %s" % result)
					var cmd:CommandSelectBlocks = CommandSelectBlocks.new()
					cmd.builder = builder
					cmd.selection_type = Selection.choose_type(e.shift_pressed, e.ctrl_pressed)

					if result:
						cmd.block_paths.append(result.object.get_path())
						
					if cmd.will_change_anything():
						var undo:EditorUndoRedoManager = builder.get_undo_redo()
						cmd.add_to_undo_manager(undo)
					
					tool_state = ToolState.NONE

				elif tool_state == ToolState.MOVE_BLOCK:
					
					#Finish moving blocks
					var undo:EditorUndoRedoManager = builder.get_undo_redo()
					cmd_move_blocks.add_to_undo_manager(undo)
					
					tool_state = ToolState.NONE

				elif tool_state == ToolState.DRAG_SELECTION:
					
					var frustum:Array[Plane] = MathUtil.calc_frustum_camera_rect(viewport_camera, drag_select_start_pos, drag_select_to_pos)
					
					var result:Array[CyclopsBlock] = builder.intersect_frustum_all(frustum)
					
					if !result.is_empty():
						
						var cmd:CommandSelectBlocks = CommandSelectBlocks.new()
						cmd.builder = builder
						cmd.selection_type = Selection.choose_type(e.shift_pressed, e.ctrl_pressed)

						for r in result:
							cmd.block_paths.append(r.get_path())
							
						if cmd.will_change_anything():
							var undo:EditorUndoRedoManager = builder.get_undo_redo()
							cmd.add_to_undo_manager(undo)
					
					tool_state = ToolState.NONE
				
			return true
		
			
	elif event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event

		if (e.button_mask & MOUSE_BUTTON_MASK_MIDDLE):
			return super._gui_input(viewport_camera, event)

		var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
		var dir:Vector3 = viewport_camera.project_ray_normal(e.position)
		
		var start_pos:Vector3 = origin + builder.block_create_distance * dir
#		var w2l = blocks_root.global_transform.affine_inverse()
#		var origin_local:Vector3 = w2l * origin
#		var dir_local:Vector3 = w2l.basis * dir
	
#		var global_scene:CyclopsGlobalScene = builder.get_node("/root/CyclopsAutoload")
		
		#print("tool_state %s" % tool_state)
				
		if tool_state == ToolState.READY:
			var offset:Vector2 = e.position - event_start.position
			if offset.length_squared() > MathUtil.square(builder.drag_start_radius):
				start_drag(viewport_camera, event_start)

			return true
			
		elif tool_state == ToolState.MOVE_BLOCK:
			if e.alt_pressed:
				block_drag_cur = MathUtil.closest_point_on_line(origin, dir, block_drag_p0, Vector3.UP)
			else:
				block_drag_cur = MathUtil.intersect_plane(origin, dir, block_drag_p0, Vector3.UP)
			
#			print("block_drag_cur %s" % block_drag_cur)
#			print("block_drag_p0 %s" % block_drag_p0)

			var grid_step_size:float = pow(2, builder.get_global_scene().grid_size)
			block_drag_cur = MathUtil.snap_to_grid(block_drag_cur, grid_step_size)
			
			cmd_move_blocks.move_offset = block_drag_cur - block_drag_p0
			#print("cmd_move_blocks.move_offset %s" % cmd_move_blocks.move_offset)
			cmd_move_blocks.do_it()

			return true

		elif tool_state == ToolState.DRAG_SELECTION:
			drag_select_to_pos = e.position
			return true
			
	
	return super._gui_input(viewport_camera, event)		


func _activate(builder:CyclopsLevelBuilder):
	super._activate(builder)
	
	builder.mode = CyclopsLevelBuilder.Mode.OBJECT
	var global_scene:CyclopsGlobalScene = builder.get_global_scene()
	global_scene.clear_tool_mesh()

