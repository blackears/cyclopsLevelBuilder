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
extends Node
class_name HotkeyItem

## Key to press
@export var key:Key:
	set(value):
		key = value
		
		if is_node_ready():
			editor_description = _key_as_string()

@export var shift:bool:
	set(value):
		shift = value
		
		if is_node_ready():
			editor_description = _key_as_string()
	
@export var ctrl:bool:
	set(value):
		ctrl = value
		
		if is_node_ready():
			editor_description = _key_as_string()
	
@export var alt:bool:
	set(value):
		alt = value
		
		if is_node_ready():
			editor_description = _key_as_string()

## Action hotkey will be mapped to
@export var action:CyclopsAction

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _key_as_string() -> String:
	return OS.get_keycode_string(key) \
		+ (" + shift" if shift else "") \
		+ (" + ctrl" if ctrl else "") \
		+ (" + alt" if alt else "")
		
