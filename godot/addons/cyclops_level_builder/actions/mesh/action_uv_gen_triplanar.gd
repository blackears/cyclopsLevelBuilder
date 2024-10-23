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
class_name ActionUvGenTriplanar
extends CyclopsAction

const ACTION_ID:String = "uv_gen_triplanar"

func _get_action_id():
	return ACTION_ID

func _execute(event:CyclopsActionEvent):
	var plugin:CyclopsLevelBuilder = event.plugin
	var root:Node = plugin.get_editor_interface().get_edited_scene_root()
	
	var ed_sel:EditorSelection = EditorInterface.get_selection()
	var sel_nodes:Array[Node] = ed_sel.get_selected_nodes()

	var block_paths:Array[NodePath]
	for node in sel_nodes:
		if node is CyclopsBlock:
			block_paths.append(node.get_path())

	if block_paths.is_empty():
		return
		
	var cmd:CommandUvGenTriplanar = CommandUvGenTriplanar.new()
	cmd.builder = plugin
	
	cmd.block_paths = block_paths
	cmd.selected_faces_only = false
	cmd.transform = Transform3D.IDENTITY
	
	var undo:EditorUndoRedoManager = plugin.get_undo_redo()
	cmd.add_to_undo_manager(undo)
	
