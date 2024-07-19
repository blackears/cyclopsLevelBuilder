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
extends Resource
class_name KeymapInvoker

@export var enabled:bool = true
@export var action_id:String
@export var input_event:KeymapInputEvent
@export var params:Dictionary

func is_invoked_by(context:CyclopsOperatorContext, event:InputEvent)->bool:
	if !enabled:
		return false
	
	return input_event.is_invoked_by(context, event)

func invoke(context:CyclopsOperatorContext, event:InputEvent):
	
	var action:CyclopsAction = context.plugin.get_action(action_id)
	if !action:
		push_warning("Could not find action with action_id '", action_id, "'")
		return
	
	for name:String in params.keys():
		action.set(name, params[name])
		
	action.invoke(context, event)
	

#func get_action(context:CyclopsOperatorContext)->CyclopsAction:
	#var action:CyclopsAction = context.plugin.get_action(action_id)
	#if !action:
		#push_warning("Could not find action with action_id '", action_id, "'")
	#return action
