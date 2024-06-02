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


var tool_button_group = ButtonGroup.new()
var override_shortcuts: Dictionary = {} #Dictionary[InputEvent, String]
var currently_in_3d := false

func on_active_node_changed():
	update_grid()
	

# Called when the node enters the scene tree for the first time.
func _ready():

	%Menu.clear()
	%Menu.add_action_item(ActionToolDuplicate.new(editor_plugin))
	%Menu.add_action_item(ActionMergeSelectedBlocks.new(editor_plugin))
	%Menu.add_action_item(ActionSubtractBlock.new(editor_plugin))
	%Menu.add_action_item(ActionIntersectBlock.new(editor_plugin))
	%Menu.add_action_item(ActionDeleteSelectedBlocks.new(editor_plugin))
	%Menu.add_action_item(ActionSnapToGrid.new(editor_plugin))
	%Menu.add_action_item(ActionMergeVerticesCenter.new(editor_plugin))
	%Menu.add_separator()
	%Menu.add_action_item(ActionConvertToMesh.new(editor_plugin))
	%Menu.add_action_item(ActionExportAsGltf.new(editor_plugin))
	%Menu.add_action_item(ActionExportAsGodotScene.new(editor_plugin))
	%Menu.add_action_item(ActionExportAsCyclops.new(editor_plugin))
	%Menu.add_separator()
	%Menu.add_action_item(ActionRotateX90Ccw.new(editor_plugin))
	%Menu.add_action_item(ActionRotateX90Cw.new(editor_plugin))
	%Menu.add_action_item(ActionRotateX180.new(editor_plugin))
	%Menu.add_action_item(ActionMirrorSelectionX2.new(editor_plugin))
	%Menu.add_separator()
	%Menu.add_action_item(ActionRotateY90Ccw.new(editor_plugin))
	%Menu.add_action_item(ActionRotateY90Cw.new(editor_plugin))
	%Menu.add_action_item(ActionRotateY180.new(editor_plugin))
	%Menu.add_action_item(ActionMirrorSelectionY2.new(editor_plugin))
	%Menu.add_separator()
	%Menu.add_action_item(ActionRotateZ90Ccw.new(editor_plugin))
	%Menu.add_action_item(ActionRotateZ90Cw.new(editor_plugin))
	%Menu.add_action_item(ActionRotateZ180.new(editor_plugin))
	%Menu.add_action_item(ActionMirrorSelectionZ.new(editor_plugin))
	
	var global_scene = get_node("/root/CyclopsAutoload")

	global_scene.xray_mode_changed.connect(on_xray_mode_changed)
	%bn_xray.button_pressed = global_scene.xray_mode
			
	update_grid()
	



var prev_button_pressed: Button = null
func _press_button_line(button: Button) -> void:
	if prev_button_pressed != null:
		var line := prev_button_pressed.get_node_or_null('line')
		if line != null:
			prev_button_pressed.remove_child(line)
			line.queue_free()
		prev_button_pressed = null
	
	var new_line := ColorRect.new()
	new_line.anchor_left = 0.05
	new_line.anchor_top = 0.9
	new_line.anchor_right = 0.95
	new_line.anchor_bottom = 0.94
	button.add_child(new_line)
	new_line.name = 'line'
	prev_button_pressed = button


func build_ui():
	#Tools
	for child in %ToolButtonContainer.get_children():
		%ToolButtonContainer.remove_child(child)
	
	%snap_options.clear()
	
	if !editor_plugin:
		return
		
	editor_plugin.main_screen_changed.connect(_on_main_screen_changed)
	set_process_input(true)
	
	
	var config:CyclopsConfig = editor_plugin.config
	for tag: ToolTag in config.tool_tags:
#		print("adding tag %s" % tag.name)
		var bn:Button = Button.new()
		if tag.icon:
			bn.icon = tag.icon
		else:
			bn.text = tag.name
		
		bn.name = tag.name
		
		if !tag.input_events.is_empty(): #InputEvent
			if tag.input_events_override: #bool
				for v: InputEvent in tag.input_events:
					override_shortcuts[v] = tag.name #for _input function
			else:
				bn.shortcut = Shortcut.new()
				for v: InputEvent in tag.input_events:
					bn.shortcut.events.append(v)
		
		bn.tooltip_text = tag.tooltip
		bn.pressed.connect(func():
			_press_button_line(bn)
			tag._activate(editor_plugin)
		)
#		print("adding bn %s" % tag.name)
		
		%ToolButtonContainer.add_child(bn)
		
	%display_mode.select(editor_plugin.display_mode)
	
	#Snapping
	for tag in config.snapping_tags:
		if tag.icon:
			%snap_options.add_icon_item(tag.icon, tag.name)
		else:
			%snap_options.add_item(tag.name)

func update_grid():
	if !editor_plugin:
		return
		
	#var size:int = editor_plugin.get_global_scene().grid_size
	#$HBoxContainer/grid_size.select(size + 4)
	
	$HBoxContainer/display_mode.select(editor_plugin.display_mode)
		


func _on_main_screen_changed(screen_name: String):
	currently_in_3d = (screen_name == '3D')

func _input(event: InputEvent) -> void:
	if !currently_in_3d:		return
	
	for v: InputEvent in override_shortcuts:
		if event.is_match(v, true) and event.is_pressed() and not event.is_echo():
			var button := %ToolButtonContainer.get_node_or_null(override_shortcuts[v] as String) as Button
			if button:
				button.pressed.emit() #simulate press
			break


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


#func _on_grid_size_item_selected(index):
	#editor_plugin.get_global_scene().grid_size = index - 4



func _on_check_lock_uvs_toggled(button_pressed):
	editor_plugin.lock_uvs = button_pressed



func _on_display_mode_item_selected(index:int):
	editor_plugin.display_mode = index


func on_xray_mode_changed(value:bool):
	%bn_xray.button_pressed = value

func _on_bn_xray_toggled(button_pressed:bool):
	if !editor_plugin:
		return
	
	var global_scene:CyclopsGlobalScene = editor_plugin.get_global_scene()
	global_scene.xray_mode = button_pressed
	
#
#func _on_bn_snap_settings_pressed():
##	var rect:Rect2 = %bn_snap_settings.get_rect()
	#
	#var rect:Rect2 = %bn_snap_settings.get_global_rect()
	#var new_rect:Rect2 = Rect2(rect.position.x, rect.position.y + rect.size.y, 200, 100)
	#%snap_settings_popup.popup_on_parent(new_rect)
	##print("snap popup2 ", rect)
	

func _on_snap_options_item_selected(index:int):
	var tag:SnappingTag = editor_plugin.config.snapping_tags[index]
	tag._activate(editor_plugin)
	


func _on_bn_snap_toggled(toggled_on):
	CyclopsAutoload.settings.set_property(CyclopsGlobalScene.SNAPPING_ENABLED, toggled_on)
	pass # Replace with function body.
