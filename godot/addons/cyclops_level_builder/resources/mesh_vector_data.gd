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
class_name MeshVectorData


@export var selected:bool = false
@export var active:bool = false
@export var collision:bool = true
@export_flags_3d_physics var physics_layer:int
@export_flags_3d_physics var physics_mask:int

@export var num_vertices:int
@export var num_edges:int
@export var num_faces:int
@export var num_face_vertices:int

@export var active_vertex:int
@export var active_edge:int
@export var active_face:int
@export var active_face_vertex:int


@export var edge_vertex_indices:PackedInt32Array
@export var edge_face_indices:PackedInt32Array

@export var face_vertex_count:PackedInt32Array #Number of verts in each face
@export var face_vertex_indices:PackedInt32Array #Vertex index per face

var vertex_data:Dictionary
var edge_data:Dictionary
var face_data:Dictionary
var face_vertex_data:Dictionary

const V_POSITION: StringName = "position"
const V_SELECTED: StringName = "selected"
const V_COLOR: StringName = "color"

const E_SELECTED: StringName = "selected"

const F_MATERIAL_INDEX: StringName = "material_index"
const F_UV_XFORM: StringName = "uv_transform"
const F_VISIBLE: StringName = "visible"
const F_COLOR: StringName = "color"
const F_SELECTED: StringName = "selected"

const FV_VERTEX_INDEX: StringName = "vertex_index"
const FV_FACE_INDEX: StringName = "face_index"
const FV_VERTEX_LOCAL_INDEX: StringName = "vertex_local_index"
const FV_SELECTED: StringName = "selected"
const FV_COLOR: StringName = "color"
const FV_UV1: StringName = "uv1"
const FV_UV2: StringName = "uv2"


func create_from_convex_block(block_data:ConvexBlockData):

	selected = block_data.selected
	active = block_data.active
	collision = block_data.collision
	physics_layer = block_data.physics_layer
	physics_mask = block_data.physics_mask
	
	
	num_vertices = block_data.vertex_points.size()
	num_edges = block_data.edge_vertex_indices.size() / 2
	num_faces = block_data.face_vertex_count.size()
	
	set_vertex_data(DataVectorFloat.new(V_POSITION, 
		block_data.vertex_points.to_byte_array().to_float32_array(), 
		DataVector.DataType.VECTOR3,
		3))

	set_vertex_data(DataVectorByte.new(V_SELECTED, 
		block_data.vertex_selected, 
		DataVector.DataType.BOOL))

	set_edge_data(DataVectorByte.new(E_SELECTED, 
		block_data.edge_selected, 
		DataVector.DataType.BOOL))

	set_face_data(DataVectorInt.new(F_MATERIAL_INDEX, 
		block_data.face_material_indices, 
		DataVector.DataType.INT))

	set_face_data(DataVectorByte.new(F_VISIBLE, 
		block_data.face_visible, 
		DataVector.DataType.BOOL))
		
		
	set_face_data(DataVectorByte.new(F_SELECTED, 
		block_data.face_selected, 
		DataVector.DataType.BOOL))

	set_face_data(DataVectorFloat.new(F_COLOR, 
		block_data.face_color.to_byte_array().to_float32_array(), 
		DataVector.DataType.COLOR, 
		4))

	
	#Create face-vertex data
	edge_vertex_indices = block_data.edge_vertex_indices
	edge_face_indices = block_data.edge_face_indices
	face_vertex_count = block_data.face_vertex_count
	face_vertex_indices = block_data.face_vertex_indices
	
	num_face_vertices = 0
	for n in block_data.face_vertex_count:
		num_face_vertices += n

	var fv_array_offset:int = 0
	var next_fv_idx:int = 0
	var face_indices:PackedInt32Array
	var vert_indices:PackedInt32Array

#@export var edge_vertex_indices:PackedInt32Array
#@export var edge_face_indices:PackedInt32Array
#
#@export var face_vertex_count:PackedInt32Array #Number of verts in each face
#@export var face_vertex_indices:PackedInt32Array #Vertex index per face

	
	for f_idx in block_data.face_vertex_count.size():
		var num_verts_in_face:int = block_data.face_vertex_count[f_idx]
		for fv_local_idx in num_verts_in_face:
			var v_idx:int = block_data.face_vertex_indices[fv_array_offset + fv_local_idx]
			
			face_indices.append(f_idx)
			vert_indices.append(v_idx)
			
		fv_array_offset += num_verts_in_face
	

	set_face_vertex_data(DataVectorInt.new(FV_FACE_INDEX, 
		face_indices, 
		DataVector.DataType.INT))

	set_face_vertex_data(DataVectorInt.new(FV_VERTEX_INDEX, 
		vert_indices, 
		DataVector.DataType.INT))

	#set_face_vertex_data(DataVectorInt.new(FV_VERTEX_LOCAL_INDEX, 
		#fv_local_indices, 
		#DataVector.DataType.INT))
	
	var col_fv_data:PackedColorArray
	for fv_idx in num_face_vertices:
		var f_idx:int = face_indices[fv_idx]
		var v_idx:int = vert_indices[fv_idx]
		col_fv_data.append(block_data.face_color[f_idx])
		

	set_face_vertex_data(DataVectorFloat.new(FV_COLOR, 
		col_fv_data.to_byte_array().to_float32_array(), 
		DataVector.DataType.COLOR, 
		4))
			


func set_vertex_data(data_vector:DataVector):
	#print("set_vertex_data ", var_to_str(data_vector))
	#print("data_vector.name ", data_vector.name)
	vertex_data[data_vector.name] = data_vector

func set_edge_data(data_vector:DataVector):
	edge_data[data_vector.name] = data_vector

func set_face_data(data_vector:DataVector):
	face_data[data_vector.name] = data_vector
	
func set_face_vertex_data(data_vector:DataVector):
	face_vertex_data[data_vector.name] = data_vector

func validate()->bool:
	return true
	

func create_vector_xml_node(name:String, type:String, value:String)->XMLElement:
	var evi_ele:XMLElement = XMLElement.new("vector")
	evi_ele.set_attribute("name", name)
	evi_ele.set_attribute("type", type)
	evi_ele.set_attribute("value", value)
	return evi_ele
	
func section_to_xml(type:String, vertex_data:Dictionary)->XMLElement:
	var sec_vertex_ele:XMLElement = XMLElement.new("section")
	sec_vertex_ele.set_attribute("type", type)

	for vec_name in vertex_data.keys():
		var v:DataVector = vertex_data[vec_name]
		match v.data_type:
			DataVector.DataType.BOOL:
				sec_vertex_ele.add_child(create_vector_xml_node(v.name, "bool", var_to_str(v.data)))
			DataVector.DataType.INT:
				sec_vertex_ele.add_child(create_vector_xml_node(v.name, "int", var_to_str(v.data)))
			DataVector.DataType.FLOAT:
				sec_vertex_ele.add_child(create_vector_xml_node(v.name, "float", var_to_str(v.data)))
			DataVector.DataType.STRING:
				sec_vertex_ele.add_child(create_vector_xml_node(v.name, "string", var_to_str(v.data)))
			DataVector.DataType.COLOR:
				sec_vertex_ele.add_child(create_vector_xml_node(v.name, "color", var_to_str(v.data)))
			DataVector.DataType.VECTOR2:
				sec_vertex_ele.add_child(create_vector_xml_node(v.name, "vector2", var_to_str(v.data)))
			DataVector.DataType.VECTOR3:
				sec_vertex_ele.add_child(create_vector_xml_node(v.name, "vector3", var_to_str(v.data)))
			DataVector.DataType.VECTOR4:
				sec_vertex_ele.add_child(create_vector_xml_node(v.name, "vector4", var_to_str(v.data)))
			DataVector.DataType.TRANSFORM_2D:
				sec_vertex_ele.add_child(create_vector_xml_node(v.name, "transform2D", var_to_str(v.data)))
			DataVector.DataType.TRANSFORM_3D:
				sec_vertex_ele.add_child(create_vector_xml_node(v.name, "transform3D", var_to_str(v.data)))
	
	return sec_vertex_ele
		
func to_xml()->XMLElement:
	var rec_ele:XMLElement = XMLElement.new("record")
	rec_ele.set_attribute("type", "mesh")
	
	rec_ele.set_attribute("selected", str(selected))
	rec_ele.set_attribute("active", str(active))
	rec_ele.set_attribute("collision", str(collision))
	
	rec_ele.set_attribute("physics_layer", str(physics_layer))
	rec_ele.set_attribute("physics_mask", str(physics_mask))

	rec_ele.set_attribute("num_vertices", str(num_vertices))
	rec_ele.set_attribute("num_edges", str(num_edges))
	rec_ele.set_attribute("num_faces", str(num_faces))
	rec_ele.set_attribute("num_face_vertices", str(num_face_vertices))


	rec_ele.add_child(create_vector_xml_node("edge_vertex_indices", "int", var_to_str(edge_vertex_indices)))
	rec_ele.add_child(create_vector_xml_node("edge_face_indices", "int", var_to_str(edge_face_indices)))
	rec_ele.add_child(create_vector_xml_node("face_vertex_count", "int", var_to_str(face_vertex_count)))
	rec_ele.add_child(create_vector_xml_node("face_vertex_indices", "int", var_to_str(face_vertex_indices)))

	rec_ele.set_attribute("active_vertex", str(active_vertex))
	rec_ele.set_attribute("active_edge", str(active_edge))
	rec_ele.set_attribute("active_face", str(active_face))
	rec_ele.set_attribute("active_face_vertex", str(active_face_vertex))
	
	var sec_vertex_ele:XMLElement = XMLElement.new("data")
	sec_vertex_ele.set_attribute("type", "vertex")
	rec_ele.add_child(sec_vertex_ele)

	rec_ele.add_child(section_to_xml("vertex", vertex_data))
	rec_ele.add_child(section_to_xml("edge", edge_data))
	rec_ele.add_child(section_to_xml("face", face_data))
	rec_ele.add_child(section_to_xml("faceVertex", face_vertex_data))
				
	
	return rec_ele
