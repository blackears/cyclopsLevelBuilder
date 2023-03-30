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
class_name CommandDaleteBlocks
extends CyclopsCommand

var blocks_root:CyclopsBlocks
var block_owner:Node
#var builder:CyclopsLevelBuilder


var tracked_blocks:Array[CyclopsBlock]
var tracked_block_data:Array[ConvexBlockData]
var block_names:Array[String]
var block_selected:Array[bool]

func _init():
	command_name = "Dalete blocks"

#Add blocks to be moved here
func add_block(block:CyclopsBlock):
	tracked_blocks.append(block)
	block_names.append(block.name)
	block_selected.append(block.selected)
	tracked_block_data.append(block.block_data.duplicate())

#Moves all blocks from the start position by this amount
#func move_to(offset:Vector3):
#	for block_idx in tracked_blocks.size():
#		var ctl_mesh:ConvexVolume = ConvexVolume.new()
#		ctl_mesh.init_from_convex_block_data(tracked_block_data[block_idx])
#		ctl_mesh.translate(offset, lock_uvs)
#		var result_data:ConvexBlockData = ctl_mesh.to_convex_block_data()
#		tracked_blocks[block_idx].block_data = result_data

func do_it():
	print("doing delete")
	for block in tracked_blocks:
		block.queue_free()
	tracked_blocks = []

func undo_it():
	print("undoing delete")
	for i in tracked_block_data.size():
		var block:CyclopsBlock = preload("../controls/cyclops_block.gd").new()
		
		
		blocks_root.add_child(block)
		block.owner = blocks_root.owner
#		block.owner = builder.get_editor_interface().get_edited_scene_root()
		block.block_data = tracked_block_data[i]
		block.name = block_names[i]
		block.selected = block_selected[i]
		
		tracked_blocks.append(block)

		
	
