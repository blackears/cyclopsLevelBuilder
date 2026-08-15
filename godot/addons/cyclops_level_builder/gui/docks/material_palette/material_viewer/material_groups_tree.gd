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

signal visiblity_changed

enum ButtonType { VISIBLE }

const bn_vis_off = preload("res://addons/cyclops_level_builder/art/icons/eye_closed.svg")
const bn_vis_on = preload("res://addons/cyclops_level_builder/art/icons/eye_open.svg")

const column_visible:int = 0

@onready var create_material_dialog:CreateMaterialDialog = %CreateMaterialDialog

@export var show_unused_dirs:bool = true:
	get:
		return show_unused_dirs
	set(value):
		if value == show_unused_dirs:
			return
		show_unused_dirs = value
		
		reload_materials()

class PathInfo:
	var visible:bool
	var collapsed:bool
	var tree_item:TreeItem


var tree_item_to_path_map:Dictionary[TreeItem, String]
var path_to_path_info:Dictionary[String, PathInfo]


func reload_materials():
	#print("reload_materials")
	clear()
	tree_item_to_path_map.clear()

	var efs:EditorFileSystem = EditorInterface.get_resource_filesystem()
	var root_dir:EditorFileSystemDirectory = efs.get_filesystem()
	
	var path = root_dir.get_path()
	var path_info:PathInfo
	if path_to_path_info.has(path):
		path_info = path_to_path_info[path]
	else:
		path_info = PathInfo.new()
		path_info.collapsed = false
		path_info.visible = true
		path_to_path_info[path] = path_info
	
	var root_tree_item:TreeItem = create_item()
	root_tree_item.set_text(0, root_dir.get_name())
	root_tree_item.add_button(column_visible, bn_vis_on if path_info.visible else bn_vis_off, ButtonType.VISIBLE, false, "Visible")
	root_tree_item.set_checked(column_visible, path_info.visible)
	root_tree_item.collapsed = path_info.collapsed
	
	path_info.tree_item = root_tree_item
	
	tree_item_to_path_map[root_tree_item] = path
	
	build_tree_recursive(root_dir, root_tree_item)
	
	#collapse_unused_dirs()


func build_tree_recursive(parent_dir:EditorFileSystemDirectory, tree_item_parent:TreeItem):
	#print("par_dir count ", parent_dir.get_path(), parent_dir.get_subdir_count())

	for i in parent_dir.get_subdir_count():
		var child_dir:EditorFileSystemDirectory = parent_dir.get_subdir(i)
		#print("add child ", child_dir.get_path())

		if !show_unused_dirs && !dir_has_materials_recursive(child_dir):
			continue

		var path = child_dir.get_path()
		var path_info:PathInfo
		if path_to_path_info.has(path):
			path_info = path_to_path_info[path]
		else:
			path_info = PathInfo.new()
			path_info.collapsed = false
			path_info.visible = true
			path_to_path_info[path] = path_info

		#print("build_tree_recursive ", path, " ", path_info.collapsed)

		var item:TreeItem = create_item(tree_item_parent)
		item.set_text(0, child_dir.get_name())
		item.add_button(column_visible, bn_vis_on if path_info.visible else bn_vis_off, ButtonType.VISIBLE, false, "Visible")
		item.set_checked(column_visible, path_info.visible)
		item.collapsed = path_info.collapsed

		path_info.tree_item = item

		tree_item_to_path_map[item] = path
		#print("path ", child_dir.get_path())
		
		build_tree_recursive(child_dir, item)
		
	
func on_filesystem_changed():
	reload_materials()
	pass

func on_resources_reimported(resources: PackedStringArray):
	pass

func on_resources_reload(resources: PackedStringArray):
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	set_column_expand(0, true)
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



func _on_popup_menu_id_pressed(id:int):
	match id:
		0:
			create_new_group()
		1:
			delete_selected_group()
		2:
			rename_selected_group()


func _on_button_clicked(item:TreeItem, column:int, id:int, mouse_button_index:int):
	var checked:bool = !item.is_checked(column_visible)
	item.set_checked(column_visible, checked)
	item.set_button(column_visible, ButtonType.VISIBLE, bn_vis_on if checked else bn_vis_off)
	
	var path:String = tree_item_to_path_map[item]
	path_to_path_info[path].visible = checked
	
	visiblity_changed.emit()

func _on_item_collapsed(item: TreeItem) -> void:
	if !tree_item_to_path_map.has(item):
		return
	var path:String = tree_item_to_path_map[item]
	path_to_path_info[path].collapsed = item.collapsed
	
	#print("_on_item_collapsed ", path, " ", path_to_path_info[path].collapsed)
	
	
func is_path_visible(path:String)->bool:
	if path_to_path_info.has(path):
		return path_to_path_info[path].visible
		
	return false
	

func dir_has_materials(dir:EditorFileSystemDirectory)->bool:
	for i in dir.get_file_count():
		var file_type:StringName = dir.get_file_type(i)
		
		if file_type == "StandardMaterial3D" || file_type == "ORMMaterial3D" || file_type == "ShaderMaterial":
			return true
	
	return false
	
func dir_has_materials_recursive(dir:EditorFileSystemDirectory)->bool:
	if dir_has_materials(dir):
		return true
	
	for i in dir.get_subdir_count():
		var child_dir:EditorFileSystemDirectory = dir.get_subdir(i)
		if dir_has_materials_recursive(child_dir):
			return true
	
	return false

func collapse_unused_dirs():

	var efs:EditorFileSystem = EditorInterface.get_resource_filesystem()

	var root_dir:EditorFileSystemDirectory = efs.get_filesystem()
	collapse_unused_dirs_recursive(root_dir)


func collapse_unused_dirs_recursive(dir:EditorFileSystemDirectory)->bool:
	#print("path ", dir.get_path())
	var path:String = dir.get_path()
	if !path_to_path_info.has(path):
		return false
		
	var item:TreeItem = path_to_path_info[path].tree_item
	#print("item ", item.get_text(0))
	var expanded:bool = dir_has_materials(dir)

	for i in dir.get_subdir_count():
		var child_dir:EditorFileSystemDirectory = dir.get_subdir(i)
		var result:bool = collapse_unused_dirs_recursive(child_dir)
		if result:
			expanded = true
			
	item.collapsed = !expanded
	
	return expanded

func _can_drop_data(at_position:Vector2, data:Variant):
#	print("_can_drop_data %s" % data)
	return typeof(data) == TYPE_DICTIONARY and data.has("type") and data["type"] == "files"


func _drop_data(at_position:Vector2, data:Variant):
	var item:TreeItem = get_item_at_position(at_position)
	if !item:
		return
	
	var files = data["files"]
	#print("--drop")
	var texture_list:Array[Texture2D]
	for f in files:
#		print("Dropping %s" % f)
		var res:Resource = load(f)
		if res is Texture2D:
			#print("Dropping %s" % res.resource_path)

			texture_list.append(res)

	if texture_list.is_empty():
		return
	
	var parent_dir_path:String = tree_item_to_path_map[item]
	
	create_material_dialog.parent_dir_path = parent_dir_path
	create_material_dialog.texture_list = texture_list
	create_material_dialog.popup_centered()
	

func _on_create_material_dialog_create_material(params:Dictionary):
	#Prepare texture
	var target_texture:Texture2D

	var tex_list:Array = params["textures"]
	if tex_list.size() == 1:
		target_texture = tex_list[0]
	elif tex_list.size() > 1:
		var anim_tex:AnimatedTexture = AnimatedTexture.new()
		anim_tex.frames = tex_list.size()
		for i in tex_list.size():
			anim_tex.set_frame_texture(i, tex_list[i])
		
		target_texture = anim_tex
	
	#Create material
	if params["material_type"] == "standard":
		var new_mat:StandardMaterial3D = StandardMaterial3D.new()
		new_mat.albedo_texture = target_texture
		
		if params["uv_type"] == "pix_per_game_unit":
			var ppgu:int = params["pix_per_game_unit"]
			new_mat.uv1_scale = Vector3(tex_list[0].get_width() / ppgu, tex_list[0].get_height() / ppgu, 1)
		
		ResourceSaver.save(new_mat, params["parent_dir"] + "/" + params["name"] + ".tres")

	elif params["material_type"] == "shader":
		var new_mat:ShaderMaterial = ShaderMaterial.new()
		new_mat.shader = ResourceLoader.load(params["shader_res_path"], "Shader")
		
		#print("tex param ", params["texture_parameter"])
		new_mat.set_shader_parameter(params["texture_parameter"], target_texture)

		if params["uv_type"] == "pix_per_game_unit":
			var ppgu:float = params["pix_per_game_unit"]
			new_mat.set_shader_parameter(params["uv_parameter"], Vector3(tex_list[0].get_width() / ppgu, tex_list[0].get_height() / ppgu, 1))
		
		ResourceSaver.save(new_mat, params["parent_dir"] + "/" + params["name"] + ".tres")
		

func load_state(state:Dictionary):
	if state.has("paths"):
		var path_arr:Array[Dictionary] = state["paths"]
		
		for path_tuple:Dictionary in path_arr:
			var fs_path:String = path_tuple.get("path")
			
			var path_info:PathInfo
			if path_to_path_info.has(fs_path):
				path_info = path_to_path_info[fs_path]
			else:
				path_info = PathInfo.new()
				path_to_path_info[fs_path] = path_info
			
			path_info.visible = path_tuple.get("visible", true)
			path_info.collapsed = path_tuple.get("collapsed", false)

	reload_materials()

func save_state(state:Dictionary):
	var path_arr:Array[Dictionary]

	for fs_path:String in path_to_path_info:
		var path_info:PathInfo = path_to_path_info[fs_path]
		path_arr.append({"path": fs_path, "visible": path_info.visible, "collapsed": path_info.collapsed})
	
	state["paths"] = path_arr
	


func _on_tree_entered() -> void:
	var efs:EditorFileSystem = EditorInterface.get_resource_filesystem()
	efs.filesystem_changed.connect(on_filesystem_changed)
	efs.resources_reimported.connect(on_resources_reimported)
	efs.resources_reload.connect(on_resources_reload)


func _on_tree_exiting() -> void:
	var efs:EditorFileSystem = EditorInterface.get_resource_filesystem()
	efs.filesystem_changed.disconnect(on_filesystem_changed)
	efs.resources_reimported.disconnect(on_resources_reimported)
	efs.resources_reload.disconnect(on_resources_reload)
