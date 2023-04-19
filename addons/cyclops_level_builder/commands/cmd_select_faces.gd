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
class_name CommandSelectFaces
extends CyclopsCommand

class BlockFaceChanges extends RefCounted:
	var block_path:NodePath
	var face_indices:Array[int] = []
	var tracked_block_data:ConvexBlockData

#Public
var selection_type:Selection.Type = Selection.Type.REPLACE

#Private
var block_map:Dictionary = {}

func add_face(block_path:NodePath, index:int):
	add_faces(block_path, [index])
	
func add_faces(block_path:NodePath, indices:Array[int]):
	var changes:BlockFaceChanges
	if block_map.has(block_path):
		changes = block_map[block_path]
	else:
		changes = BlockFaceChanges.new()
		changes.block_path = block_path
		var block:CyclopsConvexBlock = builder.get_node(block_path)
		changes.tracked_block_data = block.block_data
		block_map[block_path] = changes

	for index in indices:
		if !changes.face_indices.has(index):
			changes.face_indices.append(index)
	

func _init():
	command_name = "Select faces"

func will_change_anything()->bool:
	for block_path in block_map.keys():
		#print("path %s" % node_path)
		
		var rec:BlockFaceChanges = block_map[block_path]
		var block:CyclopsConvexBlock = builder.get_node(block_path)
			
		var vol:ConvexVolume = ConvexVolume.new()
		vol.init_from_convex_block_data(rec.tracked_block_data)
		
		var active_idx:int = -1
		if !rec.face_indices.is_empty():
			active_idx = rec.face_indices[0]
			
		match selection_type:
			Selection.Type.REPLACE:
				for f_idx in vol.faces.size():
					var f:ConvexVolume.FaceInfo = vol.faces[f_idx]
					if f.selected != rec.face_indices.has(f_idx):
						return true
					if f.active != (f_idx == active_idx):
						return true
				
#				for f_idx in vol.faces.size():
#					var f:ConvexVolume.FaceInfo = vol.faces[f_idx]
#					var in_list:bool = rec.face_indices.has(f_idx)
#					if (f.selected && !in_list) || (!f.selected && in_list):
#						return true
			Selection.Type.ADD:
				for f_idx in vol.faces.size():
					var f:ConvexVolume.FaceInfo = vol.faces[f_idx]
					if rec.face_indices.has(f_idx):
						if !f.selected:
							return true
					if f.active != (f_idx == active_idx):
						return true
				
#				for f_idx in rec.face_indices:
#					var f:ConvexVolume.FaceInfo = vol.faces[f_idx]
#					if !f.selected:
#						return true
			Selection.Type.SUBTRACT:
				for f_idx in vol.faces.size():
					var f:ConvexVolume.FaceInfo = vol.faces[f_idx]
					if rec.face_indices.has(f_idx):
						if f.selected:
							return true
				
#				for f_idx in rec.face_indices:
#					var f:ConvexVolume.FaceInfo = vol.faces[f_idx]
#					if f.selected:
#						return false
			Selection.Type.TOGGLE:
				return true
	
	return false
	
func do_it():
	print("sel verts do_it")
	#print("sel vert do_it()")
	for block_path in block_map.keys():
#		print("path %s" % block_path)
		
		var rec:BlockFaceChanges = block_map[block_path]
		var block:CyclopsConvexBlock = builder.get_node(block_path)
			
		var vol:ConvexVolume = ConvexVolume.new()
		vol.init_from_convex_block_data(rec.tracked_block_data)
		
		var active_idx:int = -1
		if !rec.face_indices.is_empty():
			active_idx = rec.face_indices[0]
		
		print("face active index %s" % active_idx)
		
		match selection_type:
			Selection.Type.REPLACE:
				for f_idx in vol.faces.size():
					var f:ConvexVolume.FaceInfo = vol.faces[f_idx]
					f.selected = rec.face_indices.has(f_idx)
					f.active = f_idx == active_idx
#					print("set face %s %s %s" % [f_idx, f.selected, f.active])

			Selection.Type.ADD:
				for f_idx in vol.faces.size():
					var f:ConvexVolume.FaceInfo = vol.faces[f_idx]
					if rec.face_indices.has(f_idx):
						f.selected = true
					f.active = f_idx == active_idx
					
			Selection.Type.SUBTRACT:
				for f_idx in vol.faces.size():
					var f:ConvexVolume.FaceInfo = vol.faces[f_idx]
					if rec.face_indices.has(f_idx):
						f.selected = false
						f.active = false
			Selection.Type.TOGGLE:
				for f_idx in vol.faces.size():
					var f:ConvexVolume.FaceInfo = vol.faces[f_idx]
					if rec.face_indices.has(f_idx):
						f.selected = !f.selected
					f.active = f.selected && f_idx == active_idx

		#Synchronize edge & vertex selection
		var selected_verts:Array[int] = []
		for f in vol.faces:
			if f.selected:
				for v_idx in f.vertex_indices:
					if !selected_verts.has(v_idx):
						selected_verts.append(v_idx)
		for v_idx in vol.vertices.size():
			vol.vertices[v_idx].selected = selected_verts.has(v_idx)
		
		vol.update_edge_and_face_selection_from_vertices()
		block.block_data = vol.to_convex_block_data()

func undo_it():
#	print("undo_it() select faces")
	for block_path in block_map.keys():
		var rec:BlockFaceChanges = block_map[block_path]
		var block:CyclopsConvexBlock = builder.get_node(block_path)
		block.block_data = rec.tracked_block_data

	
	
	

