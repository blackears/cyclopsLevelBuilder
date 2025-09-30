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

#var file_dialog:FileDialog
var save_path:String

var plugin:CyclopsLevelBuilder

@onready var check_flatten:CheckBox = %check_flatten
@onready var check_markers:CheckBox = %check_markers
@onready var check_lights:CheckBox = %check_lights
@onready var check_cameras:CheckBox = %check_cameras
@onready var check_exclude_invisible:CheckBox = %check_exclude_invisible
@onready var lineEdit_path:LineEdit = %lineEdit_path
@onready var file_dialog:FileDialog = %FileDialog

# Called when the node enters the scene tree for the first time.
func _ready():
	
	#file_dialog = FileDialog.new()
	#add_child(file_dialog)
	#file_dialog.size = Vector2(600, 400)
	#file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	#file_dialog.set_access(FileDialog.ACCESS_FILESYSTEM)
	#file_dialog.title = "Export scene..."
	#file_dialog.filters = PackedStringArray(["*.gltf; glTF files"])
#	file_dialog.file_selected.connect(on_save_file)
#	file_dialog.current_file = save_path

#	lineEdit_path.text = save_path
	pass


#func on_save_file(path:String):
	#save_path = path
	#lineEdit_path.text = path

func _on_bn_browse_pressed():
	file_dialog.popup_centered()

func branch_is_valid(node:Node)->bool:
	if !node:
		return false
		
	if node is CyclopsBlock || (check_markers.button_pressed && node is Marker3D):
		return true
	
	for child in node.get_children():
		if child is Node3D and branch_is_valid(child):
			return true
	
	return false
	

func clone_branch(node:Node3D)->Node3D:
	var node_list:Array[Node3D] = []
	var root_clone:Node3D = clone_branch_recursive(node, node_list)
	
	for node_clone in node_list:
		if node_clone != root_clone:
#			print("setting owner ", node_clone.name)
			node_clone.owner = root_clone
	
	return root_clone

func clone_branch_recursive(node:Node3D, node_list:Array[Node3D])->Node3D:
	#print("clean_branch ", node.name)
	if check_exclude_invisible.button_pressed:
		if !node.visible:
			return null
	
	if node is CyclopsBlock:
		var block:CyclopsBlock = node
		var new_node:MeshInstance3D = block.mesh_instance.duplicate()
		new_node.name = block.name
		new_node.transform = block.transform
		node_list.append(new_node)
		return new_node
		
	elif node is Marker3D:
		if check_markers.button_pressed:
			var new_node:Marker3D = node.duplicate()
			node_list.append(new_node)
			new_node.transform = node.transform
			return new_node
		return null
		
	elif node is Light3D:
		if check_lights.button_pressed:
			var new_node:Marker3D = node.duplicate()
			node_list.append(new_node)
			new_node.transform = node.transform
			return new_node
		return null
		
	elif node is Camera3D:
		if check_cameras.button_pressed:
			var new_node:Camera3D = node.duplicate()
			node_list.append(new_node)
			new_node.transform = node.transform
			return new_node
		return null
		
	else:
		var new_node:Node3D = Node3D.new()
		new_node.transform = node.transform
		new_node.name = node.name
		node_list.append(new_node)
		
		for child in node.get_children():
			if branch_is_valid(child):
				var child_branch_copy:Node3D = clone_branch_recursive(child, node_list)
				new_node.add_child(child_branch_copy)
				
		return new_node


#func search_nodes_flat(node:Node, root:Node3D):
##	print("searching %s" % node.name)
	#
	#if node is CyclopsBlock:
		##print("exporting block %s" % node.name)
		#var block:CyclopsBlock = node
		#var new_mesh_node:MeshInstance3D = block.mesh_instance.duplicate()
		#new_mesh_node.name = block.name
		#
		#root.add_child(new_mesh_node)
		#new_mesh_node.global_transform = block.mesh_instance.global_transform
		#
	#elif node is Marker3D:
		#if check_markers.button_pressed:
			#var new_node:Marker3D = Marker3D.new()
			#new_node.name = node.name
#
			#root.add_child(new_node)
			#new_node.global_transform = node.global_transform
#
		#
	#for child in node.get_children():
		#search_nodes_flat(child, root)
	
	

func clone_flat_recursive(node:Node3D, root_clone:Node3D)->void:
	#print("clean_branch ", node.name)
	if check_exclude_invisible.button_pressed:
		return
	
	if node is CyclopsBlock:
		var block:CyclopsBlock = node
		var new_node:MeshInstance3D = block.mesh_instance.duplicate()
		new_node.name = block.name
		root_clone.add_child(new_node)
		new_node.owner = root_clone
		new_node.transform = node.global_transform
		return
		
	elif node is Marker3D:
		if check_markers.button_pressed:
			var new_node:Marker3D = node.duplicate()
			root_clone.add_child(new_node)
			new_node.owner = root_clone
			new_node.transform = node.global_transform
			return
		return
		
	elif node is Light3D:
		if check_lights.button_pressed:
			var new_node:Marker3D = node.duplicate()
			root_clone.add_child(new_node)
			new_node.owner = root_clone
			new_node.transform = node.global_transform
			return
		return
		
	elif node is Camera3D:
		if check_cameras.button_pressed:
			var new_node:Camera3D = node.duplicate()
			root_clone.add_child(new_node)
			new_node.owner = root_clone
			new_node.transform = node.global_transform
			return
		return
		
	else:
		for child in node.get_children():
			if branch_is_valid(child):
				clone_flat_recursive(child, root_clone)

func clone_flat(node:Node3D)->Node3D:
	#print("clean_flat")
	var root:Node3D = Node3D.new()
	root.name = "root"
	
	for child in node.get_children():
		#print("rpt chjild %s" % child.name)
		clone_flat_recursive(child, root)
		
	return root
	

func _on_bn_okay_pressed():
	
	var path:String = save_path
	if !save_path.to_lower().ends_with(".gltf") && !save_path.to_lower().ends_with(".glb"):
		path = save_path + ".gltf"
	
	var doc:GLTFDocument = GLTFDocument.new()
	var state:GLTFState = GLTFState.new()
	var root:Node = plugin.get_editor_interface().get_edited_scene_root()
	var root_clean:Node3D
	
	if check_flatten.button_pressed:
		root_clean = clone_flat(root)
	else:
		root_clean = clone_branch(root)
	
	doc.append_from_scene(root_clean, state)
	doc.write_to_filesystem(state, path)
	
	hide()


func _on_bn_cancel_pressed():
	hide()


func _on_close_requested():
	hide()


func _on_file_dialog_file_selected(path: String) -> void:
	save_path = path
	lineEdit_path.text = path
	pass # Replace with function body.
