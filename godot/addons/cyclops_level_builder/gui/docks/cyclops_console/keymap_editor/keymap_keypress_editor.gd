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
class_name KeymapKeypressEditor

@export var keypress:KeymapKeypress:
	set(value):
		if keypress:
			keypress.changed.disconnect(on_keypress_changed)
			
		keypress = value
		
		if keypress:
			keypress.changed.connect(on_keypress_changed)
			
		setup_ui()

func setup_ui():
	if keypress:
		var text:String = OS.get_keycode_string(keypress.keycode)
		print("text *", text, "*")
		if text == "":
			text = " "
		%bn_keycode.text = text
		%check_shift.button_pressed = keypress.shift
		%check_ctrl.button_pressed = keypress.ctrl
		%check_alt.button_pressed = keypress.alt

func on_keypress_changed():
	#print("on_keypress_changed()")
	setup_ui()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_bn_keycode_pressed():
	if keypress:
		#print("_on_bn_keycode_pressed")
		#keypress.keycode = toggled_on
		var picker:KeycodePicker = preload("res://addons/cyclops_level_builder/gui/docks/cyclops_console/keymap_editor/keycode_picker.tscn").instantiate()
		add_child(picker)
		picker.key = keypress.keycode
		picker.key_selected.connect(func(key): 
			keypress.keycode = key
			#print("Setting keycode ", OS.get_keycode_string(key))
			picker.hide()
			picker.queue_free()
			)
		
		picker.popup_centered()
		pass


func _on_check_shift_toggled(toggled_on):
	if keypress:
		keypress.shift = toggled_on


func _on_check_ctrl_toggled(toggled_on):
	if keypress:
		keypress.ctrl = toggled_on


func _on_check_alt_toggled(toggled_on):
	if keypress:
		keypress.alt = toggled_on
