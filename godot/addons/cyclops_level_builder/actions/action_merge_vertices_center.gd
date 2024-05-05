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
class_name ActionMergeVerticesCenter
extends CyclopsAction


func _init(plugin:CyclopsLevelBuilder, name:String = "", accellerator:Key = KEY_NONE):
	super._init(plugin, "Merge Vertices Center")

func _execute():
	var blocks:Array[CyclopsBlock] = plugin.get_selected_blocks()
	if blocks.is_empty():
		return
		
	var cmd:CommandMergeVertices = CommandMergeVertices.new()
	cmd.builder = plugin
	
	for block in blocks:
		var sel_vec:DataVector = block.mesh_vector_data.get_vertex_data(MeshVectorData.V_SELECTED)
		
		if sel_vec.size() < 2:
			continue

		var indices:Array[int]
		#print("sel vert bytes ", block.block_data.vertex_selected)
		for idx in sel_vec.size():
			if sel_vec.get_value(idx):
				indices.append(idx)
		cmd.add_vertices(block.get_path(), indices)
			
	
	if cmd.will_change_anything():
		var undo:EditorUndoRedoManager = plugin.get_undo_redo()
		cmd.add_to_undo_manager(undo)
