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
class_name MaterialButton

signal apply_material(mat_bn:MaterialButton)
signal select_material(mat_bn:MaterialButton, selection_type:SelectionList.Type)

@export var selected:bool = false:
	get:
		return selected
	set(value):
		if selected == value:
			return
		selected = value
		update_border()
	
@export var active:bool = false:
	get:
		return active
	set(value):
		if active == value:
			return
		active = value
		update_border()

@export_file("*.tres") var material_path:String:
	get:
		return material_path
	set(value):
		if material_path == value:
			return
		
		material_path = value
		
		dirty = true


@export var group:RadioButtonGroup:
	get:
		return group
	set(value):
		if group == value:
			return
		
		if group != null:
			group.remove_button(self)
		
		group = value
		
		if group != null:
			group.add_button(self)
			
@export var theme_normal:Theme = preload("res://addons/cyclops_level_builder/docks/material_palette/material_viewer/mat_bn_normal_theme.tres")
@export var theme_selected:Theme = preload("res://addons/cyclops_level_builder/docks/material_palette/material_viewer/mat_bn_selected_theme.tres")
@export var theme_active:Theme = preload("res://addons/cyclops_level_builder/docks/material_palette/material_viewer/mat_bn_active_theme.tres")

var plugin:CyclopsLevelBuilder:
	get:
		return plugin
	set(value):
		if value == plugin:
			return
		
		plugin = value
		
		dirty = true

var dirty:bool = true

var material_local:Material

func rebuild_thumbnail():
	if !plugin:
		return
	
	var rp:EditorResourcePreview = plugin.get_editor_interface().get_resource_previewer()
	rp.queue_resource_preview(material_path, self, "resource_preview_callback", null)
	
	material_local = ResourceLoader.load(material_path, "Material")
#	material_local = load(material_path)
	%MaterialName.text = GeneralUtil.calc_resource_name(material_local)
	tooltip_text = material_path

func resource_preview_callback(path:String, preview:Texture2D, thumbnail_preview:Texture2D, userdata:Variant):
	#print("Set bn tex ", path)
	%TextureRect.texture = preview


func _gui_input(event:InputEvent):
	if event is InputEventMouseButton:
		var e:InputEventMouseButton = event
	
		if e.button_index == MOUSE_BUTTON_LEFT:
		
			if e.pressed:
				if e.double_click:
					#apply_material_to_selected()
					apply_material.emit(self)
				else:
					#if group:
						#group.select_thumbnail(self)
					#else:
						#selected = true
						
	#				builder.tool_material_path = material_path
					
					select_material.emit(self, SelectionList.choose_type(e.shift_pressed, e.ctrl_pressed))
					
			get_viewport().set_input_as_handled()

func update_border():
	if active:
		theme = theme_active
	elif selected:
		theme = theme_selected
	else:
		theme = theme_normal

	
# Called when the node enters the scene tree for the first time.
func _ready():
	update_border()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if dirty:
		rebuild_thumbnail()
		dirty = false
	pass
