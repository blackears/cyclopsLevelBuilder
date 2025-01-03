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
class_name ActionSnapToGrid
extends CyclopsAction

const ACTION_ID:String = "snap_to_grid"

func _get_action_id():
	return ACTION_ID
	
#func _init(plugin:CyclopsLevelBuilder):
	#super._init(plugin, "Snap to grid")
	
func _init():
	name = "Snap to grid"


func _execute(event:CyclopsActionEvent):
	var plugin:CyclopsLevelBuilder = event.plugin
	var blocks:Array[CyclopsBlock] = plugin.get_selected_blocks()
	if blocks.is_empty():
		return
		
	var pivot:Vector3 = calc_pivot_of_blocks(blocks)
	
	var cmd:CommandSnapToGrid = CommandSnapToGrid.new()
	cmd.builder = plugin
	
	for block in blocks:
		cmd.add_block(block.get_path())
		
	
	#cmd.grid_size = pow(2, plugin.get_global_scene().grid_size)
	#var snap_to_grid_util:SnapToGridUtil = CyclopsAutoload.calc_snap_to_grid_util()
	#print("snap_to_grid_util  %s" % snap_to_grid_util)
	#cmd.snap_to_grid_util = snap_to_grid_util
	
	
	#print("cform %s" % xform)
	
	var undo:EditorUndoRedoManager = plugin.get_undo_redo()
	cmd.add_to_undo_manager(undo)
