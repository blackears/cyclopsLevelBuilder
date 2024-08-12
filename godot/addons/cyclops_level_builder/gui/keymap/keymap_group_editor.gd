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
class_name KeymapGroupEditor


var tree_item_map:Dictionary


var plugin:CyclopsLevelBuilder:
	set(value):
		plugin = value

	
#var root_group:KeymapGroup = KeymapGroup.new():
var root_group:KeymapGroup:
	set(value):
		root_group = value
		rebuild_display()

var action_id_selector:ActionIdSelector = preload("res://addons/cyclops_level_builder/gui/docks/cyclops_console/keymap_editor/action_id_selector.tscn").instantiate()


func rebuild_display():
	var collapsed_groups:Array[KeymapGroup]
	for key:TreeItem in tree_item_map.keys():
		if key.collapsed:
			collapsed_groups.append(tree_item_map[key])
	
	%Tree.clear()
	tree_item_map.clear()
	
	if !root_group:
		return
	
	var tree:Tree = %Tree
	var root_item:TreeItem = tree.create_item()
	tree_item_map[root_item] = root_group
			
	rebuild_display_recursive(root_group, tree, root_item, collapsed_groups)
#	var grp:KeymapGroup = plugin.keymap
	#for child:KeymapItem in root_group.children:
		#if child is KeymapActionMapper:
			#tree.create_item(root_item)
			
func rebuild_display_recursive(grp:KeymapGroup, tree:Tree, root_item:TreeItem, collapsed_groups:Array[KeymapGroup]):
	for child:KeymapItem in grp.children:
		if child is KeymapActionMapper:
			var am:KeymapActionMapper = child
			var item:TreeItem = tree.create_item(root_item)
			item.set_text(0, am.name)
			item.set_text(1, am.action_id)
			item.set_text(2, str(am.keypress))
			item.set_editable(0, true)
			item.set_editable(1, true)
			#item.set_editable(2, true)
			item.set_selectable(0, true)
			item.set_selectable(1, true)
			item.set_selectable(2, true)
			
			item.set_cell_mode(2, TreeItem.CELL_MODE_STRING)

			tree_item_map[item] = child
			
		elif child is KeymapGroup:
			var item:TreeItem = tree.create_item(root_item)
			item.set_text(0, child.name)
			item.set_editable(0, true)
			item.set_selectable(0, true)
			item.set_custom_bg_color(0, Color.DIM_GRAY)

			tree_item_map[item] = child
			
			if collapsed_groups.has(child):
				item.collapsed = true
			
			rebuild_display_recursive(child, tree, item, collapsed_groups)


	

# Called when the node enters the scene tree for the first time.
func _ready():
	%Tree.set_column_title(0, "Display Name")
	%Tree.set_column_title(1, "Action")
	%Tree.set_column_title(2, "Hotkey")
	
	action_id_selector.id_selected.connect(func(action_id:String): 
		add_keymap_entry(action_id)
		action_id_selector.hide()
		)
	add_child(action_id_selector)
	action_id_selector.visible = false
	
	rebuild_display()
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func show_popup(popup_pos:Vector2):

	#print("get_screen_transform() ", get_screen_transform())
	#print("popup_pos ", popup_pos)
	#print("get_screen_transform() * popup_pos ", get_screen_transform() * popup_pos)

	%popup_actions.popup(Rect2i(get_screen_transform() * popup_pos, Vector2i.ZERO))

var dragging:bool = false
var mouse_down_pos:Vector2

func _on_tree_gui_input(event:InputEvent):
	#print("_on_tree_gui_input")
	if event is InputEventMouseButton:
		var e:InputEventMouseButton = event
		if e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				dragging = true
				mouse_down_pos = e.position
			else:
				dragging = false
			
		elif e.button_index == MOUSE_BUTTON_RIGHT:
			if e.pressed:
#				show_popup(get_global_transform() * e.position)
				show_popup(e.position)
				#%popup_actions.popup(Rect2i(Vector2i(e.position), Vector2i(0, 0)))
#				%popup_actions.popup_on_parent(Rect2i(Vector2i(e.position), Vector2i(0, 0)))
				pass
				
			get_viewport().set_input_as_handled()
		pass

	if event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event
		
		if dragging && e.position.distance_to(mouse_down_pos) > 4:
			#print("starting drag")
			var data:KeymapTreeControl.DndData = KeymapTreeControl.DndData.new()
			var item:TreeItem = %Tree.get_item_at_position(e.position)
			
			data.node_index = item.get_index()
			data.item = item
			force_drag(data, null)
			dragging = false
	
	pass # Replace with function body.

func add_keymap_entry(action_id:String):
	var insert_group:KeymapGroup
	var insert_idx:int

#	print("Addding keymap entry ", action_id)

	var cur_item:TreeItem = %Tree.get_selected()
	
	if !cur_item:
		insert_group = root_group
		insert_idx = root_group.children.size()
		
	elif tree_item_map[cur_item] is KeymapGroup:
		insert_group = tree_item_map[cur_item]
		insert_idx = 0
	else:	
		var par_item:TreeItem = cur_item.get_parent()
		
		if par_item:
			insert_group = tree_item_map[par_item]
			insert_idx = insert_group.children.find(tree_item_map[cur_item])
		else:
			insert_group = root_group
			insert_idx = root_group.children.size()
	
	var new_map:KeymapActionMapper = KeymapActionMapper.new()
	new_map.name = action_id
	new_map.action_id = action_id
	insert_group.children.insert(insert_idx, new_map)
	
	plugin.save_keymap()
	rebuild_display()

func add_keymap_group_entry():
	var insert_group:KeymapGroup
	var insert_idx:int

	var cur_item:TreeItem = %Tree.get_selected()
	
	if !cur_item:
		insert_group = root_group
		insert_idx = root_group.children.size()
		
	elif tree_item_map[cur_item] is KeymapGroup:
		insert_group = tree_item_map[cur_item]
		insert_idx = 0
	else:	
		var par_item:TreeItem = cur_item.get_parent()
		
		if par_item:
			insert_group = tree_item_map[par_item]
			insert_idx = insert_group.children.find(tree_item_map[cur_item])
		else:
			insert_group = root_group
			insert_idx = root_group.children.size()
	
	var new_group:KeymapGroup = KeymapGroup.new()
	new_group.name = "New group"
	insert_group.children.insert(insert_idx, new_group)
	
	plugin.save_keymap()
	rebuild_display()

func remove_keymap_entry():
	plugin.save_keymap()
	pass

func build_parameter_ui(action_mapper:KeymapActionMapper):
	for child in %param_grid.get_children():
		%param_grid.remove_child(child)
		child.queue_free()
	
	#if !%bn_show_params.button_pressed:
		#return
	if !action_mapper:
		return
	
#	print("action_id, ", action_id)
	var action:CyclopsAction = plugin.get_action(action_mapper.action_id)

	if action:
#		print("param props")
		for prop_dict in action.get_property_list():
			#print("prop_dict ", prop_dict)
			var prop_name:String = prop_dict["name"]
			var usage:PropertyUsageFlags = prop_dict["usage"]
			var hint:PropertyHint = prop_dict["hint"]
			var hint_string:String = prop_dict["hint_string"]
			
			if !(usage & PROPERTY_USAGE_EDITOR):
				continue
				
			#print("-adding prop ", prop_name)
			
			var type:Variant.Type = prop_dict["type"]
			match type:
				TYPE_BOOL:
					var label:Label = Label.new()
					label.text = prop_name
					%param_grid.add_child(label)
					
					var editor:CheckBox = CheckBox.new()
					if action_mapper.params.has(prop_name):
						editor.button_pressed = action_mapper.params[prop_name]
					editor.toggled.connect(func(state:bool):
						action_mapper.params[prop_name] = state
						)
					%param_grid.add_child(editor)
					
				TYPE_INT:
					var label:Label = Label.new()
					label.text = prop_name
					%param_grid.add_child(label)
					
					var editor:SpinBox = SpinBox.new()
					if action_mapper.params.has(prop_name):
						editor.value = action_mapper.params[prop_name]
					editor.value_changed.connect(func(value:float):
						action_mapper.params[prop_name] = int(value)
						)
					
					if hint == PROPERTY_HINT_RANGE:
						var parts:Array = hint_string.split(",")
						editor.min_value = int(float(parts[0]))
						editor.max_value = int(float(parts[1]))
						if parts.size() >= 2:
							editor.step = int(float(parts[2]))
						
					%param_grid.add_child(editor)
					
				TYPE_FLOAT:
					var label:Label = Label.new()
					label.text = prop_name
					%param_grid.add_child(label)
					
					var editor:SpinBox = SpinBox.new()
					if action_mapper.params.has(prop_name):
						editor.value = action_mapper.params[prop_name]
					editor.value_changed.connect(func(value:float):
						action_mapper.params[prop_name] = value
						)
					
					if hint == PROPERTY_HINT_RANGE:
						var parts:Array = hint_string.split(",")
						editor.min_value = float(parts[0])
						editor.max_value = float(parts[1])
						if parts.size() >= 2:
							editor.step = float(parts[2])
						
					%param_grid.add_child(editor)
				
				TYPE_STRING:
					#print("adding string")
					var label:Label = Label.new()
					label.text = prop_name
					%param_grid.add_child(label)
					
					var editor:LineEdit = LineEdit.new()
					editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					if action_mapper.params.has(prop_name):
						editor.text = action_mapper.params[prop_name]
					editor.text_submitted.connect(func(value:String):
						action_mapper.params[prop_name] = value
						)
					editor.focus_exited.connect(func():
						action_mapper.params[prop_name] = editor.text
						)
						
					%param_grid.add_child(editor)

func _on_popup_actions_id_pressed(id:int):
	match id:
		0:
			#var id_sel:ActionIdSelector = preload("res://addons/cyclops_level_builder/gui/docks/cyclops_console/keymap_editor/action_id_selector.tscn").instantiate()
			
			action_id_selector.plugin = plugin
			#id_sel.close_requested.connect(func():
				#id_sel.queue_free()
				#print("closing id pick")
				#)
			action_id_selector.popup_centered()
			
		1:
			add_keymap_group_entry()
		2:
			remove_keymap_entry()
	pass # Replace with function body.


func _on_tree_empty_clicked(position, mouse_button_index):
	#if mouse_button_index == MOUSE_BUTTON_RIGHT:
		#show_popup(position)
	pass # Replace with function body.

#func picked_keypress(am:KeymapActionMapper, key:Key):
	#am.keypress = KeymapKeypress.new()
	#am.keypress.keycode = key
	#rebuild_display()
	
func _on_tree_cell_selected():
	#print("_on_tree_cell_selected")
	var item:TreeItem = %Tree.get_selected()
	var col:int = %Tree.get_selected_column()
	
	if !item:
		return
		
	var node:KeymapItem = tree_item_map[item]
	
	if node is KeymapActionMapper:
		build_parameter_ui(node)
	else:
		build_parameter_ui(null)
	
	match col:
		2:
			if node is KeymapActionMapper:
				var am:KeymapActionMapper = node
				#print("select col ", am.action_id)
				
				var picker:KeycodePicker = preload("res://addons/cyclops_level_builder/gui/docks/cyclops_console/keymap_editor/keycode_picker.tscn").instantiate()
				picker.key_selected.connect(func(key:Key, modifier_mask:KeyModifierMask): 
					am.keypress = KeymapKeypress.new()
					am.keypress.keycode = key
					am.keypress.shift = (modifier_mask & KEY_MASK_SHIFT) != 0
					am.keypress.ctrl = (modifier_mask & KEY_MASK_CTRL) != 0
					am.keypress.alt = (modifier_mask & KEY_MASK_ALT) != 0
					am.keypress.meta = (modifier_mask & KEY_MASK_META) != 0
					rebuild_display()
					picker.queue_free()
					)
				picker.close_requested.connect(func():
					picker.queue_free()
					)
				
				add_child(picker)
				picker.popup_centered()
				return
	
			
	
	pass # Replace with function body.


func _on_tree_item_edited():
	var item:TreeItem = %Tree.get_edited()
	var col:int = %Tree.get_edited_column()
	
	var node:KeymapItem = tree_item_map[item]
	
	match col:
		0:
			if node is KeymapActionMapper:
				node.name = item.get_text(0)
			elif node is KeymapGroup:
				node.name = item.get_text(0)
			pass

	plugin.save_keymap()

	pass # Replace with function body.


func _on_tree_item_selected():
	#var item:TreeItem = %Tree.get_selected()
	#var col:int = %Tree.get_selected_column()
	#
	#item.set_editable(col, true)
	pass # Replace with function body.


func _on_tree_item_mouse_selected(position, mouse_button_index):
	print("_on_tree_item_mouse_selected")
	pass # Replace with function body.


func _on_tree_custom_item_clicked(mouse_button_index):
	print("_on_tree_custom_item_clicked")
	pass # Replace with function body.


func is_item_same_or_ancestor_of(item:TreeItem, peer:TreeItem)->bool:
	if item == peer:
		return true
	
	if !peer:
		return false
	
	var parent:TreeItem = peer.get_parent()
	if !parent:
		return false
		
	return is_item_same_or_ancestor_of(item, parent)

func _on_tree_drop_tree_item(data:KeymapTreeControl.DndData, position:Vector2):
#	var item:TreeItem = %Tree.get_child(data.node_index)
	var dragged_item:TreeItem = data.item
	
	var dragged_node:KeymapItem = tree_item_map[dragged_item]
	var drop_item:TreeItem = %Tree.get_item_at_position(position)
	if !drop_item:
		return
	#-1 - just before, 0 - on top of, 1 - just after
	var drop_section:int = %Tree.get_drop_section_at_position(position)
	
	if is_item_same_or_ancestor_of(dragged_item, drop_item):
		return

	#Remove from current group
	var parent_dragged_item:TreeItem = dragged_item.get_parent()
	var parent_dragged_node:KeymapGroup = tree_item_map[parent_dragged_item]
	parent_dragged_node.children.remove_at(parent_dragged_node.children.find(dragged_node))

	#Reinsert into tree
	var drop_node:KeymapItem = tree_item_map[drop_item]
	
	
	if drop_section == 0:
		if drop_node is KeymapGroup:
			drop_node.children.append(dragged_node)
		else:
			var parent_drop_node:KeymapGroup = tree_item_map[drop_item.get_parent()]
			var drop_index:int = parent_drop_node.children.find(drop_node)
			parent_drop_node.children.insert(drop_index, dragged_node)
	
	else:
		var parent_drop_node:KeymapGroup = tree_item_map[drop_item.get_parent()]
		var drop_index:int = parent_drop_node.children.find(drop_node)
		if drop_section == 1:
			drop_index += 1
		parent_drop_node.children.insert(drop_index, dragged_node)

	plugin.save_keymap()

	rebuild_display()

