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
class_name SnappingSystemGridPropertiesEditor

var properties:SnappingSystemGrid:
	get:
		return properties
	set(value):
		#print("setting SnappingSystemGridPropertiesEditor props")
		if value == properties:
			return
		properties = value
		update_ui_from_props()

func set_grid_transform_from_ui():
	var xform:Transform3D = MathUtil.compose_matrix_3d(%xform_translate.value,
		%xform_rotate.value,
		%xform_shear.value,
		%xform_scale.value)
	properties.grid_transform = xform

func update_ui_from_props():
	#print("setting SnappingSystemGridPropertiesEditor props")
	
	if !properties:
		return
	
	%spin_power_of_two.value = properties.power_of_two_scale
	%ed_unit_size.value = properties.unit_size
	%check_use_subdiv.button_pressed = properties.use_subdivisions
	%spin_subdiv.value = properties.grid_subdivisions
	
	var parts:Dictionary = MathUtil.decompose_matrix_3d(properties.grid_transform)
	
	%xform_translate.value = parts.translate
	%xform_rotate.value = parts.rotate
	%xform_shear.value = parts.shear
	%xform_scale.value = parts.scale
	
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_spin_power_of_two_value_changed(value:float):
	if !properties:
		return
		
	properties.power_of_two_scale = value

func _on_ed_unit_size_value_changed(value:float):
	if !properties:
		return
		
	properties.unit_size = value

func _on_check_use_subdiv_toggled(toggled_on:bool):
	if !properties:
		return
		
	properties.use_subdivisions = toggled_on

func _on_spin_subdiv_value_changed(value):
	if !properties:
		return
		
	properties.grid_subdivisions = value

func _on_xform_translate_value_changed(value):
	if !properties:
		return
	
	set_grid_transform_from_ui()

func _on_xform_rotate_value_changed(value):
	if !properties:
		return
	
	set_grid_transform_from_ui()

func _on_xform_scale_value_changed(value):
	if !properties:
		return
	
	set_grid_transform_from_ui()

func _on_xform_shear_value_changed(value):
	if !properties:
		return
	
	set_grid_transform_from_ui()
