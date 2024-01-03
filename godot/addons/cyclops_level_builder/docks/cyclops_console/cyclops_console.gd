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
class_name CyclopsConsole

var editor_plugin:CyclopsLevelBuilder

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func save_state(state:Dictionary):
	var substate:Dictionary = {}
	state["cyclops_console"] = substate
	

func load_state(state:Dictionary):
	if state == null || !state.has("cyclops_console"):
		return
	
	var substate:Dictionary = state["cyclops_console"]

func _on_enable_cyclops_toggled(button_pressed):
	editor_plugin.always_on = button_pressed


func _on_bn_create_block_pressed():
	var cmd:CommandAddBlock = CommandAddBlock.new()
	cmd.builder = editor_plugin

	var bounds:AABB = AABB(%block_position.value, %block_size.value)
	cmd.bounds = bounds
	var scene_root = editor_plugin.get_editor_interface().get_edited_scene_root()
	cmd.blocks_root_path = scene_root.get_path()
	cmd.block_name = GeneralUtil.find_unique_name(scene_root, "block")
	
	var undo:EditorUndoRedoManager = editor_plugin.get_undo_redo()
	cmd.add_to_undo_manager(undo)

