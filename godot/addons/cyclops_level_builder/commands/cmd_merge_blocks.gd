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
class_name CommandMergeBlocks
extends CyclopsCommand

#Public 
var block_paths:Array[NodePath]
var block_name_prefix:String = "Block_"

#Private
var tracked_blocks:Array[TrackedBlock]
var merged_block_data:ConvexBlockData
var merged_mat_list:Array[Material]
var merged_block_path:NodePath
var world_pivot:Vector3
			
func _init():
	command_name = "Merge blocks"

func get_best_face(centroid:Vector3, ref_list:Array[NodePath])->Array:
	var best_face:ConvexVolume.FaceInfo
	var best_dist:float = INF
	var best_block:CyclopsBlock
	
	for block_path in ref_list:
		var block:CyclopsBlock = builder.get_node(block_path)
		var vol:ConvexVolume = block.control_mesh
		for f in vol.faces:
			var face_center:Vector3 = f.get_centroid()
			var offset:float = centroid.distance_squared_to(face_center)
			if offset < best_dist:
				best_dist = offset
				best_face = f
				best_block = block
				
	if best_face.material_id == -1:
		return [best_face, null]
	return [best_face, best_block.materials[best_face.material_id]]

func copy_face_attributes(target:ConvexVolume, ref_list:Array[NodePath])->Array[Material]:
	var mat_list:Array[Material]
	
	for f in target.faces:
		var centroid:Vector3 = f.get_centroid()
		var res:Array = get_best_face(centroid, ref_list)
		var ref_face:ConvexVolume.FaceInfo = res[0]
		var material:Material = res[1]
		
		var mat_idx:int = -1
		if material != null:
			mat_idx = mat_list.find(material)
			if mat_idx == -1:
				mat_idx = mat_list.size()
				mat_list.append(material)
		
		f.material_id = mat_idx
		f.uv_transform = ref_face.uv_transform
		f.selected = ref_face.selected
		
	return mat_list

func do_it():
	
	if tracked_blocks.is_empty():
		var points:PackedVector3Array
		
		var first_block:CyclopsBlock = builder.get_node(block_paths[0])
		world_pivot = first_block.global_transform.origin
		
		for path in block_paths:
			var block:CyclopsBlock = builder.get_node(path)
			var tracker:TrackedBlock = TrackedBlock.new(block)
			tracked_blocks.append(tracker)
			
			var world_block:ConvexVolume = ConvexVolume.new()
			world_block.init_from_convex_block_data(block.control_mesh.to_convex_block_data())
			world_block.transform(block.global_transform)
			points.append_array(world_block.get_points())
			
		var merged_vol:ConvexVolume = ConvexVolume.new()
		merged_vol.init_from_points(points)
		merged_mat_list = copy_face_attributes(merged_vol, block_paths)
		merged_vol.translate(-world_pivot)
		merged_block_data = merged_vol.to_convex_block_data()
		


	#Delete source blocks
	for block_path in block_paths:
		var del_block:CyclopsBlock = builder.get_node(block_path)
		del_block.queue_free()

	#Create block	
	var block:CyclopsBlock = preload("../nodes/cyclops_block.gd").new()
	var parent:Node = builder.get_node(tracked_blocks[0].path_parent)
	parent.add_child(block)
	block.owner = builder.get_editor_interface().get_edited_scene_root()
	block.name = GeneralUtil.find_unique_name(parent, block_name_prefix)
	block.block_data = merged_block_data
	block.materials = merged_mat_list
	block.global_transform = Transform3D.IDENTITY.translated(world_pivot)
	#block.materials
	
	merged_block_path = block.get_path()
	
func undo_it():
#	var blocks_root:CyclopsBlocks = builder.get_node(blocks_root_path)
	var merged_block:CyclopsBlock = builder.get_node(merged_block_path)
	merged_block.queue_free()
	
#	for i in blocks_to_merge.size():
	for tracked in tracked_blocks:
		var parent = builder.get_node(tracked.path_parent)
		
		var block:CyclopsBlock = preload("../nodes/cyclops_block.gd").new()
		block.block_data = tracked.data
		block.materials = tracked.materials
		block.name = tracked.name
		#block.selected = tracked.selected
		block.global_transform = tracked.world_xform
		
		parent.add_child(block)
		block.owner = builder.get_editor_interface().get_edited_scene_root()
