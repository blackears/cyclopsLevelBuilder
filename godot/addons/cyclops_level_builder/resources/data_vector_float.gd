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
class_name DataVectorFloat

#@export var data:PackedFloat32Array
@export var data:PackedFloat32Array:
	get():
		return data_base.to_float32_array()
	set(value):
		data_base = value.to_byte_array()

func _init(data:PackedFloat32Array = [], data_type:DataType = DataType.FLOAT):
#	self.name = name
	self.data = data
	self.data_type = data_type
	self.stride = data_type_num_components(data_type)

func duplicate_explicit()->DataVectorFloat:
	var v:DataVectorFloat = DataVectorFloat.new(data.duplicate(), data_type)
	v.category = category
	return v

func add(peer:DataVector)->DataVectorFloat:
	if peer.data_type != data_type:
		printerr("mismatching data_type")
		return null
		
	if peer.data.size() != data.size():
		printerr("mismatching vector size")
		return null
	
	var values:PackedFloat32Array
	values.resize(data.size())
	for i in data.size():
		values[i] = data[i] + peer.data[i]
	
	return DataVectorFloat.new(values, data_type)

func subtract(peer:DataVector)->DataVectorFloat:
	if peer.data_type != data_type:
		printerr("mismatching data_type")
		return null
		
	if peer.data.size() != data.size():
		printerr("mismatching vector size")
		return null
	
	var values:PackedFloat32Array
	values.resize(data.size())
	for i in data.size():
		values[i] = data[i] - peer.data[i]
	
	return DataVectorFloat.new(values, data_type)

func is_zero()->bool:
	for i in data.size():
		if data[i] != 0:
			return false
	return true

func get_data_format_type()->DataFormatType:
	return DataFormatType.FLOAT32

func num_components()->int:
	return data.size() / stride

func size()->int:
	return data.size()

func resize(size:int):
	data.resize(size * stride)

func equals_data(peer:DataVector)->bool:
	if data_type != peer.data_type:
		return false
	
	if data.size() != peer.data.size():
		return false
	
	for i in data.size():
		if data[i] != peer.data[i]:
			return false
			
	return true

func set_data(peer:DataVector)->void:
	if data_type != peer.data_type:
		printerr("vector data type mismatch")
		return
		
	data = peer.data.duplicate()
	return
	
func get_value(index:int)->float:
	return data[index]

func to_vec2_array()->PackedVector2Array:
	var result:PackedVector2Array
	for i in range(0, data.size(), 2):
		result.append(Vector2(data[i], data[i + 1]))
	return result

func to_vec3_array()->PackedVector3Array:
	var result:PackedVector3Array
	for i in range(0, data.size(), 3):
		result.append(Vector3(data[i], data[i + 1], data[i + 2]))
	return result

func to_vec4_array()->Array[Vector4]:
	var result:Array[Vector4]
	for i in range(0, data.size(), 4):
		result.append(Vector4(data[i], data[i + 1], data[i + 2], data[i + 3]))
	return result

func to_color_array()->PackedColorArray:
	var result:PackedColorArray
	for i in range(0, data.size(), 4):
		result.append(Color(data[i], data[i + 1], data[i + 2], data[i + 3]))
	return result

func to_transform2d_array()->Array[Transform2D]:
	#print("to_transform2d_array num_components() ", num_components())
	var result:Array[Transform2D]
	for i in range(0, data.size(), 6):
		result.append(Transform2D(
			Vector2(data[i], data[i + 1]), 
			Vector2(data[i + 2], data[i + 3]),
			Vector2(data[i + 4], data[i + 5])
			))
	
	#for i in num_components():
		#result.append(get_value_transform2d(i))
	return result

func get_value_vec2(index:int)->Vector2:
	return Vector2(data[index * stride], data[index * stride + 1])
	
func get_value_vec3(index:int)->Vector3:
	return Vector3(data[index * stride], data[index * stride + 1], data[index * stride + 2])

func get_value_vec4(index:int)->Vector4:
	return Vector4(data[index * stride], data[index * stride + 1], data[index * stride + 2], data[index * stride + 3])

func get_value_color(index:int)->Color:
	return Color(data[index * stride], data[index * stride + 1], data[index * stride + 2], data[index * stride + 3])

func get_value_transform2d(index:int)->Transform2D:
	return Transform2D(
		Vector2(data[index * stride], data[index * stride + 1]),
		Vector2(data[index * stride + 2], data[index * stride + 3]),
		Vector2(data[index * stride + 4], data[index * stride + 5])
		)

func get_value_transform3d(index:int)->Transform3D:
	return Transform3D(
		Vector3(data[index * stride], data[index * stride + 1], data[index * stride + 2]),
		Vector3(data[index * stride + 3], data[index * stride + 4], data[index * stride + 5]),
		Vector3(data[index * stride + 6], data[index * stride + 7], data[index * stride + 8]),
		Vector3(data[index * stride + 9], data[index * stride + 10], data[index * stride + 11])
		)
	

func set_value(value:int, index:int):
	data[index] = value
	
func set_value_vec2(value:Vector2, index:int):
	data[index * stride] = value.x
	data[index * stride + 1] = value.y

func set_value_vec3(value:Vector3, index:int):
	data[index * stride] = value.x
	data[index * stride + 1] = value.y
	data[index * stride + 2] = value.z

func set_value_vec4(value:Vector4, index:int):
	data[index * stride] = value.x
	data[index * stride + 1] = value.y
	data[index * stride + 2] = value.z
	data[index * stride + 3] = value.w

func set_value_color(value:Color, index:int):
	data[index * stride] = value.r
	data[index * stride + 1] = value.g
	data[index * stride + 2] = value.b
	data[index * stride + 3] = value.a

func get_buffer_byte_data()->PackedByteArray:
	return data.to_byte_array()

func append_float(value:float):
	data.append(value)

func append_vector2(value:Vector2):
	data.append(value.x)
	data.append(value.y)

func append_vector3(value:Vector3):
	data.append(value.x)
	data.append(value.y)
	data.append(value.z)

func append_vector4(value:Vector4):
	data.append(value.x)
	data.append(value.y)
	data.append(value.z)
	data.append(value.w)

func append_color(value:Color):
	data.append(value.r)
	data.append(value.g)
	data.append(value.b)
	data.append(value.a)

#func to_dictionary(buffer_ar:BufferArchive)->Dictionary:
	#var result:Dictionary = super(buffer_ar)
	#var region:BufferArchive.BufferRegion = buffer_ar.store_buffer(data.to_byte_array())
	#
	#result["data_buffer"] = region.index
	#
	#return result

func _to_string() -> String:
	return "DataVectorFloat " + DataType.keys()[data_type] + " " + str(data)
