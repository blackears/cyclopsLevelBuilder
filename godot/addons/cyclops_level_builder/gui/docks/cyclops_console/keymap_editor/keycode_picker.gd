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
extends Popup
class_name KeycodePicker

signal key_selected(key:Key, modifier_mask:KeyModifierMask)

@export var key:Key:
	set(value):
		key = value
		%line_keycode_string.text = OS.get_keycode_string(key)

func _unhandled_input(event):
	
#	if %capture.button_pressed:
	if event is InputEventKey:
		var e:InputEventKey = event
		if e.keycode == KEY_SHIFT || e.keycode == KEY_CTRL || e.keycode == KEY_ALT || e.keycode == KEY_META:
			return
		
		if e.is_pressed():
			key = e.keycode
			%capture.button_pressed = false
			
			var mask:KeyModifierMask = \
				(KEY_MASK_SHIFT if Input.is_key_pressed(KEY_SHIFT) else 0) |\
				(KEY_MASK_CTRL if Input.is_key_pressed(KEY_CTRL) else 0) |\
				(KEY_MASK_ALT if Input.is_key_pressed(KEY_ALT) else 0) |\
				(KEY_MASK_META if Input.is_key_pressed(KEY_META) else 0)
			
			key_selected.emit(key, mask)
			
		get_viewport().set_input_as_handled()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_line_keycode_string_text_submitted(new_text:String):
	key = OS.find_keycode_from_string(new_text)
	key_selected.emit(key)
