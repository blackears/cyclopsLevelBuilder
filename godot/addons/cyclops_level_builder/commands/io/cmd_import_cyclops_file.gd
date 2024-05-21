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
class_name CommandImportCyclopsFile
extends CyclopsCommand

@export var file_path:String
@export var target_parent:NodePath

var added_blocks:Array[NodePath]

func _init():
	command_name = "Import Cyclops File"

func will_change_anything()->bool:
	return FileAccess.file_exists(file_path)
	
func do_it():
	if !FileAccess.file_exists(file_path):
		push_error("No such file: ", file_path)
		return
	
	var source:String = FileAccess.get_file_as_string(file_path)
	var raw = JSON.parse_string(source)
	if !(raw is Dictionary):
		push_error("Invalid file format: ", file_path)
		return

	load_file(raw)
	
	pass
	

func load_file(root:Dictionary):
	var loader:CyclopsFileLoader = CyclopsFileLoader.new()
	loader.load(root)
	
	var editor_scene_root:Node = builder.get_editor_interface().get_edited_scene_root()
	
	
	for scene_id in loader.scene_map.keys():
		var root_node_id:int = loader.scene_map[scene_id]
		var loaded_scene:Node3D = loader.node_map[root_node_id]
		
		editor_scene_root.add_child(loaded_scene)
		set_owner_recursive(loaded_scene, editor_scene_root)
		
		added_blocks.append(loaded_scene.get_path())
		

func undo_it():
	for block_path in added_blocks:
		var block:Node3D = builder.get_node(block_path)
		block.queue_free()

	added_blocks.clear()
	
func set_owner_recursive(loaded_node:Node3D, owner_node:Node3D):
	loaded_node.owner = owner_node
	if loaded_node is CyclopsBlock:
		#Do not set owner of hidden children
		return
	
	for child in loaded_node.get_children():
		set_owner_recursive(child, owner_node)
		
