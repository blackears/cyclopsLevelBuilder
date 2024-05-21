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
class_name CyclopsFileLoader
extends RefCounted

class BufferRegion:
	var start:int
	var length:int
	var buffer_id:int

var buffer_archive:BufferArchive = BufferArchive.new()

var buffer_map:Dictionary
var buffer_region_map:Dictionary
var object_map:Dictionary
var node_map:Dictionary
var scene_map:Dictionary

var plugin:CyclopsLevelBuilder

func load(root:Dictionary):
	for buf_dict in root["buffers"]:
		var buf_id:int = buf_dict["id"]
		var buf_size:int = buf_dict["byte_length"]
		var text:String = buf_dict["data_buffer"]
		var zip_buf:PackedByteArray = Marshalls.base64_to_raw(text)
		var buf:PackedByteArray = zip_buf.decompress(buf_size)
		
		var ba:BufferArchive = BufferArchive.new()
		ba.buffer = buf
		buffer_map[buf_id] = ba

	for reg_dict in root["buffer_regions"]:
		var reg:BufferRegion = BufferRegion.new()
		var id:int = reg_dict["id"]
		reg.start = reg_dict["start"]
		reg.length = reg_dict["length"]
		reg.buffer_id = reg_dict["buffer_id"]
		
		buffer_region_map[id] = reg
	
	for obj_dict in root["objects"]:
		var id:int = obj_dict["id"]
		var type:String = obj_dict["type"]
		var body:Dictionary = obj_dict["body"]
		
		var object_node
		match type:
			"convex_block":
				object_node = load_convex_block(body)

		if object_node:
			object_map[id] = object_node
	
	for node_dict in root["nodes"]:
		var id:int = node_dict["id"]
		var node:Node3D
		if node_dict.has("object"):
			var obj_id:int = node_dict["object"]
			node = object_map[obj_id]
		else:
			node = Node3D.new()
		
		node_map[id] = node
		
		if node_dict.has("name"):
			node.name = node_dict["name"]
		
		if node_dict.has("visible"):
			node.visible = node_dict["visible"]
		if node_dict.has("basis"):
			var a:Array = node_dict["basis"]
			var basis:Basis = Basis(Vector3(a[0], a[1], a[2]), Vector3(a[3], a[4], a[5]), Vector3(a[6], a[7], a[8]))
			node.basis = basis
		if node_dict.has("translate"):
			var a:Array = node_dict["translate"]
			node.position = Vector3(a[0], a[1], a[2])
	
	for node_dict in root["nodes"]:
		var id:int = node_dict["id"]
		var node:Node3D = node_map[id]
		
		if node_dict.has("children"):
			for child_idx in node_dict["children"]:
				
				var child_node:Node3D = node_map[int(child_idx)]
				node.add_child(child_node)
		
	for scene_dict in root["scenes"]:
		var id:int = scene_dict["id"]
		var root_id:int = scene_dict["root"]
		scene_map[id] = root_id
		

func load_convex_block(body_dict:Dictionary)->CyclopsBlock:
	var block:CyclopsBlock = preload("res://addons/cyclops_level_builder/nodes/cyclops_block.gd").new()
	#blocks_root.add_child(block)
	#block.owner = builder.get_editor_interface().get_edited_scene_root()
	#block.name = GeneralUtil.find_unique_name(blocks_root, block_name_prefix)
	
	block.collision_type = Collision.Type.get(body_dict["collision_type"])
	block.collision_layer = body_dict["collision_layer"]
	block.collision_mask = body_dict["collision_mask"]
	
	for mat_res_path in body_dict["materials"]:
		var res = ResourceLoader.load(mat_res_path)
		block.materials.append(res)

	if body_dict.has("mesh"):
		var mesh_dict:Dictionary = body_dict["mesh"]
		var mesh:MeshVectorData = MeshVectorData.new()
		mesh.num_vertices = mesh_dict["num_vertices"]
		mesh.num_edges = mesh_dict["num_edges"]
		mesh.num_faces = mesh_dict["num_faces"]
		mesh.num_face_vertices = mesh_dict["num_face_vertices"]
		mesh.active_vertex = mesh_dict["active_vertex"]
		mesh.active_edge = mesh_dict["active_edge"]
		mesh.active_face = mesh_dict["active_face"]
		mesh.active_face_vertex = mesh_dict["active_face_vertex"]
		
		mesh.edge_vertex_indices = load_buffer(mesh_dict["edge_vertex_index_buffer"]).to_int32_array()
		mesh.edge_face_indices = load_buffer(mesh_dict["edge_face_index_buffer"]).to_int32_array()
		mesh.face_vertex_count = load_buffer(mesh_dict["face_vertex_count_buffer"]).to_int32_array()
		mesh.face_vertex_indices = load_buffer(mesh_dict["face_vertex_index_buffer"]).to_int32_array()

		for vec_dict in mesh_dict["vectors"]["vertices"]:
			var vec:DataVector = load_data_vector(vec_dict)
			mesh.vertex_data[vec.name] = vec

		for vec_dict in mesh_dict["vectors"]["edges"]:
			var vec:DataVector = load_data_vector(vec_dict)
			mesh.edge_data[vec.name] = vec

		for vec_dict in mesh_dict["vectors"]["faces"]:
			var vec:DataVector = load_data_vector(vec_dict)
			mesh.face_data[vec.name] = vec

		for vec_dict in mesh_dict["vectors"]["face_vertices"]:
			var vec:DataVector = load_data_vector(vec_dict)
			mesh.face_vertex_data[vec.name] = vec
		
		block.mesh_vector_data = mesh
	
	return block

#enum DataType { BOOL, INT, FLOAT, STRING, COLOR, VECTOR2, VECTOR3, VECTOR4, TRANSFORM_2D, TRANSFORM_3D }

func load_data_vector(vec_dict)->DataVector:
	match vec_dict["data_type"]:
		"BOOL":
			var buf:PackedByteArray = load_buffer(vec_dict["data_buffer"])
			return DataVectorByte.new(vec_dict["name"], buf, DataVector.DataType.BOOL)
		"INT":
			var buf:PackedInt32Array = load_buffer(vec_dict["data_buffer"]).to_int32_array()
			return DataVectorInt.new(vec_dict["name"], buf, DataVector.DataType.INT)
		"FLOAT":
			var buf:PackedFloat32Array = load_buffer(vec_dict["data_buffer"]).to_float32_array()
			return DataVectorFloat.new(vec_dict["name"], buf, DataVector.DataType.FLOAT)
		"STRING":
			var buf:PackedStringArray = bytes_to_var(load_buffer(vec_dict["data_buffer"]))
			return DataVectorString.new(vec_dict["name"], buf, DataVector.DataType.STRING)
		"COLOR":
			var buf:PackedFloat32Array = load_buffer(vec_dict["data_buffer"]).to_float32_array()
			return DataVectorFloat.new(vec_dict["name"], buf, DataVector.DataType.COLOR)
		"TRANSFORM_2D":
			var buf:PackedFloat32Array = load_buffer(vec_dict["data_buffer"]).to_float32_array()
			return DataVectorFloat.new(vec_dict["name"], buf, DataVector.DataType.TRANSFORM_2D)
		"TRANSFORM_3D":
			var buf:PackedFloat32Array = load_buffer(vec_dict["data_buffer"]).to_float32_array()
			return DataVectorFloat.new(vec_dict["name"], buf, DataVector.DataType.TRANSFORM_3D)
		"VECTOR2":
			var buf:PackedFloat32Array = load_buffer(vec_dict["data_buffer"]).to_float32_array()
			return DataVectorFloat.new(vec_dict["name"], buf, DataVector.DataType.VECTOR2)
		"VECTOR3":
			var buf:PackedFloat32Array = load_buffer(vec_dict["data_buffer"]).to_float32_array()
			return DataVectorFloat.new(vec_dict["name"], buf, DataVector.DataType.VECTOR3)
		"VECTOR4":
			var buf:PackedFloat32Array = load_buffer(vec_dict["data_buffer"]).to_float32_array()
			return DataVectorFloat.new(vec_dict["name"], buf, DataVector.DataType.VECTOR4)
		_:
			return null
			

func load_buffer(buf_id:int)->PackedByteArray:
	var buf_reg:BufferRegion = buffer_region_map[buf_id]
	var buf_src:BufferArchive = buffer_map[buf_reg.buffer_id]
	return buf_src.buffer.slice(buf_reg["start"], buf_reg["start"] + buf_reg["length"])
