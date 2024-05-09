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
class_name CyclopsFileBuilder 
extends RefCounted


#class ItemIndexer extends RefCounted:
	#var dict:Dictionary
	#
	#func get_or_create_id(node:Variant)->int:
		#if dict.has(node):
			#return dict[node]
		#
		#var id:int = dict.size()
		#dict[node] = id
		#return id
		
var plugin:CyclopsLevelBuilder
var buffer_archive:BufferArchive = BufferArchive.new()

#var doc:XMLDocument
#var root_ele:XMLElement
#var scenes_ele:XMLElement
#var nodes_ele:XMLElement
#var meshes_ele:XMLElement

var document:Dictionary
#var scenes_group:Dictionary
#var nodes_group:Dictionary
#var meshes_group:Dictionary
#var mesh_id_map:Dictionary
var node_indexer:ItemIndexer = ItemIndexer.new()
var mesh_indexer:ItemIndexer = ItemIndexer.new()
var buffer_region_indexer:ItemIndexer = ItemIndexer.new()

var buffer_region_map:Dictionary


func _init(plugin:CyclopsLevelBuilder):
	self.plugin = plugin

func create_json():

	var root:Node = plugin.get_editor_interface().get_edited_scene_root()

	document = {
		"header": [],
		"scenes": [],
		"nodes": [],
		"meshes": [],
		"buffer_regions": [],
		"buffers": []
	}
	
	document.header["exporter"] = "Cyclops Level Builder " + plugin.get_plugin_version()
	document.header["version"] = "1.0.0"

	var build_scene:Dictionary
	build_scene["root"] = root.name
	document.scenes.append(build_scene)

	export_scene_recursive(root)
	
	for key in buffer_region_map.keys():
		var region:BufferArchive.BufferRegion = key
		document.buffer_regions.append({
			"id": key,
			"start": region.start_byte,
			"length": region.length,
		})
	
	document.buffers.append({
		"id": 0,
		"buffer": Marshalls.raw_to_base64(buffer_archive.buffer.compress())
		})
	

func export_scene_recursive(cur_node:Node3D):
	if cur_node is Node3D:
		
		var build_node:Dictionary
		build_node["id"] = node_indexer.get_or_create_id(cur_node)
		build_node["name"] = cur_node.name
		document.nodes.append(build_node)

		if !cur_node.position.is_equal_approx(Vector3.ZERO):
			cur_node.set_attribute("translate", [cur_node.position.x, cur_node.position.y, cur_node.position.z])
		if !cur_node.transform.basis.is_equal_approx(Basis.IDENTITY):
			cur_node.set_attribute("basis", [
				cur_node.basis.x.x, cur_node.basis.x.y, cur_node.basis.x.z,
				cur_node.basis.y.x, cur_node.basis.y.y, cur_node.basis.y.z,
				cur_node.basis.z.x, cur_node.basis.z.y, cur_node.basis.z.z
				])

		var child_ids:Array[int]
		for local_child in cur_node.children:
			if local_child is Node3D:
				child_ids.append(node_indexer.get_or_create_id(local_child))
		if !child_ids.is_empty():
			build_node["children"] = child_ids

	
		for local_child in cur_node.children:
			if local_child is Node3D:
				export_scene_recursive(local_child)
		
		if cur_node is CyclopsBlock:
			var mesh_id:int = mesh_indexer.get_or_create_id(cur_node)
				
			build_node["mesh"] = mesh_id
			export_mesh_node(cur_node)
			pass
			
func export_mesh_node(cur_node:CyclopsBlock):
	var build_mesh:Dictionary
	document.meshes.append(build_mesh)
	
	build_mesh["id"] = mesh_indexer.get_or_create_id(cur_node)
	
	build_mesh["collision_type"] = Collision.Type.values()[cur_node.collision_type]
	build_mesh["collision_layer"] = cur_node.collision_layer
	build_mesh["collision_mask"] = cur_node.collision_mask
	
	var mat_res_paths:PackedStringArray
	for mat in cur_node.materials:
		if mat:
			mat_res_paths.append(mat.resource_path)
		else:
			mat_res_paths.append("")
	build_mesh["materials"] = mat_res_paths
	
	
	build_mesh["mesh"] = cur_node.mesh_vector_data.to_dictionary(self)
	


func export_vector(vec:DataVector)->Dictionary:
	var result:Dictionary
	
	result["name"] = vec.name
	result["data_type"] = DataVector.DataType.values()[vec.data_type]
	if vec.stride != 1:
		result["stride"] = vec.stride
	if !vec.category.is_empty():
		result["category"] = vec.category
	
	var region:BufferArchive.BufferRegion = buffer_archive.store_buffer(vec.get_buffer_byte_data())
	var buf_id:int = buffer_region_indexer.get_or_create_id(region)
	buffer_region_map[buf_id] = region
#	result["data_buffer"] = region.index
	result["data_buffer"] = buf_id
	
	return result
	
