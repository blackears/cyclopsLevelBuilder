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
class_name ToolVertexColorBrush

enum ToolState { READY, PAINTING }
var tool_state:ToolState = ToolState.READY

const TOOL_ID:String = "vertex_color_brush"

var cmd:CommandVertexPaintStroke

var settings:ToolVertexColorBrushSettings = ToolVertexColorBrushSettings.new()

var last_mouse_pos:Vector2

var brush_over_mesh:bool = false
var last_hit_pos:Vector3

func _get_tool_id()->String:
	return TOOL_ID

func _draw_tool(viewport_camera:Camera3D):
	var global_scene:CyclopsGlobalScene = builder.get_global_scene()
	global_scene.clear_tool_mesh()
	global_scene.draw_selected_blocks(viewport_camera)

	#super._draw_tool(viewport_camera)

	if brush_over_mesh:
		var view_dir:Vector3 = viewport_camera.global_transform.basis.z
		var bounding_points:PackedVector3Array = \
			MathUtil.create_circle_points(last_hit_pos, view_dir.normalized(), settings.radius, 16)
		global_scene.draw_loop(bounding_points, true, global_scene.tool_material)


func _get_tool_properties_editor()->Control:
	var ed:ToolVertexColorBrushSettingsEditor = preload("res://addons/cyclops_level_builder/tools/tool_vertex_color_brush_settings_editor.tscn").instantiate()

	ed.settings = settings

	return ed


func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:

	if event is InputEventKey:
		var e:InputEventKey = event
		
		if e.keycode == KEY_X:
			if e.shift_pressed:
				if e.is_pressed():
					#Pick closest vertex color
					var origin:Vector3 = viewport_camera.project_ray_origin(last_mouse_pos)
					var dir:Vector3 = viewport_camera.project_ray_normal(last_mouse_pos)

					var result:IntersectResults = builder.intersect_ray_closest(origin, dir)

					if result:
						var block:CyclopsBlock = result.object
						result.face_index
						
						var vol:ConvexVolume = ConvexVolume.new()
						vol.init_from_mesh_vector_data(block.mesh_vector_data)
						
						var face:ConvexVolume.FaceInfo = vol.faces[result.face_index]
						var v_idx:int = face.get_closest_vertex(result.position)
						var vert:ConvexVolume.VertexInfo = vol.vertices[v_idx]
					
						var fv:ConvexVolume.FaceVertexInfo = vol.get_face_vertex(result.face_index, v_idx)
						#print("sample color ", fv.color)
					
						settings.color = fv.color

			return true
			

		elif e.keycode == KEY_Q:

			if e.is_pressed():
				select_block_under_cursor(viewport_camera, last_mouse_pos)
				
			return true

	elif event is InputEventMouseButton:

		var e:InputEventMouseButton = event
		if e.button_index == MOUSE_BUTTON_LEFT:

			if e.is_pressed():

				if tool_state == ToolState.READY:
					#print("vertex color brush bn down")
						
					var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
					var dir:Vector3 = viewport_camera.project_ray_normal(e.position)

					var result:IntersectResults = builder.intersect_ray_closest(origin, dir)
					
					var sel_blocks:Array[CyclopsBlock] = builder.get_selected_blocks()
#					if result && result.object == builder.get_active_block():
					if result && sel_blocks.has(result.object):
						#print("starting paint")
						cmd = CommandVertexPaintStroke.new()
						cmd.builder = builder

						cmd.append_block(result.object.get_path())
						cmd.color = settings.color
						cmd.strength = settings.strength
						cmd.radius = settings.radius
						cmd.falloff_curve = settings.falloff_curve.duplicate()
						cmd.mask = settings.mask_type
						
						var pos:Vector3 = result.get_world_position()
						#print("pos ", pos)
						cmd.append_stroke_point(pos, 1)


						cmd.do_it()
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

		var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
		var dir:Vector3 = viewport_camera.project_ray_normal(e.position)

		var result:IntersectResults = builder.intersect_ray_closest(origin, dir)
		
		if result:
			brush_over_mesh = true
			last_hit_pos = result.object.global_transform * result.position
		else:
			brush_over_mesh = false

		if tool_state == ToolState.PAINTING:

			if result:
				#print ("hit ", result.object.name)
				cmd.undo_it()
				
				cmd.append_stroke_point(result.get_world_position(), \
					e.pressure if settings.pen_pressure_strength else 1)

				cmd.do_it()

			return true

	return false


func _activate(builder:CyclopsLevelBuilder):
	super._activate(builder)

	var cache:Dictionary = builder.get_tool_cache(TOOL_ID)
	settings.load_from_cache(cache)

func _deactivate():
	var cache:Dictionary = settings.save_to_cache()
	builder.set_tool_cache(TOOL_ID, cache)
