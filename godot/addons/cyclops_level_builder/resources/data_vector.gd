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
class_name DataVector

enum DataFormatType { BYTE, INT32, FLOAT32, STRING }
enum DataType { BOOL, INT, FLOAT, STRING, COLOR, VECTOR2, VECTOR3, VECTOR4, TRANSFORM_2D, TRANSFORM_3D }

@export var name:StringName
@export var category:String #uv, color, weights, etc.
@export var data_type:DataType
@export var stride:int = 1

func get_data_format_type()->DataFormatType:
	return DataFormatType.BYTE
	
func size()->int:
	return 0
	
func num_components()->int:
	return size() / stride

func get_buffer_byte_data()->PackedByteArray:
	return []

#func to_dictionary(buffer_ar:BufferArchive)->Dictionary:
	#var result:Dictionary
	#
	#result["name"] = name
	#result["data_type"] = DataType.values()[data_type]
	#if stride != 1:
		#result["stride"] = stride
	#if !category.is_empty():
		#result["category"] = category
	#
	#return result

static func data_type_num_components(type:DataType)->int:
	match type:
		DataType.BOOL:
			return 1
		DataType.INT:
			return 1
		DataType.FLOAT:
			return 1
		DataType.STRING:
			return 1
		DataType.COLOR:
			return 4
		DataType.VECTOR2:
			return 2
		DataType.VECTOR3:
			return 3
		DataType.VECTOR4:
			return 4
		DataType.TRANSFORM_2D:
			return 6
		DataType.TRANSFORM_3D:
			return 12
		_:
			push_error("Invalid data type")
			return 1
