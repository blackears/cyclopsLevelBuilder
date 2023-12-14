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
class_name ActionSubtractBlock
extends CyclopsAction


func _init(plugin:CyclopsLevelBuilder, name:String = "", accellerator:Key = KEY_NONE):
	super._init(plugin, "Subtract Block")

func _execute():
	var blocks:Array[CyclopsBlock] = plugin.get_selected_blocks()
	if blocks.size() < 2:
		plugin.log("Not enough objects selected")
		return

	var active:CyclopsBlock = plugin.get_active_block()
	if !active:
		plugin.log("No active object selected")
		return
		
	var cmd:CommandSubtractBlock = CommandSubtractBlock.new()
	cmd.builder = plugin

	for block in blocks:
		if plugin.is_active_block(block):
			cmd.block_to_subtract_path = block.get_path()
		else:
			cmd.block_paths.append(block.get_path())
	
	if cmd.block_to_subtract_path.is_empty():
		return
	
	if cmd.will_change_anything():
		var undo:EditorUndoRedoManager = plugin.get_undo_redo()
		cmd.add_to_undo_manager(undo)
