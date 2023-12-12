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
class_name CyclopsCommand
extends RefCounted

var command_name:String = ""
var builder:CyclopsLevelBuilder

class TrackedBlock extends RefCounted:
	var path:NodePath
	var path_parent:NodePath
	var data:ConvexBlockData
	var world_xform:Transform3D
	var materials:Array[Material]
	var selected:bool
	var name:String

	func _init(block:CyclopsBlock):
		path = block.get_path()
		path_parent = block.get_parent().get_path()
		name = block.name
		data = block.block_data.duplicate()
		world_xform = block.global_transform
		#selected = block.selected
		materials = block.materials


func add_to_undo_manager(undo_manager:EditorUndoRedoManager):
	undo_manager.create_action(command_name, UndoRedo.MERGE_DISABLE)
	undo_manager.add_do_method(self, "do_it")
	undo_manager.add_undo_method(self, "undo_it")

	undo_manager.commit_action()

func node_global_transform(node:Node)->Transform3D:
	var node_parent:Node3D
	while node:
		if node is Node3D:
			node_parent = node
			break
		node = node.get_parent()
		
	return node_parent.global_transform if node_parent else Transform3D.IDENTITY

func do_it()->void:
	pass

func undo_it()->void:
	pass

