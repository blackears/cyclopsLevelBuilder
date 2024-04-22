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
class_name ToolBlockSettingsEditor

var settings:ToolBlockSettings:
	get:
		return settings
	set(value):
		settings = value
		dirty = true

var dirty:bool = true

func _ready():
	%collision_type.clear()
	for text in Collision.Type.keys():
		%collision_type.add_item(text)

func _process(delta):
	if dirty:
		update()
		dirty = false

func update():
	if !settings:
		%check_match_selected_block.disabled = true
		%default_block_elevation.disabled = true
		%default_block_height.disabled = true
		return

	%check_match_selected_block.disabled = false
	%check_match_selected_block.button_pressed = settings.match_selected_block
	%default_block_elevation.disabled = false
	%default_block_elevation.value = settings.default_block_elevation
	%default_block_height.disabled = false
	%default_block_height.value = settings.default_block_height
	
	%alignment_type.selected = settings.block_alignment
	
	%collision_type.selected = settings.collision_type
	%collision_layers.value = settings.collision_layer
	%collision_mask.value = settings.collision_mask


func _on_default_block_height_value_changed(value:float):
	settings.default_block_height = value


func _on_default_block_elevation_value_changed(value:float):
	settings.default_block_elevation = value


func _on_check_match_selected_block_toggled(value:bool):
	settings.match_selected_block = value


func _on_collision_layers_value_changed(value):
	settings.collision_layer = value


func _on_collision_mask_value_changed(value):
	settings.collision_mask = value

func _on_collision_type_item_selected(index):
	settings.collision_type = index


func _on_alignment_type_item_selected(index):
	settings.block_alignment = index
