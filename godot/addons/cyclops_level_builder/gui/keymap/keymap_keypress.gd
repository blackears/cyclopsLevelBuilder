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
extends KeymapInputEvent
class_name KeymapKeypress

@export var keycode:Key = KEY_NONE:
	set(value):
		keycode = value
		changed.emit()

@export var shift:bool = false:
	set(value):
		shift = value
		changed.emit()
		
@export var ctrl:bool = false:
	set(value):
		ctrl = value
		changed.emit()
		
@export var alt:bool = false:
	set(value):
		alt = value
		changed.emit()

func is_invoked_by(context:CyclopsOperatorContext, event:InputEvent)->bool:
	if event is InputEventKey:
		var e:InputEventKey = event
		
		if e.keycode != keycode:
			return false
		if e.shift_pressed != shift:
			return false
		if e.ctrl_pressed != ctrl:
			return false
		if e.alt_pressed != alt:
			return false
	
		return true
	
	return false
