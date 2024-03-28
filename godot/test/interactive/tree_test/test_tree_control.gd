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

extends Tree


var model:TestTreeDataModel = TestTreeDataModel.new()

func _gui_input(event):
	if event is InputEventMouseButton:
		var e:InputEventMouseButton = event
		
		if e.button_index == MOUSE_BUTTON_RIGHT:
			if !e.is_pressed():
				
				picked_item = get_item_at_position(e.position)
				%PopupMenu.popup(Rect2i(e.position.x, e.position.y, 0, 0))

			get_viewport().set_input_as_handled()

var tree_item_to_tier_map:Dictionary
var tier_to_tree_item_map:Dictionary

var picked_item:TreeItem

# Called when the node enters the scene tree for the first time.
func _ready():
	var root:TreeItem = create_item()
	root.set_editable(0, true)
	root.set_text(0, model.root.name)
	#root.get_index()
	tree_item_to_tier_map[root] = model.root
	tier_to_tree_item_map[model.root] = root
	
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _can_drop_data(at_position:Vector2, data:Variant)->bool:
	if !(data is TestTreeDataModel.Path):
		return false
	
	var src_path:TestTreeDataModel.Path = data
	
	var item:TreeItem = get_item_at_position(at_position)
	if !item:
		return false

	var section:int = get_drop_section_at_position(at_position)
	var parent_item:TreeItem = item.get_parent()

	var tgt_path:TestTreeDataModel.Path = tree_item_to_tier_map[item].get_path()
	
	if src_path.path == tgt_path.path:
		return false

	if src_path.equals_path(tgt_path):
		return false
	
	#Values -1, 0, or 1 will be returned for the "above item", "on item", and "below item" drop sections
	match section:
		-1:
			if !parent_item:
				return false
			tgt_path = tree_item_to_tier_map[parent_item].get_path()
			return !src_path.is_ancestor_of_or_equal_to(tgt_path)
		1:
			if !parent_item:
				return false
			tgt_path = tree_item_to_tier_map[parent_item].get_path()
			return !src_path.is_ancestor_of_or_equal_to(tgt_path)
		0:
			return !src_path.is_ancestor_of_or_equal_to(tgt_path)
		_:
			return false
	
	return true
		

func _drop_data(at_position:Vector2, data:Variant):
#	print("_drop_data")
	if !(data is TestTreeDataModel.Path):
		return false
	
	var src_path:TestTreeDataModel.Path = data
	var src_tier:TestTreeDataModel.Tier = model.get_tier_from_path(src_path)
	
	var item:TreeItem = get_item_at_position(at_position)
	if !item:
		return false

	var section:int = get_drop_section_at_position(at_position)
	var parent_item:TreeItem = item.get_parent()

	var tgt_tier:TestTreeDataModel.Tier = tree_item_to_tier_map[item]
	var tgt_path:TestTreeDataModel.Path = tgt_tier.get_path()

	match section:
		0:
			clone_branch(src_tier, tgt_tier, 0)
			delete_branch(src_tier)
		-1:
			var par_tier:TestTreeDataModel.Tier = tgt_tier.parent
			clone_branch(src_tier, par_tier, par_tier.index_of(tgt_tier))
			delete_branch(src_tier)
		1:
			var par_tier:TestTreeDataModel.Tier = tgt_tier.parent
			clone_branch(src_tier, par_tier, par_tier.index_of(tgt_tier) + 1)
			delete_branch(src_tier)

func clone_branch(src_tier:TestTreeDataModel.Tier, tgt_tier:TestTreeDataModel.Tier, index:int):
	var child_name:String = tgt_tier.create_unique_name(src_tier.name)
	
	var tgt_item:TreeItem = tier_to_tree_item_map[tgt_tier]
	var child_item = create_item(tgt_item, index)
	child_item.set_editable(0, true)
	child_item.set_text(0, child_name)
	
	var child_tier = tgt_tier.create_child_with_name(child_name, index)
	
	tier_to_tree_item_map[child_tier] = child_item
	tree_item_to_tier_map[child_item] = child_tier
	
	for i in src_tier.children.size():
		clone_branch(src_tier.children[i], child_tier, i)
	
	pass
	
func delete_branch(tier:TestTreeDataModel.Tier):
	delete_recursive(tier_to_tree_item_map[tier])
	
func _get_drag_data(at_position:Vector2)->Variant:
	
	var item:TreeItem = get_item_at_position(at_position)
	if !item:
		return null
	
	var tier:TestTreeDataModel.Tier = tree_item_to_tier_map[item]
	
	var label:Label = Label.new()
	label.text = tier.name
	set_drag_preview(label)
	
	return tier.get_path()
	

func _on_item_selected():
	#print("_on_tree_item_selected")
	pass


func _on_item_edited():
	#print("_on_tree_item_edited")
	var item:TreeItem = get_edited()
	if tree_item_to_tier_map.has(item):
		tree_item_to_tier_map[item].name = item.get_text(0)
	
	pass # Replace with function body.

func create_new_item():
#	var item:TreeItem = %Tree.get_selected()
	var item:TreeItem = picked_item
	if !item:
		return

	var parent_tier:TestTreeDataModel.Tier = tree_item_to_tier_map[item]
	
	var child_name:String = parent_tier.create_unique_name("tier")
	var child_tier:TestTreeDataModel.Tier = \
		parent_tier.create_child_with_name(child_name, parent_tier.num_children())
	
	var child:TreeItem = create_item(item)
	child.set_editable(0, true)
	child.set_text(0, child_name)
	
	tree_item_to_tier_map[child] = child_tier
	tier_to_tree_item_map[child_tier] = child
	pass


func delete_recursive(item:TreeItem):
	for child in item.get_children():
		delete_recursive(child)
		
	
	var child_tier:TestTreeDataModel.Tier = tree_item_to_tier_map[item]
	var parent_tier:TestTreeDataModel.Tier = child_tier.get_parent()
	parent_tier.remove_child(child_tier)
		
	item.get_parent().remove_child(item)
	tree_item_to_tier_map.erase(child_tier)
	tier_to_tree_item_map.erase(item)
	

func delete_selected_item():
	#var item:TreeItem = %Tree.get_selected()
	var item:TreeItem = picked_item
	if !item:
		return
		
	delete_recursive(item)
	
func _on_popup_menu_id_pressed(id):
	match id:
		0:
			create_new_item()
		1:
			delete_selected_item()
			


