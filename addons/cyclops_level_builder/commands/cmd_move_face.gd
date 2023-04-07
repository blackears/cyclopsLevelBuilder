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
class_name CommandMoveFace
extends CyclopsCommand

#Public 
var block_path:NodePath
#var vertex_position:Vector3
var face_index:int
var move_offset:Vector3 = Vector3.ZERO
var lock_uvs:bool = false

#Private
var tracked_block_data:ConvexBlockData

func _init():
	command_name = "Move face"


func do_it():
	var block:CyclopsConvexBlock = builder.get_node(block_path)
	
	if !tracked_block_data:	
		tracked_block_data = block.block_data
		
	var vol:ConvexVolume = ConvexVolume.new()
	vol.init_from_convex_block_data(tracked_block_data)
	
	var moved_vert_indices:PackedInt32Array
	var face:ConvexVolume.FaceInfo = vol.faces[face_index]
	for v_idx in face.vertex_indices:
		moved_vert_indices.append(v_idx)
	
	var new_points:PackedVector3Array
	for i in vol.vertices.size():
		var v:ConvexVolume.VertexInfo = vol.vertices[i]
		if moved_vert_indices.has(i):
			new_points.append(v.point + move_offset)
		else:
			new_points.append(v.point)
		

	#print("new points %s " % new_points)
	
	var new_vol:ConvexVolume = ConvexVolume.new()
	new_vol.init_from_points(new_points)
	
	new_vol.copy_face_attributes(vol)
	block.block_data = new_vol.to_convex_block_data()

func undo_it():
	var block:CyclopsConvexBlock = builder.get_node(block_path)
	block.block_data = tracked_block_data
