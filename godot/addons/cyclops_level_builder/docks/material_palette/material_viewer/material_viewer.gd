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

#var button_group:RadioButtonGroup = RadioButtonGroup.new()

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

var selected_material_paths:Array[String]
var material_viewer_state:MaterialViewerState = preload("res://addons/cyclops_level_builder/docks/material_palette/material_viewer/material_viewer_state_res.tres")

func on_filesystem_changed():
	#print("on_filesystem_changed")
	reload_materials()
	pass

func on_resources_reimported(resources:PackedStringArray):
	#print("on_resources_reimported ", resources)
	pass

func on_resources_reload(resources:PackedStringArray):
	#print("on_resources_reload ", resources)
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
	var mat_name_filter:String = %lineEd_filter.text
	
	if !%MatGroupTree.is_path_visible(dir.get_path()):
		return
	#var vis = %MatGroupTree.is_path_visible(dir.get_path())
	#print("reload check path ", dir.get_path(), " vis ", vis)
	#get_hidden_directories()
	
	var ed_iface:EditorInterface = builder.get_editor_interface()
	var res_prev:EditorResourcePreview = ed_iface.get_resource_previewer()

	for i in dir.get_file_count():
#		dir.get_file(i)
		var type:String = dir.get_file_type(i)
		#"StandardMaterial3D"
		if type == "StandardMaterial3D" || type == "ShaderMaterial" || type == "ORMMaterial3D":
			var path:String = dir.get_file_path(i)
			
			if !mat_name_filter.is_empty() && !path.contains(mat_name_filter):
				continue
			
			#print("path %s type %s" % [path, type])
			
			#res_prev.queue_resource_preview(path, self, "resource_preview_callback", null)
			
			var bn:MaterialButton = preload("res://addons/cyclops_level_builder/docks/material_palette/material_viewer/material_button.tscn").instantiate()
			bn.material_path = path
			bn.plugin = builder
			bn.selected = selected_material_paths.has(path)
			bn.active = !selected_material_paths.is_empty() && path == selected_material_paths[-1]
			#button_group.add_button(bn)
			bn.apply_material.connect(func(mat_bn:MaterialButton): apply_material(mat_bn))
			bn.select_material.connect(func(mat_bn:MaterialButton, type:SelectionList.Type): select_material(mat_bn, type))
			
			%ButtonArea.add_child(bn)
			pass

	for i in dir.get_subdir_count():
		reload_materials_recursive(dir.get_subdir(i))

func apply_material(mat_bn:MaterialButton):
	var cmd:CommandSetMaterial = CommandSetMaterial.new()
	cmd.builder = builder
	cmd.material_path = mat_bn.material_path

	var is_obj_mode:bool = builder.mode == CyclopsLevelBuilder.Mode.OBJECT

	var sel_blocks:Array[CyclopsBlock] = builder.get_selected_blocks()
	for block in sel_blocks:
		if is_obj_mode:
			cmd.add_target(block.get_path(), block.control_mesh.get_face_indices())
		else:
			var face_indices:PackedInt32Array = block.control_mesh.get_face_indices(true)					
			if !face_indices.is_empty():
				cmd.add_target(block.get_path(), face_indices)
	
	if cmd.will_change_anything():
		var undo:EditorUndoRedoManager = builder.get_undo_redo()
		cmd.add_to_undo_manager(undo)
		
		
func is_active_material(path:String):
	return !selected_material_paths.is_empty() && path == selected_material_paths[-1]

func select_material(mat_bn:MaterialButton, sel_type:SelectionList.Type):
	match sel_type:
		SelectionList.Type.REPLACE:
			selected_material_paths = [mat_bn.material_path]
		SelectionList.Type.TOGGLE:
			var idx:int = selected_material_paths.find(mat_bn.material_path)
			if idx >= 0:
				selected_material_paths.remove_at(idx)
			else:
				selected_material_paths.append(mat_bn.material_path)
		SelectionList.Type.RANGE:
			var bn_list = %ButtonArea.get_children()
			var range_from_idx:int = -1
			var range_to_idx:int = -1
			for i in bn_list.size():
				if bn_list[i] == mat_bn:
					range_to_idx = i
				if is_active_material(bn_list[i].material_path):
					range_from_idx = i
			
			for i in range(range_from_idx, range_to_idx + (1 if range_from_idx < range_to_idx else -1), 1 if range_from_idx < range_to_idx else -1):
				var path = bn_list[i].material_path
				if selected_material_paths.has(path):
					selected_material_paths.erase(path)
				selected_material_paths.append(path)

	material_viewer_state.active_material_path = \
		"" if selected_material_paths.is_empty() else selected_material_paths[-1]
		
	#print("set sel mat: ", material_viewer_state.active_material_path)
	#print("sel mat list: ", selected_material_paths)

	for bn in %ButtonArea.get_children():
		var mat_idx:int = selected_material_paths.find(bn.material_path)
		if mat_idx >= 0:
			if mat_idx == selected_material_paths.size() - 1:
				bn.active = true
			else:
				bn.active = false
			
			bn.selected = true
			
		else:
			bn.active = false
			bn.selected = false
		
		
	
#func resource_preview_callback(path:String, preview:Texture2D, userdata:Variant):
	#pass

# Called when the node enters the scene tree for the first time.
func _ready():
	#material_groups = MaterialGroup.new("All")
	#
	#reload_materials()
	
	
	#var root:TreeItem = %Tree.create_item()
	#var child1:TreeItem = %Tree.create_item(root)
	#var child2:TreeItem = %Tree.create_item(root)
	#var subchild1:TreeItem = %Tree.create_item(child1)
	#subchild1.set_text(0, "Subchild1")
	
	pass
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_line_ed_filter_text_changed(new_text):
	reload_materials()


func _on_mat_group_tree_visiblity_changed():
	reload_materials()



func _on_bn_show_unused_dirs_toggled(toggled_on):
	%MatGroupTree.show_unused_dirs = toggled_on
