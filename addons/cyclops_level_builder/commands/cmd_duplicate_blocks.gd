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
class_name CommandDuplicateBlocks
extends CyclopsCommand

#Public
var blocks_root_path:NodePath
var blocks_to_duplicate:Array[NodePath]
var move_offset:Vector3
var lock_uvs:bool

#Private
class BlockInfo extends RefCounted:
	var new_block:CyclopsConvexBlock
	var source_data:ConvexBlockData
	#var materials:Array[Material]
	
	func _init(new_block:CyclopsConvexBlock, source_data:ConvexBlockData):
		self.new_block = new_block
		self.source_data = source_data

var added_blocks:Array[BlockInfo]

func will_change_anything():
	return !added_blocks.is_empty()

func do_it():
	if added_blocks.is_empty():
		#Create new blocks
		for block_path in blocks_to_duplicate:
			var new_block:CyclopsConvexBlock = preload("../nodes/cyclops_convex_block.gd").new()
			
			var source_block:CyclopsConvexBlock = builder.get_node(block_path)
			
			var blocks_root:CyclopsBlocks = builder.get_node(blocks_root_path)
			new_block.name = GeneralUtil.find_unique_name(blocks_root, source_block.name)
			blocks_root.add_child(new_block)
			new_block.owner = builder.get_editor_interface().get_edited_scene_root()
			
			var info:BlockInfo = BlockInfo.new(new_block, source_block.block_data)
			new_block.materials = source_block.materials
			new_block.selected = true
			
			added_blocks.append(info)

	for path in blocks_to_duplicate:
		var block:CyclopsConvexBlock = builder.get_node(path)
		block.selected = false

	for info in added_blocks:
		var vol:ConvexVolume = ConvexVolume.new()
		vol.init_from_convex_block_data(info.source_data)
		vol.translate(move_offset, lock_uvs)
		info.new_block.block_data = vol.to_convex_block_data()


func undo_it():
	for block in added_blocks:
		block.new_block.queue_free()
	added_blocks = []

	for path in blocks_to_duplicate:
		var block:CyclopsConvexBlock = builder.get_node(path)
		block.selected = true

