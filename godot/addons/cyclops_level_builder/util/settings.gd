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

@export var definition_map:Dictionary
@export var lookup:Dictionary

var float_regex_strn:String = "[+-]?([0-9]*[.])?[0-9]+"
var regex_int = RegEx.create_from_string("[0-9]+")
var regex_float = RegEx.create_from_string(float_regex_strn)
var regex_color = RegEx.create_from_string("color\\(" + float_regex_strn + "\\)")

class SettingDef:
	var name:String
	var default_value
	var type:Variant.Type
	var hint:PropertyHint
	var hint_string:String


func value_to_text(value, type:int)->String:
	match type:
		TYPE_BOOL:
			return "true" if value else "false"
			
		TYPE_COLOR:
			return JSON.stringify([value.r, value.g, value.b, value.a])
			
		TYPE_FLOAT:
			return str(value)
			
		TYPE_INT:
			return str(value)
			
		TYPE_NODE_PATH:
			return str(value)
			
		TYPE_STRING:
			return "\"" + value + "\""
			
		TYPE_TRANSFORM2D:
			var a:Transform2D = value
			return JSON.stringify({"x": [a.x.x, a.x.y],
				"y": [a.y.x, a.y.y],
				"o": [a.origin.x, a.origin.y],
			})
			
		TYPE_TRANSFORM3D:
			var a:Transform3D = value
			return JSON.stringify({"x": [a.basis.x.x, a.basis.x.y, a.basis.x.z],
				"y": [a.basis.y.x, a.basis.y.y, a.basis.y.z],
				"z": [a.basis.z.x, a.basis.z.y, a.basis.z.z],
				"o": [a.origin.x, a.origin.y, a.origin.z],
			})
			
		TYPE_VECTOR2:
			var a:Vector2 = value
			return JSON.stringify([a.x, a.y])
			
		TYPE_VECTOR3:
			var a:Vector3 = value
			return JSON.stringify([a.x, a.y, a.z])
			
		TYPE_VECTOR4:
			var a:Vector4 = value
			return JSON.stringify([a.x, a.y, a.z, a.w])
			
		_:
			return ""

func text_to_value(text:String, type:int):
	text = text.lstrip(" ").rstrip(" ")
	
	match type:
		TYPE_BOOL:
			return text.to_lower() == "true"

		TYPE_COLOR:
			var a:Array = JSON.parse_string(text)
			return Color(a[0], a[1], a[2], a[3])

		TYPE_FLOAT:
			return float(text)

		TYPE_INT:
			return int(text)

		TYPE_NODE_PATH:
			return NodePath(text)

		TYPE_STRING:
			#Trim starting and ending quotes
			return text.substr(1, text.length() - 2)

		TYPE_TRANSFORM2D:
			var a:Dictionary = JSON.parse_string(text)
			return Transform2D(Vector2(a["x"][0], a["x"][1]),
				Vector2(a["y"][0], a["y"][1]),
				Vector2(a["o"][0], a["o"][1]))

		TYPE_TRANSFORM3D:
			var a:Dictionary = JSON.parse_string(text)
			return Transform3D(Vector3(a["x"][0], a["x"][1], a["x"][2]),
				Vector3(a["y"][0], a["y"][1], a["y"][2]),
				Vector3(a["z"][0], a["z"][1], a["z"][2]),
				Vector3(a["o"][0], a["o"][1], a["o"][2]))

		TYPE_VECTOR2:
			var a:Array = JSON.parse_string(text)
			return Vector2(a[0], a[1])

		TYPE_VECTOR3:
			var a:Array = JSON.parse_string(text)
			return Vector3(a[0], a[1], a[2])
			
		TYPE_VECTOR4:
			var a:Array = JSON.parse_string(text)
			return Vector4(a[0], a[1], a[2], a[3])

		_:
			return null
	

func save_to_file(path:String):
	var keys:Array = lookup.keys()
	keys.sort()
	
	var f:FileAccess = FileAccess.open(path, FileAccess.WRITE)
	
	for key in keys:
		var def:SettingDef = definition_map[key]
		f.store_line("%s=%s" % [key, value_to_text(lookup[key], def.type)])
	
	f.close()
	
func load_from_file(path:String):
	lookup.clear()

	var f:FileAccess = FileAccess.open(path, FileAccess.READ)
	
	while !f.eof_reached():
		var line:String = f.get_line()
		line = line.lstrip(" ")
		if line.is_empty() || line[0] == "#":
			continue

		var idx = line.find("=")
		if idx == -1:
			continue
			
		var name:String = line.substr(0, idx)
		var value_text:String = line.substr(idx + 1)
		
		if !definition_map.has(name):
			continue
			
		var def:SettingDef = definition_map[name]
		set_property(name, text_to_value(value_text, def.type))

	

func add_setting(name:String, default_value, type:Variant.Type, hint:PropertyHint = PROPERTY_HINT_NONE, hint_string:String = ""):
	var def:SettingDef = SettingDef.new()
	def.name = name
	def.default_value = default_value
	def.type = type
	def.hint = hint
	def.hint_string = hint_string
	
	definition_map[name] = def


func set_property(name:String, value):
	if !definition_map.has(name):
		push_error("Unknown setting name " + name)
		return
	
	var def:SettingDef = definition_map[name]
	var var_type:int = typeof(value)
	if var_type != def.type:
		push_error("Settings error: Bad setting type.  Needed %s but got %s" % [def.type, var_type])
		return
		
	lookup[name] = value


func has_property(name:String)->bool:
	return definition_map.has(name)

func get_property(name:String):
	#print("lookup ", name)
	if !definition_map.has(name):
		push_error("Unknown setting name " + name)
		return null
		
	#print("is defined ", name)
	if lookup.has(name):
		return lookup[name]
	
	#print("returning default ", name)
	var def:SettingDef = definition_map[name]
	return def.default_value

