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
extends XMLNode
class_name XMLElement

@export var name:String
@export var attributes:Array[XMLAttribute]
@export var children:Array[XMLNode]

func _init(name:String = ""):
	self.name = name


func format_document_recursive(cur_indent:String = "", indent_increment:String = "    ")->String:
	var result = cur_indent + "<" + name
	for attr in attributes:
		result += " "  + attr.name + "=\"" + attr.value + "\""
	if children.is_empty():
		result += "/>"
	else:
		result += ">"
		for child in children:
			result += child.to_string_recursive(cur_indent + indent_increment, indent_increment)
		result += "</" + name + ">"
	return result

	
func add_child(node:XMLNode):
	children.append(node)

func get_attribute(name:String)->XMLAttribute:
	for attr in attributes:
		if attr.name == name:
			return attr
	return null
	
func get_attribute_value(name:String, default_value:String = "")->String:
	for attr in attributes:
		if attr.name == name:
			return attr.value
	return default_value

func get_attribute_index(nane:String)->int:
	for attr_idx in attributes.size():
		if attributes[attr_idx].name == name:
			return attr_idx
	return -1

func set_attribute(name:String, value:String):
	var idx = get_attribute_index(name)
	if idx != -1:
		attributes[idx].value = value
	else:
		attributes.append(XMLAttribute.new(name, value))

#func set_attribute_bool(name:String, value:bool):
	#set_attribute(name, str(value))
#
#func set_attribute_int(name:String, value:int):
	#set_attribute(name, str(value))
