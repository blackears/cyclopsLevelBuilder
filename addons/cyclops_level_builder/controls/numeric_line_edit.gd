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
class_name NumbericLineEdit

signal value_changed(value)

@export var value:float:
	get:
		return value
	set(v):
		if value == v:
			return
		value = v
		text = "%s" % value

@export var step_size:float = 1

# Called when the node enters the scene tree for the first time.
func _ready():
#	text = "%.4f" % value
	text = "%s" % value

func _on_text_submitted(new_text):
	#print("text changed2 %s" % new_text)
	
	var regex = RegEx.new()
	regex.compile("^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$")
	var result:RegExMatch = regex.search(new_text)
	if result:
#		print("found match")
		value = float(new_text)
		value_changed.emit(value)

	#var v:float = round(value * 1000) / 1000

#	text = "%.4f" % v
	#text = "%s" % v
	text = "%s" % value
	print("text changed2 %s" % text)
