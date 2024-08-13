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
extends KeymapItem
class_name KeymapActionMapper

@export var enabled:bool = true:
	set(value):
		if enabled == value:
			return
			
		enabled = value
		emit_changed()
		keymap_tree_changed.emit()
	
@export var name:String:
	set(value):
		if name == value:
			return
			
		name = value
		emit_changed()
		keymap_tree_changed.emit()
		
@export var action_id:String:
	set(value):
		if action_id == value:
			return
			
		action_id = value
		emit_changed()
		keymap_tree_changed.emit()
	
@export var keypress:KeymapKeypress:
	set(value):
		if keypress == value:
			return
			
		keypress = value
		emit_changed()
		keymap_tree_changed.emit()
	
@export var params:Dictionary:
	set(value):
		if params == value:
			return
			
		params = value
		emit_changed()
		keymap_tree_changed.emit()


func lookup_invoker(context:CyclopsOperatorContext, event:InputEvent)->KeymapActionMapper:
	if !enabled:
		return null
	
	if keypress.is_invoked_by(context, event):
		return self
		
	return null

func is_invoked_by(context:CyclopsOperatorContext, event:InputEvent)->bool:
	if !enabled:
		return false
	
	return keypress.is_invoked_by(context, event)

func invoke(context:CyclopsOperatorContext, event:InputEvent):
	
	var action:CyclopsAction = context.plugin.get_action(action_id)
	if !action:
		push_warning("Could not find action with action_id '", action_id, "'")
		return
	
	for name:String in params.keys():
		action.set(name, params[name])
		
	action.invoke(context, event)
	
func set_parameter(key:String, value:Variant):
	params[key] = value
	keymap_tree_changed.emit()
	emit_changed()
	

#func get_action(context:CyclopsOperatorContext)->CyclopsAction:
	#var action:CyclopsAction = context.plugin.get_action(action_id)
	#if !action:
		#push_warning("Could not find action with action_id '", action_id, "'")
	#return action
