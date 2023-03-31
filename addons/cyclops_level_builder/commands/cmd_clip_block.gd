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
var material_id:int = 0

#Private
var block_sibling_name:String
var old_block_data:ConvexBlockData
var block_sibling_path:NodePath

func _init():
	command_name = "Clip block"

func do_it():
	var blocks_root:CyclopsBlocks = builder.get_node(blocks_root_path)
	var block:CyclopsBlock = builder.get_node(block_path)
	
	old_block_data = block.block_data.duplicate()
	
	var cut_plane_reverse:Plane = Plane(-cut_plane.normal, cut_plane.get_center())

	#var block_data:ConvexBlockData = clipped_block.block_data
	var vol0:ConvexVolume = ConvexVolume.new()
	vol0.init_from_convex_block_data(old_block_data)
	vol0.add_face(cut_plane, builder.tool_uv_transform, builder.tool_material_id)
	
	var vol1:ConvexVolume = ConvexVolume.new()
	vol1.init_from_convex_block_data(old_block_data)
	vol1.add_face(cut_plane_reverse, builder.tool_uv_transform, builder.tool_material_id)

	#Set data of existing block
	block.block_data = vol0.to_convex_block_data()
	
	#Create second block
	var block_sibling:CyclopsBlock = preload("../controls/cyclops_block.gd").new()
	
	blocks_root.add_child(block_sibling)
	block_sibling.owner = builder.get_editor_interface().get_edited_scene_root()
	block_sibling.name = block_sibling_name
	block_sibling_path = block_sibling.get_path()

	block_sibling.block_data = vol1.to_convex_block_data()
	

func undo_it():
	var block:CyclopsBlock = builder.get_node(block_path)
	block.block_data = old_block_data
	
	var block_sibling:CyclopsBlock = builder.get_node(block_sibling_path)
	block_sibling.queue_free()
	
	
