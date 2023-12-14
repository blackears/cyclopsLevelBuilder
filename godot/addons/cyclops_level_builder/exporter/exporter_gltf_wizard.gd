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
extends Window
class_name ExporterGltfWizard

#@onready var _text_path:LineEdit = $VBoxContainer/HBoxContainer/text_path
var _text_path:LineEdit

var file_dialog:FileDialog
var save_path:String

var plugin:CyclopsLevelBuilder



# Called when the node enters the scene tree for the first time.
func _ready():
	
	file_dialog = FileDialog.new()
	add_child(file_dialog)
	file_dialog.size = Vector2(600, 400)
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.set_access(FileDialog.ACCESS_FILESYSTEM)
	file_dialog.title = "Export scene..."
	file_dialog.filters = PackedStringArray(["*.gltf ; glTF files"])
	file_dialog.current_file = save_path

#	_text_path = $VBoxContainer/HBoxContainer/lineEdit_path
	#var hh = get_node("VBoxContainer")
	#var children = get_children()


#	_text_path = get_node("VBoxContainer/HBoxContainer/lineEdit_path")
	_text_path = %lineEdit_path
	_text_path.text = save_path


func on_save_file(path:String):
	save_path = path
	_text_path.text = path

func _on_bn_browse_pressed():
	file_dialog.file_selected.connect(on_save_file)
	file_dialog.popup_centered()
	pass

func branch_is_valid(node:Node)->bool:
	if node is CyclopsBlock || (%check_markers.button_pressed && node is Marker3D):
		return true
	
	for child in node.get_children():
		if child is Node3D and branch_is_valid(child):
			return true
	
	return false
	

func clean_branch(node:Node3D)->Node3D:
	if node is CyclopsBlock:
		var block:CyclopsBlock = node
		var new_mesh_node:MeshInstance3D = block.mesh_instance.duplicate()
		new_mesh_node.name = block.mesh_instance.name
		
		var new_node:Node3D = Node3D.new()
		new_node.name = node.name
		new_node.transform = node.transform
		new_node.add_child(new_mesh_node)
		return new_node
		
	elif node is Marker3D:
		var new_node:Marker3D = node.duplicate()
		return new_node
		
	else:
		var new_node:Node3D = Node3D.new()
		new_node.transform = node.transform
		new_node.name = node.name
		for child in node.get_children():
			if branch_is_valid(child):
				new_node.add_child(clean_branch(child))
		return new_node


func search_nodes_flat(node:Node, root:Node3D):
#	print("searching %s" % node.name)
	
	if node is CyclopsBlock:
		#print("exporting block %s" % node.name)
		var block:CyclopsBlock = node
		var new_mesh_node:MeshInstance3D = block.mesh_instance.duplicate()
		new_mesh_node.name = block.name
		
		root.add_child(new_mesh_node)
		new_mesh_node.global_transform = block.mesh_instance.global_transform
		
	elif node is Marker3D:
		if %check_markers.button_pressed:
			var new_node:Marker3D = Marker3D.new()
			new_node.name = node.name

			root.add_child(new_node)
			new_node.global_transform = node.global_transform

		
	for child in node.get_children():
		search_nodes_flat(child, root)
	
	

func clean_flat(node:Node3D)->Node3D:
	#print("clean_flat")
	var root:Node3D = Node3D.new()
	root.name = "CyclopsScene"
	
	for child in node.get_children():
		#print("rpt chjild %s" % child.name)
		search_nodes_flat(child, root)
		
	return root
	

func _on_bn_okay_pressed():
	
	var path:String = save_path
	if !save_path.to_lower().ends_with(".gltf") && !save_path.to_lower().ends_with(".glb"):
		path = save_path + ".gltf"
		
	
	var doc:GLTFDocument = GLTFDocument.new()
	var state:GLTFState = GLTFState.new()
	var root:Node = plugin.get_editor_interface().get_edited_scene_root()
	var root_clean:Node3D = clean_flat(root) if %check_flatten.button_pressed else clean_branch(root)
	
	doc.append_from_scene(root_clean, state)
	doc.write_to_filesystem(state, path)
	
	hide()


func _on_bn_cancel_pressed():
	hide()


func _on_close_requested():
	hide()
