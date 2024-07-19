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
class_name KeymapInvokerEditor

signal delete_invoker(invoker:KeymapInvoker)

var plugin:CyclopsLevelBuilder

@export var invoker:KeymapInvoker:
	set(value):
		invoker = value
		
		if invoker:
			%check_enabled.button_pressed = invoker.enabled
			var action_id:String = invoker.action_id
			%line_action_id.text = invoker.action_id
			if invoker.input_event is KeymapKeypress:
				var keypress:KeymapKeypress = invoker.input_event
				%keymap_keypress_editor.keypress = keypress
				
			build_parameter_ui(action_id)
			#for child in %param_grid.get_children():
				#%param_grid.remove_child(child)
				#child.queue_free()
			#
			#print("action_id, ", action_id)
			#var action:CyclopsAction = plugin.get_action(action_id)
#
			#if action:
				#print("param props")
				#for prop_dict in action.get_property_list():
					#print("prop_dict ", prop_dict)
					#var prop_name:String = prop_dict["name"]
					#var usage:PropertyUsageFlags = prop_dict["usage"]
					#var hint:PropertyHint = prop_dict["hint"]
					#var hint_string:String = prop_dict["hint_string"]
					#
					#if !(usage & PROPERTY_USAGE_EDITOR):
						#continue
						#
					#print("-adding prop ", prop_name)
					#
					#var type:Variant.Type = prop_dict["type"]
					#match type:
						#TYPE_BOOL:
							#var label:Label = Label.new()
							#label.text = prop_name
							#%param_grid.add_child(label)
							#
							#var editor:CheckBox = CheckBox.new()
							#if invoker.params.has(prop_name):
								#editor.button_pressed = invoker.params[prop_name]
							#editor.toggled.connect(func(state:bool):
								#invoker.params[prop_name] = state
								#)
							#%param_grid.add_child(editor)
							#
						#TYPE_INT:
							#var label:Label = Label.new()
							#label.text = prop_name
							#%param_grid.add_child(label)
							#
							#var editor:SpinBox = SpinBox.new()
							#if invoker.params.has(prop_name):
								#editor.value = invoker.params[prop_name]
							#editor.value_changed.connect(func(value:float):
								#invoker.params[prop_name] = int(value)
								#)
							#
							#if hint == PROPERTY_HINT_RANGE:
								#var parts:Array = hint_string.split(",")
								#editor.min_value = int(float(parts[0]))
								#editor.max_value = int(float(parts[1]))
								#if parts.size() >= 2:
									#editor.step = int(float(parts[2]))
								#
							#%param_grid.add_child(editor)
							#
						#TYPE_FLOAT:
							#var label:Label = Label.new()
							#label.text = prop_name
							#%param_grid.add_child(label)
							#
							#var editor:SpinBox = SpinBox.new()
							#if invoker.params.has(prop_name):
								#editor.value = invoker.params[prop_name]
							#editor.value_changed.connect(func(value:float):
								#invoker.params[prop_name] = value
								#)
							#
							#if hint == PROPERTY_HINT_RANGE:
								#var parts:Array = hint_string.split(",")
								#editor.min_value = float(parts[0])
								#editor.max_value = float(parts[1])
								#if parts.size() >= 2:
									#editor.step = float(parts[2])
								#
							#%param_grid.add_child(editor)
						#
						#TYPE_STRING:
							#print("adding string")
							#var label:Label = Label.new()
							#label.text = prop_name
							#%param_grid.add_child(label)
							#
							#var editor:LineEdit = LineEdit.new()
							#editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
							#if invoker.params.has(prop_name):
								#editor.text = invoker.params[prop_name]
							#editor.text_submitted.connect(func(value:String):
								#invoker.params[prop_name] = value
								#)
								#
							#%param_grid.add_child(editor)

func build_parameter_ui(action_id:String):
	for child in %param_grid.get_children():
		%param_grid.remove_child(child)
		child.queue_free()
	
	if !%bn_show_params.button_pressed:
		return
		
#	print("action_id, ", action_id)
	var action:CyclopsAction = plugin.get_action(action_id)

	if action:
#		print("param props")
		for prop_dict in action.get_property_list():
			#print("prop_dict ", prop_dict)
			var prop_name:String = prop_dict["name"]
			var usage:PropertyUsageFlags = prop_dict["usage"]
			var hint:PropertyHint = prop_dict["hint"]
			var hint_string:String = prop_dict["hint_string"]
			
			if !(usage & PROPERTY_USAGE_EDITOR):
				continue
				
			#print("-adding prop ", prop_name)
			
			var type:Variant.Type = prop_dict["type"]
			match type:
				TYPE_BOOL:
					var label:Label = Label.new()
					label.text = prop_name
					%param_grid.add_child(label)
					
					var editor:CheckBox = CheckBox.new()
					if invoker.params.has(prop_name):
						editor.button_pressed = invoker.params[prop_name]
					editor.toggled.connect(func(state:bool):
						invoker.params[prop_name] = state
						)
					%param_grid.add_child(editor)
					
				TYPE_INT:
					var label:Label = Label.new()
					label.text = prop_name
					%param_grid.add_child(label)
					
					var editor:SpinBox = SpinBox.new()
					if invoker.params.has(prop_name):
						editor.value = invoker.params[prop_name]
					editor.value_changed.connect(func(value:float):
						invoker.params[prop_name] = int(value)
						)
					
					if hint == PROPERTY_HINT_RANGE:
						var parts:Array = hint_string.split(",")
						editor.min_value = int(float(parts[0]))
						editor.max_value = int(float(parts[1]))
						if parts.size() >= 2:
							editor.step = int(float(parts[2]))
						
					%param_grid.add_child(editor)
					
				TYPE_FLOAT:
					var label:Label = Label.new()
					label.text = prop_name
					%param_grid.add_child(label)
					
					var editor:SpinBox = SpinBox.new()
					if invoker.params.has(prop_name):
						editor.value = invoker.params[prop_name]
					editor.value_changed.connect(func(value:float):
						invoker.params[prop_name] = value
						)
					
					if hint == PROPERTY_HINT_RANGE:
						var parts:Array = hint_string.split(",")
						editor.min_value = float(parts[0])
						editor.max_value = float(parts[1])
						if parts.size() >= 2:
							editor.step = float(parts[2])
						
					%param_grid.add_child(editor)
				
				TYPE_STRING:
					#print("adding string")
					var label:Label = Label.new()
					label.text = prop_name
					%param_grid.add_child(label)
					
					var editor:LineEdit = LineEdit.new()
					editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					if invoker.params.has(prop_name):
						editor.text = invoker.params[prop_name]
					editor.text_submitted.connect(func(value:String):
						invoker.params[prop_name] = value
						)
					editor.focus_exited.connect(func():
						invoker.params[prop_name] = editor.text
						)
						
					%param_grid.add_child(editor)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_bn_show_params_toggled(toggled_on):
	#%param_area.visible = toggled_on
	
	build_parameter_ui(invoker.action_id)

	pass # Replace with function body.


func _on_bn_delete_pressed():
	delete_invoker.emit(invoker)


func _on_bn_browse_action_id_pressed():
	var popup:ActionIdSelector = preload("res://addons/cyclops_level_builder/gui/docks/cyclops_console/keymap_editor/action_id_selector.tscn").instantiate()
	popup.plugin = plugin
	popup.id_selected.connect(func(id:String): 
		invoker.action_id = id
		%line_action_id.text = invoker.action_id
		build_parameter_ui(invoker.action_id)
		popup.hide()
		popup.queue_free()
		)
	
	add_child(popup)
	popup.popup_centered()



func _on_line_action_id_text_submitted(new_text):
	invoker.action_id = new_text
	build_parameter_ui(invoker.action_id)
