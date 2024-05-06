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

var cmd:CommandSetMaterial

var settings:ToolMaterialBrushSettings = ToolMaterialBrushSettings.new()
var material_viewer_state:MaterialViewerState = preload("res://addons/cyclops_level_builder/docks/material_palette/material_viewer/material_viewer_state_res.tres")

var last_mouse_pos:Vector2

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

	if event is InputEventKey:
		var e:InputEventKey = event
		
		if e.keycode == KEY_X:
			if e.shift_pressed:
				if e.is_pressed():
					var origin:Vector3 = viewport_camera.project_ray_origin(last_mouse_pos)
					var dir:Vector3 = viewport_camera.project_ray_normal(last_mouse_pos)

					var result:IntersectResults = builder.intersect_ray_closest(origin, dir)

					if result:
						var block:CyclopsBlock = result.object
						result.face_index
						
						var vol:ConvexVolume = ConvexVolume.new()
						vol.init_from_mesh_vector_data(block.mesh_vector_data)
						
						var face:ConvexVolume.FaceInfo = vol.faces[result.face_index]
					
						#Sample under cursor
						if settings.paint_materials:
							if face.material_id != -1:
								#Pick this material
								#print("face.material_id ", face.material_id)
								var mat:Material = block.materials[face.material_id] \
									if face.material_id >= 0 && face.material_id < block.materials.size() \
									else null
								settings.material_path = mat.resource_path if mat else NodePath()
								#print("settings.material_path ", settings.material_path)
								
							
						if settings.paint_color:
							settings.color = face.color
							
						if settings.paint_visibility:
							settings.visibility = face.visible
							
						if settings.paint_uv:
							settings.uv_matrix = face.uv_transform

			return true
			
	elif event is InputEventMouseButton:

		var e:InputEventMouseButton = event
		if e.button_index == MOUSE_BUTTON_LEFT:

			if e.is_pressed():

				if tool_state == ToolState.READY:
					var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
					var dir:Vector3 = viewport_camera.project_ray_normal(e.position)

					var result:IntersectResults = builder.intersect_ray_closest(origin, dir)

					if result:
						cmd = CommandSetMaterial.new()
						cmd.builder = builder

						#print("settings.paint_materials ", settings.paint_materials)
						cmd.setting_material = settings.paint_materials
						
						cmd.material_path = settings.material_path \
							if !settings.erase_material else ""

						cmd.setting_color = settings.paint_color
						cmd.color = settings.color

						cmd.setting_visibility = settings.paint_visibility
						cmd.visibility = settings.visibility

						cmd.painting_uv = settings.paint_uv
						cmd.uv_matrix = settings.uv_matrix

						var block:CyclopsBlock = result.object
						
						if settings.individual_faces:
							cmd.add_target(block.get_path(), [result.face_index])

						else:
							cmd.add_target(block.get_path(), block.control_mesh.get_face_indices())

						tool_state = ToolState.PAINTING

			else:
				
				if tool_state == ToolState.PAINTING:
					cmd.undo_it()
					if cmd.will_change_anything():
						var undo:EditorUndoRedoManager = builder.get_undo_redo()
						cmd.add_to_undo_manager(undo)

					tool_state = ToolState.READY

			return true


	elif event is InputEventMouseMotion:

		var e:InputEventMouseMotion = event

		last_mouse_pos = e.position

		if tool_state == ToolState.PAINTING:
			var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
			var dir:Vector3 = viewport_camera.project_ray_normal(e.position)

			var result:IntersectResults = builder.intersect_ray_closest(origin, dir)

			if result:
				#print ("hit ", result.object.name)
				cmd.undo_it()
				var block:CyclopsBlock = result.object
				if settings.individual_faces:
					cmd.add_target(block.get_path(), [result.face_index])

				else:
					cmd.add_target(block.get_path(), block.control_mesh.get_face_indices())
				cmd.do_it()

			return true

	return false


func on_material_viewer_state_changed():
	#print("mat changed to ", material_viewer_state.active_material_path)
	settings.material_path = material_viewer_state.active_material_path


func _init():
	material_viewer_state.changed.connect(on_material_viewer_state_changed)

func _activate(builder:CyclopsLevelBuilder):
	super._activate(builder)

	var cache:Dictionary = builder.get_tool_cache(TOOL_ID)
	settings.load_from_cache(cache)
	settings.material_path = material_viewer_state.active_material_path
	
#	material_viewer_state.changed.connect(on_material_viewer_state_changed)

func _deactivate():
#	material_viewer_state.changed.disconnect(on_material_viewer_state_changed)
	
	var cache:Dictionary = settings.save_to_cache()
	builder.set_tool_cache(TOOL_ID, cache)



