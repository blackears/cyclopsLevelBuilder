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
extends PanelContainer
class_name EditorToolbar

var editor_plugin:CyclopsLevelBuilder:
	get:
		return editor_plugin
	set(value):
		editor_plugin = value
		editor_plugin.active_node_changed.connect(on_active_node_changed)
		
		build_ui()
#var editor_plugin:CyclopsLevelBuilder

#var action_map:Array[CyclopsAction]

func on_active_node_changed():
	update_grid()
	

# Called when the node enters the scene tree for the first time.
func _ready():
	$HBoxContainer/grid_size.clear()
	$HBoxContainer/grid_size.add_item("1/16", 0)
	$HBoxContainer/grid_size.add_item("1/8", 1)
	$HBoxContainer/grid_size.add_item("1/4", 2)
	$HBoxContainer/grid_size.add_item("1/2", 3)
	$HBoxContainer/grid_size.add_item("1", 4)
	$HBoxContainer/grid_size.add_item("2", 5)
	$HBoxContainer/grid_size.add_item("4", 6)
	$HBoxContainer/grid_size.add_item("8", 7)
	$HBoxContainer/grid_size.add_item("16", 8)
	
	$HBoxContainer/MenuBar/Menu.clear()
	$HBoxContainer/MenuBar/Menu.add_action_item(ActionToolDuplicate.new(editor_plugin))
	$HBoxContainer/MenuBar/Menu.add_action_item(ActionMergeSelectedBlocks.new(editor_plugin))
	$HBoxContainer/MenuBar/Menu.add_action_item(ActionSubtractBlock.new(editor_plugin))
	$HBoxContainer/MenuBar/Menu.add_action_item(ActionIntersectBlock.new(editor_plugin))
	$HBoxContainer/MenuBar/Menu.add_action_item(ActionDeleteSelectedBlocks.new(editor_plugin))
	$HBoxContainer/MenuBar/Menu.add_action_item(ActionSnapToGrid.new(editor_plugin))
	$HBoxContainer/MenuBar/Menu.add_separator()
	$HBoxContainer/MenuBar/Menu.add_action_item(ActionRotateX90Ccw.new(editor_plugin))
	$HBoxContainer/MenuBar/Menu.add_action_item(ActionRotateX90Cw.new(editor_plugin))
	$HBoxContainer/MenuBar/Menu.add_action_item(ActionRotateX180.new(editor_plugin))
	$HBoxContainer/MenuBar/Menu.add_action_item(ActionMirrorSelectionX2.new(editor_plugin))
	$HBoxContainer/MenuBar/Menu.add_separator()
	$HBoxContainer/MenuBar/Menu.add_action_item(ActionRotateY90Ccw.new(editor_plugin))
	$HBoxContainer/MenuBar/Menu.add_action_item(ActionRotateY90Cw.new(editor_plugin))
	$HBoxContainer/MenuBar/Menu.add_action_item(ActionRotateY180.new(editor_plugin))
	$HBoxContainer/MenuBar/Menu.add_action_item(ActionMirrorSelectionY2.new(editor_plugin))
	$HBoxContainer/MenuBar/Menu.add_separator()
	$HBoxContainer/MenuBar/Menu.add_action_item(ActionRotateZ90Ccw.new(editor_plugin))
	$HBoxContainer/MenuBar/Menu.add_action_item(ActionRotateZ90Cw.new(editor_plugin))
	$HBoxContainer/MenuBar/Menu.add_action_item(ActionRotateZ180.new(editor_plugin))
	$HBoxContainer/MenuBar/Menu.add_action_item(ActionMirrorSelectionZ.new(editor_plugin))
	
	update_grid()

var tool_button_group = ButtonGroup.new()

func build_ui():
#	print("build_ui()")
	for child in $HBoxContainer/ToolButtonContainer.get_children():
		$HBoxContainer/ToolButtonContainer.remove_child(child)
	
	if !editor_plugin:
		return
		
	var config:CyclopsConfig = editor_plugin.config
	for tag in config.tool_tags:
#		print("adding tag %s" % tag.name)
		var bn:Button = Button.new()
		if tag.icon:
			bn.icon = tag.icon
		else:
			bn.text = tag.name
		bn.tooltip_text = tag.tooltip
		bn.pressed.connect(func():tag._activate(editor_plugin))
#		print("adding bn %s" % tag.name)
		
		$HBoxContainer/ToolButtonContainer.add_child(bn)
		
	$HBoxContainer/display_mode.select(editor_plugin.display_mode)
	pass

func update_grid():
	if !editor_plugin:
		return
		
	var size:int = editor_plugin.get_global_scene().grid_size
	$HBoxContainer/grid_size.select(size + 4)
	
	$HBoxContainer/display_mode.select(editor_plugin.display_mode)
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_grid_size_item_selected(index):
	editor_plugin.get_global_scene().grid_size = index - 4



func _on_check_lock_uvs_toggled(button_pressed):
	editor_plugin.lock_uvs = button_pressed



func _on_display_mode_item_selected(index):
	editor_plugin.display_mode = index




