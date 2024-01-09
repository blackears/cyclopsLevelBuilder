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
extends CyclopsSnappingSystem
class_name SnappintSystemVertex

@export var max_radius:float = .2

var settings:SnappingSystemVertexSettings = SnappingSystemVertexSettings.new()

#Point is in world space
func _snap_point(point:Vector3, query:SnappingQuery)->Vector3:
		
	var screen_point:Vector2 = query.viewport_camera.unproject_position(point)
		
	var blocks:Array[CyclopsBlock] = plugin.get_blocks()
	
	var best_vertex:Vector3 = Vector3.INF
	var best_dist:float = INF
	
	#print("Exclude blocks ", query.exclude_blocks)
	for block in blocks:
		if query.exclude_blocks.has(block.get_path()):
			continue
		
		#print("check block ", block.name)
		var ctrl_mesh:ConvexVolume = block.control_mesh
		var bounds_local:AABB = ctrl_mesh.bounds
		
		var obj_center:Vector3 = block.global_transform * bounds_local.get_center()
		var obj_corner:Vector3 = block.global_transform * bounds_local.position
		var radius:float = obj_corner.distance_to(obj_center)
		var obj_offset:Vector3 = obj_center + query.viewport_camera.global_basis.x * radius
		
		var screen_obj_center:Vector2 = query.viewport_camera.unproject_position(obj_center)
		var screen_obj_offset:Vector2 = query.viewport_camera.unproject_position(obj_offset)
		
		#print("screen_point ", screen_point)
		#print("screen_obj_center ", screen_obj_center)
		#print("screen_obj_offset ", screen_obj_offset)
		#print("screen_point.distance_to(screen_obj_center) ", screen_point.distance_to(screen_obj_center))
		#print("screen_obj_center.distance_to(screen_obj_offset) ", screen_obj_center.distance_to(screen_obj_offset))
		if screen_point.distance_to(screen_obj_center) > \
			screen_obj_center.distance_to(screen_obj_offset) + settings.snap_radius:
			#Skip if bounding box text fails
			continue

		
		#print("snap block ", block.name)
		for v_idx in ctrl_mesh.vertices.size():
			var v:ConvexVolume.VertexInfo = ctrl_mesh.vertices[v_idx]
			var v_point_world:Vector3 = block.global_transform * v.point
			var v_point_screen:Vector2 = query.viewport_camera.unproject_position(v_point_world)
		
			var dist:float = v_point_screen.distance_to(screen_point)
			#print("dist ", dist, " settings.snap_radius ", settings.snap_radius)
			if dist > settings.snap_radius:
				continue
		
			#print("try vertex ", v_point_world)
			if dist < best_dist:
#			if dist < best_dist:
				best_vertex = v_point_world
				best_dist = dist

	
	return best_vertex if is_finite(best_dist) else point


func _get_properties_editor()->Control:
	var ed:SnappingSystemVertexPropertiesEditor = preload("res://addons/cyclops_level_builder/snapping/snapping_system_vertex_properties_editor.tscn").instantiate()
	ed.settings = settings
	
	return ed
	

