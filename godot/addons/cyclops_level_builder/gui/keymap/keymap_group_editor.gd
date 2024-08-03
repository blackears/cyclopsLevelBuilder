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

var root_group:KeymapGroup = KeymapGroup.new():
	set(value):
		root_group = value
		rebuild_display()

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
			item.set_editable(2, true)
			item.set_selectable(0, true)
			item.set_selectable(1, true)
			item.set_selectable(2, true)

			tree_item_map[item] = child
			
		elif child is KeymapGroup:
			var item:TreeItem = tree.create_item(root_item)
			item.set_text(0, child.name)
			item.set_editable(0, true)
			item.set_selectable(0, true)

			tree_item_map[item] = child
			
			if collapsed_groups.has(child):
				item.collapsed = true
			
			rebuild_display_recursive(child, tree, item, collapsed_groups)


	

# Called when the node enters the scene tree for the first time.
func _ready():
	%Tree.set_column_title(0, "Display Name")
	%Tree.set_column_title(1, "Action")
	%Tree.set_column_title(2, "Hotkey")
	
	rebuild_display()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#func _get_drag_data(at_position):
	#print("_get_drag_data ",at_position)
	#return null

func show_popup(position:Vector2):
	%popup_actions.position = position
#	%popup_actions.popup()
	%popup_actions.show()
#	%popup_actions.popup(Rect2i(Vector2i(position), Vector2i(0, 0)))
#				%popup_actions.popup_on_parent(Rect2i(Vector2i(e.position), Vector2i(0, 0)))

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
				show_popup(e.position)
				%popup_actions.popup(Rect2i(Vector2i(e.position), Vector2i(0, 0)))
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

func add_keymap_entry():
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
	
	var new_map:KeymapActionMapper = KeymapActionMapper.new()
	new_map.name = "New mapping"
	insert_group.children.insert(insert_idx, new_map)
	
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
	
	rebuild_display()

func remove_keymap_entry():
	pass

func _on_popup_actions_id_pressed(id:int):
	match id:
		0:
			add_keymap_entry()
		1:
			add_keymap_group_entry()
		2:
			remove_keymap_entry()
	pass # Replace with function body.


func _on_tree_empty_clicked(position, mouse_button_index):
	#if mouse_button_index == MOUSE_BUTTON_RIGHT:
		#show_popup(position)
	pass # Replace with function body.


func _on_tree_cell_selected():
	pass # Replace with function body.


func _on_tree_item_edited():
	var item:TreeItem = %Tree.get_edited()
	var col:int = %Tree.get_edited_column()
	
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


func _on_tree_drop_tree_item(data:KeymapTreeControl.DndData, position:Vector2):
#	var item:TreeItem = %Tree.get_child(data.node_index)
	var item:TreeItem = data.item
	var dragged_item:KeymapItem = tree_item_map[item]
	
	
	pass # Replace with function body.
