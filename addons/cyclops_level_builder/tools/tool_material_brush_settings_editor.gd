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
class_name ToolMaterialBrushSettingsEditor

@export var settings:ToolMaterialBrushSettings:
	get:
		return settings
	set(value):
		settings = value
		update()

func update():
	if !settings:
		%check_paint_material.disabled = true
		%check_individual_faces.disabled = true
		%check_erase_material.disabled = true

		%check_paint_color.disabled = true
		%color_button.disabled = true

		%check_paint_visibility.disabled = true
		%check_visibility.disabled = true
		
		return
		
	%check_paint_material.disabled = false
	%check_paint_color.disabled = false
	%check_paint_visibility.disabled = false
	%check_individual_faces.disabled = false

	%check_individual_faces.button_pressed = settings.individual_faces
	
	%check_paint_material.button_pressed = settings.paint_materials
	%check_erase_material.button_pressed = settings.erase_material
	%check_erase_material.disabled = !settings.paint_materials

	%check_paint_color.button_pressed = settings.paint_color
	%color_button.color = settings.color
	%color_button.disabled = !settings.paint_color
	
	%check_paint_visibility.button_pressed = settings.paint_visibility
	%check_visibility.button_pressed = settings.visibility
	%check_visibility.disabled = !settings.paint_visibility
	
	

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_check_paint_material_toggled(button_pressed:bool):
	settings.paint_materials = button_pressed
	%check_erase_material.disabled = !settings.paint_materials


func _on_check_individual_faces_toggled(button_pressed:bool):
	settings.individual_faces = button_pressed


func _on_check_erase_material_toggled(button_pressed:bool):
	settings.erase_material = button_pressed


func _on_check_paint_color_toggled(button_pressed:bool):
	settings.paint_color = button_pressed
	%color_button.disabled = !settings.paint_color


func _on_color_button_color_changed(color:Color):
	settings.color = color


func _on_check_paint_visibility_toggled(button_pressed:bool):
	settings.paint_visibility = button_pressed
	%check_visibility.disabled = !settings.paint_visibility


func _on_check_visibility_toggled(button_pressed:bool):
	settings.visibility = button_pressed

