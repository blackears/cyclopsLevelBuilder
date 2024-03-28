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
extends RefCounted
class_name MaterialGroup

class Tier:
	var name:String
	var children:Array[MaterialGroup]

	func _init(name:String = ""):
		self.name = name
		
	func create_child_with_name(name:String)->Tier:
		var child:Tier = Tier.new(name)
		children.append(child)
		return child

	func get_child_with_name(name:String):
		for child in children:
			if child.name == name:
				return child
		return null

	func get_child_index_with_name(name:String)->int:
		for i in children.size():
			if children[i].name == name:
				return i
		return -1

	func remove_child_with_name(name:String):
		var idx:int = get_child_index_with_name(name)
		if idx > -1:
			children.remove_at(idx)

var root:Tier = Tier.new("Any")
	
