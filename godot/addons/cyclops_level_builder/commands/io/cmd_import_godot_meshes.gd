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
class_name CommandImportGodotMeshes
extends CyclopsCommand

@export var source_nodes:Array[NodePath]
@export var target_parent:NodePath
@export var collision_type:Collision.Type = Collision.Type.STATIC
@export var collision_layers:int = 1
@export var collision_mask:int = 1

var added_blocks:Array[NodePath]

func _init():
	command_name = "Import Godot Meshes"

func will_change_anything()->bool:
	return !target_parent.is_empty() && !source_nodes.is_empty()

func do_it():
	var tgt_parent_node:Node = builder.get_node(target_parent)
	if !tgt_parent_node || !(tgt_parent_node is Node3D):
		return
	
	for src_path in source_nodes:
		var src_node:Node = builder.get_node(src_path)
		if !src_node is MeshInstance3D:
			continue
		
		var src_mesh_inst:MeshInstance3D = src_node
		if !src_mesh_inst.mesh:
			continue

		var block:CyclopsBlock = preload("res://addons/cyclops_level_builder/nodes/cyclops_block.gd").new()

		var blocks_root:Node3D = tgt_parent_node
		blocks_root.add_child(block)
		block.owner = builder.get_editor_interface().get_edited_scene_root()
		block.name = src_node.name
		block.global_transform = src_node.global_transform
		block.collision_type = collision_type
		block.collision_layer = collision_layers
		block.collision_mask = collision_mask

		added_blocks.append(block.get_path())

		var best_mat:Material
		var points:PackedVector3Array
		for i in src_mesh_inst.mesh.get_surface_count():
			var mat:Material = src_mesh_inst.mesh.surface_get_material(i)
			if best_mat != null:
				best_mat = mat
			
			var surface_arrs:Array = src_mesh_inst.mesh.surface_get_arrays(i)
			
			if surface_arrs[Mesh.ARRAY_INDEX].is_empty():
				for pt in surface_arrs[Mesh.ARRAY_VERTEX]:
					points.append(pt)
			else:
				for idx in surface_arrs[Mesh.ARRAY_INDEX]:
					points.append(surface_arrs[Mesh.ARRAY_VERTEX][idx])
				
		if best_mat:
			block.materials = [best_mat]
			
		var vol:ConvexVolume = ConvexVolume.new()
		vol.init_from_points(points, Transform2D.IDENTITY, 0 if best_mat else -1)
		block.mesh_vector_data = vol.to_mesh_vector_data()
		
	
func undo_it():
	for block_path in added_blocks:
		var block:CyclopsBlock = builder.get_node(block_path)
		block.queue_free()

	added_blocks.clear()

