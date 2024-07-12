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
class_name CreateMaterialDialog

signal create_material(params:Dictionary)

var texture_list:Array[Texture2D]
var parent_dir_path:String

var plugin:CyclopsLevelBuilder:
	get:
		return plugin
	set(value):
		if value == plugin:
			return
			
		plugin = value
		#print("CreateMaterialDialog setting plugin")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_bn_okay_pressed():
	var mat_type:String = "standard" if %radio_stdMat.is_pressed() else "shader"
	var tgt_param:String = "albedo_texture"
	
	
	create_material.emit({
		"name": %line_material_name.text,
		"material_type" : mat_type,
		"shader_res_path" : %line_shader_path.text,
		"texture_parameter" : %target_slot.get_item_text(%target_slot.selected),
		"uv_parameter" : %uv_slot.get_item_text(%uv_slot.selected),
		"uv_type" : "1x1" if %radio_uv_1x1.is_pressed() else "pix_per_game_unit",
		"pix_per_game_unit" : %line_pix_per_game_unit.text.to_int(),
		"parent_dir" : parent_dir_path,
		"textures" : texture_list
		#material_type: ""
	})
	
	hide()


func _on_bn_cancel_pressed():
	hide()


func _on_bn_browse_shader_pressed():
	%FileDialog.popup_centered()


func _on_about_to_popup():
	#print("CreateMaterialDialog about to popup")
	
	var ed_iface:EditorInterface = plugin.get_editor_interface()
	var efs:EditorFileSystem = ed_iface.get_resource_filesystem()

	var root_dir:EditorFileSystemDirectory = efs.get_filesystem()
	
	if !texture_list.is_empty():
		%line_material_name.text = texture_list[0].resource_path.get_file().get_basename()


func _on_file_dialog_file_selected(path:String):
	var shader:Shader = ResourceLoader.load(path, "Shader")
	if !shader:
		return
	
	%line_shader_path.text = path
	update_shader_slot_list()
	
func update_shader_slot_list():
	var path:String = %line_shader_path.text
	var shader:Shader = ResourceLoader.load(path, "Shader")
	%target_slot.clear()
	%uv_slot.clear()
	
	#TYPE_VECTOR2
	if shader:
		#Array of dictionaries
		var params:Array = shader.get_shader_uniform_list()
		
		for p in params:
			#print("shader param ", str(p))
			if p["hint_string"] == "Texture2D":
				%target_slot.add_item(p["name"])
			if p["type"] == TYPE_VECTOR2 || p["type"] == TYPE_VECTOR3:
				%uv_slot.add_item(p["name"])
	
	


func _on_line_shader_path_text_changed(new_text):
	update_shader_slot_list()
