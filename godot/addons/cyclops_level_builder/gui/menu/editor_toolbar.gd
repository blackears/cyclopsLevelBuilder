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

func init_action(action:CyclopsAction)->CyclopsAction:
	action.plugin = editor_plugin
	return action

# Called when the node enters the scene tree for the first time.
func _ready():
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)

	%Menu.clear()
	%Menu.add_action_item(init_action(ActionToolDuplicate.new()))
	%Menu.add_action_item(init_action(ActionMergeSelectedBlocks.new()))
	%Menu.add_action_item(init_action(ActionSubtractBlock.new()))
	%Menu.add_action_item(init_action(ActionIntersectBlock.new()))
	%Menu.add_action_item(init_action(ActionDeleteSelectedBlocks.new()))
	%Menu.add_action_item(init_action(ActionSnapToGrid.new()))
	%Menu.add_action_item(init_action(ActionMergeVerticesCenter.new()))
	%Menu.add_separator()
	%Menu.add_action_item(init_action(ActionConvertToMesh.new()))
	%Menu.add_action_item(init_action(ActionExportAsGltf.new()))
	%Menu.add_action_item(init_action(ActionExportAsGodotScene.new()))
	%Menu.add_action_item(init_action(ActionExportAsCyclops.new()))
	%Menu.add_separator()
	%Menu.add_action_item(init_action(ActionRotateX90Ccw.new()))
	%Menu.add_action_item(init_action(ActionRotateX90Cw.new()))
	%Menu.add_action_item(init_action(ActionRotateX180.new()))
	%Menu.add_action_item(init_action(ActionMirrorSelectionX2.new()))
	%Menu.add_separator()
	%Menu.add_action_item(init_action(ActionRotateY90Ccw.new()))
	%Menu.add_action_item(init_action(ActionRotateY90Cw.new()))
	%Menu.add_action_item(init_action(ActionRotateY180.new()))
	%Menu.add_action_item(init_action(ActionMirrorSelectionY2.new()))
	%Menu.add_separator()
	%Menu.add_action_item(init_action(ActionRotateZ90Ccw.new()))
	%Menu.add_action_item(init_action(ActionRotateZ90Cw.new()))
	%Menu.add_action_item(init_action(ActionRotateZ180.new()))
	%Menu.add_action_item(init_action(ActionMirrorSelectionZ.new()))
	
	#var global_scene = get_node("/root/CyclopsAutoload")
#
	update_grid()
	
#var prev_button_pressed: Button = null
#
#func _press_button_line(button: Button) -> void:
	#if prev_button_pressed != null:
		#var line := prev_button_pressed.get_node_or_null('line')
		#if line != null:
			#prev_button_pressed.remove_child(line)
			#line.queue_free()
		#prev_button_pressed = null
	#
	#var new_line := ColorRect.new()
	#new_line.anchor_left = 0.05
	#new_line.anchor_top = 0.9
	#new_line.anchor_right = 0.95
	#new_line.anchor_bottom = 0.94
	#button.add_child(new_line)
	#new_line.name = 'line'
	#prev_button_pressed = button

#var menu_map:Array[KeymapActionMapper]

func build_menu():
	for child in %MenuBar.get_children():
		%MenuBar.remove_child(child)
		child.queue_free()
	
	#menu_map.clear()
	
	if !editor_plugin:
		return
	
	var keymap_root:KeymapGroup = editor_plugin.keymap
	for child in keymap_root.children:
		#var popup:PopupMenu = PopupMenu.new()
		#popup.name = child.name
		
		var popup:PopupMenu = build_menu_recursive(child)
		%MenuBar.add_child(popup)
	
func build_menu_recursive(base_node:KeymapGroup)->PopupMenu:
	var action_list:Array[KeymapActionMapper]
	var base_menu:PopupMenu = PopupMenu.new()
	base_menu.name = base_node.name
	base_menu.id_pressed.connect(func(id:int):
		var ctx:CyclopsOperatorContext = CyclopsOperatorContext.new()
		ctx.plugin = editor_plugin
		action_list[id].invoke(ctx, null)
		)
	
	
	for child in base_node.children:
		if child is KeymapGroup:
			var child_menu:PopupMenu = build_menu_recursive(child)
			
			base_menu.add_child(child_menu)
			base_menu.add_submenu_item(child.name, child.name)

			#if child.subgroup:
				#var child_menu:PopupMenu = build_menu_recursive(child)
				#
				#base_menu.add_child(child_menu)
				#base_menu.add_submenu_item(child.name, child.name)
#
			#else:
				#base_menu.add_separator()
				#build_menu_recursive(base_menu, child)
				
		elif child is KeymapActionMapper:
			var am:KeymapActionMapper = child
	
			base_menu.add_item(am.name, action_list.size())
			action_list.append(am)
#			menu_map.append(am)
	return base_menu

func build_ui():
	#print("build_ui")
	#Tools
	for child in %ToolButtonContainer.get_children():
		%ToolButtonContainer.remove_child(child)
		child.queue_free()
	
	%snap_options.clear()
	
	if !editor_plugin:
		return

	%bn_xray.button_pressed = editor_plugin.xray_mode
		
	set_process_input(true)
	
	var active_block:CyclopsBlock = editor_plugin.get_active_block()
	for tool:CyclopsTool in editor_plugin.tool_list:
		if tool._show_in_toolbar() && tool._can_handle_object(active_block):
			var bn:ToolButton = preload("res://addons/cyclops_level_builder/gui/menu/tool_button.tscn").instantiate()
			bn.plugin = editor_plugin
			bn.tool_id = tool._get_tool_id()
			bn.icon = tool._get_tool_icon()
			if !bn.icon:
				bn.text = tool._get_tool_name()
			bn.tooltip_text = tool._get_tool_tooltip()
			
			%ToolButtonContainer.add_child(bn)
		
	%display_mode.select(editor_plugin.display_mode)
	
	#Snapping
	var config:CyclopsConfig = editor_plugin.config
	for tag in config.snapping_tags:
		if tag.icon:
			%snap_options.add_icon_item(tag.icon, tag.name)
		else:
			%snap_options.add_item(tag.name)

	build_menu()

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
