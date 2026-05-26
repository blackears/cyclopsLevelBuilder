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
class_name UvEditorSnappingGridEditor

@onready var spin_rotation_increment:SpinBox = %spin_rotation_increment
@onready var bn_affect_move:Button = %bn_affect_move
@onready var bn_affect_rotate:Button = %bn_affect_rotate
@onready var bn_affect_scale:Button = %bn_affect_scale

var settings:UvEditorSnappingGrid:
	set(v):
		if v == settings:
			return
		
		settings = v
		
		if is_node_ready():
			update_from_settings()

func _ready() -> void:
	update_from_settings()

func update_from_settings():
	if !settings:
		return

	#bn_affect_move.button_pressed = (settings.affects_flags & UvEditorSnappingGrid.AFFECTS_MOVE) != 0
	#bn_affect_rotate.button_pressed = (settings.affects_flags & UvEditorSnappingGrid.AFFECTS_ROTATE) != 0
	#bn_affect_scale.button_pressed = (settings.affects_flags & UvEditorSnappingGrid.AFFECTS_SCALE) != 0
	
#	spin_rotation_increment.value = settings.rotation_increment


func _on_bn_affect_move_toggled(toggled_on: bool) -> void:
	#if toggled_on:
		#settings.affects_flags |= UvEditorSnappingGrid.AFFECTS_MOVE
	#else:
		#settings.affects_flags &= ~UvEditorSnappingGrid.AFFECTS_MOVE
	pass


func _on_bn_affect_rotate_toggled(toggled_on: bool) -> void:
	#if toggled_on:
		#settings.affects_flags |= UvEditorSnappingGrid.AFFECTS_ROTATE
	#else:
		#settings.affects_flags &= ~UvEditorSnappingGrid.AFFECTS_ROTATE
	pass


func _on_bn_affect_scale_toggled(toggled_on: bool) -> void:
	#if toggled_on:
		#settings.affects_flags |= UvEditorSnappingGrid.AFFECTS_SCALE
	#else:
		#settings.affects_flags &= ~UvEditorSnappingGrid.AFFECTS_SCALE
	pass


func _on_spin_rotation_increment_value_changed(value: float) -> void:
#	settings.rotation_increment = value
	pass
