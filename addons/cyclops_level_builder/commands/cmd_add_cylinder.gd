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
class_name CommandAddCylinder
extends CyclopsCommand

#Public data to set before activating command
var blocks_root_path:NodePath
#var block_name:String
var block_name_prefix:String = "Block_"
var origin:Vector3
var axis_normal:Vector3
var height:float
var radius_inner:float
var radius_outer:float
var segments:int
var tube:bool = false

var material_path:String
var uv_transform:Transform2D = Transform2D.IDENTITY

#Private data
var block_paths:Array[NodePath]

func _init():
	command_name = "Add cylinder"

func create_block(blocks_root:CyclopsBlocks, mat:Material)->CyclopsConvexBlock:
	var block:CyclopsConvexBlock = preload("../nodes/cyclops_convex_block.gd").new()
	blocks_root.add_child(block)
	block.owner = builder.get_editor_interface().get_edited_scene_root()
	block.name = GeneralUtil.find_unique_name(builder.active_node, block_name_prefix)

	if mat:
		block.materials.append(mat)
			
	return block


func do_it():
	var blocks_root:CyclopsBlocks = builder.get_node(blocks_root_path)
	
	var material:Material
	var material_id:int = -1
	if ResourceLoader.exists(material_path):
		var mat = load(material_path)
		if mat is Material:
			material_id = 0
			material = mat
	
	if tube:
		var bounding_points_inner:PackedVector3Array = MathUtil.create_circle_points(origin, axis_normal, radius_inner, segments)
		var bounding_points_outer:PackedVector3Array = MathUtil.create_circle_points(origin, axis_normal, radius_outer, segments)
		
		for p_idx0 in bounding_points_inner.size():
			var p_idx1:int = wrap(p_idx0 + 1, 0, bounding_points_inner.size())
			
			var block:CyclopsConvexBlock = create_block(blocks_root, material)
			
			var mesh:ConvexVolume = ConvexVolume.new()
			var base_points:PackedVector3Array = [bounding_points_inner[p_idx0], bounding_points_inner[p_idx1], bounding_points_outer[p_idx1], bounding_points_outer[p_idx0]]
			
			mesh.init_prism(base_points, axis_normal * height, uv_transform, material_id)

			block.block_data = mesh.to_convex_block_data()
			block_paths.append(block.get_path())
		
	else:
		var block:CyclopsConvexBlock = create_block(blocks_root, material)
		
		var bounding_points:PackedVector3Array = MathUtil.create_circle_points(origin, axis_normal, radius_outer, segments)
		var mesh:ConvexVolume = ConvexVolume.new()
		mesh.init_prism(bounding_points, axis_normal * height, uv_transform, material_id)

		block.block_data = mesh.to_convex_block_data()
		block_paths.append(block.get_path())

func undo_it():
	for path in block_paths:
		var block:CyclopsConvexBlock = builder.get_node(path)
		block.queue_free()
