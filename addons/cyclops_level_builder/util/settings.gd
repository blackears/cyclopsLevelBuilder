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
class_name Settings

@export var lookup:Dictionary

func save_to_file(path:String):
	var f:FileAccess = FileAccess.open(path, FileAccess.WRITE)
	
	f.store_line(JSON.stringify(lookup, "\t"))
	
	f.close()
	
func load_from_file(path:String):
	lookup.clear()
	
	var text:String = FileAccess.get_file_as_string(path)
	var values = JSON.parse_string(text)
	
	lookup = values

func set_property(name:String, value):
	lookup[name] = value


func has_property(name:String)->bool:
	return lookup.has(name)

func get_property(name:String, default = null):
	return lookup[name] if lookup.has(name) else default

func arr_to_vec3(arr:Array)->Vector3:
	return Vector3(arr[0], arr[1], arr[2])

func get_property_transform3d(name:String, default:Transform3D = Transform3D.IDENTITY):
	if !lookup.has(name):
		return default
		
	var arr:Dictionary = lookup[name]
	
	return Transform3D(arr_to_vec3(arr["X"]),
		arr_to_vec3( arr["Y"]), 
		arr_to_vec3(arr["Z"]), 
		arr_to_vec3(arr["O"]))
	#return lookup[name] if lookup.has(name) else default
	
