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
#var tracked_selected_blocks:Array[NodePath]
#var tracked_active_blocks:Array[NodePath]
var cached_selection:Array[NodePath]
var init:bool = false

func _init():
	command_name = "Select blocks"

#func will_change_anything()->bool:
#
#	var active_path:NodePath
#	if !block_paths.is_empty():
#		active_path = block_paths[0]
##	print("will change active %s" % active_path)
#
#	for child in builder.get_blocks():
#		if child is CyclopsBlock:
#			var block:CyclopsBlock = child
#			var path:NodePath = block.get_path()
#
#			match selection_type:
#				Selection.Type.REPLACE:
#					if block.selected != block_paths.has(path):
#						return true
#
#					if block.active != (path == active_path):
#						return true
#
#				Selection.Type.ADD:
#					if block_paths.has(path):
#						if !block.selected:
#							return true
#					if block.active != (path == active_path):
#						return true
#
#				Selection.Type.SUBTRACT:
#					if block_paths.has(path):
#						if block.selected:
#							return true
#
#				Selection.Type.TOGGLE:
#					if !block_paths.is_empty():
#						return true
#
##	print("will chage anything false")
#	return false

func will_change_anything()->bool:
	var selection:EditorSelection = builder.get_editor_interface().get_selection()
	
	var cur_node_list:Array[Node] = selection.get_selected_nodes()
	if !init:
		for node in cur_node_list:
			cached_selection.append(node.get_path())
		init = true
	
	var cur_paths:Array[NodePath]
	for node in selection.get_selected_nodes():
		cur_paths.append(node.get_path())
	
	if selection_type == Selection.Type.REPLACE:
		if cur_paths.size() != block_paths.size():
			return true
		for i in cur_paths.size():
			if cur_paths[i] != block_paths[i]:
				return true
		return false
		
			
	elif selection_type == Selection.Type.ADD:
		for path in block_paths:
			if !cur_paths.has(path):
				return true
		return false

	elif selection_type == Selection.Type.SUBTRACT:
		for path in block_paths:
			if cur_paths.has(path):
				return true
		return false

	elif selection_type == Selection.Type.TOGGLE:
		if !block_paths.is_empty():
			return true
		return false

	return false
	
func do_it():
	var selection:EditorSelection = builder.get_editor_interface().get_selection()
	
	var cur_node_list:Array[Node] = selection.get_selected_nodes()
	if !init:
		cached_selection = cur_node_list.duplicate()
		init = true
	
	var cur_paths:Array[NodePath]
	for node in selection.get_selected_nodes():
		cur_paths.append(node.get_path())
	
	if selection_type == Selection.Type.REPLACE:
		selection.clear()
		for path in block_paths:
			var node:Node = builder.get_node(path)
			selection.add_node(node)
			
	elif selection_type == Selection.Type.ADD:
		for path in block_paths:
			if !cur_paths.has(path):
				var node:Node = builder.get_node(path)
				selection.add_node(node)

	elif selection_type == Selection.Type.SUBTRACT:
		for path in block_paths:
			if cur_paths.has(path):
				var node:Node = builder.get_node(path)
				selection.remove_node(node)

	elif selection_type == Selection.Type.TOGGLE:
		for path in block_paths:
			var node:Node = builder.get_node(path)
			
			if cur_paths.has(path):
				selection.remove_node(node)
			else:
				selection.add_node(node)


#func do_it_old():
##	print("sel verts do_it")
#
#	#Cache state
#	tracked_selected_blocks.clear()
#	tracked_active_blocks.clear()
#
#
#	var active_block:CyclopsBlock = builder.get_active_block()
#	tracked_active_blocks.append(active_block.get_path())
#
#	for child in builder.get_selected_blocks():
#		var block:CyclopsBlock = child
#		tracked_selected_blocks.append(block.get_path())
#
#	#Do selection
#	var active_path:NodePath
#	if !block_paths.is_empty():
#		active_path = block_paths[0]
#
#	#print("do_it active %s" % active_path)
##	print("Setting active %s" % active_path)
#	for child in builder.get_blocks():
#		var block:CyclopsBlock = child
#		var path:NodePath = block.get_path()
#
#		match selection_type:
#			Selection.Type.REPLACE:
#				block.selected = block_paths.has(path)
#				block.active = path == active_path
#			Selection.Type.ADD:
#				if block_paths.has(path):
#					block.selected = true
#				block.active = path == active_path
#			Selection.Type.SUBTRACT:
#				if block_paths.has(path):
#					block.selected = false
#					block.active = false
#			Selection.Type.TOGGLE:
#				#print("Check block %s" % path)
#				#print("act %s  sel %s" % [block.active, block.selected])
#				if path == active_path:
#					#print("Match active")
#					if !block.active:
#						#print("Setting active %s" % block.name)
#						block.active = true
#						block.selected = true
#					else:
#						#print("Clearing active %s" % block.name)
#						block.active = false
#						block.selected = false
#				else:					
#					if block_paths.has(path):
#						#print("Setting sel")
#						block.selected = !block.selected
#					block.active = false
#
#	builder.selection_changed.emit()

func undo_it():
	var selection:EditorSelection = builder.get_editor_interface().get_selection()
	selection.clear()
	
	for path in cached_selection:
		var node:Node = builder.get_node(path)
		selection.add_node(node)
				
#func undo_it():
#
#	for child in builder.get_blocks():
#		if child is CyclopsBlock:
#			var block:CyclopsBlock = child
#			var path:NodePath = block.get_path()
#
#			block.selected = tracked_selected_blocks.has(path)
#			block.active = tracked_active_blocks.has(path)
#
#	builder.selection_changed.emit()
