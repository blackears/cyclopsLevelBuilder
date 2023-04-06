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
class_name MaterialThumbnail

@export var selected:bool = false

@export_file("*.tres") var material_path:String:
	get:
		return material_path
	set(value):
		material_path = value
		$VBoxContainer/MaterialName.text = value

@export var group:ThumbnailGroup:
	get:
		return group
	set(value):
		if group == value:
			return
		
		if group != null:
			group.remove_thumbnail(self)
		
		group = value
		
		if group != null:
			group.add_thumbnail(self)
			
			

@export var theme_normal:Theme
@export var theme_selected:Theme

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if selected:
		theme = theme_selected
	else:
		theme = theme_normal
	
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			grab_focus()
			if group:
				group.select_thumbnail(self)
		else:
			selected = true
		
		get_viewport().set_input_as_handled()



func _on_focus_entered():
	pass # Replace with function body.


func _on_focus_exited():
	pass # Replace with function body.


func _on_tree_exiting():
	if group != null:
		group.remove_thumbnail(self)
		
