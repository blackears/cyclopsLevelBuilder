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
	var face_ids:PackedInt32Array

class BlockCache extends RefCounted:
	var path:NodePath
	var data:ConvexBlockData
	var materials:Array[Material]
	
#Public
var material_path:String

#Private
var target_list:Array[Target] = []

var cache_list:Array[BlockCache] = []

func add_target(block_path:NodePath, face_ids:PackedInt32Array):
#	print("add target %s %s" % [block_path, face_ids])
	var target:Target = Target.new()
	target.block_path = block_path
	target.face_ids = face_ids
	
	target_list.append(target)

func make_cache():
	cache_list = []
	
	for t in target_list:
		var cache:BlockCache = BlockCache.new()
		var block:CyclopsConvexBlock = builder.get_node(t.block_path)
		
		cache.path = block.get_path()
		cache.data = block.block_data
		cache.materials = block.materials.duplicate()
		
		cache_list.append(cache)

func _init():
	command_name = "Set material"
	
func do_it():
	make_cache()
	
#	print("cmd set material")
	for t in target_list:
		var block:CyclopsConvexBlock = builder.get_node(t.block_path)
		
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
		if !target_material:				
			target_material = load(material_path)
			mat_list.append(target_material)
		
#		print("target mat list")
#		for m in mat_list:
#			print("mat %s" % "?" if m == null else m.resource_path)
		
		var remap_face_idx_to_mat:Array[Material] = []
		
		var ctl_mesh:ConvexVolume = ConvexVolume.new()
		ctl_mesh.init_from_convex_block_data(block.control_mesh.to_convex_block_data())
			
		for f in ctl_mesh.faces:
			if t.face_ids.has(f.id):
				remap_face_idx_to_mat.append(target_material)
			elif f.id >= 0 && f.id < block.materials.size():
				remap_face_idx_to_mat.append(block.materials[f.material_id])
			else:
				remap_face_idx_to_mat.append(null)

#		print("remap faceidx to mat")
#		for m in remap_face_idx_to_mat:
#			print("mat %s" % "?" if m == null else m.resource_path)
		
		#Reduce material list, discarding unused materials
		var mat_reorder:Array[Material]
		for m in remap_face_idx_to_mat:
			if m != null && !mat_reorder.has(m):
				mat_reorder.append(m)

#		print("mat reorder")
#		for m in mat_reorder:
#			print("mat %s" % "?" if m == null else m.resource_path)
		
		#Set new face materials using new material ids
		for face_idx in remap_face_idx_to_mat.size():
#			print("face_idx %s" % face_idx)
			var face:ConvexVolume.FaceInfo = ctl_mesh.faces[face_idx]
			var mat = remap_face_idx_to_mat[face_idx]
#			print("mat %s" % "?" if mat == null else mat.resource_path)
#			print("has %s" % mat_reorder.has(mat))
#			print("find %s" % mat_reorder.find(mat))
			
			face.material_id = -1 if mat == null else mat_reorder.find(mat)
#			print("face.material_id %s" % face.material_id)
		
		block.materials = mat_reorder
		block.block_data = ctl_mesh.to_convex_block_data()

func undo_it():
	for cache in cache_list:
		var block:CyclopsConvexBlock = builder.get_node(cache.path)
		block.materials = cache.materials.duplicate()
		block.block_data = cache.data
		
