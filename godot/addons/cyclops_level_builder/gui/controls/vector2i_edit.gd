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
extends HFlowContainer
class_name Vector2iEdit

signal value_changed(value:Vector2i)

@export var value:Vector2i: set = set_value
	
func set_value(v:Vector2i):
		if v == value:
			return
		
		value = v
		
		%spin_x.set_value_no_signal(value.x)
		%spin_y.set_value_no_signal(value.y)
		
		value_changed.emit(value)

func set_value_no_signal(v:Vector2i):
		if v == value:
			return
		
		value = v
		
		%spin_x.set_value_no_signal(value.x)
		%spin_y.set_value_no_signal(value.y)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%spin_x.set_value_no_signal(value.x)
	%spin_y.set_value_no_signal(value.y)
	pass # Replace with function body.


func _on_spin_x_value_changed(v: float) -> void:
	set_value(Vector2i(v, value.y))


func _on_spin_y_value_changed(v: float) -> void:
	set_value(Vector2i(value.x, v))
	pass # Replace with function body.
