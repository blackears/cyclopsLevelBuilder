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
class_name CommandMergeBlocks
extends CyclopsCommand

class TrackedBlock extends RefCounted:
	var path:NodePath
	var path_parent:NodePath
	var data:ConvexBlockData
	var materials:Array[Material]
	var selected:bool
	var name:String

	func _init(block:CyclopsConvexBlock):
		path = block.get_path()
		path_parent = block.get_parent().get_path()
		name = block.name
		data = block.block_data.duplicate()
		selected = block.selected
		materials = block.materials

#Public 
var block_paths:Array[NodePath]
var block_name_prefix:String = "Block_"

#Private
var tracked_blocks:Array[TrackedBlock]
var merged_block_data:ConvexBlockData
var merged_block_path:NodePath
			
func _init():
	command_name = "Merge blocks"

func do_it():
	if tracked_blocks.is_empty():
		var points:PackedVector3Array
		
		for path in block_paths:
			var block:CyclopsConvexBlock = builder.get_node(path)
			var tracker:TrackedBlock = TrackedBlock.new(block)
			tracked_blocks.append(tracker)
			
			points.append_array(block.control_mesh.get_points())
			
		var merged_vol:ConvexVolume = ConvexVolume.new()
		merged_vol.init_from_points(points)
		merged_block_data = merged_vol.to_convex_block_data()

	#Delete source blocks
	for block_path in block_paths:
		var del_block:CyclopsConvexBlock = builder.get_node(block_path)
		del_block.queue_free()

	#Create block	
	var block:CyclopsConvexBlock = preload("../nodes/cyclops_convex_block.gd").new()
	var parent:Node = builder.get_node(tracked_blocks[0].path_parent)
	parent.add_child(block)
	block.owner = builder.get_editor_interface().get_edited_scene_root()
	block.name = GeneralUtil.find_unique_name(parent, block_name_prefix)
	block.block_data = merged_block_data
	#block.materials
	
	merged_block_path = block.get_path()
	
func undo_it():
#	var blocks_root:CyclopsBlocks = builder.get_node(blocks_root_path)
	var merged_block:CyclopsConvexBlock = builder.get_node(merged_block_path)
	merged_block.queue_free()
	
#	for i in blocks_to_merge.size():
	for tracked in tracked_blocks:
		var parent = builder.get_node(tracked.path_parent)
		
		var block:CyclopsConvexBlock = preload("../nodes/cyclops_convex_block.gd").new()
		block.block_data = tracked.data
		block.materials = tracked.materials
		block.name = tracked.name
		block.selected = tracked.selected
		
		parent.add_child(block)
		block.owner = builder.get_editor_interface().get_edited_scene_root()
