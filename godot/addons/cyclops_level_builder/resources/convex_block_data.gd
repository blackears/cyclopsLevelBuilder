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
class_name ConvexBlockData

@export var selected:bool = false
@export var active:bool = false
@export var collision:bool = true
@export_flags_3d_physics var physics_layer:int
@export_flags_3d_physics var physics_mask:int

@export var vertex_points:PackedVector3Array  #Per vertex
@export var vertex_selected:PackedByteArray  #Per vertex

@export var edge_selected:PackedByteArray

@export var face_material_indices:PackedInt32Array #Material index for each face
@export var face_uv_transform:Array[Transform2D]
@export var face_visible:PackedByteArray
@export var face_color:PackedColorArray
@export var face_selected:PackedByteArray  #Per face

@export var face_vertex_face_index:PackedInt32Array  #Face index of this face-vertex
@export var face_vertex_vertex_index:PackedInt32Array  #Vertex index of this face-vertex
@export var face_vertex_normal:PackedVector3Array  #Per face-vertex
@export var face_vertex_color:PackedColorArray  #Per face-vertex


@export var edge_vertex_indices:PackedInt32Array
@export var edge_face_indices:PackedInt32Array

@export var face_vertex_count:PackedInt32Array #Number of verts in each face
@export var face_vertex_indices:PackedInt32Array #Vertex indices encountered as you iterate over mesh one face at a time and each vertex per face

@export var active_vertex:int
@export var active_edge:int
@export var active_face:int
@export var active_face_vertex:int

	
#Validate arrays to make sure they're the right size
#@deprecated
func validate_arrays():
	#print("deprecated validate_arrays")
	var num_faces:int = face_vertex_count.size()

	if face_visible.size() < num_faces:
		var arr:PackedByteArray
		arr.resize(num_faces - face_visible.size())
		arr.fill(true)
		face_visible.append_array(arr)
		

	if face_color.size() < num_faces:
		var arr:PackedColorArray
		arr.resize(num_faces - face_color.size())
		arr.fill(Color.WHITE)
		face_color.append_array(arr)
		
func init_from_mesh_vector_data(mvd:MeshVectorData):

	active_vertex = mvd.active_vertex
	active_edge = mvd.active_edge
	active_face = mvd.active_face
	active_face_vertex = mvd.active_face_vertex
	
	#selected = mvd.selected
	#active = mvd.active
	#collision = mvd.collision
	#physics_layer = mvd.physics_layer
	#physics_mask = mvd.physics_mask
	
	var v_pos:DataVectorFloat = mvd.get_vertex_data(MeshVectorData.V_POSITION)
	vertex_points = v_pos.to_vec3_array()
	
	var v_sel:DataVectorByte = mvd.get_vertex_data(MeshVectorData.V_SELECTED)
	vertex_selected = v_sel.data
	
	var e_sel:DataVectorByte = mvd.get_edge_data(MeshVectorData.E_SELECTED)
	edge_selected = e_sel.data
	
	var f_mat:DataVectorInt = mvd.get_face_data(MeshVectorData.F_MATERIAL_INDEX)
	face_material_indices = f_mat.data
	
#	print("+build convex_block_data")
	var f_uv_xform:DataVectorFloat = mvd.get_face_data(MeshVectorData.F_UV_XFORM)
	face_uv_transform = f_uv_xform.to_transform2d_array()
#	print("-build convex_block_data")
	
	var f_vis:DataVectorByte = mvd.get_face_data(MeshVectorData.F_VISIBLE)
	face_visible = f_vis.data
	
	var f_col:DataVectorFloat = mvd.get_face_data(MeshVectorData.F_COLOR)
	face_color = f_col.to_color_array()
	
	var f_sel:DataVectorByte = mvd.get_face_data(MeshVectorData.F_SELECTED)
	face_selected = f_sel.data
	
	var fv_fidx:DataVectorInt = mvd.get_face_vertex_data(MeshVectorData.FV_FACE_INDEX)
	face_vertex_face_index = fv_fidx.data
	
	var fv_vidx:DataVectorInt = mvd.get_face_vertex_data(MeshVectorData.FV_VERTEX_INDEX)
	face_vertex_vertex_index = fv_vidx.data
	
	var fv_norm:DataVectorFloat = mvd.get_face_vertex_data(MeshVectorData.FV_NORMAL)
	face_vertex_normal = fv_norm.to_vec3_array()
	
	var fv_col:DataVectorFloat = mvd.get_face_vertex_data(MeshVectorData.FV_COLOR)
	face_vertex_color = fv_col.to_color_array()

	edge_vertex_indices = mvd.edge_vertex_indices
	edge_face_indices = mvd.edge_face_indices
	face_vertex_count = mvd.face_vertex_count
	face_vertex_indices = mvd.face_vertex_indices
	
