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
class_name ToolVertexColorBrushSettingsEditor

@export var settings:ToolVertexColorBrushSettings:
	get:
		return settings
		
	set(value):
		if settings == value:
			return
		
		if settings:
			settings.changed.disconnect(on_settings_changed)
		
		settings = value
		
		if settings:
			settings.changed.connect(on_settings_changed)
		
		update()

func on_settings_changed():
	update()

func update():

	%opbn_mask_type.selected = settings.mask_type

	%color_button.color = settings.color
	%spin_strength.value = settings.strength
	%spin_radius.value = settings.radius
	%check_pen_pressure_str.button_pressed = settings.pen_pressure_strength


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_color_button_color_changed(color:Color):
	settings.color = color


#func _on_opbn_geom_component_item_selected(index):
	#match index:
		#0:
			#settings.component_type = GeometryComponentType.Type.OBJECT
		#1:
			#settings.component_type = GeometryComponentType.Type.VERTEX
		#2:
			#settings.component_type = GeometryComponentType.Type.FACE
		#3:
			#settings.component_type = GeometryComponentType.Type.FACE_VERTEX


func _on_spin_strength_value_changed(value):
	settings.strength = value


func _on_check_pen_pressure_str_toggled(toggled_on):
	settings.pen_pressure_strength = toggled_on


func _on_spin_radius_value_changed(value):
	settings.radius = value


func _on_opbn_mask_type_item_selected(index):
	match index:
		0:
			settings.mask_type = CommandVertexPaintStroke.MaskType.NONE
		1:
			settings.mask_type = CommandVertexPaintStroke.MaskType.VERTICES
		2:
			settings.mask_type = CommandVertexPaintStroke.MaskType.FACES
