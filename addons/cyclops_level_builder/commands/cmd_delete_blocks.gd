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
class_name CommandDeleteBlocks
extends CyclopsCommand

#class TrackedBlock extends RefCounted:
#	var path:NodePath
#	var path_parent:NodePath
#	var data:ConvexBlockData
#	var materials:Array[Material]
#	var selected:bool
#	var name:String
#
#	func _init(block:CyclopsBlock):
#		path = block.get_path()
#		path_parent = block.get_parent().get_path()
#		name = block.name
#		data = block.block_data.duplicate()
#		selected = block.selected
#		materials = block.materials

#Public 
var block_paths:Array[NodePath]

#Private
var tracked_blocks:Array[TrackedBlock]

func _init():
	command_name = "Delete blocks"

func will_change_anything():
	if !block_paths.is_empty():
		return true

	return false


func do_it():
	#print("Delete do_it")
	
	if tracked_blocks.is_empty():
		var points:PackedVector3Array
		
		for path in block_paths:
			var block:CyclopsBlock = builder.get_node(path)
			var tracker:TrackedBlock = TrackedBlock.new(block)
			tracked_blocks.append(tracker)
	
	#Delete source blocks
	for block_path in block_paths:
		var del_block:CyclopsBlock = builder.get_node(block_path)
		del_block.queue_free()


func undo_it():
	#print("Delete undo_it")
	for tracked in tracked_blocks:
		var parent = builder.get_node(tracked.path_parent)
		
		var block:CyclopsBlock = preload("../nodes/cyclops_block.gd").new()
		block.block_data = tracked.data
		block.materials = tracked.materials
		block.name = tracked.name
		block.selected = tracked.selected
		
		parent.add_child(block)
		block.owner = builder.get_editor_interface().get_edited_scene_root()
		block.global_transform = tracked.world_xform
		

		
	
