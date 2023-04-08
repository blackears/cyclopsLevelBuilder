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
class_name CommandMoveVertices
extends CyclopsCommand

class BlockVertexChanges extends RefCounted:
	var block_path:NodePath
	var vertex_indices:Array[int] = []
	var tracked_block_data:ConvexBlockData

#Public 
#var block_path:NodePath
#var vertex_position:Vector3
var move_offset:Vector3 = Vector3.ZERO

#Private
#var tracked_block_data:ConvexBlockData
var block_map:Dictionary = {}


func add_vertex(block_path:NodePath, index:int):
	var changes:BlockVertexChanges
	if block_map.has(block_path):
		changes = block_map[block_path]
	else:
		changes = BlockVertexChanges.new()
		changes.block_path = block_path
		var block:CyclopsConvexBlock = builder.get_node(block_path)
		changes.tracked_block_data = block.block_data
		block_map[block_path] = changes

	if !changes.vertex_indices.has(index):
		changes.vertex_indices.append(index)


#func copy_vertex_attributes(from_vol:ConvexVolume, to_vol:ConvexVolume):
#	print("--copy_vertex_attributes")
#	for v_idx1 in to_vol.vertices.size():
#		var v1:ConvexVolume.VertexInfo = to_vol.vertices[v_idx1]
#		var start_pos:Vector3 = v1.point - move_offset
#		var v0:ConvexVolume.VertexInfo = null
#		print(" start pos %s" % start_pos)
#		for v in from_vol.vertices:
#			print("v.point %s" % v.point)
#			if v.point.is_equal_approx(start_pos):
#				v0 = v
#				break
#		if v0:
#			print("v0 %s %s  v1 %s %s" % [v0.point, v0.selected, v1.point, v1.selected])
#			v1.selected = v0.selected
			
func _init():
	command_name = "Move vertices"

func do_it():
#	print("move verts do_it")
	for block_path in block_map.keys():
		
		var block:CyclopsConvexBlock = builder.get_node(block_path)
		var rec:BlockVertexChanges = block_map[block_path]
		
		var vol:ConvexVolume = ConvexVolume.new()
		vol.init_from_convex_block_data(rec.tracked_block_data)

#		print("rec.vertex_indices %s" % rec.vertex_indices)
#		print("move_offset %s" % move_offset)
		var selected_points:PackedVector3Array
		var new_points:PackedVector3Array
		for v_idx in vol.vertices.size():
			if rec.vertex_indices.has(v_idx):
				var p:Vector3 = vol.vertices[v_idx].point + move_offset
				new_points.append(p)
				selected_points.append(p)
			else:
				new_points.append(vol.vertices[v_idx].point)
				
		
		var new_vol:ConvexVolume = ConvexVolume.new()
		new_vol.init_from_points(new_points)
		
#		new_vol.copy_face_attributes(vol)
		for v_idx in new_vol.vertices.size():
			var v:ConvexVolume.VertexInfo = new_vol.vertices[v_idx]
#			print ("vol point %s " % v1.point)
			if selected_points.has(v.point):
#				print("set sel")
				v.selected = true

		block.block_data = new_vol.to_convex_block_data()
		
		#Copy selection
#		print ("sel points %s " % selected_points)
		
		#Copy vertex attributes from old mesh data
		#copy_vertex_attributes(vol, block.control_mesh)
#		for v_idx1 in block.control_mesh.vertices.size():
#			var v1:ConvexVolume.VertexInfo = block.control_mesh.vertices[v_idx1]
#			var start_pos:Vector3 = v1.point - move_offset
#			var v0:ConvexVolume.VertexInfo = null
#			for v in vol.vertices:
#				if v.point.is_equal_approx(start_pos):
#					v0 = v
#					break
#			if v0:
#				v1.selected = v0.selected
			
	
func undo_it():
#	print("move verts undo_it")
	for block_path in block_map.keys():
		var rec:BlockVertexChanges = block_map[block_path]
		var block:CyclopsConvexBlock = builder.get_node(block_path)
		block.block_data = rec.tracked_block_data
#		copy_vertex_attributes(vol, block.control_mesh)
