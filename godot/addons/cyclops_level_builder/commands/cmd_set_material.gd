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
	var data:MeshVectorData
	var materials:Array[Material]

#Public
var setting_material:bool = true
var material_path:String

var setting_color:bool = false
var color:Color = Color.WHITE

var setting_visibility:bool = false
var visibility:bool = true

var painting_uv:bool = false
var uv_matrix:Transform2D = Transform2D.IDENTITY

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
		cache.data = block.mesh_vector_data
		cache.materials = block.materials.duplicate()

		cache_list.append(cache)

func will_change_anything()->bool:
	return !target_list.is_empty()
	
func _init():
	command_name = "Set material"

func do_it():
	make_cache()

	for tgt in target_list:
		var block:CyclopsBlock = builder.get_node(tgt.block_path)

		var data:MeshVectorData = block.mesh_vector_data
		var vol:ConvexVolume = ConvexVolume.new()
		vol.init_from_mesh_vector_data(data)

		if setting_material:

			var target_material:Material = null
			if ResourceLoader.exists(material_path, "Material"):
				#print("loading material ", material_path)
				var mat = load(material_path)
				target_material = mat if mat is Material else null

			var mat_reindex:Dictionary
			var mat_list_reduced:Array[Material]

			for f_idx in vol.faces.size():
				var f:ConvexVolume.FaceInfo = vol.faces[f_idx]

				var mat_to_apply:Material

				if tgt.face_indices.has(f_idx):
					mat_to_apply = target_material
				else:
					mat_to_apply = null if f.material_id == -1 else block.materials[f.material_id]

				if !mat_to_apply:
					f.material_id = -1
				elif !mat_reindex.has(mat_to_apply):
					var new_idx = mat_reindex.size()
					mat_reindex[mat_to_apply] = new_idx
					mat_list_reduced.append(mat_to_apply)
					f.material_id = new_idx
				else:
					f.material_id = mat_reindex[mat_to_apply]

			block.materials = mat_list_reduced
			
		#Set other properties
		for f_idx in vol.faces.size():
			if tgt.face_indices.has(f_idx):
				var f:ConvexVolume.FaceInfo = vol.faces[f_idx]
				if setting_color:
					f.color = color
					for v_idx in f.vertex_indices:
						var fv:ConvexVolume.FaceVertexInfo = \
							vol.get_face_vertex(f_idx, v_idx)
						fv.color = color
				if setting_visibility:
					f.visible = visibility
				if painting_uv:
					f.uv_transform = uv_matrix
			
		block.mesh_vector_data = vol.to_mesh_vector_data()


func undo_it():
	for cache in cache_list:
		var block:CyclopsBlock = builder.get_node(cache.path)
		block.materials = cache.materials.duplicate()
		block.mesh_vector_data = cache.data

