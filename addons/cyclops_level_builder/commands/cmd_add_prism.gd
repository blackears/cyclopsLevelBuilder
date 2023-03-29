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

var blocks_root_inst_id:int
var block_name:String
var block_owner:Node
#var bounds:AABB
var base_polygon:PackedVector3Array
var extrude:Vector3
#	var block:CyclopsBlock
var block_inst_id:int

func _init():
	command_name = "Add prism"

func do_it():
	var block:CyclopsBlock = preload("../controls/cyclops_block.gd").new()
	
	var blocks_root = instance_from_id(blocks_root_inst_id)
	blocks_root.add_child(block)
	block.owner = block_owner
	block.name = block_name
	
	var mesh:ConvexVolume = ConvexVolume.new()
	mesh.init_prisim(base_polygon, extrude)

	block.block_data = mesh.to_convex_block_data()
	block_inst_id = block.get_instance_id()

#	print("AddBlockCommand do_it() %s %s" % [block_inst_id, bounds])
	
func undo_it():
	var block = instance_from_id(block_inst_id)
	block.queue_free()

#	print("AddBlockCommand undo_it()")
