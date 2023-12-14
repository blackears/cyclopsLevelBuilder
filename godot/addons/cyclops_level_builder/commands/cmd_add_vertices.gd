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
class_name CommandAddVertices
extends CyclopsCommand


#Public 
var points_to_add:PackedVector3Array
var block_path:NodePath

#Private
var tracked_block_data:ConvexBlockData
var selected_points:PackedVector3Array

			
func _init():
	command_name = "Add vertices"

func do_it():
	var block:CyclopsBlock = builder.get_node(block_path)
	
	if !tracked_block_data:		
		var tracked_vol:ConvexVolume = block.control_mesh
		tracked_block_data = tracked_vol.to_convex_block_data()

		for v in tracked_vol.vertices:
			if v.selected:
				selected_points.append(v.point)
	
	var vol:ConvexVolume = ConvexVolume.new()
	vol.init_from_convex_block_data(tracked_block_data)
	
	var point_list:PackedVector3Array = vol.get_points()
	var local_points = block.global_transform.affine_inverse() * points_to_add
	point_list.append_array(local_points)

	var new_vol:ConvexVolume = ConvexVolume.new()
	new_vol.init_from_points(point_list)
	new_vol.copy_face_attributes(vol)
	

	for v_idx in new_vol.vertices.size():
		var v:ConvexVolume.VertexInfo = new_vol.vertices[v_idx]
		if selected_points.has(v.point):
			v.selected = true

	block.block_data = new_vol.to_convex_block_data()		

	
func undo_it():
	var block:CyclopsBlock = builder.get_node(block_path)
	block.block_data = tracked_block_data
