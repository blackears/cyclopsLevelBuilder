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

		build_menus()


#func _input(event: InputEvent) -> void:
	#print("view uv ed ", event)
	##input_passthrough.emit(event)
	#pass
	
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
	
#	print("plugin check")
	if !plugin || !plugin.config_scene:
		return

#	print("Build menu")
	#Build view menu
	var menu_root = plugin.config_scene.get_node("Views/UvEditor/Menu")
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

	#Build tool buttons
#	print("Build tool bns")
	var active_block:CyclopsBlock = plugin.get_active_block()
	if plugin.config_scene:
		var toolbar_root = plugin.config_scene.get_node("Views/UvEditor/Toolbar")
		for child in toolbar_root.get_children():
			if child is ToolbarButtonRef:
				var tool:CyclopsTool = child.tool

				if tool._show_in_toolbar() && tool._can_handle_object(active_block):
#					print("Adding tool")
					var bn:ToolButton = preload("res://addons/cyclops_level_builder/gui/menu/tool_button.tscn").instantiate()
					bn.plugin = plugin
					bn.tool_id = tool._get_tool_id()
					bn.icon = tool._get_tool_icon()
#					print("Adding button ", tool._get_tool_name())
					if !bn.icon:
						bn.text = tool._get_tool_name()
					bn.tooltip_text = tool._get_tool_tooltip()
					
					%tool_buttons.add_child(bn)
	
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
		%uv_editor_scene.block_nodes = nodes
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
	build_menus()
	%SubViewportContainer.set_process_input(true)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_sub_viewport_container_gui_input(event: InputEvent) -> void:
	#print("_on_sub_viewport_container_gui_input ", event)
	pass # Replace with function body.
