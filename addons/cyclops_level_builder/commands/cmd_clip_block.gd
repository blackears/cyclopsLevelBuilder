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
class_name CommandClipBlock
extends CyclopsCommand

#Public data to set before activating command
var blocks_root_path:NodePath
var block_path:NodePath
var cut_plane:Plane
var uv_transform:Transform2D = Transform2D.IDENTITY
var material_path:String = ""

#Private
var block_sibling_name:String
var old_block_data:ConvexBlockData
var old_mat_list:Array[Material]
var block_sibling_path:NodePath

func _init():
	command_name = "Clip block"

func get_material_index(mat_list:Array[Material], path:String)->int:
	if path.is_empty():
		return -1
	for i in mat_list.size():
		var mat:Material = mat_list[i]
		if mat != null && mat.resource_path == path:
			return i
	return -1

func do_it():
	var blocks_root:CyclopsBlocks = builder.get_node(blocks_root_path)
	var block:CyclopsConvexBlock = builder.get_node(block_path)
	
	old_block_data = block.block_data.duplicate()
	old_mat_list = block.materials.duplicate()
	
	var new_mat_list0:Array[Material] = old_mat_list.duplicate()
	
	var cut_mat_idx = get_material_index(old_mat_list, material_path)
	if cut_mat_idx == -1:
		var mat = load(material_path)
		if mat is Material:
			cut_mat_idx = new_mat_list0.size()
			new_mat_list0.append(mat)
	
	
	var new_mat_list1:Array[Material] = new_mat_list0.duplicate()
	
	var cut_plane_reverse:Plane = Plane(-cut_plane.normal, cut_plane.get_center())

	var vol0:ConvexVolume = block.control_mesh.cut_with_plane(cut_plane, uv_transform, cut_mat_idx)
	var vol1:ConvexVolume = block.control_mesh.cut_with_plane(MathUtil.flip_plane(cut_plane), uv_transform, cut_mat_idx)

	#Set data of existing block
	block.block_data = vol0.to_convex_block_data()
	block.materials = new_mat_list0
	
	#Create second block
	var block_sibling:CyclopsConvexBlock = preload("../nodes/cyclops_convex_block.gd").new()
	
	blocks_root.add_child(block_sibling)
	block_sibling.owner = builder.get_editor_interface().get_edited_scene_root()
	block_sibling.name = block_sibling_name
	block_sibling.selected = block.selected
	block_sibling_path = block_sibling.get_path()

	block_sibling.block_data = vol1.to_convex_block_data()
	block_sibling.materials = new_mat_list1
	

func undo_it():
	var block:CyclopsConvexBlock = builder.get_node(block_path)
	block.block_data = old_block_data
	block.materials = old_mat_list.duplicate()
	
	var block_sibling:CyclopsConvexBlock = builder.get_node(block_sibling_path)
	block_sibling.queue_free()
	
	
