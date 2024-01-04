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
class_name NumbericLineEdit

signal value_changed(value:float)

@export var value:float:
	get:
		return value
	set(v):
		if value == v:
			return
		value = v
		dirty = true

@export var snap_size:float = 1

@export var disabled:bool = false

var dirty:bool = true

enum State{ IDLE, READY, DRAGGING, TEXT_EDIT }
var state:State = State.IDLE

var mouse_down_pos:Vector2
var drag_start_radius:float = 4
var value_start_drag:float

var line_input:LineEdit
var line_display:Label

# Called when the node enters the scene tree for the first time.
func _ready():
	var foo = $HBoxContainer/line_display
	var uuu = get_node("HBoxContainer/line_display")
	
	line_input = %line_input
	line_display = %line_display
	
	if line_input:
		line_input.visible = false
	pass

func _process(delta):
	if dirty:
#		print("---value " + str(value))
		if line_input:
			line_input.text = format_number(value)
			line_display.text = format_number(value)
		
		dirty = false
	
func format_number(val:float)->String:
	var text:String = "%.5f" % val
	var idx:int = text.findn(".")
	if idx != -1:
		text = text.rstrip("0")
		if text.right(1) == ".":
			text = text.left(-1)
	return text
	

func _gui_input(event):
	if event is InputEventMouseButton:
		var e:InputEventMouseButton = event
		if e.is_pressed():
			if state == State.IDLE:
				mouse_down_pos = e.position
				state = State.READY
		else:
			if state == State.READY:
				if line_input:
					line_input.visible = true
					line_display.visible = false
				state = State.TEXT_EDIT
			elif state == State.DRAGGING:
				state = State.IDLE
				
				
		accept_event()
			
	elif event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event
		if state == State.READY:
			if e.position.distance_to(mouse_down_pos) >= drag_start_radius:
				state = State.DRAGGING
				value_start_drag = value
				
		elif state == State.DRAGGING:
			var offset = e.position.x - mouse_down_pos.x
			var new_value = value_start_drag + (offset * snap_size / 20.0)
			#print("-new_value %s" % new_value)
			new_value = ceil(new_value / snap_size) * snap_size
			
			#print("new_value %s" % new_value)
			
			if value != new_value:
				value = new_value
				value_changed.emit(value)
				dirty = true

func _on_line_edit_text_submitted(new_text):
	var regex = RegEx.new()
	regex.compile("^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$")
	var result:RegExMatch = regex.search(new_text)
	if result:
#		print("found match")
		value = float(new_text)
		value_changed.emit(value)
		
	dirty = true
	state = State.IDLE
	if line_input:
		line_input.visible = false
		line_display.visible = true

