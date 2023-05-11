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
extends Resource
class_name CyclopsTool

var builder:CyclopsLevelBuilder

#func _init(_editorPlugin:EditorPlugin):
#	editorPlugin = _editorPlugin

func _activate(builder:CyclopsLevelBuilder):
	self.builder = builder
	
func _deactivate():
	pass

func _get_tool_id()->String:
	return ""

func _draw_tool(viewport_camera:Camera3D):
	pass

func _get_tool_properties_editor()->Control:
	return null

func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:
	if event is InputEventKey:
		var e:InputEventKey = event

		if e.keycode == KEY_X:
			if e.is_pressed():
				#print("cyc tool X")
				var action:ActionDeleteSelectedBlocks = ActionDeleteSelectedBlocks.new(builder)
				action._execute()
			
			return true
				
		if e.keycode == KEY_D:
			if e.is_pressed():
				if e.shift_pressed && !Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
					
					if builder.active_node and builder.active_node.has_selected_blocks():
					
						builder.switch_to_tool(ToolDuplicate.new())
					
			return true
	
	if event is InputEventMouseButton:
		var e:InputEventMouseButton = event
		
		if e.button_index == MOUSE_BUTTON_MIDDLE:
			if e.alt_pressed:
				if e.is_pressed():
					if builder.active_node:

						var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
						var dir:Vector3 = viewport_camera.project_ray_normal(e.position)
						
						var start_pos:Vector3 = origin + builder.block_create_distance * dir
						var w2l = builder.active_node.global_transform.inverse()
						var origin_local:Vector3 = w2l * origin
						var dir_local:Vector3 = w2l.basis * dir
						
						var result:IntersectResults = builder.active_node.intersect_ray_closest(origin_local, dir_local)
						if result:
							var ed_iface:EditorInterface = builder.get_editor_interface()
							var base_control:Control = ed_iface.get_base_control()
							
							#viewport_camera
							var new_cam_origin:Vector3 = result.position + \
								viewport_camera.global_transform.basis.z * builder.block_create_distance
							viewport_camera.global_transform.origin = new_cam_origin
					return true
	
	return false



func to_local(point:Vector3, world_to_local:Transform3D, grid_step_size:float)->Vector3:
	var p_local:Vector3 = world_to_local * point

	return MathUtil.snap_to_grid(p_local, grid_step_size)

