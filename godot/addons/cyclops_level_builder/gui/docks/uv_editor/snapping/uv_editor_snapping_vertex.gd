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
extends UvEditorSnappingNode
class_name UvEditorSnappingVertex

@export var icon:Texture2D = preload("res://addons/cyclops_level_builder/art/icons/snap_vertex.svg")

@export var snap_radius_pixels:float = 10

func snap_point(point:Vector2, exclude_uvs:Dictionary)->Vector2:
	var best_snap_dist_sq:float = INF
	var best_snap_value:Vector2 = point
	
	if view_uv_editor:
		var uv_ed:UvEditor = view_uv_editor.get_uv_editor()
		var uv_to_view_xform:Transform2D = uv_ed.get_uv_to_viewport_xform()
		
		var builder = view_uv_editor.plugin
		for block:CyclopsBlock in builder.get_selected_blocks():
			print("vertex snap scanning ", block.name)
			var block_path:NodePath = block.get_path()
			var mvd:MeshVectorData = block.mesh_vector_data
			
			var uv_arr:DataVectorFloat = mvd.get_face_vertex_data(MeshVectorData.FV_UV0)
			var sel_vec:DataVectorByte = mvd.get_face_vertex_data(MeshVectorData.FV_SELECTED)

			for i in uv_arr.num_components():
				if sel_vec.get_value(i):
					continue
				
				if block_path in exclude_uvs && exclude_uvs[block_path].has(i):
					#print("blocking ", block_path, " ", i)
					continue
					
				var val:Vector2 = uv_arr.get_value_vec2(i)
				var offset:Vector2 = val - point
				var offset_view:Vector2 = uv_to_view_xform.x * offset.x + uv_to_view_xform.y * offset.y
				var offset_view_dist_sq:float = offset_view.length_squared()

				print("check mesh uv ", val)
				
				var dist_sq:float = val.distance_squared_to(point)
#				if dist_sq < best_snap_dist_sq && offset_view_dist_sq <= snap_radius_pixels * snap_radius_pixels:
				if dist_sq < best_snap_dist_sq:
					best_snap_dist_sq = dist_sq
					best_snap_value = val
		
		return best_snap_value
		
	return point
	
func get_editor()->UvEditorSnappingVertexEditor:
	var ed:UvEditorSnappingVertexEditor = preload("res://addons/cyclops_level_builder/gui/docks/uv_editor/snapping/uv_editor_snapping_vertex_editor.tscn").instantiate()
	ed.settings = self
	return ed
