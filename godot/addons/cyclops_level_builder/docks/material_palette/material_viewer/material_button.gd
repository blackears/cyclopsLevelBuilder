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

@export var selected:bool = false
@export var active:bool = false

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
			
@export var theme_normal:Theme
@export var theme_selected:Theme
@export var theme_active:Theme

var plugin:CyclopsLevelBuilder:
	get:
		return plugin
	set(value):
		if value == plugin:
			return
		
		plugin = value
		
		dirty = true

var dirty:bool = true

func rebuild_thumbnail():
	if !plugin:
		return
	
	var rp:EditorResourcePreview = plugin.get_editor_interface().get_resource_previewer()
	rp.queue_resource_preview(material_path, self, "resource_preview_callback", null)
	
#	var res:Resource = ResourceLoader.load(material_path)
	var res:Resource = load(material_path)
	#print("loading ", material_path)
	#print("res ", res)
	#print("Set bn name ", GeneralUtil.calc_resource_name(res))
	%MaterialName.text = GeneralUtil.calc_resource_name(res)
	%MaterialName.tooltip_text = material_path

func resource_preview_callback(path:String, preview:Texture2D, thumbnail_preview:Texture2D, userdata:Variant):
	#print("Set bn tex ", path)
	%TextureRect.texture = preview
	
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if dirty:
		rebuild_thumbnail()
		dirty = false
	pass
