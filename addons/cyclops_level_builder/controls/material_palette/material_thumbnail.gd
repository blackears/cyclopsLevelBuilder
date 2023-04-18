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
extends Control
class_name MaterialThumbnail

@export var selected:bool = false

@export_file("*.tres") var material_path:String:
	get:
		return material_path
	set(value):
		if material_path == value:
			return
			
		material_path = value
		#$VBoxContainer/MaterialName.text = material_path
#		print("setting material path %s" % material_path)
		
		if ResourceLoader.exists(material_path):
			var res:Resource = load(material_path)
			#print("loaded res %s" % res)

			if res is Material:
				tracked_material = res
			else:
				tracked_material = null
		else:
			tracked_material = null

		material_thumbnail_dirty = true

@export var group:ThumbnailGroup:
	get:
		return group
	set(value):
		if group == value:
			return
		
		if group != null:
			group.remove_thumbnail(self)
		
		group = value
		
		if group != null:
			group.add_thumbnail(self)
			

@export var theme_normal:Theme
@export var theme_selected:Theme

var builder:CyclopsLevelBuilder

var tracked_material:Material
var material_thumbnail_dirty:bool = true

var snapper:MaterialShapshot

# Called when the node enters the scene tree for the first time.
func _ready():
	snapper = preload("res://addons/cyclops_level_builder/controls/material_palette/material_snapshot.tscn").instantiate()
	add_child(snapper)
	
#	var view_tex:ViewportTexture = ViewportTexture.new()
#	view_tex.viewport_path = get_node("SubViewport").get_path()
#	$VBoxContainer/TextureRect.texture = view_tex
	
	pass # Replace with function body.

#func snapshot_material():
#	var viewport:SubViewport = SubViewport.new()
#	viewport.size = Vector2i(64, 64)
#	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if selected:
		theme = theme_selected
	else:
		theme = theme_normal
	
#	var mesh:MeshInstance3D = get_node("SubViewport/Node3D/MeshInstance3D")
#	mesh.material_override = tracked_material
	if material_thumbnail_dirty:
		print("updating thumbnail")
		material_thumbnail_dirty = false
#		var snapper:MaterialShapshot = preload("res://addons/cyclops_level_builder/controls/material_palette/material_snapshot.tscn").instantiate()
		#snapper.target_material = tracked_material
		#var mi:MeshInstance3D = snapper.get_node("Node3D/MeshInstance3D")
#		mi.material_override = tracked_material

		#var res:Resource = load(material_path)
		#print("loaded res %s" % res)

		snapper.target_material = tracked_material

		var tex:ImageTexture = await snapper.take_snapshot()
		print("tex %s" % tex)
		$VBoxContainer/TextureRect.texture = tex
	
		if tracked_material:
			var name:String = tracked_material.resource_name
			if name.is_empty():
				name = material_path.get_file()
				var idx:int = name.rfind(".")
				if idx != -1:
					name = name.substr(0, idx)
			$VBoxContainer/MaterialName.text = name
		else:
			$VBoxContainer/MaterialName.text = ""

		print("thumbnail update done")
		
#	if tracked_material is StandardMaterial3D:
#		var std:StandardMaterial3D = tracked_material
#		$VBoxContainer/TextureRect.texture = std.albedo_texture
#	else:
#		$VBoxContainer/TextureRect.texture = null
	
func _gui_input(event:InputEvent):
#	if event.is_action("ui_select"):
#		if event.
	if event is InputEventMouseButton:
		var e:InputEventMouseButton = event
		if e.pressed:
			if e.double_click:
				apply_material_to_selected()
			else:

				if group:
					group.select_thumbnail(self)
				else:
					selected = true
					
				builder.tool_material_path = material_path
				
				get_viewport().set_input_as_handled()


func apply_material_to_selected():
	var cmd:CommandSetMaterial = CommandSetMaterial.new()
	cmd.builder = builder
	cmd.material_path = material_path
	
	var root_blocks:CyclopsBlocks = builder.active_node
	for child in root_blocks.get_children():
#		print("child block %s %s" % [child.name, child.get_class()])
#		if child.has_method("append_mesh_wire"):
		if child is CyclopsConvexBlock:
		#if !(child is MeshInstance3D):
#			print("setting child block %s" % child.name)
			if child.selected:
				cmd.add_target(child.get_path(), child.control_mesh.get_face_ids())
			else:
				var face_ids:PackedInt32Array = child.control_mesh.get_face_ids(true)
				if !face_ids.is_empty():
					cmd.add_target(child.get_path(), face_ids)
	
	var undo:EditorUndoRedoManager = builder.get_undo_redo()
	cmd.add_to_undo_manager(undo)


func _on_focus_entered():
	pass # Replace with function body.


func _on_focus_exited():
	pass # Replace with function body.


func _on_tree_exiting():
	if group != null:
		group.remove_thumbnail(self)
