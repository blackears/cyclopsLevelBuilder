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
class_name CommandSetMaterial
extends CyclopsCommand

class Target extends RefCounted:
	var block_path:NodePath
	var face_indices:PackedInt32Array

class BlockCache extends RefCounted:
	var path:NodePath
	var data:ConvexBlockData
	var materials:Array[Material]
	
#Public
var setting_material:bool = true
var material_path:String

var setting_color:bool = false
var color:Color = Color.WHITE

var setting_visibility = false
var visibility:bool = true

#Private
var target_list:Array[Target] = []

var cache_list:Array[BlockCache] = []

func add_target(block_path:NodePath, face_indices:PackedInt32Array):
#	print("add target %s %s" % [block_path.get_name(block_path.get_name_count() - 1), face_indices])
	var target:Target = null
	for t in target_list:
		if t.block_path == block_path:
			target = t
			break

	if !target:
		target = Target.new()
		target.block_path = block_path
		target_list.append(target)
	
	for f_idx in face_indices:
		if !target.face_indices.has(f_idx):
			target.face_indices.append(f_idx)
	

func make_cache():
	cache_list = []
	
	for t in target_list:
		var cache:BlockCache = BlockCache.new()
		var block:CyclopsBlock = builder.get_node(t.block_path)
		
		cache.path = block.get_path()
		cache.data = block.block_data
		cache.materials = block.materials.duplicate()
		
		cache_list.append(cache)

func will_change_anything()->bool:
	for t in target_list:
			
		var block:CyclopsBlock = builder.get_node(t.block_path)

		var data:ConvexBlockData = block.block_data
		var vol:ConvexVolume = ConvexVolume.new()
		vol.init_from_convex_block_data(data)
		
		if setting_material:
			#Find index of current material
			var target_material:Material
			var mat_idx:int = -1
			for m_idx in block.materials.size():
				var m:Material = block.materials[m_idx]
				if m.resource_path == material_path:
					mat_idx = m_idx
					break

			if mat_idx == -1:
				return true

			for f_idx in t.face_indices:
				var f:ConvexVolume.FaceInfo = vol.faces[f_idx]
				if f.material_id != mat_idx:
					return true

		if setting_color:
			for f_idx in t.face_indices:
				var f:ConvexVolume.FaceInfo = vol.faces[f_idx]
				if f.color != color:
					return true

		if setting_visibility:
			for f_idx in t.face_indices:
				var f:ConvexVolume.FaceInfo = vol.faces[f_idx]
				if f.visible != visibility:
					return true
		
	return false

func _init():
	command_name = "Set material"
	
func do_it():
	make_cache()
	
#	print("cmd set material %s" % material_path)
	for t in target_list:
		var block:CyclopsBlock = builder.get_node(t.block_path)
		
		var data:ConvexBlockData = block.block_data
		var vol:ConvexVolume = ConvexVolume.new()
		vol.init_from_convex_block_data(data)

		var mat_list:Array[Material] = block.materials.duplicate()
#		print("start mat list")
#		for m in mat_list:
#			print("cur mat %s" % "?" if m == null else m.resource_path)

		var target_material:Material
		for m in mat_list:
			if m.resource_path == material_path:
				target_material = m
				break
				
		if !target_material && ResourceLoader.exists(material_path):
			target_material = load(material_path)
			mat_list.append(target_material)
		
#		print("target mat list")
#		for m in mat_list:
#			print("mat %s" % "?" if m == null else m.resource_path)
		
		var remap_face_idx_to_mat:Array[Material] = []
		
		var ctl_mesh:ConvexVolume = ConvexVolume.new()
		ctl_mesh.init_from_convex_block_data(block.control_mesh.to_convex_block_data())
			
		for f_idx in ctl_mesh.faces.size():
			var f:ConvexVolume.FaceInfo = ctl_mesh.faces[f_idx]
			
			if t.face_indices.has(f_idx):
				remap_face_idx_to_mat.append(target_material)
			elif f.material_id >= 0 && f.material_id < block.materials.size():
				remap_face_idx_to_mat.append(block.materials[f.material_id])
			else:
				remap_face_idx_to_mat.append(null)

#		print("remap faceidx to mat")
#		for m in remap_face_idx_to_mat:
#			print("mat %s" % "?" if m == null else m.resource_path)
		
		#Reduce material list, discarding unused materials
		var mat_list_reduced:Array[Material]
		for m in remap_face_idx_to_mat:
			if m != null && !mat_list_reduced.has(m):
				mat_list_reduced.append(m)

#		print("mat_list_reduced")
#		for m in mat_list_reduced:
#			print("mat %s" % "?" if m == null else m.resource_path)
		
		#Set new face materials using new material ids
		for f_idx in remap_face_idx_to_mat.size():
			#print("face_idx %s" % f_idx)
			var face:ConvexVolume.FaceInfo = ctl_mesh.faces[f_idx]
			var mat = remap_face_idx_to_mat[f_idx]
			#print("mat %s" % "?" if mat == null else mat.resource_path)
			#print("has %s" % mat_list_reduced.has(mat))
			#print("find %s" % mat_list_reduced.find(mat))
			
			if setting_material:
				face.material_id = -1 if mat == null else mat_list_reduced.find(mat)
			#print("face.material_id %s" % face.material_id)
			
		for f_idx in ctl_mesh.faces.size():
			var face:ConvexVolume.FaceInfo = ctl_mesh.faces[f_idx]
			
			if t.face_indices.has(f_idx):
				if setting_color:
					face.color = color
				if setting_visibility:
					face.visible = visibility
		
		block.materials = mat_list_reduced
		block.block_data = ctl_mesh.to_convex_block_data()

func undo_it():
	for cache in cache_list:
		var block:CyclopsBlock = builder.get_node(cache.path)
		block.materials = cache.materials.duplicate()
		block.block_data = cache.data
		
