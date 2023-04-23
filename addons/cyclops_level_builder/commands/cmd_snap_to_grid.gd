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
class_name CommandSnapToGrid
extends CyclopsCommand

class TrackedInfo extends RefCounted:
	var data:ConvexBlockData
	
var grid_size:float

#Private
var blocks_to_move:Array[NodePath]
var tracked_block_data:Array[TrackedInfo]


func _init():
	command_name = "Snap to grid"


#Add blocks to be moved here
func add_block(block_path:NodePath):
	blocks_to_move.append(block_path)
	
	var block:CyclopsConvexBlock = builder.get_node(block_path)
	#tracked_blocks.append(block)
	var info:TrackedInfo = TrackedInfo.new()
	info.data = block.block_data.duplicate()
#	info.materials = block.materials
	tracked_block_data.append(info)


func do_it():
	for i in blocks_to_move.size():
		var block:CyclopsConvexBlock = builder.get_node(blocks_to_move[i])
		
		var vol:ConvexVolume = ConvexVolume.new()
		vol.init_from_convex_block_data(tracked_block_data[i].data)

		var points_new:PackedVector3Array
		for v_idx in vol.vertices.size():
			var v:ConvexVolume.VertexInfo = vol.vertices[v_idx]
			var p_snap:Vector3 = MathUtil.snap_to_grid(v.point, grid_size)
			points_new.append(p_snap)
			
		var new_vol:ConvexVolume = ConvexVolume.new()
		new_vol.init_from_points(points_new)
		

		new_vol.copy_face_attributes(vol)

		block.block_data = new_vol.to_convex_block_data()

func undo_it():
	for i in blocks_to_move.size():
		var block:CyclopsConvexBlock = builder.get_node(blocks_to_move[i])
		
		block.block_data = tracked_block_data[i].data



