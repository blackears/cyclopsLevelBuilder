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
	var tracked_block_data:MeshVectorData

#Public 
@export var move_offset:Vector3 = Vector3.ZERO
@export var triplanar_lock_uvs:bool = false

#Private
var block_map:Dictionary = {}


func add_vertex(block_path:NodePath, index:int):
	add_vertices(block_path, [index])
	
func add_vertices(block_path:NodePath, indices:Array[int]):
#	print("adding vertex %s %s" % [block_path, indices])
	var changes:BlockVertexChanges
	if block_map.has(block_path):
		changes = block_map[block_path]
	else:
		changes = BlockVertexChanges.new()
		changes.block_path = block_path
		var block:CyclopsBlock = builder.get_node(block_path)
		changes.tracked_block_data = block.mesh_vector_data.duplicate()
		block_map[block_path] = changes

	for index in indices:
		if !changes.vertex_indices.has(index):
			changes.vertex_indices.append(index)
			
func _init():
	command_name = "Move vertices"

func pre_do_it():
#	print("move verts do_it")
	for block_path in block_map.keys():
		
		var block:CyclopsBlock = builder.get_node(block_path)
		var w2l:Transform3D = block.global_transform
		w2l = w2l.affine_inverse()
		var move_offset_local:Vector3 = w2l.basis * move_offset
		
		#print("move offset %s" % move_offset)
		#print("move offset local %s" % move_offset_local)
		
		var rec:BlockVertexChanges = block_map[block_path]
		
		var vol:ConvexVolume = ConvexVolume.new()
		vol.init_from_mesh_vector_data(rec.tracked_block_data)

		for v_idx in vol.vertices.size():
			if rec.vertex_indices.has(v_idx):
				vol.vertices[v_idx].point += move_offset_local

		block.mesh_vector_data = vol.to_mesh_vector_data()
	

func do_it():
	pre_do_it()

	
func undo_it():
#	print("move verts undo_it")
	for block_path in block_map.keys():
		var rec:BlockVertexChanges = block_map[block_path]
		var block:CyclopsBlock = builder.get_node(block_path)
		block.mesh_vector_data = rec.tracked_block_data
