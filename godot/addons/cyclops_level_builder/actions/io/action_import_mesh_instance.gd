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
class_name ActionImportMeshInstance
extends CyclopsAction

func _init(plugin:CyclopsLevelBuilder, name:String = "", accellerator:Key = KEY_NONE):
	super._init(plugin, "Import Godot MeshInstance...")

func _execute():
	var nodes:Array[Node] = plugin.get_editor_interface().get_selection().get_selected_nodes()

	if nodes.is_empty():
		return

	if !(nodes[-1] is Node3D):
		return

	var tgt_parent:Node3D = nodes[-1]
	if tgt_parent is MeshInstance3D:
		tgt_parent = tgt_parent.get_parent()
	
	var cmd:CommandImportGodotMeshes = CommandImportGodotMeshes.new()
	cmd.builder = plugin
	cmd.target_parent = tgt_parent.get_path()
	#print("parent ", tgt_parent.get_path())
	
	for node in nodes:
		import_branch_recursive(node, cmd)
	
	if !cmd.will_change_anything():
		return
		
	var undo:EditorUndoRedoManager = plugin.get_undo_redo()
	cmd.add_to_undo_manager(undo)

func import_branch_recursive(node:Node3D, cmd:CommandImportGodotMeshes):
	if node is MeshInstance3D:
		cmd.source_nodes.append(node.get_path())
		#print("src ", node.get_path())
	
	for child in node.get_children():
		import_branch_recursive(child, cmd)

	
