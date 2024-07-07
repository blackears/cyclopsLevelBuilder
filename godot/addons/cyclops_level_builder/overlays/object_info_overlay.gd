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
extends CyclopsOverlayObject
class_name ObjectInfoOverlay

@export var show_edge_length:bool:
	set(value):
		if show_edge_length == value:
			return
		show_edge_length = value
		
		if plugin:
			plugin.update_overlays()


func get_edge_label_locations(viewport_camera:Camera3D)->Array:
	var result:Array
	
	var sel_blocks:Array[CyclopsBlock] = plugin.get_selected_blocks()
	var pick_origin:Vector3 = viewport_camera.global_position
	
	for block in sel_blocks:
		
		var control_mesh = block.control_mesh
		if control_mesh:
			#var edges:Array[ConvexVolume.EdgeInfo] = control_mesh.get_camera_facing_edges(viewport_camera, block.global_transform)
			for e in control_mesh.edges:
				var focus:Vector3 = e.get_midpoint()
				var focus_world:Vector3 = block.global_transform * focus
				
				if viewport_camera.is_position_behind(focus_world):
					continue
					
				var res:IntersectResults = plugin.intersect_ray_closest(pick_origin, focus_world - pick_origin)
				
				if res:
					if res.object != block:
						continue
						
					var hit:bool = false
					for f_idx in e.face_indices:
						if f_idx == res.face_index:
							hit = true
							break
							
					if !hit:
						continue
				
				var focus_2d:Vector2 = viewport_camera.unproject_position(focus_world)
				
				var v0:ConvexVolume.VertexInfo = control_mesh.vertices[e.start_index]
				var v1:ConvexVolume.VertexInfo = control_mesh.vertices[e.end_index]
				
				var length:float = v0.point.distance_to(v1.point)
				
				result.append({
					"block": block,
					"edge": e,
					"center_3d": focus_world,
					"center_2d": focus_2d,
					"length": length
				})
	
	return result


func get_editor_control()->Control:
	var ed:ObjectInfoOverlayEditor = preload("res://addons/cyclops_level_builder/overlays/object_info_overlay_editor.tscn").instantiate()
	ed.overlay = self
	return ed

func _draw_overlay(view_control:Control, viewport_index:int)->void:
	#print("_draw_overlay")
	
	#Display edge lengths
	if show_edge_length:
		var global_scene:CyclopsGlobalScene = plugin.get_node("/root/CyclopsAutoload")

		var font:Font = global_scene.units_font
		var font_size:float = global_scene.units_font_size	
		var descent:float = font.get_descent(font_size)
		var text_offset:Vector2 = Vector2(0, -global_scene.vertex_radius - descent)
		
		var viewport:Viewport = EditorInterface.get_editor_viewport_3d(viewport_index)
		var viewport_camera:Camera3D = viewport.get_camera_3d()
		
		var edge_pos:Array = get_edge_label_locations(viewport_camera)
		for p:Dictionary in edge_pos:
			var len:float = p["length"]
			var pos:Vector2 = p["center_2d"]
			
			view_control.draw_string(font, pos, str(snappedf(len, .001)), HORIZONTAL_ALIGNMENT_LEFT)
	
