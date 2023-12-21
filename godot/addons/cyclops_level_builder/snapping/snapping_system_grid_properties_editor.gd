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

var tool:SnappingSystemGrid:
	get:
		return tool
	set(value):
		#print("setting SnappingSystemGridPropertiesEditor props")
		if value == tool:
			return
		tool = value
		update_ui_from_props()

func update_ui_from_props():
	#print("setting SnappingSystemGridPropertiesEditor props")
	
	if !tool:
		return
	
	var properties:SnapToGridUtil = tool.snap_to_grid_util
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
	if !tool:
		return
		
	tool.snap_to_grid_util.power_of_two_scale = value
	CyclopsAutoload.settings.set_property(CyclopsGlobalScene.SNAPPING_GRID_POWER_OF_TWO_SCALE, int(value))
	CyclopsAutoload.save_settings()

func _on_ed_unit_size_value_changed(value:float):
	if !tool:
		return
		
	tool.snap_to_grid_util.unit_size = value
	CyclopsAutoload.settings.set_property(CyclopsGlobalScene.SNAPPING_GRID_UNIT_SIZE, value)
	CyclopsAutoload.save_settings()

func _on_check_use_subdiv_toggled(toggled_on:bool):
	if !tool:
		return
		
	tool.snap_to_grid_util.use_subdivisions = toggled_on
	CyclopsAutoload.settings.set_property(CyclopsGlobalScene.SNAPPING_GRID_USE_SUBDIVISIONS, toggled_on)
	CyclopsAutoload.save_settings()

func _on_spin_subdiv_value_changed(value):
	if !tool:
		return
		
	tool.snap_to_grid_util.grid_subdivisions = value
	CyclopsAutoload.settings.set_property(CyclopsGlobalScene.SNAPPING_GRID_SUBDIVISIONS, int(value))
	CyclopsAutoload.save_settings()

func _on_xform_translate_value_changed(value):
	if !tool:
		return
	
	set_grid_transform_from_ui()

func _on_xform_rotate_value_changed(value):
	if !tool:
		return
	
	set_grid_transform_from_ui()

func _on_xform_scale_value_changed(value):
	if !tool:
		return
	
	set_grid_transform_from_ui()

func _on_xform_shear_value_changed(value):
	if !tool:
		return
	
	set_grid_transform_from_ui()

func set_grid_transform_from_ui():
	var xform:Transform3D = MathUtil.compose_matrix_3d(%xform_translate.value,
		%xform_rotate.value,
		EULER_ORDER_YXZ,
		%xform_shear.value,
		%xform_scale.value)
	tool.snap_to_grid_util.grid_transform = xform
	
	CyclopsAutoload.save_settings()

const meters_per_yard:float = 0.9144
const meters_per_feet:float = 0.3048

func _on_popup_presets_index_pressed(index):
	#print("Preset ", index)
	var unit_size:float
	var subdiv:int
	match index:
		0:
			unit_size = 1
			subdiv = 10
		1:
			unit_size = meters_per_yard
			subdiv = 3
		2:
			unit_size = meters_per_feet
			subdiv = 12
		_:
			return

	%ed_unit_size.value = unit_size
	%spin_subdiv.value = subdiv
			
	tool.snap_to_grid_util.unit_size = unit_size
	CyclopsAutoload.settings.set_property(CyclopsGlobalScene.SNAPPING_GRID_UNIT_SIZE, unit_size)

	tool.snap_to_grid_util.grid_subdivisions = subdiv
	CyclopsAutoload.settings.set_property(CyclopsGlobalScene.SNAPPING_GRID_SUBDIVISIONS, int(subdiv))

	CyclopsAutoload.save_settings()


func _on_bn_presets_pressed():
	var rect:Rect2 = %bn_presets.get_global_rect()
	%popup_presets.popup_on_parent(Rect2i(rect.position.x, rect.position.y + rect.size.y, 0, 0))


func _on_bn_presets_transform_pressed():
	var rect:Rect2 = %bn_presets_transform.get_global_rect()
	%popup_transform_presets.popup_on_parent(Rect2i(rect.position.x, rect.position.y + rect.size.y, 0, 0))


func _on_popup_transform_presets_index_pressed(index):
	var xform:Transform3D
	match index:
		0:
			xform = Transform3D.IDENTITY
		1:
			var x:Vector3 = Vector3(1, 0, 0)
			var y:Vector3 = Vector3(0, 1, 0)
			var angle:float = deg_to_rad(60)
			
			var z:Vector3 = Vector3(cos(angle), 0, sin(angle))
			xform = Transform3D(Basis(x, y, z), Vector3.ZERO)
		_:
			return

			
	tool.snap_to_grid_util.grid_transform = xform
	CyclopsAutoload.settings.set_property(CyclopsGlobalScene.SNAPPING_GRID_TRANSFORM, xform)

	CyclopsAutoload.save_settings()
	update_ui_from_props()
