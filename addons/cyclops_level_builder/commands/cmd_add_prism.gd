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
class_name CommandAddPrism
extends CyclopsCommand

var blocks_root_path:NodePath
var block_name:String
var base_polygon:PackedVector3Array
var extrude:Vector3
var uv_transform:Transform2D
var material_path:String

#Private
var block_path:NodePath

func _init():
	command_name = "Add prism"

func do_it():
	var block:CyclopsConvexBlock = preload("../nodes/cyclops_convex_block.gd").new()
	
	var blocks_root:CyclopsBlocks = builder.get_node(blocks_root_path)
	blocks_root.add_child(block)
	block.owner = builder.get_editor_interface().get_edited_scene_root()
#	block.owner = block_owner
	block.name = block_name

	var material_id:int = -1
	if ResourceLoader.exists(material_path):
		var mat = load(material_path)
		if mat is Material:
			material_id = 0
			block.materials.append(mat)
	
	var mesh:ConvexVolume = ConvexVolume.new()
	mesh.init_prism(base_polygon, extrude, uv_transform, material_id)

	block.block_data = mesh.to_convex_block_data()
	block_path = block.get_path()

#	print("AddBlockCommand do_it() %s %s" % [block_inst_id, bounds])
	
func undo_it():
	var block:CyclopsConvexBlock = builder.get_node(block_path)
	block.queue_free()

#	print("AddBlockCommand undo_it()")
