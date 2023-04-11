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
class_name CommandSelectEdges
extends CyclopsCommand

class BlockEdgeChanges extends RefCounted:
	var block_path:NodePath
	var edge_indices:Array[int] = []
	var tracked_block_data:ConvexBlockData

#Public
var selection_type:Selection.Type = Selection.Type.REPLACE

#Private
var block_map:Dictionary = {}


func add_edge(block_path:NodePath, index:int):
	var changes:BlockEdgeChanges
	if block_map.has(block_path):
		changes = block_map[block_path]
	else:
		changes = BlockEdgeChanges.new()
		changes.block_path = block_path
		var block:CyclopsConvexBlock = builder.get_node(block_path)
		changes.tracked_block_data = block.block_data
		block_map[block_path] = changes

	if !changes.edge_indices.has(index):
		changes.edge_indices.append(index)
	

func _init():
	command_name = "Select edges"
	
func do_it():
#	print("sel verts do_it")
	#print("sel vert do_it()")
	for block_path in block_map.keys():
		#print("path %s" % node_path)
		
		var rec:BlockEdgeChanges = block_map[block_path]
		var block:CyclopsConvexBlock = builder.get_node(block_path)
			
		var vol:ConvexVolume = ConvexVolume.new()
		vol.init_from_convex_block_data(rec.tracked_block_data)
		
		match selection_type:
			Selection.Type.REPLACE:
				for e_idx in vol.edges.size():
					var e:ConvexVolume.EdgeInfo = vol.edges[e_idx]
					e.selected = rec.edge_indices.has(e_idx)
			Selection.Type.ADD:
				for e_idx in rec.edge_indices:
					var e:ConvexVolume.EdgeInfo = vol.edges[e_idx]
					e.selected = true
			Selection.Type.SUBTRACT:
				for e_idx in rec.edge_indices:
					var e:ConvexVolume.EdgeInfo = vol.edges[e_idx]
					e.selected = false
			Selection.Type.TOGGLE:
				for e_idx in rec.edge_indices:
					var e:ConvexVolume.EdgeInfo = vol.edges[e_idx]
					e.selected = !e.selected
		
		block.block_data = vol.to_convex_block_data()

func undo_it():
#	print("sel verts undo_it")
	#print("sel vert undo_it()")
	for block_path in block_map.keys():
		var rec:BlockEdgeChanges = block_map[block_path]
		var block:CyclopsConvexBlock = builder.get_node(block_path)
		block.block_data = rec.tracked_block_data

	
	
	

