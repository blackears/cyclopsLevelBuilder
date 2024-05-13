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
class_name DataVectorString

@export var data:PackedStringArray

func _init(name:StringName = "", data:PackedStringArray = [], data_type:DataType = DataType.STRING):
	self.name = name
	self.data = data
	self.data_type = data_type
	self.stride = data_type_num_components(data_type)
	
func get_data_format_type()->DataFormatType:
	return DataFormatType.STRING
	
func size()->int:
	return data.size()

func resize(size:int):
	data.resize(size * stride)
	
func get_value(index:int)->String:
	return data[index]

func set_value(value:String, index:int):
	data[index] = value

func get_buffer_byte_data()->PackedByteArray:
	return var_to_bytes(data)
#	return data.to_byte_array()

#func to_dictionary(buffer_ar:BufferArchive)->Dictionary:
	#var result:Dictionary = super(buffer_ar)
	#var region:BufferArchive.BufferRegion = buffer_ar.store_buffer(data.to_byte_array())
	#
	#result["data_buffer"] = region.index
	#
	#return result
