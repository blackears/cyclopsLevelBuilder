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
class_name CommandSelectFaceVertices
extends CyclopsCommand

class BlockVertexChanges extends RefCounted:
	var block_path:NodePath
	var face_vertex_indices:Array[int] = []
	var tracked_block_data:MeshVectorData

#Public
var selection_type:Selection.Type = Selection.Type.REPLACE

#Private
var block_map:Dictionary = {}




func add_face_vertex(block_path:NodePath, index:int):
	add_face_vertices(block_path, [index])
	
func add_face_vertices(block_path:NodePath, indices:Array[int]):
	var changes:BlockVertexChanges
	if block_map.has(block_path):
		changes = block_map[block_path]
	else:
		changes = BlockVertexChanges.new()
		changes.block_path = block_path
		var block:CyclopsBlock = builder.get_node(block_path)
		changes.tracked_block_data = block.mesh_vector_data
		block_map[block_path] = changes

	for index in indices:
		if !changes.face_vertex_indices.has(index):
			changes.face_vertex_indices.append(index)
	

func _init():
	command_name = "Select face vertices"


func will_change_anything()->bool:
	for block_path in block_map.keys():
		#print("path %s" % node_path)
		
		var rec:BlockVertexChanges = block_map[block_path]
		var block:CyclopsBlock = builder.get_node(block_path)
			
		var vol:ConvexVolume = ConvexVolume.new()
		vol.init_from_mesh_vector_data(rec.tracked_block_data)

		if !rec.face_vertex_indices.is_empty():
			if vol.active_vertex != rec.face_vertex_indices[0]:
				return true
		
		match selection_type:
			Selection.Type.REPLACE:
				for fv_idx in vol.vertices.size():
					var v:ConvexVolume.VertexInfo = vol.vertices[fv_idx]
					if v.selected != rec.face_vertex_indices.has(fv_idx):
						return true
			Selection.Type.ADD:
				for fv_idx in rec.face_vertex_indices:
					var v:ConvexVolume.VertexInfo = vol.vertices[fv_idx]
					if rec.face_vertex_indices.has(fv_idx):
						if !v.selected:
							return true
			Selection.Type.SUBTRACT:
				for fv_idx in rec.face_vertex_indices:
					var v:ConvexVolume.VertexInfo = vol.vertices[fv_idx]
					if rec.face_vertex_indices.has(fv_idx):
						if v.selected:
							return true
			Selection.Type.TOGGLE:
				return true
	
	return false

	
func do_it():
#	print("sel verts do_it")
	for block_path in block_map.keys():
		#print("path %s" % node_path)
		
		var rec:BlockVertexChanges = block_map[block_path]
		var block:CyclopsBlock = builder.get_node(block_path)
		
		var vol:ConvexVolume = ConvexVolume.new()
		vol.init_from_mesh_vector_data(rec.tracked_block_data)
		
		if !rec.face_vertex_indices.is_empty():
			var active_index:int = rec.face_vertex_indices[0]
			#print("active_index ", active_index)
			
			match selection_type:
				Selection.Type.REPLACE:
					vol.active_face_vertex = active_index
				Selection.Type.ADD:
					vol.active_face_vertex = active_index
				Selection.Type.SUBTRACT:
					if rec.face_vertex_indices.has(vol.active_face_vertex):
						vol.active_face_vertex = -1
				Selection.Type.TOGGLE:
					if rec.face_vertex_indices.has(vol.active_face_vertex):
						vol.active_face_vertex = -1
					elif !vol.vertices[active_index].selected:
						vol.active_face_vertex = active_index
		else:
			if selection_type == Selection.Type.REPLACE:
				vol.active_face_vertex = -1
		
		match selection_type:
			Selection.Type.REPLACE:
				for fv_idx in vol.face_vertices.size():
					var fv:ConvexVolume.FaceVertexInfo = vol.face_vertices[fv_idx]
					fv.selected = rec.face_vertex_indices.has(fv_idx)
					
			Selection.Type.ADD:
				for fv_idx in vol.face_vertices.size():
					var fv:ConvexVolume.FaceVertexInfo = vol.face_vertices[fv_idx]
					if rec.face_vertex_indices.has(fv_idx):
						fv.selected = true
						
			Selection.Type.SUBTRACT:
				for fv_idx in vol.face_vertices.size():
					var fv:ConvexVolume.FaceVertexInfo = vol.face_vertices[fv_idx]
					if rec.face_vertex_indices.has(fv_idx):
						fv.selected = false
						
			Selection.Type.TOGGLE:
				for fv_idx in vol.face_vertices.size():
					var fv:ConvexVolume.FaceVertexInfo = vol.face_vertices[fv_idx]
					if rec.face_vertex_indices.has(fv_idx):
						fv.selected = !fv.selected
		
		#vol.update_edge_and_face_selection_from_vertices()
		#print("vol.active_vertex ", vol.active_vertex)
		block.mesh_vector_data = vol.to_mesh_vector_data()
		#print("block.mesh_vector_data.active_vertex ", block.mesh_vector_data.active_vertex)

	builder.selection_changed.emit()

func undo_it():
#	print("sel verts undo_it")
	#print("sel vert undo_it()")
	for block_path in block_map.keys():
		var rec:BlockVertexChanges = block_map[block_path]
		var block:CyclopsBlock = builder.get_node(block_path)
		block.mesh_vector_data = rec.tracked_block_data

	builder.selection_changed.emit()
