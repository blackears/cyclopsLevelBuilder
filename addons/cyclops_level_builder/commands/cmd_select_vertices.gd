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
class_name CommandSelectVertices
extends CyclopsCommand

#class Record extends RefCounted:
#	var vert_idx:int
#	var block_path:NodePath
class BlockVertexChanges extends RefCounted:
	var block_path:NodePath
	var vertex_indices:Array[int] = []
	var tracked_block_data:ConvexBlockData

#Public
var selection_type:Selection.Type = Selection.Type.REPLACE

#Private
var block_map:Dictionary = {}

#var record_list:Array[Record] = []


#enum SelectType { REPLACE, ADD, SUBTRACT, TOGGLE }

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
	

func _init():
	command_name = "Select vertices"
	
func do_it():
	print("sel vert do_it()")
	for node_path in block_map.keys():
		print("path %s" % node_path)
		
		var rec:BlockVertexChanges = block_map[node_path]
		var block:CyclopsConvexBlock = builder.get_node(node_path)
			
		var vol:ConvexVolume = ConvexVolume.new()
		vol.init_from_convex_block_data(rec.tracked_block_data)
		
		match selection_type:
			Selection.Type.REPLACE:
				for v_idx in vol.vertices.size():
					var v:ConvexVolume.VertexInfo = vol.vertices[v_idx]
					v.selected = rec.vertex_indices.has(v_idx)
			Selection.Type.ADD:
				for v_idx in rec.vertex_indices:
					var v:ConvexVolume.VertexInfo = vol.vertices[v_idx]
					v.selected = true
			Selection.Type.SUBTRACT:
				for v_idx in rec.vertex_indices:
					var v:ConvexVolume.VertexInfo = vol.vertices[v_idx]
					v.selected = false
			Selection.Type.TOGGLE:
				for v_idx in rec.vertex_indices:
					var v:ConvexVolume.VertexInfo = vol.vertices[v_idx]
					v.selected = !v.selected
		
		block.block_data = vol.to_convex_block_data()

func undo_it():
	print("sel vert undo_it()")
	for node_path in block_map.keys():
		var rec:BlockVertexChanges = block_map[node_path]
		var block:CyclopsConvexBlock = builder.get_node(node_path)
		block.block_data = rec.tracked_block_data
	pass

	
	
	

