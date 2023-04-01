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
class_name CommandMoveBlocks
extends CyclopsCommand

#Public data to set before activating command
var move_offset:Vector3
var lock_uvs:bool = false

#Private
var blocks_to_move:Array[NodePath]
var tracked_block_data:Array[ConvexBlockData]

func _init():
	command_name = "Move blocks"

#Add blocks to be moved here
func add_block(block_path:NodePath):
	blocks_to_move.append(block_path)
	
	var block:CyclopsConvexBlock = builder.get_node(block_path)
	#tracked_blocks.append(block)
	tracked_block_data.append(block.block_data.duplicate())

#Moves all blocks from the start position by this amount
func move_to(offset:Vector3):
	for i in blocks_to_move.size():
		var block:CyclopsConvexBlock = builder.get_node(blocks_to_move[i])
		
		var ctl_mesh:ConvexVolume = ConvexVolume.new()
		ctl_mesh.init_from_convex_block_data(tracked_block_data[i])
		ctl_mesh.translate(offset, lock_uvs)
		var result_data:ConvexBlockData = ctl_mesh.to_convex_block_data()
		block.block_data = result_data
		#tracked_blocks[block_idx].block_data = result_data

func do_it():
	move_to(move_offset)

func undo_it():
	move_to(Vector3.ZERO)
	
