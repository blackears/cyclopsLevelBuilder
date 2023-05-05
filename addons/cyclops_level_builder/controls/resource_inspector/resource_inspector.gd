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
class_name ResourceInspector

@export var target:Resource:
	get:
		return target
	set(value):
		target = value
		build()

func add_label(name:String):
	var label:Label = Label.new()
	label.text = name
	$GridContainer.add_child(label)

func build():
	for child in $GridContainer.get_children():
		$GridContainer.remove_child(child)
		
	if !target:
		return
		
	for prop_dict in target.get_property_list():
		var prop_name:String = prop_dict["name"]
#		prop_dict["class_name"]
		
		var type:Variant.Type = prop_dict["type"]
		match type:
			TYPE_BOOL:
				add_label(prop_name)
				
				var editor:LineEditorBool = preload("res://addons/cyclops_level_builder/controls/resource_inspector/line_editor_bool.tscn").instantiate()
				editor.resource = target
				editor.prop_name = prop_name
				$GridContainer.add_child(editor)
				
			TYPE_INT:
				add_label(prop_name)
				
				var editor:LineEditorInt = preload("res://addons/cyclops_level_builder/controls/resource_inspector/line_editor_int.tscn").instantiate()
				editor.resource = target
				editor.prop_name = prop_name
				$GridContainer.add_child(editor)
				
			TYPE_FLOAT:
				add_label(prop_name)
				
				var editor:LineEditorFloat = preload("res://addons/cyclops_level_builder/controls/resource_inspector/line_editor_float.tscn").instantiate()
				editor.resource = target
				editor.prop_name = prop_name
				$GridContainer.add_child(editor)
		
		pass

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
