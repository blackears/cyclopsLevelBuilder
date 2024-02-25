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
extends Tree
class_name MaterialGroupsTree


var plugin:CyclopsLevelBuilder:
	get:
		return plugin
	set(value):
		if value == plugin:
			return
			
		if plugin:
			var ed_iface:EditorInterface = plugin.get_editor_interface()
			var efs:EditorFileSystem = ed_iface.get_resource_filesystem()
			efs.filesystem_changed.disconnect(on_filesystem_changed)
			efs.resources_reimported.disconnect(on_resources_reimported)
			efs.resources_reload.disconnect(on_resources_reload)
			
		plugin = value
		
		if plugin:
			var ed_iface:EditorInterface = plugin.get_editor_interface()
			var efs:EditorFileSystem = ed_iface.get_resource_filesystem()
			efs.filesystem_changed.connect(on_filesystem_changed)
			efs.resources_reimported.connect(on_resources_reimported)
			efs.resources_reload.connect(on_resources_reload)
		
		reload_materials()

var root_group:MaterialGroup = MaterialGroup.new()

func _input(event):
	if event is InputEventMouseButton:
		var e:InputEventMouseButton = event
		
		if e.button_index == MOUSE_BUTTON_RIGHT:
			if !e.is_pressed():
				
				%PopupMenu.popup_on_parent(Rect2i(e.position.x, e.position.y, 0, 0))

			get_viewport().set_input_as_handled()
		

func reload_materials():
	print("reload_materials")
	clear()
	
	if !root_group:
		return
	
	print("Set item ", root_group.name)
	var root_item:TreeItem = create_item()
	root_item.set_text(0, root_group.name)
	root_item.set_editable(0, true)
	
	build_tree_recursive(root_group, root_item)
	
	pass


func build_tree_recursive(mat_group:MaterialGroup, tree_group_parent:TreeItem):
	var item:TreeItem = create_item(tree_group_parent)
	item.set_text(0, mat_group.name)
	item.set_editable(0, true)
	
	for child in mat_group.children:
		build_tree_recursive(child, item)
	
	
func on_filesystem_changed():
	pass

func on_resources_reimported(resources: PackedStringArray):
	pass

func on_resources_reload(resources: PackedStringArray):
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func create_new_group():
	pass

func delete_selected_group():
	pass

func rename_selected_group():
	pass

func _on_item_selected():
	var item:TreeItem = get_selected()
	item.get_index()
	pass # Replace with function body.


func _on_item_edited():
	var item:TreeItem = get_edited()
	pass # Replace with function body.


func _on_popup_menu_id_pressed(id:int):
	match id:
		0:
			create_new_group()
		1:
			delete_selected_group()
		2:
			rename_selected_group()
			
