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
class_name ExporterGodotSceneWizard

#var _text_path:LineEdit
var default_material:Material = preload("res://addons/cyclops_level_builder/materials/grid.tres")

var file_dialog:FileDialog
var save_path:String

var plugin:CyclopsLevelBuilder

# Called when the node enters the scene tree for the first time.
func _ready():
	file_dialog = FileDialog.new()
	add_child(file_dialog)
	file_dialog.size = Vector2(600, 400)
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.set_access(FileDialog.ACCESS_RESOURCES)
	file_dialog.title = "Export scene..."
	file_dialog.filters = PackedStringArray(["*.tscn; tscn files"])
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
	if !save_path.to_lower().ends_with(".tscn") && !save_path.to_lower().ends_with(".tscn"):
		path = save_path + ".tscn"

	var root:Node = plugin.get_editor_interface().get_edited_scene_root()
	#var dup_node:Node = copy_scene_recursive(root)
	var dup_node:Node = root.duplicate()
	await get_tree().process_frame

	replace_blocks_recursive(dup_node, dup_node)
	#dup_node.name = "aaaaaaa"

	var dup_scene:PackedScene = PackedScene.new()
	dup_scene.pack(dup_node)
	ResourceSaver.save(dup_scene, path)

	hide()

func replace_blocks_recursive(node:Node, root:Node):
	
	for child in node.get_children():		
		#print("child.name ", child.name)

		if child is CyclopsBlock:
			var child_block:CyclopsBlock = child
			
			var new_child:Node3D = Node3D.new()
			child.add_sibling(new_child)
			new_child.owner = root
			new_child.transform = child_block.transform
			new_child.set_display_folded(true)
			
			#Mesh
			var vol:ConvexVolume = ConvexVolume.new()
			vol.init_from_mesh_vector_data(child_block.mesh_vector_data)

			var mesh:ArrayMesh = vol.create_mesh(child_block.materials, default_material)
			
			var mesh_instance:MeshInstance3D = MeshInstance3D.new()
			new_child.add_child(mesh_instance)
			mesh_instance.owner = root
			mesh_instance.mesh = mesh
			mesh_instance.name = "mesh_instance"
			
			#Collision
			var collision_body:PhysicsBody3D

			match child_block.collision_type:
				Collision.Type.STATIC:
					collision_body = StaticBody3D.new()
				Collision.Type.KINEMATIC:
					collision_body = CharacterBody3D.new()
				Collision.Type.RIGID:
					collision_body = RigidBody3D.new()
					
			if collision_body:
				collision_body.collision_layer = child_block.collision_layer
				collision_body.collision_mask = child_block.collision_mask
				new_child.add_child(collision_body)
				collision_body.owner = root
				collision_body.name = "collision_body"
				
				var collision_shape:CollisionShape3D = CollisionShape3D.new()
				collision_body.add_child(collision_shape)
				collision_shape.owner = root
				
				var shape:ConvexPolygonShape3D = ConvexPolygonShape3D.new()
				shape.points = vol.get_points()
				collision_shape.shape = shape
				collision_shape.name = "collision_shape"
				
			var child_name:String = child.name
			node.remove_child(child)
			child.queue_free()
			new_child.name = child_name
		
		else:
			replace_blocks_recursive(child, root)
		
	
	
