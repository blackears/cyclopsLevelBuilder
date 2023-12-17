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
class_name CommandTransformBlocks
extends CyclopsCommand

#Public data to set before activating command
var transform:Transform3D
var lock_uvs:bool = false

#Private
var tracked_blocks:Array[TrackedBlock]

func _init():
	command_name = "Transform blocks"

#Add blocks to be moved here
func add_block(block_path:NodePath):
	
	var block:CyclopsBlock = builder.get_node(block_path)
	var tracked:TrackedBlock = TrackedBlock.new(block)
	tracked_blocks.append(tracked)

#Moves all blocks from the start position by this amount
func move_to(offset:Vector3):
	for tracked in tracked_blocks:
		var block:CyclopsBlock = builder.get_node(tracked.path)
		var w_init_xform:Transform3D = tracked.world_xform
		
		var new_w_xform:Transform3D = w_init_xform.translated(offset)
		block.global_transform = new_w_xform
		
		
func do_it():
	for tracked in tracked_blocks:
		var block:CyclopsBlock = builder.get_node(tracked.path)
		var w_init_xform:Transform3D = tracked.world_xform
		
		var new_w_xform:Transform3D = transform * w_init_xform
		block.global_transform = new_w_xform
		
		#if !lock_uvs:
			#var vol:ConvexVolume = ConvexVolume.new()
			#vol.init_from_convex_block_data(tracked.data)
			#
			#var uv_xform:Transform3D = transform.affine_inverse()
			#vol.transform_uvs(uv_xform)
			#
			#block.block_data = vol.to_convex_block_data()

func undo_it():
	for tracked in tracked_blocks:
		var block:CyclopsBlock = builder.get_node(tracked.path)
		block.global_transform = tracked.world_xform
	
