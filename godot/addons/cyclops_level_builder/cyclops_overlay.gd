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
extends Control
class_name CyclopsOverlay


class TextLabel extends Resource:
	var text:String
	var pos:Vector2
	var font:Font
	var font_size:float
	
var text_labels:Array[TextLabel]

func draw_text(text:String, pos:Vector2, font:Font, font_size:float):
	#print("draw_Text")
	var label:TextLabel = TextLabel.new()
	label.text = text
	label.pos = pos
	label.font = font
	label.font_size = font_size
	
	text_labels.append(label)
	queue_redraw()

#func add_label(label:TextLabel):
#	text_labels.append(label)
#	queue_redraw()
	
func clear():
	text_labels.clear()
	queue_redraw()
	
func _draw():
	for label in text_labels:
		draw_string(label.font, label.pos, \
			label.text, HORIZONTAL_ALIGNMENT_CENTER, -1, \
			label.font_size)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
