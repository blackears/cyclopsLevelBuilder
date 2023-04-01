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
class_name CommandDeleteBlocks
extends CyclopsCommand

#Public data to set before activating command
var blocks_root_path:NodePath

#Private
var blocks_to_delete:Array[NodePath]
var tracked_block_data:Array[ConvexBlockData]
var block_names:Array[String]
var block_selected:Array[bool]

func _init():
	command_name = "Delete blocks"

#Add blocks to be moved here
func add_block(block_path:NodePath):
	blocks_to_delete.append(block_path)
	
	var block:CyclopsConvexBlock = builder.get_node(block_path)
	block_names.append(block.name)
	block_selected.append(block.selected)
	tracked_block_data.append(block.block_data.duplicate())

func do_it():
	#print("doing delete")
	for block_path in blocks_to_delete:
		var block:CyclopsConvexBlock = builder.get_node(block_path)
		block.queue_free()

func undo_it():
	#print("undoing delete")
	print("undoing delete %s" % blocks_root_path)
	var blocks_root:CyclopsBlocks = builder.get_node(blocks_root_path)
	
	for i in blocks_to_delete.size():
		var block:CyclopsConvexBlock = preload("../controls/cyclops_convex_block.gd").new()
		block.block_data = tracked_block_data[i]
		block.name = block_names[i]
		block.selected = block_selected[i]
		
		blocks_root.add_child(block)
		block.owner = builder.get_editor_interface().get_edited_scene_root()
		

		
	
