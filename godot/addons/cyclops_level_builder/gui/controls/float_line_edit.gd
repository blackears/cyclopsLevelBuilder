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
extends LineEdit
class_name FloatLineEdit

signal value_changed(value:float)

enum BoundsCheck { NONE, HARD, SFOT }

@export var value:float:set = set_value
		
@export var min_value:float = 0
@export var max_value:float = 100
@export var soft_min_value:float = 0
@export var soft_max_value:float = 100
@export var bounds_check_min:BoundsCheck
@export var bounds_check_max:BoundsCheck
@export var drag_step:float = .1
@export var round_digits:int = 3

var dragging:bool = false
var mouse_down_pos:Vector2
var start_drag_value:float

func set_value(v:float):
	if v == value:
		return
	value = v
	
	update_text()
	value_changed.emit(value)

func set_value_no_signal(v:float):
	if v == value:
		return
	value = v
	
	update_text()

func update_text():
#	text = str(value)
	var strn:String = ("%." + str(max(round_digits, 0)) + "f") % [value]
	strn = strn.rstrip("0")
	strn = strn.rstrip(".")
	text = strn
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
#	text = str(value)
	update_text()
	pass # Replace with function body.



func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			dragging = true
			mouse_down_pos = event.position
			
			var exp:Expression = Expression.new()
			var err = exp.parse(text)
			
			if err:
				start_drag_value = 0
			else:
				var result = exp.execute()
				start_drag_value = result if (result is float || result is int) else 0
		else:
			dragging = false
			
	if event is InputEventMouseMotion:
		if dragging:
			var offset:Vector2 = event.position - mouse_down_pos
			var new_val:float = start_drag_value + offset.x * drag_step
#			value = snapped(new_val, pow(.1, round_digits))
			value = new_val
			
#			print(value)


func _on_text_submitted(new_text: String) -> void:
	var exp:Expression = Expression.new()
	var err = exp.parse(text)
	
	if err:
		value = 0
	else:
		value = exp.execute()
