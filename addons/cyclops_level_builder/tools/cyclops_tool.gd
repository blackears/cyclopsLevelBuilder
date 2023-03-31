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
extends Resource
class_name CyclopsTool

var builder:CyclopsLevelBuilder

#func _init(_editorPlugin:EditorPlugin):
#	editorPlugin = _editorPlugin
	
func _activate(_builder:CyclopsLevelBuilder):
	builder = _builder
	
func _deactivate():
	pass

func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:
	if event is InputEventKey:
		var e:InputEventKey = event

		var blocks_root:CyclopsBlocks = self.builder.active_node
		
		if e.is_pressed():
			if e.keycode == KEY_X:
				var cmd:CommandDeleteBlocks = CommandDeleteBlocks.new()
				cmd.blocks_root_path = blocks_root.get_path()
				cmd.builder = builder
				
				for child in blocks_root.get_children():
					if child is CyclopsBlock:
						var block:CyclopsBlock = child
						if block.selected:
							cmd.add_block(block.get_path())
				
				if cmd.blocks_to_delete.size() > 0:
					var undo:EditorUndoRedoManager = builder.get_undo_redo()
					cmd.add_to_undo_manager(undo)
				
				return true
	
	return false


func to_local(point:Vector3, world_to_local:Transform3D, grid_step_size:float)->Vector3:
	var p_local:Vector3 = world_to_local * point

	return MathUtil.snap_to_grid(p_local, grid_step_size)

