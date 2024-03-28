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

extends RefCounted
class_name TestTreeDataModel

class Path extends RefCounted:
	var path:PackedStringArray
	
	func _init(path:PackedStringArray = []):
		self.path = path
		
	func equals_path(other:Path)->bool:
		return other.path == path
		
	func is_ancestor_of_or_equal_to(other:Path)->bool:
		if path.size() > other.path.size():
			return false
		
		for i in path.size():
			if path[i] != other.path[i]:
				return false
		return true
		
	func _to_string()->String:
		return str(path)

class Tier extends RefCounted:
	var parent:Tier
	var name:String
	var children:Array[Tier]
	
	func _init(name:String = ""):
		self.name = name
	
	func index_of(child:Tier)->int:
		for i in children.size():
			if children[i] == child:
				return i
		return -1
		
	func num_children()->int:
		return children.size()
	
	func create_unique_name(root_name:String)->String:
		if !has_child_with_name(root_name):
			return root_name

		var regex = RegEx.new()
		regex.compile("(\\d+)")
		var match_res:RegExMatch = regex.search(root_name)
		
		var name_idx:int = 0
		
		if match_res:
			var suffix:String = match_res.get_string(1)
			name_idx = int(suffix) + 1
			root_name = root_name.substr(0, root_name.length() - suffix.length())
		
		while true:
			var new_name:String = "%s_%d" % [root_name, name_idx]
			if !has_child_with_name(new_name):
				return new_name
			name_idx += 1
			
		return ""
	
	func is_ancestor_of_or_equal_to(other:Tier)->bool:
		if !other:
			return false
		if other == self:
			return true
		return is_ancestor_of_or_equal_to(other.parent)
			
	
	func get_child_with_name(name:String)->Tier:
		for child in children:
			if child.name == name:
				return child
		return null
	
	func has_child_with_name(name:String)->bool:
		for child in children:
			if child.name == name:
				return true
		return false
	
	func create_child_with_name(name:String, index:int = 0)->Tier:
		var child:Tier = Tier.new(name)
		child.parent = self
		children.insert(index, child)
		return child
	
	func remove_child(child:Tier):
		var index:int = children.find(child)
		if index == -1:
			push_error("Child tier not found")
		children.remove_at(index)

	func get_parent()->Tier:
		return parent
		
	func get_path()->Path:
		if parent:
			var path:Path = parent.get_path()
			path.path.append(name)
			return path
		return Path.new([name])

var root:Tier = Tier.new("Root")

func get_tier_from_path(path:Path)->Tier:
	if path.path.is_empty():
		return null
		
	return _get_tier_from_path_recur(path, 0, root)

func _get_tier_from_path_recur(path:Path, index:int, cur_tier:Tier)->Tier:
	
	if cur_tier.name == path.path[index]:
		if index == path.path.size() - 1:
			return cur_tier
		if index + 1 >= path.path.size():
			return null
			
		var child:Tier = cur_tier.get_child_with_name(path.path[index + 1])
		if !child:
			return null
		return _get_tier_from_path_recur(path, index + 1, child)
	
	return null

