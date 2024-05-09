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
extends DataVector
class_name DataVectorInt

@export var data:PackedInt32Array

func _init(name:StringName = "", data:PackedInt32Array = [], data_type:DataType = DataType.INT):
	self.name = name
	self.data = data
	self.data_type = data_type
	self.stride = data_type_num_components(data_type)
	
func get_data_format_type()->DataFormatType:
	return DataFormatType.INT32
	
func size()->int:
	return data.size()

func resize(size:int):
	data.resize(size * stride)

func get_value(index:int)->int:
	return data[index]

func get_value_ivec2(index:int)->Vector2i:
	return Vector2i(data[index * stride], data[index * stride + 1])
	
func get_value_ivec3(index:int)->Vector3i:
	return Vector3i(data[index * stride], data[index * stride + 1], data[index * stride + 2])
	
func get_value_ivec4(index:int)->Vector4i:
	return Vector4i(data[index * stride], data[index * stride + 1], data[index * stride + 2], data[index * stride + 3])
	
	
func set_value(value:int, index:int):
	data[index] = value
	
func set_value_ivec2(value:Vector2i, index:int):
	data[index * stride] = value.x
	data[index * stride + 1] = value.y

func set_value_ivec3(value:Vector3i, index:int):
	data[index * stride] = value.x
	data[index * stride + 1] = value.y
	data[index * stride + 2] = value.z

func set_value_ivec4(value:Vector4i, index:int):
	data[index * stride] = value.x
	data[index * stride + 1] = value.y
	data[index * stride + 2] = value.z
	data[index * stride + 3] = value.w

func get_buffer_byte_data()->PackedByteArray:
	return data.to_byte_array()

#func to_dictionary(buffer_ar:BufferArchive)->Dictionary:
	#var result:Dictionary = super(buffer_ar)
	#var region:BufferArchive.BufferRegion = buffer_ar.store_buffer(data.to_byte_array())
	#
	#result["data_buffer"] = region.index
	#
	#return result
