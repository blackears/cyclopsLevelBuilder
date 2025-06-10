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

#signal forward_input(event:InputEvent)
#signal property_changed(name:StringName, value)
signal tool_changed(tool:CyclopsTool)

#@onready var side_tab_container:SideTabContainer = %SideTabContainer
#@onready var side_tab_panel:SideTabPanel = %side_tab_panel
@onready var snapping_panel:PanelContainer = %Snapping
@onready var slide_tab_container:HSlideTabContainer = %slide_tab_container
@onready var bn_use_snap:TextureButton = %bn_use_snap

@onready var theme_tool_button:Theme = preload("res://addons/cyclops_level_builder/themes/tool_button_theme.tres")

var active_tool:CyclopsTool

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


		#build_menus()
		#for child in %tools.get_children():
			#if child is CyclopsTool:
				#switch_to_tool(child)
				#break

func get_snapping_manager()->UvEditorSnapping:
	return %snapping


func switch_to_tool(_tool:CyclopsTool):
	if active_tool:
		active_tool._deactivate()
	
	active_tool = _tool

	if active_tool:
		active_tool._activate(self)

		for child in %Tool.get_children():
			child.queue_free()
		
		var control:Control = active_tool._get_tool_properties_editor()
		if control:
			control.size_flags_horizontal = Control.SIZE_EXPAND
			#control.size_flags_vertical = Control.SIZE_EXPAND
		
			%Tool.add_child(control)
		
		var idx:int = active_tool.get_index()
		%tool_buttons.get_child(idx).button_pressed = true
	
	tool_changed.emit(active_tool)
	
func get_uv_editor()->UvEditor:
	return %uv_editor

func build_menus():
#	print("uv editor build_menus()")
	
	if !is_node_ready():
		return
	
	for child in %MenuBar.get_children():
		%MenuBar.remove_child(child)
		child.queue_free()
	
	for child in %tool_buttons.get_children():
		%tool_buttons.remove_child(child)
		child.queue_free()
	
	#Snap drop down
	%option_snapping.clear()
	for child in %snapping.get_children():
		%option_snapping.add_icon_item(child.icon, child.name)
	
	#Select current snapping tool
	var snap_node:Node = %snapping.cur_snap_tool
	if snap_node:
		var idx = snap_node.get_index()
		%option_snapping.selected = idx
	
	update_snap_display()
	
#	print("plugin check")
	if !plugin || !plugin.config_scene:
		return

#	print("Build menu")
	#Build view menu
#	var menu_root = plugin.config_scene.get_node("Views/UvEditor/Menu")
	var menu_root = %menu
	for child in menu_root.get_children():
		var event:CyclopsActionEvent = CyclopsActionEvent.new()
		event.plugin = plugin
			
		if child is MenuLineItemGroup:
			var popup:LineItemPopupMenu = child.create_popup_menu()
			%MenuBar.add_child(popup)
			
			popup.action_chosen.connect(
				func(action:CyclopsAction): \
					if action: \
						action._execute(event) \
					else: \
						print("Action link not found: ", action.name)
				)
	
	build_tool_buttons()

func build_tool_buttons():
	#Build tool buttons
#	print("Build tool bns")
	var active_block:CyclopsBlock = plugin.get_active_block()
	
	var tool_button_group:ButtonGroup = ButtonGroup.new()
	
	var toolbar_root = %tools
	for child in toolbar_root.get_children():
		if child is CyclopsTool:
			var tool_inst:CyclopsTool = child
			var bn:Button = Button.new()
			bn.button_group = tool_button_group
			bn.theme = theme_tool_button
			bn.toggle_mode = true
			bn.button_pressed = child == active_tool
			bn.icon = tool_inst._get_tool_icon()
			if !bn.icon:
				bn.text = tool_inst._get_tool_name()
			bn.tooltip_text = tool_inst._get_tool_tooltip()
			
			bn.pressed.connect(func():
				switch_to_tool(tool_inst)
			)
			
			%tool_buttons.add_child(bn)

	#####
	#if plugin.config_scene:
##		var toolbar_root = plugin.config_scene.get_node("Views/UvEditor/Toolbar")
		#var toolbar_root = %tools
		#for child in toolbar_root.get_children():
			#if child is CyclopsTool:
				#var tool_inst:CyclopsTool = child
#
				#if tool_inst && tool_inst.is_inside_tree() && tool_inst._show_in_toolbar() && tool_inst._can_handle_object(active_block):
##					print("Adding tool")
					#var bn:ToolButton = preload("res://addons/cyclops_level_builder/gui/menu/tool_button.tscn").instantiate()
					#bn.plugin = plugin
					#bn.tool_path = tool_inst.get_path()
					#bn.tool_owner = self
					#bn.icon = tool_inst._get_tool_icon()
##					print("Adding button ", tool._get_tool_name())
					#if !bn.icon:
						#bn.text = tool_inst._get_tool_name()
					#bn.tooltip_text = tool_inst._get_tool_tooltip()
					#
					#%tool_buttons.add_child(bn)
	
#var foo:int = 0
func on_block_selection_changed():
	#print("uv editor: on_block_selection_changed()", foo)
	#foo += 1
	
	#return
	build_menus()
	
	if is_node_ready():
		var ed_iface:EditorInterface = plugin.get_editor_interface()
		var ed_sel:EditorSelection = ed_iface.get_selection()
		
#		print("----sel-----")
		var nodes:Array[CyclopsBlock]
		for node in ed_sel.get_selected_nodes():
			if node is CyclopsBlock:
				nodes.append(node)
#				print("sel: ", node.name)
		
#		%uv_mesh_renderer.block_nodes = nodes
		%uv_editor.block_nodes = nodes
#	pass
	

func save_state(state:Dictionary):
	var substate:Dictionary = {}
	state["uv_editor"] = substate
	#substate["materials"] = material_list.duplicate()

func load_state(state:Dictionary):
	if state == null || !state.has("uv_editor"):
		return
	
	var substate:Dictionary = state["uv_editor"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%SubViewportContainer.set_process_input(true)
	
	#snapping_panel = Control.new()
	#snapping_panel.name = "Snapping"
	#snapping_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#snapping_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	#side_tab_panel.add_control(snapping_panel)
	
	#var test_label:Label = Label.new()
	#test_label.text = "asdfgghhj"
	#side_tab_panel.add_control(test_label)
	
	var snapping_node = %snapping.get_child(0)
	var ed:Control = snapping_node.get_editor()
	ed.size_flags_horizontal = Control.SIZE_EXPAND
	ed.size_flags_vertical = Control.SIZE_EXPAND
	
	snapping_panel.add_child(ed)
	#slide_tab_container.add_child(snapping_panel)
	
#	side_tab_panel.add_control(ed)

#	%tab_insets.current_tab = -1

	bn_use_snap.set_pressed_no_signal(%snapping.use_snap)
	#side_tab_panel.active_tab = -1

	build_menus()
	
	#for child in %tools.get_children():
		#if child is CyclopsTool:
			#switch_to_tool(child)
			#break

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_uv_editor_viewport_size()->Vector2:
	return %SubViewportContainer.size

func _on_sub_viewport_container_gui_input(event: InputEvent) -> void:
	#forward_input.emit(event)
	
	if active_tool:
		active_tool._gui_input(null, event)
	#if event is InputEventKey:
		#print("_on_sub_viewport_container_gui_input ", event)
	pass # Replace with function body.


func _on_feature_vertex_pressed() -> void:
	%uv_editor.select_feature = UvEditor.SelectFeature.VERTEX


func _on_feature_edge_pressed() -> void:
	%uv_editor.select_feature = UvEditor.SelectFeature.EDGE


func _on_feature_face_pressed() -> void:
	%uv_editor.select_feature = UvEditor.SelectFeature.FACE


func _on_sticky_disabled_pressed() -> void:
	%uv_editor.sticky_state = UvEditor.StickyState.DISABLED


func _on_sticky_shared_location_pressed() -> void:
	%uv_editor.sticky_state = UvEditor.StickyState.SHARED_LOCATION


func _on_sticky_shared_vertex_pressed() -> void:
	%uv_editor.sticky_state = UvEditor.StickyState.SHARED_VERTEX


func _on_check_sync_with_mesh_toggled(toggled_on: bool) -> void:
	%uv_editor.sync_selection = toggled_on


#func _on_uv_editor_forward_input(event: InputEvent) -> void:
	#forward_input.emit(event)
	#pass # Replace with function body.


func _on_focus_entered() -> void:
	print("view uv editor._on_focus_entered()")
	pass # Replace with function body.


func _on_focus_exited() -> void:
	print("view uv editor._on_focus_exited()")
	pass # Replace with function body.


func _on_sub_viewport_container_resized() -> void:
	viewport_transform_changed()


func _on_uv_editor_proj_transform_changed(xform: Transform2D) -> void:
	viewport_transform_changed()

func viewport_transform_changed():
	if active_tool:
		active_tool._draw_tool(null)


func _on_option_snapping_item_selected(index: int) -> void:
	var snapping_node:Node = %snapping.get_child(index)
	%snapping.cur_snap_tool_path = snapping_node.get_path()
	
	#var ed:Control = snapping_node.get_editor()
	#
	#if snapping_panel.get_child_count() > 0:
		#var child = snapping_panel.get_child(0)
		#child.queue_free()
	#
	##print("swithing to ed ", ed.name, " ")
	#snapping_panel.add_child(ed)
	
	pass # Replace with function body.


func _on_bn_use_snap_toggled(toggled_on: bool) -> void:
	%snapping.use_snap = toggled_on
	pass # Replace with function body.


func _on_snapping_use_snap_changed(use_snap: bool) -> void:
	bn_use_snap.set_pressed_no_signal(use_snap)
	


func _on_snapping_snap_tool_changed(snap_node: Node) -> void:
	if snap_node:
		var idx:int = snap_node.get_index()
		if %option_snapping.selected != idx:
			%option_snapping.set_block_signals(true)
			%option_snapping.selected = idx
			%option_snapping.set_block_signals(false)
	
	update_snap_display()
	pass # Replace with function body.

func update_snap_display():
	#var snapping_node:Node = %snapping.get_child(index)
	#%snapping.cur_snap_tool_path = snapping_node.get_path()

	var snapping_node = %snapping.cur_snap_tool
	
	if snapping_node:
		for child in snapping_panel.get_children():
			child.queue_free()
		
		var ed:Control = snapping_node.get_editor()
		#print("swithing to ed ", ed.name, " ")
		snapping_panel.add_child(ed)

func activate():
	for child in %tools.get_children():
		if child is CyclopsTool:
			switch_to_tool(child)
			break
	
