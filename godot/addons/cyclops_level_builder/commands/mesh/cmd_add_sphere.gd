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
class_name CommandAddSphere
extends CyclopsCommand

#Public data to set before activating command
var blocks_root_path:NodePath
#var origin:Vector3
var block_name:String
var bounds:AABB
var segments:int = 32
var rings:int = 16
var material_path:String
var uv_transform:Transform2D = Transform2D.IDENTITY
var collision_type:Collision.Type = Collision.Type.STATIC
var collision_layers:int = 1
var collision_mask:int = 1

#Private data
var block_path:NodePath

func _init():
	command_name = "Add sphere"

func do_it():
	var block:CyclopsBlock = preload("res://addons/cyclops_level_builder/nodes/cyclops_block.gd").new()
		
	#var blocks_root:Node = builder.get_block_add_parent()
	var block_parent:Node = builder.get_node(blocks_root_path)

	block_parent.add_child(block)
	block.owner = builder.get_editor_interface().get_edited_scene_root()
	block.name = block_name
	block.collision_type = collision_type
	block.collision_layer = collision_layers
	block.collision_mask = collision_mask
	
	var material_id:int = -1
	if ResourceLoader.exists(material_path):
		var mat = load(material_path)
		if mat is Material:
			material_id = 0
			block.materials.append(mat)
		
	
	#print("Block root %s" % block)
	#print("Create bounds %s" % bounds)

	var mesh:ConvexVolume = ConvexVolume.new()
	mesh.init_sphere(bounds, segments, rings, uv_transform, material_id)
#	mesh.init_sphere(bounds, 4, 3, uv_transform, material_id)
	mesh.translate(-bounds.position)

	block.mesh_vector_data = mesh.to_mesh_vector_data()
#	block.block_data = mesh.to_convex_block_data()
	block_path = block.get_path()
	block.global_transform = Transform3D(Basis(), bounds.position)

#	print("AddBlockCommand do_it() %s %s" % [block_inst_id, bounds])
	
func undo_it():
	var block:CyclopsBlock = builder.get_node(block_path)
	block.queue_free()

#	print("AddBlockCommand undo_it()")
