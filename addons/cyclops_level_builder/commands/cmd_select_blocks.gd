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
class_name CommandSelectBlocks
extends CyclopsCommand

#Public
var selection_type:Selection.Type = Selection.Type.REPLACE

var block_paths:Array[NodePath]

#Private
var tracked_selected_blocks:Array[NodePath]
var tracked_active_blocks:Array[NodePath]


func _init():
	command_name = "Select blocks"

func will_change_anything()->bool:

	var active_path:NodePath
	if !block_paths.is_empty():
		active_path = block_paths[0]

	for child in builder.active_node.get_children():
		if child is CyclopsConvexBlock:
			var block:CyclopsConvexBlock = child
			var path:NodePath = block.get_path()
			
			match selection_type:
				Selection.Type.REPLACE:
					if block.selected != block_paths.has(path):
						return true
					
					if block.active != (path == active_path):
						return true
						
				Selection.Type.ADD:
					if block_paths.has(path):
						if !block.selected:
							return true
					if block.active != (path == active_path):
						return true
						
				Selection.Type.SUBTRACT:
					if block_paths.has(path):
						if block.selected:
							return true
							
				Selection.Type.TOGGLE:
					if !block_paths.is_empty():
						return true
				
	return false
	

func do_it():
#	print("sel verts do_it")

	#Cache state
	tracked_selected_blocks.clear()
	tracked_active_blocks.clear()
	
	for child in builder.active_node.get_children():
		if child is CyclopsConvexBlock:
			var block:CyclopsConvexBlock = child
			if block.selected:
				tracked_selected_blocks.append(block.get_path())
			if block.active:
				tracked_active_blocks.append(block.get_path())

	#Do selection
	var active_path:NodePath
	if !block_paths.is_empty():
		active_path = block_paths[0]
	
	for child in builder.active_node.get_children():
		if child is CyclopsConvexBlock:
			var block:CyclopsConvexBlock = child
			var path:NodePath = block.get_path()
			
			match selection_type:
				Selection.Type.REPLACE:
					block.selected = block_paths.has(path)
					block.active = path == active_path
				Selection.Type.ADD:
					if block_paths.has(path):
						block.selected = true
					block.active = path == active_path
				Selection.Type.SUBTRACT:
					if block_paths.has(path):
						block.selected = false
						block.active = false
				Selection.Type.TOGGLE:
					block.active = path == active_path
					if block_paths.has(path):
						block.selected = !block.selected
						if !block.selected:
							block.active = false
				
	builder.selection_changed.emit()
				
func undo_it():

	for child in builder.active_node.get_children():
		if child is CyclopsConvexBlock:
			var block:CyclopsConvexBlock = child
			var path:NodePath = block.get_path()

			block.selected = tracked_selected_blocks.has(path)
			block.active = tracked_active_blocks.has(path)
			
	builder.selection_changed.emit()
