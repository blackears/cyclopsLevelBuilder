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

#Applied trnasorm of points in local space

@tool
class_name CommandTransformVertices
extends CyclopsCommand

class TrackedInfo extends RefCounted:
	var data:ConvexBlockData
#	var materials:Array[Material]

#Local space transform of points	
var transform:Transform3D
var lock_uvs:bool = false

#Private
var blocks_to_move:Array[NodePath]
var tracked_block_data:Array[TrackedInfo]

func _init():
	command_name = "Transform vertices"

#Add blocks to be moved here
func add_block(block_path:NodePath):
	blocks_to_move.append(block_path)
	
	var block:CyclopsBlock = builder.get_node(block_path)
	#tracked_blocks.append(block)
	var info:TrackedInfo = TrackedInfo.new()
	info.data = block.block_data.duplicate()
#	info.materials = block.materials
	tracked_block_data.append(info)

#Moves all blocks from the start position by this amount
func apply_transform(xform:Transform3D):
	for i in blocks_to_move.size():
		var block:CyclopsBlock = builder.get_node(blocks_to_move[i])
		
		var ctl_mesh:ConvexVolume = ConvexVolume.new()
		ctl_mesh.init_from_convex_block_data(tracked_block_data[i].data)
		ctl_mesh.transform(xform, lock_uvs)
		var result_data:ConvexBlockData = ctl_mesh.to_convex_block_data()
		block.block_data = result_data
#		block.materials = tracked_block_data[i].materials
		#tracked_blocks[block_idx].block_data = result_data

func do_it():
#	if blocks_to_move.is_empty():
#		var blocks:Array[CyclopsConvexBlock] = builder.get_selected_blocks()
#		for block in blocks:
#			add_block(block.get_path())
	
	apply_transform(transform)

func undo_it():
	apply_transform(Transform3D.IDENTITY)
	
