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
class_name ToolMaterialBrush

enum ToolState { READY, PAINTING }
var tool_state:ToolState = ToolState.READY

const TOOL_ID:String = "material_brush"

var cmd_material:CommandSetMaterial

var settings:ToolMaterialBrushSettings = ToolMaterialBrushSettings.new()


func _get_tool_id()->String:
	return TOOL_ID

func _draw_tool(viewport_camera:Camera3D):
	super._draw_tool(viewport_camera)

	var global_scene:CyclopsGlobalScene = builder.get_global_scene()
	global_scene.clear_tool_mesh()
	global_scene.draw_selected_blocks(viewport_camera)

func _get_tool_properties_editor()->Control:
	var ed:ToolMaterialBrushSettingsEditor = preload("res://addons/cyclops_level_builder/tools/tool_material_brush_settings_editor.tscn").instantiate()

	ed.settings = settings
	
	return ed
	
func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:	
	if event is InputEventMouseButton:
		
		var e:InputEventMouseButton = event
		if e.button_index == MOUSE_BUTTON_LEFT:

			if e.is_pressed():
				
				if tool_state == ToolState.READY:
					var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
					var dir:Vector3 = viewport_camera.project_ray_normal(e.position)				
					
					var result:IntersectResults = builder.intersect_ray_closest(origin, dir)
					
					if result:
						cmd_material = CommandSetMaterial.new()
						cmd_material.builder = builder
						
						cmd_material.material_path = builder.tool_material_path if !settings.erase_material else ""
						
						var block:CyclopsBlock = result.object
						if settings.individual_faces:
							cmd_material.add_target(block.get_path(), [result.face_index])

						else:
							cmd_material.add_target(block.get_path(), block.control_mesh.get_face_indices())
						
						tool_state = ToolState.PAINTING

			else:
				if tool_state == ToolState.PAINTING:
					cmd_material.undo_it()
					if cmd_material.will_change_anything():
						var undo:EditorUndoRedoManager = builder.get_undo_redo()
						cmd_material.add_to_undo_manager(undo)					
					
					tool_state = ToolState.READY
					
			return true
		
				
	elif event is InputEventMouseMotion:
		
		var e:InputEventMouseMotion = event

		if tool_state == ToolState.PAINTING:
			var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
			var dir:Vector3 = viewport_camera.project_ray_normal(e.position)				
			
			var result:IntersectResults = builder.intersect_ray_closest(origin, dir)
			
			if result:
				cmd_material.undo_it()
				var block:CyclopsBlock = result.object
				if settings.individual_faces:
					cmd_material.add_target(block.get_path(), [result.face_index])

				else:
					cmd_material.add_target(block.get_path(), block.control_mesh.get_face_indices())
				cmd_material.do_it()
			
			return true
		
	return false

	

func _activate(builder:CyclopsLevelBuilder):
	super._activate(builder)


	
	
