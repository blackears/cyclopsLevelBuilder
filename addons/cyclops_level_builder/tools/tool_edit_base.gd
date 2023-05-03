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
class_name ToolEditBase

var mouse_hover_pos:Vector2

func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:	
	if !builder.active_node is CyclopsBlocks:
		return false
		
	var blocks_root:CyclopsBlocks = self.builder.active_node
	
	if event is InputEventKey:
		var e:InputEventKey = event
		
		if e.keycode == KEY_Q && e.alt_pressed:
			if e.is_pressed():
				var origin:Vector3 = viewport_camera.project_ray_origin(mouse_hover_pos)
				var dir:Vector3 = viewport_camera.project_ray_normal(mouse_hover_pos)
			
				var result:IntersectResults = blocks_root.intersect_ray_closest(origin, dir)
				if result:
					var cmd:CommandSelectBlocks = CommandSelectBlocks.new()
					cmd.builder = builder
					cmd.block_paths.append(result.object.get_path())
					
					if cmd.will_change_anything():
						var undo:EditorUndoRedoManager = builder.get_undo_redo()
						cmd.add_to_undo_manager(undo)
						
						_deactivate()
						_activate(builder)
					
					pass
				
			return true
	
	
	elif event is InputEventMouseButton:
		var e:InputEventMouseButton = event
		mouse_hover_pos = e.position
		return false
		
	elif event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event
		mouse_hover_pos = e.position		
		return false
		
	return false

func pick_material(global_scene:CyclopsGlobalScene, selected:bool = false, active = false)->Material:
	if active:
		return global_scene.tool_edit_active_material
	if selected:
		return global_scene.tool_edit_selected_material
	return global_scene.tool_edit_unselected_material
	
	
	
