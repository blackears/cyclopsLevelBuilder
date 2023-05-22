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
class_name CommandSubtractBlock
extends CyclopsCommand

class NewBlockInfo extends RefCounted:
	var data:ConvexBlockData
	var materials:Array[Material]
	var path:NodePath

#Public 
var block_paths:Array[NodePath]
var block_to_subtract_path:NodePath
var block_name_prefix:String = "Block_"

#Private
var start_blocks:Array[TrackedBlock]
var subtracted_block_cache:TrackedBlock
var added_blocks:Array[NewBlockInfo]
#var added_block_paths:Array[NodePath]

#var merged_block_data:ConvexBlockData
#var merged_mat_list:Array[Material]
#var merged_block_path:NodePath

func _init():
	command_name = "Subtract block"

func restore_tracked_block(tracked:TrackedBlock)->CyclopsBlock:
	var parent = builder.get_node(tracked.path_parent)
	
	var block:CyclopsBlock = preload("../nodes/cyclops_block.gd").new()
	block.block_data = tracked.data
	block.materials = tracked.materials
	block.name = tracked.name
	block.selected = tracked.selected
	
	parent.add_child(block)
	block.owner = builder.get_editor_interface().get_edited_scene_root()
	
	return block
	
func will_change_anything()->bool:
	var subtrahend_block:CyclopsBlock = builder.get_node(block_to_subtract_path)
	var subtrahend_vol:ConvexVolume = subtrahend_block.control_mesh
	
	if block_paths.is_empty():
		return false
	
	for minuend_path in block_paths:
		var minuend_block:CyclopsBlock = builder.get_node(minuend_path)
		var minuend_vol:ConvexVolume = minuend_block.control_mesh
		
		if minuend_vol.intersects_convex_volume(subtrahend_vol):
			return true
			
	return false

func do_it():
	var subtrahend_block:CyclopsBlock = builder.get_node(block_to_subtract_path)
	
	if start_blocks.is_empty():
		var subtrahend_vol:ConvexVolume = subtrahend_block.control_mesh
		subtracted_block_cache = TrackedBlock.new(subtrahend_block)
		
		for path in block_paths:
			var block:CyclopsBlock = builder.get_node(path)
			
			var minuend_vol:ConvexVolume = block.control_mesh
			if !minuend_vol.intersects_convex_volume(subtrahend_vol):
				continue
			
			var tracker:TrackedBlock = TrackedBlock.new(block)
			start_blocks.append(tracker)
			
			var fragments:Array[ConvexVolume] = minuend_vol.subtract(subtrahend_vol)
			
			for f in fragments:
				f.copy_face_attributes(minuend_vol)
				
				var block_info:NewBlockInfo = NewBlockInfo.new()
				block_info.data = f.to_convex_block_data()
				block_info.materials = block.materials
				added_blocks.append(block_info)

	#Delete source blocks
	for block_info in start_blocks:
		var del_block:CyclopsBlock = builder.get_node(block_info.path)
		del_block.queue_free()

	subtrahend_block.queue_free()

	#Create blocks
	for info in added_blocks:
		var block:CyclopsBlock = preload("../nodes/cyclops_block.gd").new()
		var parent:Node = builder.get_node(start_blocks[0].path_parent)
		parent.add_child(block)
		block.owner = builder.get_editor_interface().get_edited_scene_root()
		block.name = GeneralUtil.find_unique_name(parent, block_name_prefix)
		block.block_data = info.data
		block.materials = info.materials
		
		info.path = block.get_path()

	

func undo_it():
	
	for info in added_blocks:
		var added_block:CyclopsBlock = builder.get_node(info.path)
		added_block.queue_free()

	restore_tracked_block(subtracted_block_cache)

	for tracked in start_blocks:
		restore_tracked_block(tracked)

