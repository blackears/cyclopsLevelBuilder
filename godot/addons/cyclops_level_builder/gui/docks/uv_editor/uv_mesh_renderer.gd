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
extends Node3D

@export var face_sel_color:Color = Color(1, .5, 0, .2)
@export var face_unsel_color:Color = Color(.5, .5, .5, .2)
@export var edge_sel_color:Color = Color(1, .5, 0, 1)
@export var edge_unsel_color:Color = Color(.5, .5, .5, 1)

@export var block_nodes:Array[CyclopsBlock]:
	set(value):
		block_nodes = value
		dirty = true
		
var dirty:bool = true

#func build_mesh():
	#var uv_mesh_faces_mat:ShaderMaterial = preload("res://addons/cyclops_level_builder/gui/docks/uv_editor/uv_mesh_faces_material.tres")
	#var uv_mesh_edges_mat:ShaderMaterial = preload("res://addons/cyclops_level_builder/gui/docks/uv_editor/uv_mesh_edges_material.tres")
	#
	#var cv:ConvexVolume = ConvexVolume.new()
	#var mesh_faces:ArrayMesh = create_mesh_faces(cv, uv_mesh_faces_mat, face_sel_color, face_unsel_color)
	#
	#var mesh_edges:ArrayMesh = create_mesh_edges(cv, uv_mesh_edges_mat, edge_sel_color, edge_unsel_color)
	#
	#%mesh_faces.mesh = mesh_faces
	#%mesh_edges.mesh = mesh_edges
	#pass


func create_mesh_faces(cv:ConvexVolume, material:Material, 
	sel_color:Color = Color.ORANGE, 
	unsel_color:Color = Color.GRAY, 
	selected_faces_only:bool = false)->ArrayMesh:

	var mesh:ArrayMesh = ArrayMesh.new()

	var indices:PackedInt32Array
	var points_indexed:PackedVector3Array
	var uvs_indexed:PackedVector2Array
	var colors_indexed:PackedColorArray

	for f:ConvexVolume.FaceInfo in cv.faces:
		if selected_faces_only && !f.selected:
			continue
		
		var color:Color = sel_color if f.selected else unsel_color
		
		for local_fv_idx_0:int in f.face_vertex_indices.size():
			
			var fv0:ConvexVolume.FaceVertexInfo = cv.face_vertices[f.face_vertex_indices[local_fv_idx_0]]
			var v0:ConvexVolume.VertexInfo = cv.vertices[fv0.vertex_index]
			
			points_indexed.append(v0.point)
			uvs_indexed.append(fv0.uv0)
			colors_indexed.append(color)
			indices.append(indices.size())
		
	var arrays:Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points_indexed
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_TEX_UV] = uvs_indexed
	arrays[Mesh.ARRAY_COLOR] = colors_indexed
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	mesh.surface_set_material(0, material)
	
	return mesh

func create_mesh_edges(cv:ConvexVolume, material:Material, 
	edge_sel_color:Color = Color.ORANGE, 
	edge_unsel_color:Color = Color.GRAY, 
	selected_faces_only:bool = false)->ArrayMesh:

	var mesh:ArrayMesh = ArrayMesh.new()

	var indices:PackedInt32Array
	var points_indexed:PackedVector3Array
	var uvs_indexed:PackedVector2Array
	var colors_indexed:PackedColorArray

	for f:ConvexVolume.FaceInfo in cv.faces:
		if selected_faces_only && !f.selected:
			continue
		
		for local_fv_idx_0:int in f.face_vertex_indices.size():
			var local_fv_idx_1:int = wrap(local_fv_idx_0 + 1, 0, f.face_vertex_indices.size())
			
			var fv0:ConvexVolume.FaceVertexInfo = cv.face_vertices[f.face_vertex_indices[local_fv_idx_0]]
			var fv1:ConvexVolume.FaceVertexInfo = cv.face_vertices[f.face_vertex_indices[local_fv_idx_1]]
			
			var e:ConvexVolume.EdgeInfo = cv.get_edge(fv0.index, fv1.index)
			var color:Color = edge_sel_color if e.selected else edge_unsel_color
			
			var v0:ConvexVolume.VertexInfo = cv.vertices[fv0.vertex_index]
			var v1:ConvexVolume.VertexInfo = cv.vertices[fv1.vertex_index]
			
			colors_indexed.append(color)
			colors_indexed.append(color)

			uvs_indexed.append(fv0.uv0)
			uvs_indexed.append(fv1.uv0)
			
			points_indexed.append(v0.point)
			points_indexed.append(v1.point)
			
			indices.append(indices.size())
			indices.append(indices.size())
			
		
	var arrays:Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points_indexed
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_TEX_UV] = uvs_indexed
	arrays[Mesh.ARRAY_COLOR] = colors_indexed
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	mesh.surface_set_material(0, material)
	
	return mesh

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if dirty:
#		print("rebuild uv editor")
		var uv_mesh_faces_mat:ShaderMaterial = preload("res://addons/cyclops_level_builder/gui/docks/uv_editor/uv_mesh_faces_material.tres")
		var uv_mesh_edges_mat:ShaderMaterial = preload("res://addons/cyclops_level_builder/gui/docks/uv_editor/uv_mesh_edges_material.tres")
		
		for child in %meshes.get_children():
			%meshes.remove_child(child)
			child.queue_free()
		
		for node:CyclopsBlock in block_nodes:
			var mvd:MeshVectorData = node.mesh_vector_data
			var cv:ConvexVolume = ConvexVolume.new()
			cv.init_from_mesh_vector_data(mvd)
			
			var face_mesh:MeshInstance3D = MeshInstance3D.new()
			%meshes.add_child(face_mesh)
			face_mesh.mesh = create_mesh_faces(cv, uv_mesh_faces_mat, face_sel_color, face_unsel_color)
			
			var edge_mesh:MeshInstance3D = MeshInstance3D.new()
			%meshes.add_child(edge_mesh)
			edge_mesh.mesh = create_mesh_faces(cv, uv_mesh_edges_mat, edge_sel_color, edge_unsel_color)
		
		dirty = false
	pass
