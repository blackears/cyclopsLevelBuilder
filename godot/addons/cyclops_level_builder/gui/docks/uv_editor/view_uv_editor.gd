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
extends Control
class_name ViewUvEditor

var plugin:CyclopsLevelBuilder:
	set(value):
		if value == plugin:
			return
			
		if plugin:
			var ed_iface:EditorInterface = plugin.get_editor_interface()
			var ed_sel:EditorSelection = ed_iface.get_selection()
			ed_sel.selection_changed.disconnect(on_block_selection_changed)

		plugin = value
			
		if plugin:
			var ed_iface:EditorInterface = plugin.get_editor_interface()
			var ed_sel:EditorSelection = ed_iface.get_selection()
			ed_sel.selection_changed.connect(on_block_selection_changed)

func on_block_selection_changed():
	#return
	
	if is_node_ready():
		var ed_iface:EditorInterface = plugin.get_editor_interface()
		var ed_sel:EditorSelection = ed_iface.get_selection()
		
#		print("----sel-----")
		var nodes:Array[CyclopsBlock]
		for node in ed_sel.get_selected_nodes():
			if node is CyclopsBlock:
				nodes.append(node)
#				print("sel: ", node.name)
		
		%uv_mesh_renderer.block_nodes = nodes
#	pass
	

func save_state(state:Dictionary):
	var substate:Dictionary = {}
	state["uv_editor"] = substate
	#substate["materials"] = material_list.duplicate()

func load_state(state:Dictionary):
	if state == null || !state.has("uv_editor"):
		return
	
	var substate:Dictionary = state["uv_editor"]
#

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
