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

extends Control

#func _gui_input(event):
	#pass

var model:TestTreeDataModel = TestTreeDataModel.new()

func _input(event):
	if event is InputEventMouseButton:
		var e:InputEventMouseButton = event
		
		if e.button_index == MOUSE_BUTTON_RIGHT:
			if !e.is_pressed():
				
				picked_item = %Tree.get_item_at_position(e.position)
				%PopupMenu.popup(Rect2i(e.position.x, e.position.y, 0, 0))

			get_viewport().set_input_as_handled()

var node_map:Dictionary

var picked_item:TreeItem

# Called when the node enters the scene tree for the first time.
func _ready():
	%Tree.select_mode = Tree.SELECT_SINGLE
	
	var root:TreeItem = %Tree.create_item()
	root.set_editable(0, true)
	root.set_text(0, model.root.name)
	#root.get_index()
	node_map[root] = model.root
	
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _can_drop_data(at_position:Vector2, data:Variant)->bool:
	var item:TreeItem = %Tree.get_item_at_position(at_position)
	if !item || !item.get_parent():
		return false
	return true
		

func _drop_data(at_position:Vector2, data:Variant):
	pass
	
func _get_drag_data(at_position:Vector2)->Variant:
	print("_get_drag_data")
	
	var item:TreeItem = %Tree.get_item_at_position(at_position)
	if !item:
		return null
	
	var tier:TestTreeDataModel.Tier = node_map[item]
	
	var label:Label = Label.new()
	label.text = tier.name
	set_drag_preview(label)
	
	return tier.get_parent()
	

func _on_tree_custom_item_clicked(mouse_button_index:int):
	print("bn ", mouse_button_index)
	pass # Replace with function body.


func _on_tree_item_selected():
	#print("_on_tree_item_selected")
	pass


func _on_tree_custom_popup_edited(arrow_clicked):
	print("_on_tree_custom_popup_edited ", arrow_clicked)
	pass # Replace with function body.


func _on_tree_item_edited():
	#print("_on_tree_item_edited")
	var item:TreeItem = %Tree.get_edited()
	if node_map.has(item):
		node_map[item].name = item.get_text(0)
	
	pass # Replace with function body.

func create_new_item():
#	var item:TreeItem = %Tree.get_selected()
	var item:TreeItem = picked_item
	if !item:
		return
	
	
	var child_name:String = "child"
	var parent_tier:TestTreeDataModel.Tier = node_map[item]
	var child_tier:TestTreeDataModel.Tier = parent_tier.create_child_with_name(child_name)
	
	var child:TreeItem = %Tree.create_item(item)
	child.set_editable(0, true)
	child.set_text(0, child_name)
	
	node_map[child] = child_tier
	pass


func delete_recursive(item:TreeItem):
	for child in item.get_children():
		delete_recursive(child)
		
	
	var child_tier:TestTreeDataModel.Tier = node_map[item]
	var parent_tier:TestTreeDataModel.Tier = child_tier.get_parent()
	parent_tier.remove_child(child_tier)
		
	item.get_parent().remove_child(item)
	node_map.erase(child_tier)
	

func delete_selected_item():
	#var item:TreeItem = %Tree.get_selected()
	var item:TreeItem = picked_item
	if !item:
		return
		
	delete_recursive(item)
		
	#var child_tier:TestTreeDataModel.Tier = node_map[item]
	#var parent_tier:TestTreeDataModel.Tier = child_tier.get_parent()
	#parent_tier.remove_child(child_tier)
		#
	#item.get_parent().remove_child(item)
	#node_map.erase(child_tier)
	##delete_index()
	#pass
	
func _on_popup_menu_id_pressed(id):
	match id:
		0:
			create_new_item()
		1:
			delete_selected_item()
