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
class_name ToolSelectBox

enum ToolState { NONE, READY, DRAG_SELECTION }
var tool_state:ToolState = ToolState.NONE

const TOOL_ID:String = "select_box"

var drag_select_start_pos:Vector2
var drag_select_to_pos:Vector2

var event_start:InputEventMouseButton

func _get_tool_id()->String:
	return TOOL_ID

func _get_tool_name()->String:
	return "Select Box"

func _get_tool_icon()->Texture2D:
	#return preload("res://addons/cyclops_level_builder/art/icons/move.svg")
	return preload("res://addons/cyclops_level_builder/art/icons/tool_select_box.svg")

func _get_tool_tooltip()->String:
	return "Select blocks."

func _get_tool_properties_editor()->Control:
	return null

func _can_handle_object(node:Node)->bool:
	return node is CyclopsBlock


func _draw_tool(viewport_camera:Camera3D):
	var global_scene:CyclopsGlobalScene = builder.get_global_scene()
	global_scene.clear_tool_mesh()
#	global_scene.draw_selected_blocks(viewport_camera)
	builder.viewport_3d_manager.clear_tool_display()
	builder.viewport_3d_manager.draw_selection_marquis(viewport_camera)

	if tool_state == ToolState.DRAG_SELECTION:
		#print("draw sel %s " % drag_select_to_pos)
#		global_scene.draw_screen_rect(viewport_camera, drag_select_start_pos, drag_select_to_pos, global_scene.selection_rect_material)
		builder.viewport_3d_manager.draw_screen_rect(viewport_camera, drag_select_start_pos, drag_select_to_pos, global_scene.selection_rect_material)


func start_drag(viewport_camera:Camera3D, event:InputEvent):
	var blocks_root:Node = builder.get_block_add_parent()
	var e:InputEventMouseButton = event
	
	var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
	var dir:Vector3 = viewport_camera.project_ray_normal(e.position)
	
	tool_state = ToolState.DRAG_SELECTION
	drag_select_start_pos = e.position
	drag_select_to_pos = e.position
	


func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:

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
					
					tool_state = ToolState.READY
				
			else:
				if tool_state == ToolState.READY:
					#print("move tool mouse button event ", event)
					
					#We just clicked with the mouse
					var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
					var dir:Vector3 = viewport_camera.project_ray_normal(e.position)

					var result:IntersectResults = builder.intersect_ray_closest(origin, dir)
					
					if result:
						var cmd:CommandSelectBlocks = CommandSelectBlocks.new()
						cmd.builder = builder
						cmd.selection_type = Selection.choose_type(e.shift_pressed, e.ctrl_pressed)
						
#						print("Invoke select %s" % result)
						cmd.block_paths.append(result.object.get_path())
						
						if cmd.will_change_anything():
							var undo:EditorUndoRedoManager = builder.get_undo_redo()
							cmd.add_to_undo_manager(undo)
							
					#print("tool state up")
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
		
		#print("tool_state %s" % tool_state)
				
		if tool_state == ToolState.READY:
			var offset:Vector2 = e.position - event_start.position
			if offset.length_squared() > MathUtil.square(builder.drag_start_radius):
				#print("start drag")
				start_drag(viewport_camera, event_start)

			return true
			

		elif tool_state == ToolState.DRAG_SELECTION:
			drag_select_to_pos = e.position
			return true
	
	return super._gui_input(viewport_camera, event)
	
