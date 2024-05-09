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
class_name ExporterCyclopsWizard

#var _text_path:LineEdit
#var default_material:Material = preload("res://addons/cyclops_level_builder/materials/grid.tres")

var file_dialog:FileDialog
var save_path:String

var plugin:CyclopsLevelBuilder
#
#class ItemIndexer extends RefCounted:
	#var dict:Dictionary
	#
	#func get_or_create_id(node:Variant)->int:
		#if dict.has(node):
			#return dict[node]
		#
		#var id:int = dict.size()
		#dict[node] = id
		#return id

#class CyclopsFileBuilder extends RefCounted:
	#var plugin:CyclopsLevelBuilder
	#var buffer_archive:BufferArchive = BufferArchive.new()
	#
	##var doc:XMLDocument
	##var root_ele:XMLElement
	##var scenes_ele:XMLElement
	##var nodes_ele:XMLElement
	##var meshes_ele:XMLElement
	#
	#var document:Dictionary
	##var scenes_group:Dictionary
	##var nodes_group:Dictionary
	##var meshes_group:Dictionary
	##var mesh_id_map:Dictionary
	#var node_indexer:ItemIndexer = ItemIndexer.new()
	#var mesh_indexer:ItemIndexer = ItemIndexer.new()
	#
	#
	#func _init(plugin:CyclopsLevelBuilder):
		#self.plugin = plugin
#
	#func create_json():
#
		#var root:Node = plugin.get_editor_interface().get_edited_scene_root()
#
		#document = {
			#"header": [],
			#"scenes": [],
			#"nodes": [],
			#"meshes": [],
			#"buffers": []
		#}
		#
		#document.header["exporter"] = "Cyclops Level Builder " + plugin.get_plugin_version()
		#document.header["version"] = "1.0.0"
#
		#var build_scene:Dictionary
		#build_scene["root"] = root.name
		#document.scenes.append(build_scene)
#
		#export_scene_recursive(root)
		#
		#document.buffers.append(buffer_archive.to_dictionary())
		#
#
	#func export_scene_recursive(cur_node:Node3D):
		#if cur_node is Node3D:
			#
			#var build_node:Dictionary
			#build_node["id"] = node_indexer.get_or_create_id(cur_node)
			#build_node["name"] = cur_node.name
			#document.nodes.append(build_node)
#
			#if !cur_node.position.is_equal_approx(Vector3.ZERO):
				#cur_node.set_attribute("translate", [cur_node.position.x, cur_node.position.y, cur_node.position.z])
			#if !cur_node.transform.basis.is_equal_approx(Basis.IDENTITY):
				#cur_node.set_attribute("basis", [
					#cur_node.basis.x.x, cur_node.basis.x.y, cur_node.basis.x.z,
					#cur_node.basis.y.x, cur_node.basis.y.y, cur_node.basis.y.z,
					#cur_node.basis.z.x, cur_node.basis.z.y, cur_node.basis.z.z
					#])
#
			#var child_ids:Array[int]
			#for local_child in cur_node.children:
				#if local_child is Node3D:
					#child_ids.append(node_indexer.get_or_create_id(local_child))
			#if !child_ids.is_empty():
				#build_node["children"] = child_ids
#
		#
			#for local_child in cur_node.children:
				#if local_child is Node3D:
					#export_scene_recursive(local_child)
			#
			#if cur_node is CyclopsBlock:
				#var mesh_id:int = mesh_indexer.get_or_create_id(cur_node)
					#
				#build_node["mesh"] = mesh_id
				#export_mesh_node(cur_node)
				#pass
				#
	#func export_mesh_node(cur_node:CyclopsBlock):
		#var build_mesh:Dictionary
		#document.meshes.append(build_mesh)
		#
		#build_mesh["id"] = mesh_indexer.get_or_create_id(cur_node)
		#
		#build_mesh["collision_type"] = Collision.Type.values()[cur_node.collision_type]
		#build_mesh["collision_layer"] = cur_node.collision_layer
		#build_mesh["collision_mask"] = cur_node.collision_mask
		#
		#var mat_res_paths:PackedStringArray
		#for mat in cur_node.materials:
			#if mat:
				#mat_res_paths.append(mat.resource_path)
			#else:
				#mat_res_paths.append("")
		#build_mesh["materials"] = mat_res_paths
		#
		#
		#
		#build_mesh["mesh"] = cur_node.mesh_vector_data.to_dictionary(buffer_archive)
		#
		#pass

# Called when the node enters the scene tree for the first time.
func _ready():
	file_dialog = FileDialog.new()
	add_child(file_dialog)
	file_dialog.size = Vector2(600, 400)
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.set_access(FileDialog.ACCESS_RESOURCES)
	file_dialog.title = "Save file..."
	file_dialog.filters = PackedStringArray(["*.cyclops; Cyclops files"])
	file_dialog.current_file = save_path
	file_dialog.file_selected.connect(on_save_file)

	%lineEdit_path.text = save_path
	#_text_path = %lineEdit_path
	#_text_path.text = save_path


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func on_save_file(path:String):
	save_path = path
	%lineEdit_path.text = path

func _on_bn_browse_pressed():
	file_dialog.popup_centered()


func _on_bn_cancel_pressed():
	hide()


func _on_close_requested():
	hide()


func _on_bn_okay_pressed():
	var path:String = save_path
	if !save_path.to_lower().ends_with(".cyclops"):
		path = save_path + ".cyclops"

	var json_builder:CyclopsFileBuilder = CyclopsFileBuilder.new(plugin)

	var text = JSON.stringify(json_builder.document, "    ")

	var file:FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)

	hide()
