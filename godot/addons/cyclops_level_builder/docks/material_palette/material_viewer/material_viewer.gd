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
class_name MaterialViewer

var button_group:RadioButtonGroup = RadioButtonGroup.new()

var builder:CyclopsLevelBuilder:
	get:
		return builder
	set(value):
		if value == builder:
			return
			
		if builder:
			var ed_iface:EditorInterface = builder.get_editor_interface()
			var efs:EditorFileSystem = ed_iface.get_resource_filesystem()
			efs.filesystem_changed.disconnect(on_filesystem_changed)
			efs.resources_reimported.disconnect(on_resources_reimported)
			efs.resources_reload.disconnect(on_resources_reload)
			
		builder = value
		%MatGroupTree.plugin = builder
		
		if builder:
			var ed_iface:EditorInterface = builder.get_editor_interface()
			var efs:EditorFileSystem = ed_iface.get_resource_filesystem()
			efs.filesystem_changed.connect(on_filesystem_changed)
			efs.resources_reimported.connect(on_resources_reimported)
			efs.resources_reload.connect(on_resources_reload)
		
		reload_materials()


var material_groups:MaterialGroup

func on_filesystem_changed():
	print("on_filesystem_changed")
	pass

func on_resources_reimported(resources:PackedStringArray):
	print("on_resources_reimported ", resources)
	pass

func on_resources_reload(resources:PackedStringArray):
	print("on_resources_reload ", resources)
	pass

func reload_materials():
	#return
	
	for child in %ButtonArea.get_children():
		%ButtonArea.remove_child(child)
		child.queue_free()
	
	if !builder:
		return
		
	var ed_iface:EditorInterface = builder.get_editor_interface()
	var efs:EditorFileSystem = ed_iface.get_resource_filesystem()
	
	var efsd:EditorFileSystemDirectory = efs.get_filesystem()
	reload_materials_recursive(efsd)
	pass

func reload_materials_recursive(dir:EditorFileSystemDirectory):
	var ed_iface:EditorInterface = builder.get_editor_interface()
	var res_prev:EditorResourcePreview = ed_iface.get_resource_previewer()

	for i in dir.get_file_count():
#		dir.get_file(i)
		var type:String = dir.get_file_type(i)
		#"StandardMaterial3D"
		if type == "StandardMaterial3D" || type == "ShaderMaterial" || type == "ORMMaterial3D":
			var path:String = dir.get_file_path(i)
			#print("path %s type %s" % [path, type])
			
			res_prev.queue_resource_preview(path, self, "resource_preview_callback", null)
			
			var bn:MaterialButton = preload("res://addons/cyclops_level_builder/docks/material_palette/material_viewer/material_button.tscn").instantiate()
			bn.material_path = path
			bn.plugin = builder
			button_group.add_button(bn)
			
			%ButtonArea.add_child(bn)
			pass

	for i in dir.get_subdir_count():
		reload_materials_recursive(dir.get_subdir(i))

func resource_preview_callback(path:String, preview:Texture2D, userdata:Variant):
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	material_groups = MaterialGroup.new("All")
	
	reload_materials()
	
	
	#var root:TreeItem = %Tree.create_item()
	#var child1:TreeItem = %Tree.create_item(root)
	#var child2:TreeItem = %Tree.create_item(root)
	#var subchild1:TreeItem = %Tree.create_item(child1)
	#subchild1.set_text(0, "Subchild1")
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_bn_refresh_mat_list_pressed():
	reload_materials()


func _on_line_ed_filter_text_changed(new_text):
	pass # Replace with function body.
