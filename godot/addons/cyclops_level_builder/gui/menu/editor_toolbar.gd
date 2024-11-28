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
		if editor_plugin:
			editor_plugin.xray_mode_changed.disconnect(on_xray_mode_changed)
#			editor_plugin.main_screen_changed.disconnect(_on_main_screen_changed)
			editor_plugin.active_node_changed.disconnect(on_active_node_changed)
			editor_plugin.tool_changed.disconnect(on_tool_changed)
			editor_plugin.keymap_changed.disconnect(on_keymap_updated)
			editor_plugin.keymap_updated.disconnect(on_keymap_updated)
		
		editor_plugin = value
		
		if editor_plugin:
			editor_plugin.active_node_changed.connect(on_active_node_changed)			
			editor_plugin.xray_mode_changed.connect(on_xray_mode_changed)
#			editor_plugin.main_screen_changed.connect(_on_main_screen_changed)
			editor_plugin.tool_changed.connect(on_tool_changed)
			editor_plugin.keymap_changed.connect(on_keymap_updated)
			editor_plugin.keymap_updated.connect(on_keymap_updated)
		
		build_ui()


func on_active_node_changed():
	update_grid()
	
func on_keymap_updated():
	print("on_keymap_updated():")
	build_menu()
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)

	update_grid()
	

func build_menu():
	
	###########
	# This is the new rewrite of the action menu
	if !editor_plugin:
		return
	if !editor_plugin.config_scene:
		return
	
	for child in %MenuBar2.get_children():
		%MenuBar2.remove_child(child)
		child.queue_free()
	
	var menu_root = editor_plugin.config_scene.get_node("Views/View3D/Menu")
	for child in menu_root.get_children():
		var event:CyclopsActionEvent = CyclopsActionEvent.new()
		event.plugin = editor_plugin
			
		if child is MenuLineItemGroup:
			var popup:LineItemPopupMenu = child.create_popup_menu()
			%MenuBar2.add_child(popup)
			
			popup.action_chosen.connect(
				func(action:CyclopsAction): \
					if action: \
						action._execute(event) \
					else: \
						print("Action link not found: ", action.name)
				)
	

func build_ui():
	build_menu()
	
	#Tools
	for child in %ToolButtonContainer.get_children():
		%ToolButtonContainer.remove_child(child)
		child.queue_free()
	
	%snap_options.clear()
	
	if !editor_plugin:
		return

	%bn_xray.button_pressed = editor_plugin.xray_mode
		
	set_process_input(true)
		
	##########
	# New tool buttons setup
	var active_block:CyclopsBlock = editor_plugin.get_active_block()
	if editor_plugin.config_scene:
		var menu_root = editor_plugin.config_scene.get_node("Views/View3D/Toolbar")
	
		for child in menu_root.get_children():
			if child is ToolbarButtonRef:
				var tool_inst:CyclopsTool = child.tool

				if tool_inst.is_inside_tree() && tool_inst._show_in_toolbar() && tool_inst._can_handle_object(active_block):
					var bn:ToolButton = preload("res://addons/cyclops_level_builder/gui/menu/tool_button.tscn").instantiate()
					bn.plugin = editor_plugin
					bn.tool_path = tool_inst.get_path()
					bn.icon = tool_inst._get_tool_icon()
					if !bn.icon:
						bn.text = tool_inst._get_tool_name()
					bn.tooltip_text = tool_inst._get_tool_tooltip()
					
					%ToolButtonContainer.add_child(bn)

	
	%display_mode.select(editor_plugin.display_mode)
	
	#Snapping
	var config:CyclopsConfig = editor_plugin.config
	for tag in config.snapping_tags:
		if tag.icon:
			%snap_options.add_icon_item(tag.icon, tag.name)
		else:
			%snap_options.add_item(tag.name)


func update_grid():
	if !editor_plugin:
		return
	
	$HBoxContainer/display_mode.select(editor_plugin.display_mode)
		
func _on_selection_changed():
	build_ui()

func on_tool_changed(tool:CyclopsTool):
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func _on_check_lock_uvs_toggled(button_pressed):
	editor_plugin.lock_uvs = button_pressed



func _on_display_mode_item_selected(index:int):
	editor_plugin.display_mode = index


func on_xray_mode_changed(value:bool):
	%bn_xray.button_pressed = value

func _on_bn_xray_toggled(button_pressed:bool):
	if !editor_plugin:
		return
	
	editor_plugin.xray_mode = button_pressed

func _on_snap_options_item_selected(index:int):
	var tag:SnappingTag = editor_plugin.config.snapping_tags[index]
	tag._activate(editor_plugin)
	


func _on_bn_snap_toggled(toggled_on):
	CyclopsAutoload.settings.set_property(CyclopsGlobalScene.SNAPPING_ENABLED, toggled_on)
	pass # Replace with function body.
