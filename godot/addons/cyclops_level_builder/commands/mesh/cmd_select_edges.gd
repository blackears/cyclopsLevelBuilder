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
	var tracked_block_data:MeshVectorData

#Public
var selection_type:Selection.Type = Selection.Type.REPLACE

#Private
var block_map:Dictionary = {}


func add_edge(block_path:NodePath, index:int):
	add_edges(block_path, [index])
	
func add_edges(block_path:NodePath, indices:Array[int]):
	var changes:BlockEdgeChanges
	if block_map.has(block_path):
		changes = block_map[block_path]
	else:
		changes = BlockEdgeChanges.new()
		changes.block_path = block_path
		var block:CyclopsBlock = builder.get_node(block_path)
		changes.tracked_block_data = block.mesh_vector_data
		block_map[block_path] = changes
	
	for index in indices:
		if !changes.edge_indices.has(index):
			changes.edge_indices.append(index)
	

func _init():
	command_name = "Select edges"

func will_change_anything()->bool:
	for block_path in block_map.keys():
		#print("path %s" % node_path)
		
		var rec:BlockEdgeChanges = block_map[block_path]
		var block:CyclopsBlock = builder.get_node(block_path)
			
		var vol:ConvexVolume = ConvexVolume.new()
		vol.init_from_mesh_vector_data(rec.tracked_block_data)

		if !rec.edge_indices.is_empty():
			if vol.active_edge != rec.edge_indices[0]:
				return true
		
		match selection_type:
			Selection.Type.REPLACE:
				for e_idx in vol.edges.size():
					var e:ConvexVolume.EdgeInfo = vol.edges[e_idx]
					if e.selected != rec.edge_indices.has(e_idx):
						#print("will change SREP")
						return true
			Selection.Type.ADD:
				for e_idx in rec.edge_indices:
					var e:ConvexVolume.EdgeInfo = vol.edges[e_idx]
					if rec.edge_indices.has(e_idx):
						if !e.selected:
							#print("will change ADD")
							return true
			Selection.Type.SUBTRACT:
				for e_idx in rec.edge_indices:
					var e:ConvexVolume.EdgeInfo = vol.edges[e_idx]
					if rec.edge_indices.has(e_idx):
						if e.selected:
							#print("will change SUB")
							return true
			Selection.Type.TOGGLE:
				#print("will change TOG")
				return true
	
	return false

func do_it():
#	print("sel edges do_it")
	
	for block_path in block_map.keys():
#		print("path %s" % block_path)
		
		var rec:BlockEdgeChanges = block_map[block_path]
		var block:CyclopsBlock = builder.get_node(block_path)
			
		var vol:ConvexVolume = ConvexVolume.new()
		vol.init_from_mesh_vector_data(rec.tracked_block_data)
		
		if !rec.edge_indices.is_empty():
			var active_index:int = rec.edge_indices[0]
			match selection_type:
				Selection.Type.REPLACE:
					vol.active_edge = active_index
				Selection.Type.ADD:
					vol.active_edge = active_index
				Selection.Type.SUBTRACT:
					if rec.edge_indices.has(vol.active_edge):
						vol.active_edge = -1
				Selection.Type.TOGGLE:
					if rec.edge_indices.has(vol.active_edge):
						vol.active_edge = -1
					elif !vol.edges[active_index].selected:
						vol.active_edge = active_index
								
		match selection_type:
			Selection.Type.REPLACE:
				for e_idx in vol.edges.size():
					var e:ConvexVolume.EdgeInfo = vol.edges[e_idx]
					e.selected = rec.edge_indices.has(e_idx)
					
			Selection.Type.ADD:
				for e_idx in vol.edges.size():
					var e:ConvexVolume.EdgeInfo = vol.edges[e_idx]
					if rec.edge_indices.has(e_idx):
						e.selected = true
						
			Selection.Type.SUBTRACT:
				for e_idx in vol.edges.size():
					var e:ConvexVolume.EdgeInfo = vol.edges[e_idx]
					if rec.edge_indices.has(e_idx):
						e.selected = false
						
			Selection.Type.TOGGLE:
				for e_idx in vol.edges.size():
					var e:ConvexVolume.EdgeInfo = vol.edges[e_idx]
					if rec.edge_indices.has(e_idx):
						#print("flipping %s" % e.selected)
						e.selected = !e.selected

		if vol.active_edge != -1:
			if vol.active_edge >= vol.edges.size() || !vol.edges[vol.active_edge].selected:
				vol.active_edge = -1

		block.mesh_vector_data = vol.to_mesh_vector_data()
		
	builder.selection_changed.emit()

func undo_it():
#	print("sel verts undo_it")
	#print("sel vert undo_it()")
	for block_path in block_map.keys():
		var rec:BlockEdgeChanges = block_map[block_path]
		var block:CyclopsBlock = builder.get_node(block_path)
		block.mesh_vector_data = rec.tracked_block_data

	builder.selection_changed.emit()
	
	
	

