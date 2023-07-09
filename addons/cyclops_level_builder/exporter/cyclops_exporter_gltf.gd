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

#GLTF reference
#https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html

@tool
extends RefCounted
class_name CyclopsExporterGltf


enum BufferType { ARRAY_BUFFER = 34962, ELEMENT_ARRAY_BUFFER = 34963 }
enum AccessorDataType { BYTE = 5120, UBYTE = 5121, SHORT = 5122, USHORT = 5123, UINT = 5125, FLOAT = 5126 }


class BufferInfo extends RefCounted:
	var bytes:PackedByteArray

class BufferViewInfo extends RefCounted:
	var buffer_index:int
	var byte_length:int
	var byte_offset:int
	var target:BufferType
	

class AccessorInfo extends RefCounted:
	var buffer_view_index:int
	var byte_offset:int
	var component_type:AccessorDataType
	var count:int
	var max_val_components:Array
	var min_val_components:Array
	var type:String

class PbrMetallicRoughnessInfo extends RefCounted:
	var base_color:Color = Color(.8, .8, .8, 1)
	var metallic_factor:float = 1
	var roughness_factor:float = .5

class MaterialInfo extends RefCounted:
	var double_sided:bool = true
	var name:String
	var pbr_metallic_roughness:PbrMetallicRoughnessInfo = PbrMetallicRoughnessInfo.new()


class MeshInfo extends RefCounted:
	var name:String
	

class NodeInfo extends RefCounted:
	var name:String
	var xform:Transform3D
	var mesh_ref:MeshInfo
	var children:Array[NodeInfo]
	
	func to_dict()->Dictionary:
		var result:Dictionary
		result["name"] = name
		
		var xlate:Vector3 = xform.origin
		if !xlate.is_equal_approx(Vector3.ZERO):
			result["translation"] = [xlate.x, xlate.y, xlate.z]
		
		var rot:Quaternion = xform.basis.get_rotation_quaternion()
		if !rot.is_equal_approx(Quaternion.IDENTITY):
			result["rotation"] = [rot.x, rot.y, rot.z, rot.w]
		
		var scale:Vector3 = xform.basis.get_scale()
		if !scale.is_equal_approx(Vector3.ONE):
			result["scale"] = [scale.x, scale.y, scale.z]
		
		return result

class SceneInfo extends RefCounted:
	var name:String
	var children:Array[NodeInfo]

var accessor_list:Array[AccessorInfo]

var material_list:Array[MaterialInfo]
var node_list:Array[NodeInfo]
var scene_list:Array[SceneInfo]

var gltf_tree:Dictionary

var buffer_list:Array[BufferInfo]
var buffer_view_list:Array[BufferInfo]

func allocate_buffer(buf:PackedByteArray, buf_type:BufferType)->BufferViewInfo:
	if buffer_list.is_empty():
		var buf_info:BufferInfo = BufferInfo.new()
		buffer_list.append(buf_info)
	
	var offset = buffer_list[0].bytes.size()
	buffer_list[0].bytes.append_array(buf)
	
	var result:BufferViewInfo = BufferViewInfo.new()
	buffer_view_list.append(result)
	result.buffer_index = 0
	result.byte_offset = offset
	result.byte_length = buf.size()
	result.target = buf_type
	
	return result

func create_asset_header()->Dictionary:
	var result:Dictionary
	result["generator"] = "Cyclops Level Builder Exporter"
	result["version"] = "2.0"
	
	return result

func export_scenes(scene_root:Node3D):
	gltf_tree["asset"] = create_asset_header()
	gltf_tree["scene"] = 0
	
	material_list.append(MaterialInfo.new())
	
	var scene_info:SceneInfo = SceneInfo.new()
	scene_list.append(scene_info)
	scene_info.name = "root"
	
	for child in scene_root.get_children():
		scene_info.children.append(export_branch(child))
	
func export_branch(node:Node3D)->NodeInfo:
	var ni:NodeInfo = NodeInfo.new()
	node_list.append(ni)
	
	ni.name = node.name
	ni.xform = node.transform
	
	if node is CyclopsBlock:
		pass
	
	for child in node.get_children():
		if child is Node3D:
			ni.children.append(export_branch(child))
		
	return ni
		
	
	
